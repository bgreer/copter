
float intRoll, intPitch, intYaw;
float derRoll, derPitch, derYaw;
float dderRoll, dderPitch, dderYaw;
float lastRoll, lastPitch, lastYaw;
float errorPitch, errorRoll, errorYaw, errorLift;

void PID_init()
{
	// initialize values
	intRoll = intPitch = intYaw = 0.0;
	derRoll = derPitch = derYaw = 0.0;
	dderRoll = dderPitch = dderYaw = 0.0;
	lastRoll = lastPitch = lastYaw = 0.0;
	targetPitch = targetRoll = targetYaw = 0.0;
	targetLift = 0.0;
	userPitch = userRoll = 128;
	userYaw = userLift = 0;

        if (verifyPIDvals())
        {
          getPIDvals();
#ifdef DEBUG
          SERIAL_DEBUG.println("grabbed PID values from EEPROM");
          SERIAL_DEBUG.println(kp_roll);
          SERIAL_DEBUG.println(ki_roll);
          SERIAL_DEBUG.println(kd_roll);
#endif
        } else {
#ifdef DEBUG
          SERIAL_DEBUG.println("no PID vals in EEPROM");
#endif
          kp_roll = 0.5; // 0.5
	  ki_roll = 0.1; // 0.1
	  kd_roll = 20.0; // 20.0

	  kp_pitch = 0.5;
	  ki_pitch = 0.1;
	  kd_pitch = 20.0;
          savePIDvals();
        }

	kp_yaw = 0.0;
	ki_yaw = 0.0;
	kd_yaw = 0.0;
}


void PID_update()
{
	// get targets
	targetPitch = (((uint8_t)userPitch)-128)*0.1;
	targetRoll = (((uint8_t)userRoll)-128)*0.1;
	targetYaw = ((uint8_t)userYaw)*2.0;
	targetLift = ((uint8_t)userLift);
	
	// compute error

	errorPitch = targetPitch - pitch;
	errorRoll = targetRoll - roll;
	errorYaw = targetYaw - yaw;
	errorLift = targetLift - lift; // ???

	// derivative, with some smoothing?
	derPitch = 0.5*(errorPitch - lastPitch) + 0.5*derPitch;
	derRoll = 0.5*(errorRoll - lastRoll) + 0.5*derRoll;
	derYaw = 0.5*(errorYaw - lastYaw) + 0.5*derYaw; // TODO fix problems mod 360deg
	lastPitch = errorPitch;
	lastRoll = errorRoll;
	lastYaw = errorYaw;

	// note on integral part:
	/* the units are technically degrees*seconds here
	  so maybe it's best to divide by some stability timescale, like 0.25 sec
		then the units will be just degrees, like the proportional term
		I won't implement this scaling yet, because it can be accounted for in the gain
	*/

	// only integrate if we are flying, or close to
	// this is so that it doesnt sit around integrating
	// while it's on slightly angled ground
	if (targetLift > 60) // flight usually occurs around 90-100
	{
		intPitch += errorPitch*0.005;
		intRoll += errorRoll*0.005;
		intYaw += errorYaw*0.005;
	}

	// put bounds on integral part
	if (intRoll > PID_INTMAX) intRoll = PID_INTMAX;
	if (intRoll < -PID_INTMAX) intRoll = -PID_INTMAX;
	if (intPitch > PID_INTMAX) intPitch = PID_INTMAX;
	if (intPitch < -PID_INTMAX) intPitch = -PID_INTMAX;

#ifdef DEBUG
	/*
	SERIAL_DEBUG.print(errorPitch);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.print(intPitch);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.print(derPitch);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.println(pitch);
	*/
#endif
	// 
}

// input: targets, IMU state, prev PID state
// takes flightmode into account
// output: liftz, torquex, torquey, torquez
void PID_calcForces()
{
	// for each flightmode, determine targets
	switch (flightMode)
	{
		case LANDED: // just kidding, set to zero and return
			liftz = 0.0;
			torquex = 0.0;
			torquey = 0.0;
			torquez = 0.0;
			return;
			break;
		case SAFEMODE:
			targetPitch = 0.0;
			targetRoll = 0.0;
			targetYaw = yaw_hold;
			targetLift = safemodeLift;
			break;
		case STABILIZE:
			break;
	}

	// add it all together
	torquex = kp_roll*errorRoll + ki_roll*intRoll + kd_roll*derRoll;
	torquey = kp_pitch*errorPitch + ki_pitch*intPitch + kd_pitch*derPitch;
	torquez = kp_yaw*errorYaw + ki_yaw*intYaw + kd_yaw*derYaw;
	liftz = targetLift;// + (2.0 - cos(ToRad(pitch)) - cos(ToRad(roll)))*targetLift;

	// put bounds on overal torque
  if (torquex > TORQUEMAX) {torquex = TORQUEMAX; caution(CAUTION_TORQUE_MAX);}
  if (torquex < -TORQUEMAX) {torquex = -TORQUEMAX; caution(CAUTION_TORQUE_MAX);}
  if (torquey > TORQUEMAX) {torquey = TORQUEMAX; caution(CAUTION_TORQUE_MAX);}
  if (torquey < -TORQUEMAX) {torquey = -TORQUEMAX; caution(CAUTION_TORQUE_MAX);}
}

