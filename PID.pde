
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

	// set gains
	kp_roll = 0.02; // 0.02
	ki_roll = 0.0; // 0.05
	kd_roll = 0.02; // 0.05
	kdd_roll = 0.0;

	kp_pitch = 0.02;
	ki_pitch = 0.0;
	kd_pitch = 0.02;
	kdd_pitch = 0.0;

	kp_yaw = 0.0;
	ki_yaw = 0.0;
	kd_yaw = 0.0;
	kdd_yaw = 0.0;
}

void PID_update()
{
	// get targets TODO: check these live
	targetPitch = (((uint8_t)userPitch)-128)*0.1;
	targetRoll = (((uint8_t)userRoll)-128)*0.1;
	targetYaw = ((uint8_t)userYaw)*2.0;
	targetLift = ((uint8_t)userLift);
	
	// compute error

	errorPitch = targetPitch - pitch;
	errorRoll = targetRoll - roll;
	errorYaw = targetYaw - yaw;
	errorLift = targetLift - lift; // ???

	// update PID elements
	intPitch += errorPitch*0.001;
	derPitch = errorPitch - lastPitch;
	intRoll += errorRoll*0.001;
	derRoll = errorRoll - lastRoll;
	intYaw += errorYaw*0.001;
	derYaw = errorYaw - lastYaw; // TODO fix problems mod 360deg
#ifdef DEBUG
	/*
	SERIAL_DEBUG.print(errorPitch);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.print(errorRoll);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.print(targetYaw);
	SERIAL_DEBUG.print("\t");
	SERIAL_DEBUG.println(targetLift);
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

	torquex = kp_roll*errorRoll + ki_roll*intRoll + kd_roll*derRoll;
	torquey = kp_pitch*errorPitch + ki_pitch*intPitch + kd_pitch*derPitch;
	torquez = kp_yaw*errorYaw + ki_yaw*intYaw + kd_yaw*derYaw;
	liftz = targetLift;// + (2.0 - cos(ToRad(pitch)) - cos(ToRad(roll)))*targetLift;

}

