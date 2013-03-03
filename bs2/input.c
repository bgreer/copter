#include "SDL.h"

void handleKeydown (SDLKey key)
{
	printf("keydown: %d\n", key);
	switch (key)
	{
		case SDLK_ESCAPE:
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
	printf("%d %d\n", axis, value);
}

/* buttons:
	0 = A - flight mode != landed
	1 = B - flight mode = landed
	2 = X - reset something?
	3 = Y - cycle flight mode
	4 = LB - thrust mode
	5 = RB
	6 = Select - send stats
	7 = Start
	8 = XBOX - kill switch
	9 = Left Axis
	10 = Right Axis
*/
void handleJoybuttondown (Uint8 button)
{
	printf("%d down\n", button);
}

/* for some reason, button up events don't get sent until
  some other event happens. looks like I can't really rely
	on them then.
*/
void handleJoybuttonup (Uint8 button)
{
	printf("%d up", button);
}
