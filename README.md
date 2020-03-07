# SetWifiPoC

SetWifiPoC is a simple Arduino Nano 33 IoT application.  It demonstrates the
use of BLE and WiFi on the IoT board.  Note you cannot simultaneously use WiFi
and BLE, rather you must switch back and forth between the two.

The application hosts 2 BLE services.  The Config service allows a user to
configure WiFi parameters (SSID and password) and allows the configuration
to be locked with a password.  Once locked the configuration is written
to EEPROM.  This allows the wifi configuration information to survive a
reboot.

The Ping service is a very simple service that will take a host name and
ping it once returning the RTT.  The main purpose of this service is to 
demonstrate switching back and forth between BLE and Wifi.

# Switching between BLE and WiFi

As there is only 1 radio on the board you must switch back and forth between
using BLE and WiFi.  To get this to work you must carefully sequence the BLE and WiFi calls.

In the application the system starts using BLE.  When you want to switch to
WiFi you must execute this sequence of commands.

```
    BLE.disconnect();       // Shutdown the interface into a state where it can be restarted.
    BLE.end();              // Turn off the BLE radio and reset the rest of the driver.

    WiFi.begin(...);        // Connect to the wifi network
    ...
    WiFi.disconnect(...);   // gracefully disconnect
    WiFi.end();             // turn off the wifi radio

    BLE.begin();            // restart BLE
    BLE.addService(...);    // Add back in all services
    ...
    BLE.advertise();        // begin advertising.
```

Note, while you need to re-add your service to BLE you should not 
re-add your characteristics to your service.  If you re-add your
characteristics you will end up with duplicate characterists.

# BlueSee

To more easily manipulate the BLE interface without having to continually refer to GUIDs I'm using 
the [BlueSee](https://www.synapse.com/bluesee) application on the Mac.  In this application you 
can develop Lua scripts to provide a simple interface in English.

Install the SetWifiPoC BlueSee.lua script into the BlueSee application.