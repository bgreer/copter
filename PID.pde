
float intRoll, intPitch, intYaw;
float derRoll, derPitch, derYaw;
float dderRoll, dderPitch, dderYaw;
float lastRoll, lastPitch, lastYaw;

void PID_init()
{
	// initialize values
	intRoll = intPitch = intYaw = 0.0;
	derRoll = derPitch = derYaw = 0.0;
	dderRoll = dderPitch = dderYaw = 0.0;
	lastRoll = lastPitch = lastYaw = 0.0;

	// set gains
	kp_roll = 0.0;
	ki_roll = 0.0;
	kd_roll = 0.0;
	kdd_roll = 0.0;

	kp_pitch = 0.0;
	ki_pitch = 0.0;
	kd_pitch = 0.0;
	kdd_pitch = 0.0;

	kp_yaw = 0.0;
	ki_yaw = 0.0;
	kd_yaw = 0.0;
	kdd_yaw = 0.0;
}

void PID_update()
{
	// get targets TODO: check these live
	targetPitch = ((int)userPitch)*0.1;
	targetRoll = ((int)userRoll)*0.1;
	targetYaw = ((int)userYaw)*2.0;
	targetLift = ((int)userLift);
	
	// compute error
/*
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
	*/
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
/*
	torquex = kp_roll*errorRoll + ki_roll*intRoll + kd_roll*derRoll;
	torquey = kp_pitch*errorPitch + ki_pitch*intPitch + kd_pitch*derPitch;
	torquez = kp_yaw*errorYaw + ki_yaw*intYaw + kd_yaw*derYaw;
	liftz = targetLift + (2.0 - cos(ToRad(targetPitch)) - cos(ToRad(targetRoll)))*targetLift;
*/
}

