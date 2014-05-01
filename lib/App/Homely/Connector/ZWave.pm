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
    myzway_init(0);
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

ZWay zway;

static void myzway_log(char *loglevel, char *format ...) {
    va_list argptr;
    char *buffer;
    
    va_start(argptr,loglevel);
    ret = vsprintf(buffer, format, aptr);
    va_end(argptr);
    
    dSP;
    
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvf(loglevel)));
    XPUSHs(sv_2mortal(newSVpvf(buffer)));
    PUTBACK;

    call_pv("do_log", G_DISCARD);

    FREETMPS;
    LEAVE;

    SPAGAIN;
}

static void myzway_callback(ZWay zway, ZWDataChangeType aType, ZDataHolder data_holder, void * apArg) {
    char* path = zway_data_get_path(zway,data_holder);
    
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

static ZDataHolder myzway_dataholder(ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE command_id) {
    zway_data_acquire_lock(zway);
    
    ZDataHolder data_holder = zway_find_device_instance_cc_data(zway, node_id, instance_id, command_id, "");
    if (data_holder == NULL) {
        myzway_log("error","No data holder for node_id=%i,instance_id=%i,command_id=%i",node_id,instance_id,command_id);
        zway_data_release_lock(zway);
    }
    
    return data_holder;
}

static void myzway_device_event(const ZWay zway, ZWDeviceChangeType type, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE command_id, void *arg) {
    switch (type) {
        case  DeviceAdded:
            myzway_log("debug","New device added: %i",node_id);
            break;

        case DeviceRemoved:
            myzway_log("debug","Device removed: %i",node_id);
            break;

        case InstanceAdded:
            myzway_log("debug","New instance added to device %i: %i",node_id,instance_id);
            break;

        case InstanceRemoved:
            myzway_log("debug","Instance removed from device %i: %i\n", node_id, instance_id);
            break;

        case CommandAdded:
            myzway_log("debug","New Command Class added to device %i:%i: %i\n", node_id, instance_id, command_id);
            ZDataHolder data_holder = myzway_dataholder(node_id, instance_id, command_id);
            if (ZDataHolder != NULL) {
                zway_data_add_callback_ex(zway, data_holder, &myzway_callback, 0); // Do not watch children!
                zway_data_release_lock(zway);
            }
            break;

        case CommandRemoved:
            myzway_log("debug","Command Class removed from device %i:%i: %i\n", node_id, instance_id, command_id);
            ZDataHolder data_holder = myzway_dataholder(node_id, instance_id, command_id);
            if (ZDataHolder != NULL) {
                zway_data_remove_callback_ex(zway,data_holder,&myzway_callback);
                zway_data_release_lock(zway);
            }
            break;
    }
}

int myzway_init(int loglevel) {
    if (zway == NULL) {
        ZWError result;
        
        memset(&zway, 0, sizeof(zway));
        result = zway_init(
            &zway, 
            "/dev/ttyAMA0",
            "/opt/z-way-server/config",
            "/opt/z-way-server/translations",
            "/opt/z-way-server/ZDDX", 
            stdout, 
            loglevel
        );
        
        if (result == NoError) {
            result = zway_device_add_callback(zway, DeviceAdded | DeviceRemoved | InstanceAdded | InstanceRemoved | CommandAdded | CommandRemoved, myzway_device_event, NULL);
        } else {
            myzway_log("error","Could not initialize zway %d",result);
            return -1;
        }
        if (result == NoError) {
            result = zway_start(zway,NULL);
        }
        if (result == NoError) {
            result = zway_discover(zway);
        }
        if (result != NoError) {
            myzway_log("error","Could not start zway %d",result);
            return 0;
        }
    }
    return 1;
}

int myzway_finish() {
    ZWError result;
    
    int success = 1;
    if (zway != NULL) {
        result = zway_stop(zway);
        
        if (result != NoError) {
            myzway_log("error","Could not finish zway %d",result);
            success = 0;
        }
        zway_terminate(&zway);
        
        zway = NULL;
    }
    
    return success;
}

/*
int myzway_add_callback(ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE command_id) {
    zway_data_acquire_lock(zway);
    ZDataHolder dataHolder = zway_find_device_instance_cc_data(zway, node_id, instance_id, command_id, "");
    if (dataHolder != NULL) {
        zway_data_add_callback_ex(zway, dataHolder, &myzway_callback, 1, "");
    } else {
        myzway_log("error","No data holder for node_id=%i,instanceId=%i,CommandClass=%i",node_id,instance_id,command_id);
        return 0;
    }
    zway_data_release_lock(zway);
    return 1;
}
*/

