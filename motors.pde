uint8_t motordebug = 0;

// given target body forces and torques, set appropriate motor speeds
// the signs given to torquez may need to be reversed, or just swap the wires on the motors
// assumes motor0 is front right, goes clockwise, motor 5 is front left
void set_motorspeed()
{
	static float temp[6] = {0.0,0.0,0.0,0.0,0.0,0.0};
	static uint8_t i;
	temp[0] = liftz - torquex*0.5 + torquey*0.87 + torquez;
	temp[1] = liftz - torquex                    - torquez;
	temp[2] = liftz - torquex*0.5 - torquey*0.87 + torquez;
	temp[3] = liftz + torquex*0.5 - torquey*0.87 - torquez;
	temp[4] = liftz + torquex                    + torquez;
	temp[5] = liftz + torquex*0.5 + torquey*0.87 - torquez;
	for (i=0;i<6;i++)
	{
		if (temp[i] < 0) temp[i] = 0;
		if (temp[i] > ESC_MAX_VAL-ESC_ARM_VAL) {temp[i] = ESC_MAX_VAL-ESC_ARM_VAL; caution(CAUTION_MOTOR_MAX);}
		temp[i] += ESC_ARM_VAL;
		motorval[i] = (uint8_t)temp[i];
	}
#ifdef MOTOR_DEBUG
	//for (i=0;i<6;i++) motorval[i] = ESC_ARM_VAL;
	//motorval[motordebug] = liftz;
#endif
#ifdef DEBUG
/*
	SERIAL_DEBUG.print(motorval[0]);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.print(motorval[1]);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.print(motorval[2]);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.print(motorval[3]);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.print(motorval[4]);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.println(motorval[5]);
*/
#endif
	write_motors();
}

// commit the motor values to the ESCs
static void write_motors()
{
	if (!armed)
	{
		motorval[0] = 0;
                motorval[1] = 0;
                motorval[2] = 0;
                motorval[3] = 0;
                motorval[4] = 0;
                motorval[5] = 0;
	}
	motor[0].write(motorval[0]);
	motor[1].write(motorval[1]);
	motor[2].write(motorval[2]);
	motor[3].write(motorval[3]);
	motor[4].write(motorval[4]);
	motor[5].write(motorval[5]);
}

// start the servo library things for each motor
static void init_motors()
{
	throttle = 0;
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
	setall_motors(ESC_ARM_VAL);
	// set initial yaw as well
	initYaw = yaw;
#if DEBUG
	SERIAL_DEBUG.println("MOTORS ARMED");
#endif
}

// kill motors, then set arm flag
static void disarm_motors()
{
	throttle = 0;
	setall_motors(ESC_ARM_VAL);
	targetLift = 0;
	liftz = 0;
//	armed = 0;
	digitalWrite(LED_ARMED, LOW);
#if DEBUG
	SERIAL_DEBUG.println("MOTORS DISARMED");
#endif
}

// set value for all motors uniformly, then commit
// mostly for debugging purposes
static void setall_motors(uint8_t val)
{
	motorval[0] = val;
	motorval[1] = val;
	motorval[2] = val;
	motorval[3] = val;
	motorval[4] = val;
	motorval[5] = val;
	write_motors();
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
