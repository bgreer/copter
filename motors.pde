
// start the servo library things for each motor
static void init_motors()
{
	motor[0].attach(ESC_PIN[0]);
	motor[0].write(0);
	motor[1].attach(ESC_PIN[1]);
	motor[1].write(0);
	motor[2].attach(ESC_PIN[2]);
	motor[2].write(0);
	motor[3].attach(ESC_PIN[3]);
	motor[3].write(0);
	motor[4].attach(ESC_PIN[4]);
	motor[4].write(0);
	motor[5].attach(ESC_PIN[5]);
	motor[5].write(0);
#if DEBUG
	SERIAL_DEBUG.println("MOTORS INITIALIZED");
#endif
}

// do arming procedure, set armed flag
static void arm_motors()
{
	armed = 1;
	digitalWrite(LED_ARMED, HIGH);
#if DEBUG
	SERIAL_DEBUG.println("MOTORS ARMED");
#endif
}

// kill motors, then set arm flag
static void disarm_motors()
{
	motor[0].write(0);
	motor[1].write(0);
	motor[2].write(0);
	motor[3].write(0);
	motor[4].write(0);
	motor[5].write(0);
	armed = 0;
#if DEBUG
	SERIAL_DEBUG.println("MOTORS DISARMED");
#endif
}

// run through ESC calibration
// hopefully won't ever need to use this, but just in case..
static void calibrate_motors()
{
	// if the ESCs are armed and you run the calibration cycle,
	// you're going to have a bad time
	if (!armed)
	{

	}
}
