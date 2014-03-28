#include "header.h"

/* goal is to use sdl to make a visual interface for the copter.
	want separate 'windows' for various bits of important data
	examples:
		data rate
		data integrity
		heartbeat
		motor speeds
		battery status
		altitude (relative and absolute)
		position (relative and absolute)
	when drawing, use a list of windows with positions and other settings
	maybe use a 'window' struct with a function pointer and other stuff

	also deal with user input and sending data to copter.
	have flight logs that log everything. shouldnt be too much data
	
*/

int main (int argc, char *argv[])
{
	int ii;
	SDL_Surface *screen;
	SDL_Event event;
	SDL_Rect r1;
	TTF_Font *font;
	Uint32 time, timer0;
	float curralt, currlon, currlat;

	copterinfo c;

	// window stuff
	int numwindows;
	window *w;

	printf("Program Begin.\n");

	/* init video */
	if (SDL_Init(SDL_INIT_VIDEO) < 0)
	{
		printf("Unable to init SDL: %s\n", SDL_GetError());
		exit(EXIT_FAILURE);
	}

	/* at exit, call SDL quit */
	atexit(SDL_Quit);

	screen = SDL_SetVideoMode(800, 480, 32, SDL_NOFRAME);
	r1.x = 0; r1.y = 0; r1.w = 800; r1.h = 480;
	// hide cursor
	SDL_ShowCursor(0);

	TTF_Init();
	font = TTF_OpenFont( "/usr/share/fonts/truetype/ttf-dejavu/DejaVuSansMono.ttf", 10 );

	c.currscreen = 1;

	// initialize copterinfo
	c.datastreaminindex = 0;
	c.datastreamoutindex = 0;

	// initialize altitude
	c.alt0 = 10.0;
	memset(c.alt, 0x00, NUMALTS*sizeof(float));
	c.altindex = 0;

	// initialize gps info
	c.gpsindex = 0;
	c.lon0 = -105.0;
	c.lat0 = 40.0;
	memset(c.lon, 0x00, NUMGPS*sizeof(float));
	memset(c.lat, 0x00, NUMGPS*sizeof(float));

	// initialize motor speeds
	for (ii=0; ii<6; ii++)
	{
		c.motorspeed[ii] = 0;
		c.motorwarn[ii] = -10000;
	}

	// allocate space for windows
	numwindows = 4;
	w = (window*) malloc(numwindows * sizeof(window));

	w[0].draw = &window_position;
	w[0].click = &window_position_click;
	w[0].x0 = 300;
	w[0].y0 = 10;
	w[0].screen = 1;
	w[1].draw = &window_screennav;
	w[1].click = &window_screennav_click;
	w[1].x0 = 670;
	w[1].y0 = 10;
	w[1].screen = -1;
	w[2].draw = &window_exit;
	w[2].click = &window_exit_click;
	w[2].x0 = 740;
	w[2].y0 = 420;
	w[2].screen = 2;
	w[3].draw = &window_motorspeed;
	w[3].click = &window_motorspeed_click;
	w[3].x0 = 570;
	w[3].y0 = 270;
	w[3].screen = 1;

	curralt = 1.0;
	currlon = -105.;
	currlat = 40.0;

	c.quit = 0;
	// loop until quit
	while (!c.quit)
	{

		// fake some data for the datastreams
		c.datastreamin[c.datastreaminindex] = (uint8_t) c.datastreaminindex;
		c.datastreaminindex ++;
		if (c.datastreaminindex >= DATASTREAMSIZE) c.datastreaminindex = 0;
		c.datastreamoutindex ++;
		if (c.datastreamoutindex >= DATASTREAMSIZE) c.datastreamoutindex = 0;

		// fake some altitudes
		curralt += ((rand()%1000)-500.)*((rand()%1000)-500.)*0.000001;
		// increment altitude logger
		c.alt[c.altindex] = curralt;
		c.altindex++;
		if (c.altindex == NUMALTS) c.altindex = 0;

		// fake a location
		currlon += (rand()%1000 - 500)*0.0000001;
		currlat += (rand()%1000 - 500)*0.0000001;
		// increment gps coords
		c.lon[c.gpsindex] = currlon;
		c.lat[c.gpsindex] = currlat;
		c.gpsindex++;
		if (c.gpsindex == NUMGPS) c.gpsindex = 0;

		// fake motorspeeds
		for (ii=0; ii<6; ii++)
		{
			c.motorspeed[ii] = (int)(ii*18*(1.+sin(TWOPI*SDL_GetTicks()/10000.)));
			if (c.motorspeed[ii] > 130) c.motorwarn[ii] = SDL_GetTicks();
		}

		// clear screen
		SDL_FillRect(screen, &r1, 0);

		// draw things
		for (ii=0; ii<numwindows; ii++)
		{
			if (c.currscreen == w[ii].screen || w[ii].screen<0)
				w[ii].draw(w+ii, &c, screen, font);
		}
		SDL_Flip(screen);

		while (SDL_PollEvent(&event))
		{
//			printf("EVENT: %d\n", event.type);
			// touch down 1025
		// touch up 1026
		// touch move 1024
		// mousedown 5
		// mouseup 6
		// mousemove 4
			switch (event.type)
			{
				case SDL_QUIT:
					c.quit = 1;
					break;
				case SDL_KEYDOWN:
					if (handleKeydown(event.key.keysym.sym) < 0)
						c.quit = 1;
					break;
				case SDL_KEYUP:
					break;
				case 1025: // touch down, udoo
					handleTouch(event.button.x, event.button.y, w, numwindows, &c);
					break;
				case 5: // mouse down, laptop
					handleTouch(event.button.x, event.button.y, w, numwindows, &c);
					break;
			}
		}
		SDL_Delay(10);
	}

	TTF_CloseFont(font);

	return EXIT_SUCCESS;
}

