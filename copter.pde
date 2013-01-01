
#include "header.h"

// for main loop timing
uint32_t timer_100Hz, timer_50Hz, timer_10Hz, timer_2Hz;
uint32_t time;
uint8_t counter_10Hz;

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
	// set motor speed
	time = micros();
	if (time-timer_100Hz > 10000)
	{
		// do something?
		delay(1);
		timer_100Hz = time;
	}

	// 10Hz loop
	// check telemetry data
	// update flight mode (consider heartbeat)
	time = micros();
	if (time-timer_10Hz > 100000)
	{
		// check telemetry, run operation
		// actually runs at 5Hz
		if (counter_10Hz) checkTelemetry();
		else if (telemOpcode) parseCommand();

		// update flight mode
		// if no telemetry heartbeat, go into safe mode
		if (!heartbeat) flightMode = SAFEMODE;
		timer_10Hz = time;
		counter_10Hz = !counter_10Hz;
	}
	
	// 2Hz loop
	// check telemetry heartbeat timeout
	// get GPS info
	time = micros();
	if (time-timer_2Hz > 500000)
	{
		// check telemetry heartbeat
		if (heartbeat && time-lastHeartbeat > HEARTBEAT_TIMEOUT)
		{
			// no heartbeat detected from base station
			heartbeat = 0;
#if DEBUG
			SERIAL_DEBUG.println("heartbeat died");
#endif
		}

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
	// start serial ports
	SERIAL_TELEM.begin(TELEM_BAUD);
	SERIAL_IMU.begin(IMU_BAUD);
#if DEBUG
	SERIAL_DEBUG.begin(DEBUG_BAUD);
#endif
	// start I2C, SPI if needed here
	// set pinmodes and states
	// send quick hello over telemetry
	

	// should be ready to enter main loop now
#if DEBUG
	SERIAL_DEBUG.print("Quickstart complete after ");
	SERIAL_DEBUG.print(micros());
	SERIAL_DEBUG.println(" us");
#endif
}
