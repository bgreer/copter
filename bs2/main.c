#include <stdlib.h>
#include "SDL.h"
#include <stdio.h>
#include <math.h>
#include "header.h"

int main (int argc, char* argv[])
{
	SDL_Surface *screen;
	SDL_Event event;
	SDL_Joystick *joy;
	int quit;
	Uint32 time, timer0;

	/* check command line args */
	if (argc < 2)
	{
		printf("ERROR: incorrect number of command-line args\n");
		return EXIT_FAILURE;
	}

	commname = argv[1];

	/* init video */
	if (SDL_Init(SDL_INIT_AUDIO|SDL_INIT_VIDEO|SDL_INIT_JOYSTICK) < 0)
	{
		printf("Unable to init SDL: %s\n", SDL_GetError());
		exit(EXIT_FAILURE);
	}

	/* at exit, call SDL quit */
	atexit(SDL_Quit);

	if( !SDL_SetVideoMode(200,200,0,0) ) {
		printf("Could not init SDL window\n");
		exit(EXIT_FAILURE);
	}


	/* get joystick */
	if (SDL_NumJoysticks()>0)
	{
		joy=SDL_JoystickOpen(0);
		if (joy)
		{
			printf("Opened joystick:\n");
			printf("\tName: %s\n", SDL_JoystickName(0));
		} else {
			printf("Could not open joystick.\n");
			exit(EXIT_FAILURE);
		}
	}

	/* open serial port */
	openComm();

	/* initialize things */
	thrustmode = 0;
	statstimer = 0;
	flightmode = 0;
	newflightmode = 0;
	lastsend = 0;
	needtosend = 0;
	reallyneedtosend = 0;
	sendPitch = sendRoll = sendYaw = 128;
	targetYaw = 0.0;
	yawtimer = 0;
	thrustzp = 0.0;

	/* loop until quit */
	quit = 0;
	while (!quit)
	{
		checkWireless();

		if ((needtosend && SDL_GetTicks() - lastsend > 150) || reallyneedtosend)
		{
			sendControls();
			lastsend = SDL_GetTicks();
			timer0 = lastsend;
			needtosend = reallyneedtosend = 0;
		}

		/* heartbeat timer */
		if (SDL_GetTicks() - timer0 > 1000)
		{
			//sendHeartbeat();
			sendControls();
			lastsend = SDL_GetTicks();
			timer0 = lastsend;
		}

		/* increment yaw */
		if (SDL_GetTicks() - yawtimer > 100 && deltaYaw != 0.0)
		{
			incrementYaw();
		}
		
		/* check SDL events */
		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
				case SDL_QUIT:
					quit = 1;
					break;
				case SDL_KEYDOWN:
					handleKeydown(event.key.keysym.sym);
					break;
				case SDL_KEYUP:
					break;
				case SDL_JOYAXISMOTION:
					handleJoystick(event.jaxis.axis, event.jaxis.value);
					break;
				case SDL_JOYBUTTONDOWN:
					handleJoybuttondown(event.jbutton.button);
					break;
				case SDL_JOYBUTTONUP:
					handleJoybuttonup(event.jbutton.button);
					break;
			}
		}
		SDL_Delay(1);
	}

	/* close comm */
	closeComm();

	/* close joystick connection */
	if (SDL_JoystickOpened(0))
		SDL_JoystickClose(joy);

	printf("Exiting.\n");
	return EXIT_SUCCESS;
}
