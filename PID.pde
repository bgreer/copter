
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
		SERIAL_DEBUG.println(kp_yaw);
		SERIAL_DEBUG.println(ki_yaw);
		SERIAL_DEBUG.println(kd_yaw);
#endif
	} else {
#ifdef DEBUG
		SERIAL_DEBUG.println("no PID vals in EEPROM");
#endif
		kp_roll = 0.20; // 0.1
	  ki_roll = 0.2; // 0.2
		kd_roll = 0.20; // 200.0

	  kp_pitch = 0.2;
	  ki_pitch = 0.2;
	  kd_pitch = 0.20;

		kp_yaw = 0.0;
		ki_yaw = 0.0;
		kd_yaw = 0.0;
		savePIDvals();
	}

}


void PID_update()
{
	// get targets
	targetPitch = (((uint8_t)userPitch)-128)*0.1;
	targetRoll = (((uint8_t)userRoll)-128)*0.1;
	targetYaw = ((uint8_t)userYaw)*2.0 + initYaw;
	targetLift = ((uint8_t)userLift);
	if (targetYaw > 360.) targetYaw -= 360.;
	
	// compute error

	errorPitch = targetPitch - pitch;
	errorRoll = targetRoll - roll;
	errorYaw = targetYaw - yaw;
	errorLift = targetLift - lift; // ???

	// yaw rotation fix
	if (fabs(errorYaw) > fabs(errorYaw-360.))
		errorYaw -= 360.;
	else if (fabs(errorYaw) > fabs(errorYaw+360.))
		errorYaw += 360.;

	// derivative, with some smoothing?
#if DEBUG
//	SERIAL_DEBUG.println(dt);
#endif
        if (newimu)
        {
	  derPitch = 0.1*(errorPitch - lastPitch)*(4./dt) + 0.9*derPitch;
	  derRoll = 0.1*(errorRoll - lastRoll)*(4./dt) + 0.9*derRoll;
	  derYaw = 0.1*(errorYaw - lastYaw)*(4./dt) + 0.9*derYaw; // TODO fix problems mod 360deg
        }
        //if (newimu)
        {
	  lastPitch = errorPitch;
	  lastRoll = errorRoll;
	  lastYaw = errorYaw;
        }

	if (errorYaw > 30.) errorYaw = 30.;
	if (errorYaw < -30.) errorYaw = -30.;

	// note on integral part:
	/* the units are technically degrees*seconds here
	  so maybe it's best to divide by some stability timescale, like 0.25 sec
		then the units will be just degrees, like the proportional term
		I won't implement this scaling yet, because it can be accounted for in the gain
	*/

	// only integrate if we are flying, or close to
	// this is so that it doesnt sit around integrating
	// while it's on slightly angled ground
	if (targetLift > 30) // flight usually occurs around 90-100
	{
		intPitch += (errorPitch-intPitch)*dt*0.002;
		intRoll += (errorRoll-intRoll)*dt*0.002;
		intYaw += errorYaw*dt*0.002;
		// leaky
/*
		intPitch -= intPitch*1e-6;
		intRoll -= intRoll*1e-6;
		intYaw -= intYaw*1e-6;
*/
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
        newimu = 0;
}

// input: targets, IMU state, prev PID state
// takes flightmode into account
// output: liftz, torquex, torquey, torquez
void PID_calcForces()
{
	float temp;
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

	// angle boost
	temp = 2.0 - cos(ToRad(pitch)) - cos(ToRad(roll));
        temp = temp*0.0;
	if (temp < 0.0) temp = 0.0;
	if (temp > 1.0) temp = 1.0;

	// add it all together
	torquex = kp_roll*errorRoll + ki_roll*intRoll + kd_roll*derRoll;
	torquey = kp_pitch*errorPitch + ki_pitch*intPitch + kd_pitch*derPitch;
	torquez = kp_yaw*errorYaw + ki_yaw*intYaw + kd_yaw*derYaw;
	liftz = (1.0 + temp)*targetLift;

        if (targetLift == 0)
        {
          torquex = 0.0;
          torquey = 0.0;
          torquez = 0.0;
        }

#ifdef DEBUG
/*
	SERIAL_DEBUG.print(errorYaw*kp_yaw);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.print(intYaw*ki_yaw);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.print(derYaw*kd_yaw);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.println(torquez);
	*/
#endif

	// put bounds on overal torque
  if (torquex > TORQUEMAX) {torquex = TORQUEMAX; caution(CAUTION_TORQUE_MAX);}
  if (torquex < -TORQUEMAX) {torquex = -TORQUEMAX; caution(CAUTION_TORQUE_MAX);}
  if (torquey > TORQUEMAX) {torquey = TORQUEMAX; caution(CAUTION_TORQUE_MAX);}
  if (torquey < -TORQUEMAX) {torquey = -TORQUEMAX; caution(CAUTION_TORQUE_MAX);}
  if (torquez > TORQUEMAX) {torquez = TORQUEMAX; caution(CAUTION_TORQUE_MAX);}
  if (torquez < -TORQUEMAX) {torquez = -TORQUEMAX; caution(CAUTION_TORQUE_MAX);}

}

