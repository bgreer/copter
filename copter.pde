
#include <Servo.h>
#include "header.h"

// for main loop timing
uint32_t timer_200Hz, timer_50Hz, timer_10Hz, timer_2Hz;
uint32_t time;
uint8_t counter_10Hz, divider_1Hz;
unsigned long armtime;
uint8_t battindex;

// flight mode stuff
uint8_t flightMode = STABILIZE;



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

	// 200Hz loop
	// update IMU info
	// calculate stability
	// set motor speed (if armed)
	time = micros();
	if (time-timer_200Hz > 5000)
	{
#if TIMING
		SERIAL_DEBUG.print("200\t");
		SERIAL_DEBUG.println(time-timer_200Hz);
#endif
		// check the IMU serial comm for data
		checkIMU();
		// use PID controller to compare targets to actual values
		PID_calcForces();
		// use PID controller suggestions to set motor speed
		set_motorspeed();

		timer_200Hz = time;
	}

	// 10Hz loop
	// check wireless data
	// update flight mode (consider heartbeat)
	time = micros();
	if (time-timer_10Hz > 100000)
	{
#if TIMING
//		SERIAL_DEBUG.print("10\t");
//		SERIAL_DEBUG.println(time-timer_10Hz);
#endif
		// check wireless, run operation
		// actually runs at 5Hz
		if (counter_10Hz) checkWireless();
		else if (wirelessOpcode) parseCommand();

#if DEBUG
//		for (int i=0; i<6; i++)
//		{
//			SERIAL_DEBUG.print(motorval[i]);
//			SERIAL_DEBUG.print("\t");
//		}
//		SERIAL_DEBUG.println();
#endif

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
			changeFlightmode(SAFEMODE);
#if DEBUG
			SERIAL_DEBUG.println("heartbeat died");
#endif
		}

		// decay the safemode lift is necessary
		if (flightMode == SAFEMODE)
			safemodeLift = safemodeLift*0.99;

		sendDebug();
		// run this at 1Hz
		if (divider_1Hz)
			sendHeartbeat();
		else
			update_altitude();

		// check physical arming
#if ALLOW_PHYSICAL_ARMING
		if (armed)
		{
			if (digitalRead(PIN_ARM_BUTTON) == HIGH)
			{
				disarm_motors();
				armtime = millis();
			}
		} else {
			if (digitalRead(PIN_ARM_BUTTON) == HIGH)
			{
				if (millis() - armtime > 2000)
				{
					// arm!
					arm_motors();
					while (digitalRead(PIN_ARM_BUTTON) == HIGH) {}
				}
			} else {
				armtime = millis();
			}
		}
#endif

		// check a battery
		checkBattery(battindex);
		battindex++;
		if (battindex == 6) battindex = 0;

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
	timer_200Hz = time;
	timer_50Hz = time;
	timer_10Hz = time;
	timer_2Hz = time;
	armtime = 0;
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
	// initialize PID controller
	PID_init();

	// start serial ports
	SERIAL_WIRELESS.begin(WIRELESS_BAUD);
	SERIAL_IMU.begin(IMU_BAUD);
	SERIAL_IMU.setTimeout(10);
#if DEBUG
	SERIAL_DEBUG.begin(DEBUG_BAUD);
#endif
	// start I2C, SPI if needed here
	// set pinmodes and states
	pinMode(LED_STATUS, OUTPUT);
	pinMode(LED_ARMED, OUTPUT);
	pinMode(PIN_ARM_BUTTON, INPUT);
	// send quick hello over wireless
	SERIAL_WIRELESS.write(COMM_START);
	SERIAL_WIRELESS.write(COMM_MODE_HELLO);
	SERIAL_WIRELESS.write(COMM_END);

	// initialize the barometric pressure sensor
	alt_init();

	// should be ready to enter main loop now
#if DEBUG
	SERIAL_DEBUG.print("Quickstart complete after ");
	SERIAL_DEBUG.print(micros());
	SERIAL_DEBUG.println(" us");
#endif
	battindex = 0;
	userPitch = 0;
	userRoll = 0;
	userYaw = 0;
	userLift = 0;
}
