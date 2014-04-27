#include <stdio.h>
#include <ZWayLib.h>
#include <errno.h>
#include <signal.h>

volatile sig_atomic_t stop;

void dataChangeCallback(ZWay zway, ZWDataChangeType aType, ZDataHolder aData, void * apArg)
{
	char* path = zway_data_get_path(zway,aData);
    printf("Got callback: %s\n",path);
}

void inthand(int signum)
{
	printf("Stop zway\n");
    stop = 1;
}

void print_term_event(ZWay zway)
{
	printf("Z-Way terminated\n");
}

void print_device_event(const ZWay zway, ZWDeviceChangeType type, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE command_id, void *arg)
{
    switch (type)
    {
        case  DeviceAdded:
        	printf("New device added: %i\n", node_id);
            break;

        case DeviceRemoved:
        	printf("New device removed: %i\n", node_id);
            break;

        case InstanceAdded:
        	printf("New instance added to device %i: %i\n", node_id,instance_id);
            break;

        case InstanceRemoved:
        	printf("Instance removed from device %i: %i\n", node_id, instance_id);
            break;

        case CommandAdded:
        	printf("New Command Class added to device %i:%i: %i\n", node_id, instance_id, command_id);
            break;

        case CommandRemoved:
        	printf("Command Class removed from device %i:%i: %i\n", node_id, instance_id, command_id);
            break;
    }
}


int main(int argc, char ** argv)
{
	ZWay zway;
	ZWError result;

	printf("Init zway with size %zu\n",sizeof(zway));
	memset(&zway, 0, sizeof(zway));
	printf("Init...\n");
	result = zway_init(&zway,
		"/dev/ttyAMA0",
		"/opt/z-way-server/config",
		"/opt/z-way-server/translations",
		"/opt/z-way-server/ZDDX",
		stdout,
		Debug);

	if (result == NoError) {
		printf("Adding device events...\n");
		result = zway_device_add_callback(zway, DeviceAdded | DeviceRemoved | InstanceAdded | InstanceRemoved | CommandAdded | CommandRemoved, print_device_event, NULL);
	} else {
		printf("Error: %d\n", result);
		return -1;
	}

	if (result == NoError) {
		printf("Starting...\n");
		result = zway_start(zway,print_term_event);
	}

	if (result == NoError) {
		printf("Discovering...\n");
		result = zway_discover(zway);
	}
	/*
	if (result == NoError) {
		printf("Getting device list...\n");
		ZWDevicesList devicesList = zway_devices_list(zway);
		ZWBYTE * pDeviceNodeId = devicesList;
		if (pDeviceNodeId != NULL) {
			while (*pDeviceNodeId != 0) {
				printf("Device node ID: %d\n", *pDeviceNodeId);
				if (*pDeviceNodeId > 1) {
					ZGuessedProduct * productsList = zway_device_guess(zway, *pDeviceNodeId);
					struct _ZGuessedProduct * pProduct = *productsList;
					printf("Guessed product (%p): score=%d product=%s file_name=%s\n", pProduct, pProduct->score, pProduct->product, pProduct->file_name);
					zway_device_guess_free(productsList);
				}
				pDeviceNodeId++;
			}
			zway_devices_list_free(devicesList);
		} else {
			printf("Could not find devices ...\n");
		}
	}
	*/

	if (result == NoError) {
		printf("Acquire lock...\n");
		zway_data_acquire_lock(zway);
		printf("Get data holder...\n");
		int deviceid,instanceid;
		for (deviceid = 1; deviceid <= 3; deviceid++) {
			for (instanceid = 0; instanceid <= 2; instanceid++) {
				ZDataHolder dataHolder = zway_find_device_instance_cc_data(zway, deviceid, instanceid, 0x20, "mylevel");
				if (dataHolder != NULL) {
					printf("Add callback for deviceId=%i instanceId=%i...\n",deviceid,instanceid);
					zway_data_add_callback_ex(zway, dataHolder, &dataChangeCallback, TRUE, "");
				} else {
					printf("No data holder for deviceId=%i instanceId=%i\n",deviceid,instanceid);
				}
			}
		}
		printf("Release lock...\n");
		zway_data_release_lock(zway);

		printf("Run loop...\n");
		signal(SIGINT, inthand);
		while (!stop && zway_is_running(zway)) {
			printf("IDLE: %i",zway_is_idle(zway));
			sleep(1);
		}

		printf("Stopping ZWay...\n");
	}
	if (result != NoError) {
		printf("Error: %d\n", result);
	}
	result = zway_stop(zway);
	zway_terminate(&zway);
    return 0;
}


