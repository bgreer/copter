
float intRoll, intPitch, intYaw;
float derRoll, derPitch, derYaw;
float dderRoll, dderPitch, dderYaw;
float lastRoll, lastPitch, lastYaw;
float errorPitch, errorRoll, errorYaw, errorLift;
float introll1, intpitch1;

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
	kp_roll = 1.5; // 0.5
	ki_roll = 0.1; // 0.05
	kd_roll = 20.0; // 10.0
	kdd_roll = 0.0;

	kp_pitch = 1.5;
	ki_pitch = 0.1;
	kd_pitch = 20.0;
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
	derPitch = 0.1*(errorPitch - lastPitch) + 0.9*derPitch;
	intRoll += errorRoll*0.001;
	derRoll = 0.1*(errorRoll - lastRoll) + 0.9*derRoll;
	intYaw += errorYaw*0.001;
	derYaw = 0.1*(errorYaw - lastYaw) + 0.9*derYaw; // TODO fix problems mod 360deg
lastPitch = errorPitch;
lastRoll = errorRoll;
lastYaw = errorYaw;
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
introll1 = ki_roll*intRoll;
intpitch1 = ki_pitch*intPitch;
if (introll1 > 5.0) introll1 = 5.0;
if (introll1 < -5.0) introll1 = -5.0;
if (intpitch1 > 5.0) intpitch1 = 5.0;
if (intpitch1 < -5.0) intpitch1 = -5.0;
	torquex = kp_roll*errorRoll + introll1 + kd_roll*derRoll;
	torquey = kp_pitch*errorPitch + intpitch1 + kd_pitch*derPitch;
	torquez = kp_yaw*errorYaw + ki_yaw*intYaw + kd_yaw*derYaw;
	liftz = targetLift;// + (2.0 - cos(ToRad(pitch)) - cos(ToRad(roll)))*targetLift;

  if (torquex > TORQUEMAX) torquex = TORQUEMAX;
  if (torquex < -TORQUEMAX) torquex = -TORQUEMAX;
  if (torquey > TORQUEMAX) torquey = TORQUEMAX;
  if (torquey < -TORQUEMAX) torquey = -TORQUEMAX;
}

