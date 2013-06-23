
#include <Servo.h>
#include "header.h"

// for main loop timing
uint32_t timer_200Hz, timer_50Hz, timer_10Hz, timer_2Hz;
uint32_t time, flighttime, lasttime, delta;
uint8_t counter_10Hz, divider_1Hz, alt_armed;
unsigned long armtime;
uint8_t battindex, setdefaultyaw = 0;
float dt;

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
	// as fast as possible
	// this can run at 800Hz
	time = micros();

	checkIMU();
#if TIMING
	SERIAL_DEBUG.println((time-lasttime));
#endif
	dt = (time-lasttime)/10000.;
	lasttime = time;
	PID_update();
	PID_calcForces();
	set_motorspeed();
	// 200Hz loop
	if (time-timer_200Hz > 10000) // not quite 200Hz.. whatever
	{
		// check the IMU serial comm for data
//		checkIMU();
		timer_200Hz = time;
	}

	// 50Hz loop
	if (time-timer_50Hz > 20000)
	{
		// need to call this very frequently?
		//update_altitude();
                // logging
                if (logging)
                {
                  log_entry((uint8_t)(pitch*5+128), (uint8_t)(roll*5+128), (uint8_t)(torquex*2+128), (uint8_t)(torquey*2+128));
                  digitalWrite(13, logflash);
                  logflash = ~logflash;
                } else {
                  if (armed)
                    digitalWrite(13, HIGH);
                  else
                    digitalWrite(13, LOW);
                }
		timer_50Hz = time;
	}

	// 10Hz loop
	// check wireless data
	// update flight mode (consider heartbeat)
	
//	time = micros();
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

		// check to see if i've flipped over
		// if i have, kill motors and let me die gracefully
		if (abs(roll) > KILL_ANGLE || abs(pitch) > KILL_ANGLE)
		{
			disarm_motors();
			caution(CAUTION_ANGLE_KILL);
		}
                


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

//	time = micros();
	if (time-timer_2Hz > 500000)
	{
		// set default yaw
		if (time > 1530000 && !setdefaultyaw)
		{
			initYaw = yaw;
			setdefaultyaw = 1;
		}

		// check wireless heartbeat
		
		if (heartbeat && millis()-lastHeartbeat > HEARTBEAT_TIMEOUT)
		{
			// no heartbeat detected from base station
			heartbeat = 0;
			changeFlightmode(SAFEMODE);
#if DEBUG
			SERIAL_DEBUG.println("heartbeat died");
#endif
			caution(CAUTION_COMM_LOST);
		}

		// decay the safemode lift is necessary
		if (flightMode == SAFEMODE)
			safemodeLift = safemodeLift*0.99;

		if (debugmode > 0)
			sendDebug();
		if (dosendPID > 0)
			sendPID();
		// run this at 1Hz
		if (divider_1Hz)
			sendHeartbeat();

		flighttime = millis();

		// check physical arming
#if ALLOW_PHYSICAL_ARMING
		if (armed)
		{
			if (digitalRead(PIN_ARM_BUTTON) == HIGH)
			{
				disarm_motors(); // TODO: don't call disarm, it's dumb
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
	alt_armed = 0;
	commtimer = 0;

	init_motors();
	// initialize PID controller

	// start serial ports
	//SERIAL_WIRELESS.begin(WIRELESS_BAUD);
        Serial3.begin(WIRELESS_BAUD);
	Serial1.begin(IMU_BAUD);
	SERIAL_IMU.setTimeout(2);
#if DEBUG
	Serial.begin(DEBUG_BAUD);
#endif

	PID_init();
	// start I2C, SPI if needed here
	// set pinmodes and states
	pinMode(LED_STATUS, OUTPUT);
	pinMode(LED_ARMED, OUTPUT);

	pinMode(PIN_ARM_BUTTON, INPUT);
	// send quick hello over wireless
	SERIAL_WIRELESS.write(COMM_START);
	SERIAL_WIRELESS.write(COMM_MODE_HELLO);
	SERIAL_WIRELESS.write(COMM_END);

	//alt_init();
	// should be ready to enter main loop now
#if DEBUG
	SERIAL_DEBUG.print("Quickstart complete after ");
	SERIAL_DEBUG.print(micros());
	SERIAL_DEBUG.println(" us");
#endif
	battindex = 0;

}
