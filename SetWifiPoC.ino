/*
 * Develop a prototype of a system that will use BLE to allow the
 * device to set parameters.  Once set these should be stored
 * in EEPROM.  The idea for this is that we would configure
 * a set of parameters such as wifi ssid and password, host name, 
 * and other sets of parmeters.  E.g. in our sensor example we
 * could store the config parameters for which mosquitto server
 * we connect to.
 * 
 * Key learnings from this sketch when working with BLE and WiFi
 * 1) You cannot simultaneously use BLE and WiFi on the Nano IOT 33
 *    because there is only a single radio.  You use it either or.
 * 2) When switching between radios you must carefully align your
 *    BLE.begin() and BLE.end() with your WiFi.begin() and WiFi.end().
 *    Make sure you always call the corresponding .end() before calling
 *    the opposite .begin().  If you interlace them e.g. call WiFi.begin()
 *    before calling BLE.end() the WiFi will work but it will fail when
 *    you attempt to return to BLE.  This is because in the driver there
 *    is a set of initialization and deinitialization steps.  And if called
 *    in the wrong order the system is in an inconsistent state.
 * 3) While it appeared in prior attempts that it is necessary to wait some
 *    period of time between using BLE and then WiFi and again when switching
 *    back, this no longer is the case.  (It probably never was.)
 * 4) The BLEService objects persist after calls to BLE.end().  Therefore
 *    it is not necessary to reinitialize the when restarting BLE.  Infact
 *    if you do try to reinitialize them you'll end up with multiple copies
 *    of the characteristics on the your services.
 * 5) When restarting BLE, assuming your services and characteristics are
 *    already set the sequence is:
 *      BLE.being(); 
 *      BLE.addService(); // note each service must be added if you have more than one
 *      BLE.advertise();
 * 6) Static configuration stuff for your service entries may be called before
 *    BLE.begin().  This enables you to set everything up in advance and also means
 *    this data survives the BLE.begin() and BLE.end() events.  Essentially you
 *    only need to call BLE.being() when you're ready to start using the radio.
 */

#include <ArduinoBLE.h>
#include <WiFiNINA.h>

// default wifi password and secret, used when not in the EEPROM, useful as a testing shortcut
#include "arduino_secret.h"
char default_ssid[] = SECRET_SSID;
char default_pass[] = SECRET_PASS;

// Service to configure the wifi.  To lock the configuration call Lock with a password.
// to unlock the configuration call unlock with the password.
BLEService wifiSettingService("2de598db-ae66-4942-9106-490c3f5e5687");
BLEStringCharacteristic wifiSSID("15bc7004-c6c0-4d1e-a390-af4a6ee643db", BLERead | BLEWrite, 128);
BLEStringCharacteristic wifiPWD("01510af0-bdbc-4549-aef8-ef724bba2265", BLEWrite, 128);   // Note, we only allow write
BLEBooleanCharacteristic wifiEnabled("2cb1beb2-3603-41e3-a9d1-33a5272f3399", BLERead | BLEWrite);
BLEStringCharacteristic configurationLock("5a622576-7f47-49d7-83fb-6a96ecea03e8", BLEWrite, 128);
BLEStringCharacteristic configurationUnlock("50ee954b-12b8-4a41-875e-11b8bf1a3506", BLEWrite, 128);
BLEBooleanCharacteristic configurationIsLocked("e5add166-af0e-4c54-9121-4a34371c638b", BLERead);
String wifiNetworkSSID = "";
String wifiPassword = "";
String configurationLockPassword = "";

// A simple wifi service to ping a server
BLEService wifiPing("6e1de8ff-a379-4cbc-b4aa-8bb627c9a2af");
BLEStringCharacteristic pingTarget("680e23d1-4214-4ab1-b20f-0e0c85528284", BLERead | BLEWrite, 128);
BLEIntCharacteristic pingRTT("6d8d89cb-e5cd-4f18-8ae3-282b7bb8e58a", BLERead);

void setup() {
  Serial.begin(250000);
  while (!Serial);

  pinMode(LED_BUILTIN, OUTPUT);

//  BLE.begin();
  configureBLE();
  startBLE();
//  BLE.addService(wifiSettingService);
//  BLE.advertise();
  
  Serial.println("Finishing Setup"); 
}

void configureBLE() {
  Serial.println("Configuring BLE...");
  BLE.setDeviceName("TJPTestDevice");
  BLE.setLocalName("Config");
  BLE.setAdvertisedService(wifiSettingService);

  wifiSettingService.addCharacteristic(wifiSSID);
  wifiSSID.setEventHandler(BLEWritten, wifiSSIDWritten);
  wifiSSID.writeValue(default_ssid);

  wifiSettingService.addCharacteristic(wifiPWD);
  wifiPWD.setEventHandler(BLEWritten, wifiPWDWritten);
  wifiPWD.writeValue(default_pass);

  wifiSettingService.addCharacteristic(configurationLock);
  configurationLock.setEventHandler(BLEWritten, configurationLockWritten);
  configurationLock.writeValue("");

  wifiSettingService.addCharacteristic(configurationIsLocked);
  configurationIsLocked.setEventHandler(BLERead, configurationIsLockedRead);
  configurationIsLocked.writeValue(false);

  wifiSettingService.addCharacteristic(configurationUnlock);
  configurationUnlock.setEventHandler(BLEWritten, configurationUnlockWritten);
  configurationUnlock.writeValue("");

  wifiPing.addCharacteristic(pingTarget);
  pingTarget.setEventHandler(BLEWritten, pingTargetWritten);
  pingTarget.writeValue("");

  // We don't need an event handler as this is just a state value.
  wifiPing.addCharacteristic(pingRTT);
  
  // Set the event handlers
  BLE.setEventHandler(BLEConnected, blePeripheralConnect);
  BLE.setEventHandler(BLEDisconnected, blePeripheralDisconnect);  
  Serial.println("BLE Configured");
}

void startBLE() {

  Serial.println("Starting BLE");
  
  BLE.begin();
  BLE.addService(wifiSettingService);
  BLE.addService(wifiPing);
  BLE.advertise();  

  Serial.println("BLE started");
}

void blePeripheralConnect(BLEDevice central) {
  Serial.print("Connected: ");
  Serial.println(central.address());
}

void blePeripheralDisconnect(BLEDevice central) {
  Serial.print("Disconnected: ");
  Serial.println(central.address());
}

void wifiSSIDWritten(BLEDevice central, BLECharacteristic characteristic) {
  Serial.print("WiffiSSID written: ");
  Serial.println(wifiSSID.value());
}

void wifiPWDWritten(BLEDevice central, BLECharacteristic characteristic) {
  Serial.print("WifiPWD written: ");
  Serial.println(wifiPWD.value());
}

void configurationLockWritten(BLEDevice central, BLECharacteristic characteristic) {
  if (!configurationIsLocked.value()) {
    Serial.println("Locking configuration");
    configurationLockPassword = configurationLock.value();
    configurationIsLocked.writeValue(true);
  } else {
    Serial.println("Configuration is already locked, cannot change lock password");
  }
}

void configurationUnlockWritten(BLEDevice central, BLECharacteristic characteristic) {
  Serial.println("Attempting to unlock");
  if(configurationIsLocked.value() == 1) {
    if(configurationLockPassword == configurationUnlock.value()) {
      Serial.println("Unlocking configuration");
      configurationIsLocked.writeValue(false);
    } else {
      Serial.println("Invalid unlock password");
    }
  } else {
    Serial.println("Cannot unlock because the configuration is not locked");
  }
}

void configurationIsLockedRead(BLEDevice central, BLECharacteristic characteristic) {
  Serial.print("Configuration Locked = ");
  Serial.println(configurationIsLocked.value());  
}

void pingTargetWritten(BLEDevice central, BLECharacteristic characteristic) {
  Serial.print("Pinging ");
  Serial.println(pingTarget.value());

  //TODO: Validate that the WiFi sevice is configured.
  // To ping a target we need to end the bluetooth, start the wifi, ping the target
  // save the results in the pingRTT characteristic, turn off wifi and restart BLE.
  BLE.end();
  while (WiFi.begin(wifiSSID.value().c_str(), wifiPWD.value().c_str()) != WL_CONNECTED) {
    Serial.println("Waiting for WiFi to connect.");
    delay(1500);
  }
  Serial.println("WiFi connected!");
  int rtt = WiFi.ping(pingTarget.value().c_str());
  Serial.print("Ping time = ");
  Serial.println(rtt);
  pingRTT.writeValue(rtt);
  WiFi.end();
  startBLE();
}

void loop() {
  BLE.poll();
}
