#include <a_samp>

w(playerid) {
    if(IsPlayerConnected(playerid)) {
        printf("Saying hello to %d", playerid);
        SendClientMessage(playerid, 0xFF3200FF, "Hello World!");
    } else {
        print("Hello World sampctl!");
    }
}

public OnPlayerConnect(playerid) {
    HelloWorld(playerid);
    return 1;
}