main.out: test.c
	c99 -I/opt/z-way-server/libzway-dev -L/opt/z-way-server/libs -L/lib/arm-linux-gnueabihf -L/usr/lib/arm-linux-gnueabihf -lzway -lxml2 -lpthread -lcrypto -larchive -o test.out test.c

clean:
	rm -f test.out

run: main.out  
	export LD_LIBRARY_PATH=/opt/z-way-server/libs && ./test.out
