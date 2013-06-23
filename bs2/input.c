#include "SDL.h"
#include "header.h"

int inputmode = 0;
uint8_t userinputbuffer[128];
int userinputbufferpos = 0; // im too tired to name properly

/* functions for converting input to controls */

void mapRoll (Sint16 input)
{
	Uint8 mapped;
	float temp;

	temp = input;
	temp /= 280.;
	temp += 128;


	if (temp < 0.0) temp = 0.0;
	if (temp > 255.0) temp = 255.0;

	mapped = (Uint8) temp;

	sendRoll = mapped;
	needtosend = 1;
}

void mapPitch (Sint16 input)
{
	Uint8 mapped;
	float temp;

	temp = input;
	temp /= 280.;
	temp += 128;


	if (temp < 0.0) temp = 0.0;
	if (temp > 255.0) temp = 255.0;

	mapped = (Uint8) temp;

	sendPitch = mapped;
	needtosend = 1;
}

/* yaw is different */
void mapYaw (Sint16 input)
{
	float temp;

	temp = input;
	temp /= 32767.;

	deltaYaw = temp;
}

void incrementYaw ()
{
	Uint8 mapped;

	targetYaw += deltaYaw*0.0001;
	if (targetYaw >= 360.0) targetYaw -= 360.;
	if (targetYaw < 0.0) targetYaw += 360.;

	mapped = (Uint8)(targetYaw/2.);

	sendYaw = mapped;
	needtosend = 1;
}

void mapLift (Sint16 input)
{
	Uint8 mapped;
	float temp;

	thrust = -input/1024.;
/*	if (input < 0)
		thrust = thrust*thrust/500.;
	else
		thrust = -thrust*thrust/500.;
		*/

	temp = thrust + thrustzp;
	if (temp < 0.0) temp = 0.0;
	if (temp > 255.0) temp = 255.0;

	mapped = (Uint8) temp;

	if (mapped != sendLift)
	{
		sendLift = mapped;
		printf("%d\n", sendLift);
		needtosend = 1;
	}
}

void parseuserinput()
{
	float temp;
	userinputbuffer[userinputbufferpos] = '\0';
	temp = atof(userinputbuffer);
	printf("\nUser input: %f\n", temp);
	if (temp >= 0.0 && temp <= 500.)
	{
		switch (inputmode)
		{
			case 1: // P
				KPout = temp;
				break;
			case 2: // I
				KIout = temp;
				break;
			case 3: // D
				KDout = temp;
				break;
		}
	} else {
		printf("Invalid input!\n");
	}
	inputmode = 0;
	userinputbufferpos =0;
}


/* functions for handling direct input */

void handleKeydown (SDLKey key)
{
	float tempin;
//	printf("keydown: %d\n", key);
	if (inputmode > 0 && key != 13)
	{
		userinputbuffer[userinputbufferpos] = (uint8_t)key;
		userinputbufferpos ++;
		if (userinputbufferpos == 128)
		{
			printf("\nuser input buffer overflow\n");
			userinputbufferpos = 0;
		}
	}
	switch (key)
	{
		case SDLK_ESCAPE:
			break;
		case 112: /* P */
			printf("\nType new P value: ");
			inputmode = 1;
			break;
		case 105: /* I */
			printf("\nType new I value: ");
			inputmode = 2;
			break;
		case 100: /* D */
			printf("\nType new D value: ");
			inputmode = 3;
			break;
		case 115: /* S */
			printf("\nCurrent PID values: ");
			printf("P = %f, ", KPin);
			printf("I = %f, ", KIin);
			printf("D = %f\n", KDin);
			printf("    New PID values: ");
			printf("P = %f, ", KPout);
			printf("I = %f, ", KIout);
			printf("D = %f\n", KDout);
			fflush(stdout);
			break;
		case 103: /* G */
			getPID();
			break;
		case 13: /* enter */
			parseuserinput();
			break;
		case 113: /* Q */
			sendP();
			break;
		case 119: /* W */
			sendI();
			break;
		case 101: /* E */
			sendD();
			break;
		case 108: /* L */
			startlog();
			break;
		case 107: /* K */
			printlog();
			break;
	}
}


void handleKeyup (SDLKey key)
{

}

/* axes:
	0 = Left X - roll
	1 = Left Y - pitch
	2 = Right X - yaw
	3 = Right Y - thrust (if thrust mode)
	4 = Left Trigger (broken)
	5 = Right Trigger (broken)
*/
void handleJoystick (Uint8 axis, Sint16 value)
{
//	printf("%d %d\n", axis, value);
	switch (axis)
	{
		case 0:
			mapRoll(value);
			break;
		case 1:
			mapPitch(value);
			break;
		case 2:
			mapYaw(value);
			break;
		case 3:
			if (thrustmode)
				mapLift(value);
			break;
	}
}

/* buttons:
	0 = A - flight mode != landed
	1 = B - flight mode = landed
	2 = X - resend user controls
	3 = Y - cycle flight mode
	4 = LB - thrust mode
	5 = RB - set thrust zero point
	6 = Select - send stats
	7 = Start - arm motors
	8 = XBOX - kill switch
	9 = Left Axis
	10 = Right Axis
*/
void handleJoybuttondown (Uint8 button)
{
	switch (button)
	{
		case 0:
			sendFlightmode(0x02);
			break;
		case 1:
			sendFlightmode(0x01);
			break;
		case 2:
			printf("\nPitch=%d\nRoll=%d\nYaw=%d\nLift=%d\n",sendPitch,sendRoll,sendYaw,sendLift);
			needtosend = 1;
			break;
		case 3:
			break;
		case 4:
			thrustmode = 1;
			break;
		case 5:
			/* send thrust zero-point command */
			thrustzp = sendLift;
			thrust = 0.0;
			thrustmode = 0; /* don't want to suddenly accelerate */
			break;
		case 6:
			requestStats();
			break;
		case 7:
			armMotors();
			break;
		case 8:
			killSwitch();
			break;
	}
}

void handleJoybuttonup (Uint8 button)
{
	switch (button)
	{
		case 4:
			thrustmode = 0;
			break;
	}
}
