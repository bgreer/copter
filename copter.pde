
#include <Servo.h>
#include "header.h"

// for main loop timing
uint32_t timer_100Hz, timer_50Hz, timer_10Hz, timer_2Hz;
uint32_t time;
uint8_t counter_10Hz, divider_1Hz;

// flight mode stuff
uint8_t flightMode = SAFEMODE;



void setup()
{
	// do quick start
	quick_start();
	// see if a ground start is ok to do?
#if DEBUG
	SERIAL_DEBUG.print("Version: ");
	SERIAL_DEBUG.println(VERSION);
#endif
}


void loop()
{

	// 100Hz loop
	// update IMU info
	// calculate stability
	// set motor speed (if armed)
	time = micros();
	if (time-timer_100Hz > 10000)
	{
		// do something?
		delay(1);
		timer_100Hz = time;
	}

	// 10Hz loop
	// check wireless data
	// update flight mode (consider heartbeat)
	time = micros();
	if (time-timer_10Hz > 100000)
	{
		// check wireless, run operation
		// actually runs at 5Hz
		if (counter_10Hz) checkWireless();
		else if (wirelessOpcode) parseCommand();

		// update flight mode
		// if no wireless heartbeat, go into safe mode
		if (!heartbeat) flightMode = SAFEMODE;
		timer_10Hz = time;
		counter_10Hz = !counter_10Hz;
	}
	
	// 2Hz loop
	// check wireless heartbeat timeout
	// get GPS info
	time = micros();
	if (time-timer_2Hz > 500000)
	{
		// check wireless heartbeat
		if (heartbeat && time-lastHeartbeat > HEARTBEAT_TIMEOUT)
		{
			// no heartbeat detected from base station
			heartbeat = 0;
#if DEBUG
			SERIAL_DEBUG.println("heartbeat died");
#endif
		}

		// run this at 1Hz
		if (divider_1Hz)
			sendDebug();

		divider_1Hz = !divider_1Hz;
		timer_2Hz = time;
	}
}


// main init function
// perform quick start in case of in-air failure
// 
static void quick_start()
{
	// init the main loop timers
	time = micros();
	timer_100Hz = time;
	timer_50Hz = time;
	timer_10Hz = time;
	timer_2Hz = time;
	counter_10Hz = 0;
	divider_1Hz = 0;
	// set pinmodes for esc lines TODO: redesign so this isnt needed
	pinMode(GND_PIN[0], OUTPUT);
	digitalWrite(GND_PIN[0], LOW);
	pinMode(GND_PIN[1], OUTPUT);
	digitalWrite(GND_PIN[1], LOW);
	pinMode(GND_PIN[2], OUTPUT);
	digitalWrite(GND_PIN[2], LOW);
	pinMode(GND_PIN[3], OUTPUT);
	digitalWrite(GND_PIN[3], LOW);
	pinMode(GND_PIN[4], OUTPUT);
	digitalWrite(GND_PIN[4], LOW);
	pinMode(GND_PIN[5], OUTPUT);
	digitalWrite(GND_PIN[5], LOW);
	init_motors();

	// start serial ports
	SERIAL_WIRELESS.begin(WIRELESS_BAUD);
	SERIAL_IMU.begin(IMU_BAUD);
#if DEBUG
	SERIAL_DEBUG.begin(DEBUG_BAUD);
#endif
	// start I2C, SPI if needed here
	// set pinmodes and states
	pinMode(LED_STATUS, OUTPUT);
	pinMode(LED_ARMED, OUTPUT);
	// send quick hello over wireless
	SERIAL_WIRELESS.write(COMM_START);
	SERIAL_WIRELESS.write(COMM_MODE_HELLO);
	SERIAL_WIRELESS.write(COMM_END);

	// should be ready to enter main loop now
#if DEBUG
	SERIAL_DEBUG.print("Quickstart complete after ");
	SERIAL_DEBUG.print(micros());
	SERIAL_DEBUG.println(" us");
#endif
}
