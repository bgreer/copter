
First off, I refuse to prefix everything with Ardu- or postfix with -uino just because I'm using some Arduino boards.
http://i.imgur.com/lFrg9.gif

Second, a lot of this is heavily influenced by (and sometimes copied from) the ArduCopter code from diydrones. It's turning out to be a weird mashup of the most recent ArduCopter release (2.8ish?) and my own original codes. One significant change is how the copter communicates with the base station. I don't have one of those fancy controllers to send PWM signals around, so I'm using my laptop with a USB-powered XBEE. The cool part is that I get to make a python app to take keyboard input (WASD probably) and send it off to the copter for controls.
