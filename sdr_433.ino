/*
 * Basic 433MHz transmission example using
 * http://code.google.com/p/rc-switch/
 * and based on the SendDemo example
 *
 * See https://ilias.giechaskiel.com/posts/rtl_433/index.html
 * for details.
 */

#include <RCSwitch.h>

RCSwitch mySwitch = RCSwitch();

void setup() {
  mySwitch.enableTransmit(10);
}

void loop() {
  mySwitch.send("010010100101");
  delay(1000); 
}

