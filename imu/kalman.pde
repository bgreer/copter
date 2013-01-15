
/* kalman.pde
	holds the entire state vector and deals with updating it

	state vector:
	0,1,2 = position x,y,z
	3,4,5 = velocity x,y,z
	6,7,8 = acceleration x,y,z
	9,10,11,12 = quaternion
*/

#define KALMAN_NUMSTATES 13

float kg[KALMAN_NUMSTATES]; // gain vector
float ks[KALMAN_NUMSTATES]; // state vector
float ks_old[KALMAN_NUMSTATES];
float *km[KALMAN_NUMSTATES]; // measurement pointer vector
uint32_t kalman_lastcalled;
float dt2;

// default initialization
void kalman_init()
{
	uint8_t ii;
	for (ii=0; ii<KALMAN_NUMSTATES; ii++)
	{
		kalman_setstate(ii, 0.0);
		kalman_setgain(ii, 0.5);
	}
	kalman_lastcalled = micros(); // warning, micros() overflows after ~70mins
}

float kalman_getstate(uint8_t index)
{
	return ks[index];
}

void kalman_setstate(uint8_t index, float value)
{
	ks[index] = value;
}

void kalman_setgain(uint8_t index, float value)
{
	kg[index] = value;
}

void kalman_addmeasurement(uint8_t index, float *ptr)
{
	km[index] = ptr;
}

void kalman_update()
{
	uint8_t ii;

	dt = (micros() - kalman_lastcalled)*0.001*0.001;
	kalman_lastcalled = micros();
	dt2 = dt*dt*0.5;

	// copy state
	for (ii=0; ii<KALMAN_NUMSTATES; ii++)
		ks_old[ii] = ks[ii];

	// predict
	// position integrated from vel and acc
	ks[0] = ks_old[0] + ks_old[3]*dt + ks_old[6]*dt2;
	ks[1] = ks_old[1] + ks_old[4]*dt + ks_old[7]*dt2;
	ks[2] = ks_old[2] + ks_old[5]*dt + ks_old[8]*dt2;
	// velocity integrated from acc
	ks[3] = ks_old[3] + ks_old[6]*dt;
	ks[4] = ks_old[4] + ks_old[7]*dt;
	ks[5] = ks_old[5] + ks_old[8]*dt;
	// acc not changed, remove from state vector? use differentiated velocity?
	// quaternion??

	// correct with non-NULL measurements
	for (ii=0; ii<KALMAN_NUMSTATES; ii++)
	{
		if (km[ii] != NULL)
		{
			ks[ii] = ks[ii] + kg[ii]*(*(km[ii]) - ks[ii]);
			// at the end, kill the measurement
			km[ii] = NULL;
		}
	}
}
