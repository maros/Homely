#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use 5.010;

use Inline 
    C               => 'Config', 
    LIBS            => '-L/opt/z-way-server/libs -L/lib/arm-linux-gnueabihf -L/usr/lib/arm-linux-gnueabihf -lzway -lxml2 -lpthread -lcrypto -larchive',
    INC             => '-I/opt/z-way-server/libzway-dev',
    AUTO_INCLUDE    => '#include <ZWayLib.h>';
    
use Inline 
    C       => 'DATA',
    NAME    => __PACKAGE__;

say "<perl>PRE INIT $$  ";
sleep(10);
myzway_init(3);
say "<perl>POST INIT";

sub do_log {
    say "<perl>Got callback (".join(';',@_).")";
}

Inline->init()

__DATA__
__C__

ZWay zway;

static void myzway_log(char *loglevel, char *message) {
    printf("<c>enter myzway_log (%s)\n",message);
    dSP;
    
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvf(loglevel)));
    XPUSHs(sv_2mortal(newSVpvf(message)));
    PUTBACK;

    call_pv("do_log", G_DISCARD);

    FREETMPS;
    LEAVE;

    SPAGAIN;
    printf("<c>exit myzway_log (%s)\n",message);
}

int myzway_init(int loglevel) {
    ZWError result;
    
    printf("<c>XXX1\n");
    myzway_log("info","Start init zway");

    memset(&zway, 0, sizeof(zway));
    myzway_log("info","Pre init zway");
    printf("<c>XXX2\n");
    result = zway_init(
        &zway, 
        "/dev/ttyAMA0",  
    	"/opt/z-way-server/config",
    	"/opt/z-way-server/translations",
    	"/opt/z-way-server/ZDDX", 
		stdout, 
       	loglevel
   	);
   	printf("<c>XXX3\n");
    myzway_log("info","Post init zway");
    hase;
    if (result == NoError) {
        result = zway_start(zway,NULL);
    }
    
    if (result != NoError) {
        char errormessage[100];
        printf(errormessage,"<c>Could not initialize zway %d",result);
        myzway_log("error",errormessage);
        return 0;
    }

printf("<c>XXX4");
    return 1;
}
