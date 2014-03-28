
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <SDL.h>
#include <SDL_ttf.h>
#include <SDL_draw.h>

#define PI 3.14159265359
#define TWOPI 6.28318530718

// colors
#define COLOR_PRIMARY 0x009cff
#define COLOR_SECONDARY 0xffc000
#define COLOR_TERTIARY 0xff203a
#define COLOR_QUATERNARY 0x84ff20

#define COLOR_WARN 0xff2222

#define DATASTREAMSIZE 256
#define NUMALTS 64
#define NUMGPS 32

static const SDL_Color SDL_COLOR_PRIMARY = {0,156,255};
static const SDL_Color SDL_COLOR_SECONDARY = {255,192,0};
static const SDL_Color SDL_COLOR_TERTIARY = {255,32,58};
static const SDL_Color SDL_COLOR_QUATERNARY = {132,255,32};

typedef struct copterinfo copterinfo;
struct copterinfo
{
	int datastreaminindex, datastreamoutindex;
	uint8_t datastreamin[DATASTREAMSIZE];
	uint8_t datastreamout[DATASTREAMSIZE];

	// altitude
	float alt0;
	float alt[NUMALTS];
	int altindex;

	// motors
	int motorspeed[6]; // speed
	Uint32 motorwarn[6]; // time of last warning

	// gps
	float lon[NUMGPS], lat[NUMGPS];
	int gpsindex;
	float lon0, lat0;

	// controller info. ehh..
	int currscreen;
	int quit;
};


typedef struct window window;
struct window
{
	void (*draw)(window *w, copterinfo *c, SDL_Surface *screen, TTF_Font *font);// function pointer 
	void (*click)(int x, int y, window *w, copterinfo *c);
	int x0, y0; // origin of window on screen
	int screen; // which screen to show in, -1 for all
	Uint32 color;
};


// function prototypes

void handleTouch (int x, int y, window *w, int numwindows, copterinfo *c);

// windows.c
void window_test (window *w, copterinfo *c, SDL_Surface *screen, TTF_Font *font);
void window_position (window *w, copterinfo *c, SDL_Surface *screen, TTF_Font *font);
void window_datastream (window *w, copterinfo *c, SDL_Surface *screen, TTF_Font *font);
void window_screennav (window *w, copterinfo *c, SDL_Surface *screen, TTF_Font *font);
void window_exit (window *w, copterinfo *c, SDL_Surface *screen, TTF_Font *font);
void window_motorspeed (window *w, copterinfo *c, SDL_Surface *screen, TTF_Font *font);
void window_position_click (int x, int y, window *w, copterinfo *c);
void window_screennav_click (int x, int y, window *w, copterinfo *c);
void window_exit_click (int x, int y, window *w, copterinfo *c);
void window_motorspeed_click (int x, int y, window *w, copterinfo *c);
