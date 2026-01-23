// Jackson Coxson
// heartbeat.c

#include "idevice.h"
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/_types/_u_int64_t.h>
#include <CoreFoundation/CoreFoundation.h>
#include <limits.h>
#include "heartbeat.h"
@import Foundation;

bool isHeartbeat = false;
NSDate* lastHeartbeatDate = nil;

static NSArray<NSString *> *TunnelIPCandiates(void) {
    NSString *override = [[NSUserDefaults standardUserDefaults] stringForKey:@"TunnelDeviceIP"];
    NSMutableArray<NSString *> *ips = [NSMutableArray array];

    // User override first
    if (override.length > 0) {
        [ips addObject:override];
    }

    // Auto fallback order:
    //  - SideStore LocalDevVPN commonly uses 10.7.0.1 as tunnel peer
    //  - StikDebug legacy commonly uses 10.7.0.2
    [ips addObject:@"10.7.0.1"];
    [ips addObject:@"10.7.0.2"];

    // De-dup while preserving order
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithArray:ips];
    return set.array;
}

void startHeartbeat(IdevicePairingFile* pairing_file,
                    IdeviceProviderHandle** provider,
                    bool* isHeartbeat,
                    HeartbeatCompletionHandlerC completion,
                    LogFuncC logger)
{
    // Initialize logger (stderr/stdout from idevice will go to default logger)
    idevice_init_logger(Debug, Disabled, NULL);

    if (*isHeartbeat) {
        return;
    }

    NSArray<NSString *> *ips = TunnelIPCandiates();

    IdeviceProviderHandle* newProvider = NULL;
    HeartbeatClientHandle *client = NULL;
    IdeviceFfiError* err = NULL;

    // Try each candidate IP until we can connect heartbeat
    for (NSString *ip in ips) {
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons(LOCKDOWN_PORT);

        if (inet_pton(AF_INET, ip.UTF8String, &addr.sin_addr) != 1) {
            if (logger) logger("Heartbeat: invalid IP: %s", ip.UTF8String);
            continue;
        }

        if (logger) logger("Heartbeat: trying TunnelDeviceIP=%s", ip.UTF8String);

        newProvider = NULL;
        err = idevice_tcp_provider_new((struct sockaddr *)&addr,
                                       pairing_file,
                                       "ExampleProvider",
                                       &newProvider);
        if (err != NULL) {
            if (logger) logger("Heartbeat: provider_new failed on %s: [%d] %s",
                               ip.UTF8String, err->code, err->message);
            idevice_error_free(err);
            err = NULL;
            continue;
        }

        client = NULL;
        err = heartbeat_connect(newProvider, &client);
        if (err != NULL) {
            if (logger) logger("Heartbeat: connect failed on %s: [%d] %s",
                               ip.UTF8String, err->code, err->message);
            idevice_provider_free(newProvider);
            newProvider = NULL;
            idevice_error_free(err);
            err = NULL;
            continue;
        }

        // SUCCESS on this IP
        if (logger) logger("Heartbeat: connected via %s", ip.UTF8String);
        break;
    }

    if (!newProvider || !client) {
        fprintf(stderr, "Failed to connect Heartbeat on any TunnelDeviceIP candidate.\n");
        idevice_pairing_file_free(pairing_file);
        *isHeartbeat = false;
        return;
    }

    // Mark heartbeat as success and set the default provider
    *isHeartbeat = true;
    *provider = newProvider;

    completion(0, "Heartbeat Completed");

    u_int64_t current_interval = 15;
    while (1) {
        // Get the new interval
        u_int64_t new_interval = 0;
        err = heartbeat_get_marco(client, current_interval, &new_interval);
        if (err != NULL) {
            fprintf(stderr, "Failed to get marco: [%d] %s", err->code, err->message);
            heartbeat_client_free(client);
            idevice_error_free(err);
            *isHeartbeat = false;
            return;
        }
        current_interval = new_interval + 5;

        // Reply
        err = heartbeat_send_polo(client);
        if (err != NULL) {
            fprintf(stderr, "Failed to send polo: [%d] %s", err->code, err->message);
            heartbeat_client_free(client);
            idevice_error_free(err);
            *isHeartbeat = false;
            return;
        }
    }
}