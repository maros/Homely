# ============================================================================
package App::Homely::Connector::ZWave;
# ============================================================================
use strict;
use warnings;
use utf8;

use Inline 'C' 
    => Config 
    => LIBS => '-L/opt/z-way-server/libs -L/lib/arm-linux-gnueabihf -L/usr/lib/arm-linux-gnueabihf -lzway -lxml2 -lpthread -lcrypto -larchive'
    => INC  => '-I/opt/z-way-server/libzway-dev';
use Inline 'C';
use Log::Any qw($log);

my $stash = Package::Stash->new(__PACKAGE__);

sub init {
    my ($self) = @_;
    my $core = App::Homely::Core->instance;
    _init_zway($core->debug ? 0:3); 
}

sub DEMOLISH {
    _finish_zway(); 
}

sub add_callback {
    my ($self,$device,$instance,$command,$callback) = @_;
    
    my $symbol = '&callback_'.$device.'_'.$instance.'_'.$command;
    unless ($stash->has_symbol($symbol)) {
        $stash->add_symbol($symbol,sub {
            $log->debug('Got callback from DeviceId='.$device.',InstanceId='.$instance.'CommandClass='.$command);
            $callback->($device,$instance,$command,@_);
        });
        _add_callback($device,$instance,$command);
    }
    _add_callback($device,$instance,$command);
}

sub _callback {
    my ($path) = @_;
    my $self = __PACKAGE__->instance;
    $log->debug('Got callback from '.$path);
}

sub _log {
    my ($loglevel,$message) = @_;
    $log->$loglevel($message);
}

1;

__END__
__C__

#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <ZWayLib.h>

ZWay aZWay;

char* concat(char *s1, char *s2) {
    char *result = malloc(strlen(s1)+strlen(s2)+1);//+1 for the zero-terminator
    //in real code you would check for errors in malloc here
    strcpy(result, s1);
    strcat(result, s2);
    return result;
}

void _log(char* loglevel, char* message) {
    ENTER;
    SAVETMPS;

    XPUSHs(sv_2mortal(newSVpvf(loglevel)));
    XPUSHs(sv_2mortal(newSVpvf(message)));
    PUTBACK;

    call_pv("_log", G_DISCARD);

    FREETMPS;
    LEAVE;
}

int _init_zway(int LogLevel) {
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
            _log('error',errormessage);
            return 0;
        }
    }
    return 1;
}

int _finish_zway() {
    ZWError result;
    int success = 1;
    if (aZWay != NULL) {
        result = zway_stop(aZWay);
        if (result != NoError) {
            char errormessage[100];
            sprintf(errormessage,"Could not finish zway %d",result);
            _log('error',errormessage);
            success = 0;
        }
        zway_terminate(&aZWay);
    }
    return success;
}

int _add_callback(int DeviceId, int InstanceId, int CommandClass) {
    zway_data_acquire_lock(aZWay);
    ZDataHolder dataHolder = zway_find_device_instance_cc_data(aZWay, DeviceId, InstanceId, CommandClass, "");
    if (dataHolder != NULL) {
        zway_data_add_callback_ex(aZWay, dataHolder, &_dataChangeCallback, 1, "");
    } else {
        char errormessage[150];
        sprintf("No data holder for deviceId=%i,instanceId=%i,CommandClass=%i",DeviceId,InstanceId,CommandClass);
        _log('error',errormessage);
        return 0;
    }
    zway_data_release_lock(aZWay);
    return 1;
}

void _dataChangeCallback(ZWay aZWay, ZWDataChangeType aType, ZDataHolder aData, void * apArg) {
    char *path = zway_data_get_path(aZWay,aData);
    
    ENTER;
    SAVETMPS;

    XPUSHs(sv_2mortal(newSVpvf(path)));
    PUTBACK;

    call_pv("_callback", G_DISCARD);

    FREETMPS;
    LEAVE;
*/
}
