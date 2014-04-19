# ============================================================================
package App::Homely::Connector::ZWave;
# ============================================================================
use strict;
use warnings;
use utf8;

use Moose;
extends qw(App::Homely::Connector);

use Inline 
    C               => 'Config', 
    LIBS            => '-L/opt/z-way-server/libs -L/lib/arm-linux-gnueabihf -L/usr/lib/arm-linux-gnueabihf -lzway -lxml2 -lpthread -lcrypto -larchive',
    INC             => '-I/opt/z-way-server/libzway-dev',
    AUTO_INCLUDE    => '#include "ZWayLib.h"';
    
use Inline 
    C       => 'DATA',
    NAME    => __PACKAGE__;

use Log::Any qw($log);

Inline->init();
my $stash = Package::Stash->new(__PACKAGE__);

sub init {
    my ($self) = @_;
    my $core = App::Homely::Core->instance;
    warn myzway_init($core->debug ? 0:3); 
}

sub DEMOLISH {
    my ($self) = @_;
    myzway_finish(); 
}

sub add_callback {
    my ($self,$device,$instance,$command,$callback) = @_;
    
    die('Device, instance, command or callback missing')
        unless defined $device
        && defined $instance
        && defined $command
        && defined $callback
        && ref($callback) eq 'CODE';
    
    my $symbol = '&callback_'.$device.'_'.$instance.'_'.$command;
    unless ($stash->has_symbol($symbol)) {
        $stash->add_symbol($symbol,sub {
            $log->debug('Got callback from DeviceId='.$device.',InstanceId='.$instance.'CommandClass='.$command);
            $callback->($device,$instance,$command,@_);
        });
    }
    myzway_add_callback($device,$instance,$command);
}

sub do_callback {
    my ($path) = @_;
    my $self = __PACKAGE__->instance;
    $log->debug('Got callback from '.$path);
}

sub do_log {
    my ($loglevel,$message) = @_;
    $log->$loglevel('LOG'.$message);
}

1;

__DATA__
__C__

ZWay aZWay;

static void myzway_log(char *loglevel, char *message) {
    dSP;
    
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(loglevel)));
    XPUSHs(sv_2mortal(newSVpv(message)));
    PUTBACK;

    call_pv("do_log", G_DISCARD);

    FREETMPS;
    LEAVE;
    
    SPAGAIN;
}

static void myzway_callback(ZWay aZWay, ZWDataChangeType aType, ZDataHolder aData, void * apArg) {
    char* path = zway_data_get_path(aZWay,aData);
    
    dSP;
    
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(path)));
    PUTBACK;

    call_pv("do_callback", G_DISCARD);

    FREETMPS;
    LEAVE;
    
    SPAGAIN;
}

int myzway_init(int LogLevel) {
    if (aZWay != NULL) {
        ZWError result;
        memset(&aZWay, 0, sizeof(aZWay));
        result = zway_init(&aZWay, "/dev/ttyAMA0",
            "/opt/z-way-server/config",
            "/opt/z-way-server/translations",
            "/opt/z-way-server/ZDDX", 
            stdout, 
            LogLevel
        );
        if (result == NoError) {
            result = zway_start(aZWay,NULL);
        }
        if (result == NoError) {
            char errormessage[100];
            sprintf(errormessage,"Could not initialize zway %d",result);
            myzway_log('error',errormessage);
            return 0;
        }
    }
    return 1;
}

int myzway_finish() {
    ZWError result;
    int success = 1;
    if (aZWay != NULL) {
        result = zway_stop(aZWay);
        if (result != NoError) {
            char errormessage[100];
            sprintf(errormessage,"Could not finish zway %d",result);
            myzway_log('error',errormessage);
            success = 0;
        }
        zway_terminate(&aZWay);
    }
    return success;
}

int myzway_add_callback(int DeviceId, int InstanceId, int CommandClass) {
    zway_data_acquire_lock(aZWay);
    ZDataHolder dataHolder = zway_find_device_instance_cc_data(aZWay, DeviceId, InstanceId, CommandClass, "");
    if (dataHolder != NULL) {
        zway_data_add_callback_ex(aZWay, dataHolder, &myzway_callback, 1, "");
    } else {
        char errormessage[100];
        sprintf(errormessage,"No data holder for deviceId=%i,instanceId=%i,CommandClass=%i",DeviceId,InstanceId,CommandClass);
        myzway_log('error',errormessage);
        return 0;
    }
    zway_data_release_lock(aZWay);
    return 1;
}


