# ============================================================================
package App::Homely::Connector::ZWave;
# ============================================================================
use utf8;
use 5.014;

use Moose;
extends qw(App::Homely::Connector);

use Inline
    C               => 'Config', 
    LIBS            => '-L/opt/z-way-server/libs -L/lib/arm-linux-gnueabihf -L/usr/lib/arm-linux-gnueabihf -lzway -lxml2 -lpthread -lcrypto -larchive',
    INC             => '-I/opt/z-way-server/libzway-dev',
    AUTO_INCLUDE    => '#include "ZWayLib.h"
#include <pthread.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/select.h>',
    # DEBUG ONLY
    CLEAN_AFTER_BUILD=> 0,
    BUILD_NOISY     => 1;
    
use Inline 
    C       => 'DATA',
    NAME    => __PACKAGE__;

use Log::Any qw($log);

Inline->init();
my $stash = Package::Stash->new(__PACKAGE__);

sub init {
    my ($self) = @_;
    myzway_init(3);
    #my $core = App::Homely::Core->instance;
    #myzway_init($core->debug ? 0:3);
    return $self;
}

sub DEMOLISH {
    my ($self) = @_;
    myzway_finish(); 
}

sub do_callback {
    my ($path) = @_;
    my $self = __PACKAGE__->instance;
    $log->debug('Got callback from '.$path.' via ');
}

sub do_log {
    my ($loglevel,$message) = @_;
    warn "------> $loglevel - $message";
    #$log->$loglevel('LOG'.$message);
}

sub loop {
    while(1) { 
        say "CHECK:".myzway_check();
        sleep 1 
    }
}

1;

__DATA__
__C__

ZWay zway;
pthread_t main_thread;
int fd[2];

static int myzway_in_mainthread() {
    if (main_thread == (unsigned int)pthread_self()) {
        return 1;
    } else {
        return 0;
    }
}

static void myzway_log(char *loglevel, char *format, ...) {
    va_list argptr;
    char buffer[200];
    
    va_start(argptr,format);
    vsprintf(buffer, format, argptr);
    va_end(argptr);
    
    printf("(PID=%i,TID=%i)myzway_log going to call do_log with: %s,%s\n",getpid(),(unsigned int)pthread_self(),loglevel,buffer);
    
    dSP;
    
    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvf(loglevel)));
    XPUSHs(sv_2mortal(newSVpvf(buffer)));
    PUTBACK;
    
    call_pv("do_log", G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;

    SPAGAIN;
}

static void myzway_event(ZWay zway, ZWDataChangeType aType, ZDataHolder data_holder, void * apArg) {
    char *path = zway_data_get_path(zway,data_holder);
    zway_log(zway, Debug, ZSTR("[myzway_event] Got data holder event: %s\n"), path);
    write(fd[1], path, strlen(path));
}

static ZDataHolder myzway_dataholder(const ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE command_id) {
    zway_data_acquire_lock(zway);
    
    ZDataHolder data_holder = zway_find_device_instance_cc_data(zway, node_id, instance_id, command_id, "");
    if (data_holder == NULL) {
        zway_log(zway, Error, ZSTR("[myzway_device_event] No data holder for node_id=%i,instance_id=%i,command_id=\n"), node_id, instance_id,command_id);
        zway_data_release_lock(zway);
    }
    return data_holder;
}

static void myzway_device_event(const ZWay zway, ZWDeviceChangeType type, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE command_id, void *arg) {
    ZDataHolder data_holder;
    
    switch (type) {
        case  DeviceAdded:
            zway_log(zway, Debug, ZSTR("[myzway_device_event] New device added: %i\n"), node_id);
            break;

        case DeviceRemoved:
            zway_log(zway, Debug, ZSTR("[myzway_device_event] Device removed: %i\n"),node_id);
            break;

        case InstanceAdded:
            zway_log(zway, Debug, ZSTR("[myzway_device_event] New instance added to device %i: %i\n"),node_id,instance_id);
            break;

        case InstanceRemoved:
            zway_log(zway, Debug, ZSTR("[myzway_device_event] Instance removed from device %i: %i\n"), node_id, instance_id);
            break;

        case CommandAdded:
            zway_log(zway, Debug, ZSTR("[myzway_device_event] Command Class added to device %i:%i: %i\n"), node_id, instance_id, command_id);
            data_holder = myzway_dataholder(zway, node_id, instance_id, command_id);
            if (data_holder != NULL) {
                zway_data_add_callback_ex(zway, data_holder, &myzway_event, 0, ""); // Do not watch children!
                zway_data_release_lock(zway);
            }
            break;

        case CommandRemoved:
            zway_log(zway, Debug, ZSTR("[myzway_device_event] Command Class removed from device %i:%i: %i\n"), node_id, instance_id, command_id);
            data_holder = myzway_dataholder(zway, node_id, instance_id, command_id);
            if (data_holder != NULL) {
                zway_data_remove_callback_ex(zway, data_holder, &myzway_event, "");
                zway_data_release_lock(zway);
            }
            break;
    }
}

int myzway_init(int loglevel) {
    if (zway == NULL) {
        ZWError result;
        
        main_thread = pthread_self();        
        pipe(fd);
        
        myzway_log("info","Initializing zway %i",1);
        
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
            myzway_log("warning","Start zway");
            result = zway_start(zway,NULL);
        }
        if (result == NoError) {
            myzway_log("warning","Discover zway");
            result = zway_discover(zway);
            
            if (myzway_in_mainthread()) {
                close(fd[1]);
            }
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
        zway_log(zway, Debug, ZSTR("[myzway_finish] Finish zway server\n"));
        
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

int myzway_check() {
    char    readbuffer[100];
    int     rv;
    fd_set  set;
    struct  timeval timeout;
    
    FD_ZERO(&set);
    FD_SET(fd[0], &set);
    
    timeout.tv_sec = 0;
    timeout.tv_usec = 1000;
    
    rv = select(fd[0] + 1, &set, NULL, NULL, &timeout);
    if(rv == -1) {
        perror("select");
        return 0;
    } else if (rv == 1) {
        rv = read( fd[0], readbuffer, sizeof(readbuffer) );
        
        printf("Received string: %s : %i\n", readbuffer,rv);
        if (rv == 1) {
            printf("(PID=%i,TID=%i)myzway_check going to call do_callback with: %s\n",getpid(),(unsigned int)pthread_self(),readbuffer);
            
            dSP;
            
            ENTER;
            SAVETMPS;
        
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSVpvf(readbuffer)));
            PUTBACK;
        
            call_pv("do_callback", G_DISCARD|G_VOID);
        
            FREETMPS;
            LEAVE;
            
            SPAGAIN;
        }
    }
    
    return rv;
}
  

  


