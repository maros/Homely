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

use IO::Handle;
use AnyEvent;
sub init {
    my ($self) = @_;
    my $fh = IO::Handle->new();
    my $fd = myzway_init(2);
    if ($fd) {
        $fh->fdopen($fd,'r');
        $fh->blocking(1);
        warn "OPEN FD $fd";
    }
    #my $core = App::Homely::Core->instance;
    #myzway_init($core->debug ? 0:3);
    my $cv = AnyEvent->condvar;
    my $int_signal = AnyEvent->signal(
        signal  => "INT", 
        cb      => sub { 
            $log->info('Recieved INT signal');
            $cv->send;
        }
    );
    my $io = AnyEvent->io(fh => $fh, poll => "r", cb => sub {
        my $input = $fh->getline;
        return 
            unless defined $input;  
        warn "--------> GOT READ EVENT '$fh' - '$fd' - '$input'";
    });
    $cv->recv;
    myzway_finish();
    return $self;
}

#sub DEMOLISH {
#    my ($self) = @_;
#    myzway_finish(); 
#}
#
#sub do_callback {
#    my ($path) = @_;
#    my $self = __PACKAGE__->instance;
#    $log->debug('Got callback from '.$path.' via ');
#}

sub do_log {
    my ($loglevel,$message) = @_;
    warn "------> $loglevel - $message";
    #$log->$loglevel('LOG'.$message);
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

static char *myzway_dump(ZWay zway, ZDataHolder data_holder) {
    ZWDataType type;
    ZWBOOL  bool_val;
    int     int_val;
    float   float_val;
    ZWCSTR  str_val;
    const   ZWBYTE *binary;
    const   int *int_arr;
    const   float *float_arr;
    const   ZWCSTR *str_arr;
    size_t  len, i;
    char    *child_path;
    
    char *path = zway_data_get_path(zway,data_holder);
    zway_data_get_type(zway, data_holder, &type);
    
    switch (type) {
        case Empty:
            zway_log(zway, Information, ZSTR("[myzway_dump] DATA %s = Empty\n"), path);
            break;
        case Boolean:
            zway_data_get_boolean(zway, data_holder, &bool_val);
            if (bool_val)
                zway_log(zway, Information, ZSTR("[myzway_dump] DATA %s = True\n"), path);
            else
                zway_log(zway, Information, ZSTR("[myzway_dump] DATA %s = False\n"), path);
            break;
        case Integer:
            zway_data_get_integer(zway, data_holder, &int_val);
            zway_log(zway, Information, ZSTR("[myzway_dump] DATA %s = %d (0x%08x)\n"), path, int_val, int_val);
            break;
        case Float:
            zway_data_get_float(zway, data_holder, &float_val);
            zway_log(zway, Information, ZSTR("[myzway_dump] DATA %s = %f\n"), path, float_val);
            break;
        case String:
            zway_data_get_string(zway, data_holder, &str_val);
            zway_log(zway, Information, ZSTR("[myzway_dump] DATA %s = \"%s\"\n"), path, str_val);
            break;
        case Binary:
            zway_data_get_binary(zway, data_holder, &binary, &len);
            zway_log(zway, Information, ZSTR("[myzway_dump] DATA %s = byte[%d]\n"), path, len);
            zway_dump(zway, Information, ZSTR("  "), len, binary);
            break;
        case ArrayOfInteger:
            zway_data_get_integer_array(zway, data_holder, &int_arr, &len);
            zway_log(zway, Information, ZSTR("[myzway_dump] DATA %s = int[%d]\n"), path, len);
            for (i = 0; i < len; i++)
                zway_log(zway, Information, ZSTR("[myzway_dump]  [%02d] %d\n"), i, int_arr[i]);
            break;
        case ArrayOfFloat:
            zway_data_get_float_array(zway, data_holder, &float_arr, &len);
            zway_log(zway, Information, ZSTR("[myzway_dump] DATA %s = float[%d]\n"), path, len);
            for (i = 0; i < len; i++)
                zway_log(zway, Information, ZSTR("[myzway_dump]  [%02d] %f\n"), i, float_arr[i]);
            break;
        case ArrayOfString:
            zway_data_get_string_array(zway, data_holder, &str_arr, &len);
            zway_log(zway, Information, ZSTR("[myzway_dump] DATA %s = string[%d]\n"), path, len);
            for (i = 0; i < len; i++)
                zway_log(zway, Information, ZSTR("[myzway_dump]  [%02d] \"%s\"\n"), i, str_arr[i]);
            break;
    }
    
    ZDataIterator child = zway_data_first_child(zway, data_holder);
    while (child != NULL) {
        child_path = zway_data_get_path(zway, child->data);
        zway_log(zway, Information, ZSTR("[myzway_dump CHILD %s\n"), path);
        free(child_path);
        child = zway_data_next_child(child);
    }
    
    return path;
}

static void myzway_event(ZWay zway, ZWDataChangeType change_type, ZDataHolder data_holder, void * apArg) {
    char *path = myzway_dump(zway,data_holder);
    zway_log(zway, Information, ZSTR("[myzway_event] Got data holder event from %s\n"),path);
    if (change_type == 1 || change_type == 40) {
        char buffer[100];
        snprintf(buffer,sizeof(buffer),"%i:%s\n",change_type,path);
        write(fd[1], buffer, strlen(buffer));
    }
}

bool myzway_command_class_handle(int command_id) {
    int i;
    int command_id_handle[4] = {
        80, // COMMAND_CLASS_BASIC_WINDOW_COVERING
        32, // COMMAND_CLASS_BASIC
        43, // COMMAND_CLASS_SCENE_ACTIVATION
        49  // COMMAND_CLASS_SENSOR_MULTILEVEL
    };
    for (i=0; i < sizeof(command_id_handle); i++) {
        if (command_id_handle[i] == command_id)
            return TRUE;
    }
    return FALSE;
}

void myzway_attach(const ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE command_id, char *path) {
    zway_data_acquire_lock(zway);
    
    ZDataHolder data_holder = zway_find_device_instance_cc_data(zway, node_id, instance_id, command_id, path);
    if (data_holder == NULL) {
        zway_log(zway, Error, ZSTR("[myzway_attach] No data holder for node_id=%i,instance_id=%i,command_id=%i\n"), node_id, instance_id,command_id);
    } else {
        zway_log(zway, Information, ZSTR("[myzway_attach] Attached callback for node_id=%i,instance_id=%i,command_id=%i\n"), node_id, instance_id,command_id);
        myzway_dump(zway,data_holder);
        zway_data_add_callback(zway, data_holder, (ZDataChangeCallback) myzway_event, FALSE, path);
    }
    
    zway_data_release_lock(zway);
    return;
}

void myzway_detach(const ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE command_id, char *path) {
    zway_data_acquire_lock(zway);
    
    ZDataHolder data_holder = zway_find_device_instance_cc_data(zway, node_id, instance_id, command_id, path);
    if (data_holder == NULL) {
        zway_log(zway, Error, ZSTR("[myzway_detach] No data holder for node_id=%i,instance_id=%i,command_id=%i\n"), node_id, instance_id,command_id);
    } else {
        zway_log(zway, Information, ZSTR("[myzway_attach] Detached callback from node_id=%i,instance_id=%i,command_id=\n"), node_id, instance_id,command_id);
        zway_data_remove_callback(zway, data_holder, (ZDataChangeCallback) myzway_event, FALSE);
    }
    
    zway_data_release_lock(zway);
    return;
}

static void myzway_device_event(const ZWay zway, ZWDeviceChangeType type, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE command_id, void *arg) {
    ZDataHolder data_holder;
    
    switch (type) {
        case  DeviceAdded:
            zway_log(zway, Information, ZSTR("[myzway_device_event] New device added: %i\n"), node_id);
            break;

        case DeviceRemoved:
            zway_log(zway, Information, ZSTR("[myzway_device_event] Device removed: %i\n"),node_id);
            break;

        case InstanceAdded:
            zway_log(zway, Information, ZSTR("[myzway_device_event] New instance added to device %i: %i\n"),node_id,instance_id);
            break;

        case InstanceRemoved:
            zway_log(zway, Information, ZSTR("[myzway_device_event] Instance removed from device %i: %i\n"), node_id, instance_id);
            break;

        case CommandAdded:
            if (command_id)
            zway_log(zway, Information, ZSTR("[myzway_device_event] Command Class added to device %i:%i: %i\n"), node_id, instance_id, command_id);
            if (myzway_command_class_handle(command_id)) {
                myzway_attach(zway, node_id, instance_id, command_id,NULL);
            }
            break;

        case CommandRemoved:
            zway_log(zway, Information, ZSTR("[myzway_device_event] Command Class removed from device %i:%i: %i\n"), node_id, instance_id, command_id);
            if (myzway_command_class_handle(command_id)) {
                myzway_detach(zway, node_id, instance_id, command_id,NULL);
            }
            break;
    }
}

int myzway_init(int loglevel) {
    if (zway == NULL) {
        ZWError result;
        
        main_thread = pthread_self();        
        pipe(fd);
        
        myzway_log("info","Initializing zway %i: p1: %i p2: %i",1,fd[0],fd[1]);
        
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
            if (result == NoError) {
                myzway_log("warning","Start zway");
                result = zway_start(zway,NULL);
            }
            if (result == NoError) {
                myzway_log("warning","Discover zway");
                result = zway_discover(zway);
            }
        
            close(fd[1]);

            if (result != NoError) {
                myzway_log("error","Could not start zway %d",result);
                return 0;
            }
            
            myzway_attach(zway, 3, 0, 32, NULL);
            myzway_attach(zway, 3, 0, 96, NULL);
            
            
            return fd[0];
        } else {
            myzway_log("error","Could not initialize zway %d",result);
        }
    }
    
    return 0;
}

int myzway_finish() {
    ZWError result;
    
    int success = 1;
    if (zway != NULL) {
        zway_log(zway, Information, ZSTR("[myzway_finish] Finish zway server\n"));
        
        result = zway_stop(zway);
        
        if (result != NoError) {
            myzway_log("error","Could not finish zway %d",result);
            success = 0;
        }
        zway_terminate(&zway);
        //zway = NULL;
    }
    
    return success;
}

/*
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
*/
  


