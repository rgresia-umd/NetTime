//
//  main.m
//  NetTime
//
//  Created by Ryan Gresia on 3/1/20.
//  Copyright © 2020 RAG. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <Network/Network.h>

#include <err.h>
#include <getopt.h>

void print_time(NSString* time);
void start_connection(nw_connection_t connection);
void send_message(nw_connection_t connection, const void* msg);
NSString *get_time(nw_connection_t connection);

int main(int argc, const char * argv[]) {
    nw_parameters_t parameters = nw_parameters_create_secure_udp(
                                    NW_PARAMETERS_DISABLE_PROTOCOL,
                                    NW_PARAMETERS_DEFAULT_CONFIGURATION);
    nw_endpoint_t endpoint = nw_endpoint_create_host("192.168.1.20", "7372");
    nw_connection_t connection = nw_connection_create(endpoint, parameters);
    unsigned int msg[] = {0xA1, 0x04, 0xB2};
    
    start_connection(connection);
    send_message(connection, msg);
    print_time(get_time(connection));
   
    return 0;
}

void start_connection(nw_connection_t connection) {
    nw_connection_set_queue(connection, dispatch_get_main_queue());
    nw_retain(connection);
    nw_connection_set_state_changed_handler(connection, ^(nw_connection_state_t state, nw_error_t error) {
        if (state == nw_connection_state_waiting) {
            printf("%s", "hold up....");
        } else if (state == nw_connection_state_failed) {
            printf("%s", "failed");
            exit(0);
        } else if (state == nw_connection_state_ready) {
            printf("%s", "ready");
        } else if (state == nw_connection_state_cancelled) {
            printf("%s", "terminated by remote host");
            nw_release(connection);
        }
    });
    nw_connection_start(connection);
}

void send_message(nw_connection_t connection, const void* msg){
    dispatch_data_t read_data = dispatch_data_create(msg, 3, dispatch_get_main_queue(), DISPATCH_DATA_DESTRUCTOR_FREE);
    nw_connection_send(connection, read_data, NW_CONNECTION_DEFAULT_MESSAGE_CONTEXT, true, ^(nw_error_t  _Nullable error) {
        if(error != NULL) {
            printf("%s", "something done goofed");
        } else {
            printf("%s", "sent");
        }
    });
}

NSString *get_time(nw_connection_t connection) {
    __block NSString *time;
    nw_connection_receive(connection, 79, 81,
                          ^(dispatch_data_t content, nw_content_context_t context, bool is_complete, nw_error_t receive_error) {
        if(content != NULL) {
            time = [NSString stringWithFormat:@"TimeReceipt:%@", content];
        } else {
            printf("%s", "no data received");
            exit(0);
        }
    });
    
    return time;
}

void print_time(NSString* time) {
    if (time != NULL){
        printf("%s", [time UTF8String]);
    }
}
