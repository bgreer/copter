#include "header.h"

void window_test (window *w, copterinfo *c, SDL_Surface *screen, TTF_Font *font)
{
	SDL_Rect r1;

	r1.x = w->x0;
	r1.y = w->y0;
	r1.w = 20;
	r1.h = 20;
	SDL_FillRect(screen, &r1, COLOR_PRIMARY);
}

void window_motorspeed (window *w, copterinfo *c, SDL_Surface *screen, TTF_Font *font)
{
	int ii, x, y;
	SDL_Rect r1;
	Uint32 time;

	time = SDL_GetTicks();

	// make border
	r1.x = w->x0;
	r1.y = w->y0;
	r1.w = 220;
	r1.h = 200;
	SDL_FillRect(screen, &r1, COLOR_PRIMARY);
	r1.x += 3;
	r1.y += 3;
	r1.w -= 6;
	r1.h -= 6;
	SDL_FillRect(screen, &r1, 0);

	// draw circles
	for (ii=0; ii<6; ii++)
	{
		// find center
		x = w->x0 + 110 + 60*cos(TWOPI*ii/6.0);
		y = w->y0 + 100 + 60*sin(TWOPI*ii/6.0);
		// draw border, possible color warning
		if (time - c->motorwarn[ii] < 2000)
		{
			Draw_FillCircle(screen, x, y, 33, COLOR_WARN);
			Draw_FillCircle(screen, x, y, 30, 0);
		} else {
			Draw_Circle(screen, x, y, 30, COLOR_PRIMARY);
		}
		// fill with motorspeed
		Draw_FillCircle(screen, x, y, (int)(30.*c->motorspeed[ii]/180.), COLOR_SECONDARY);
	}
}

void window_motorspeed_click (int x, int y, window *w, copterinfo *c)
{

}

void window_position (window *w, copterinfo *c, SDL_Surface *screen, TTF_Font *font)
{
	int ii, ind, width;
	SDL_Rect r1, r2;
	SDL_Surface *text;
	char buffer[128];
	float min, max, scale, dx, dy, dist;

	// make border
	r1.x = w->x0;
	r1.y = w->y0;
	r1.w = 200;
	r1.h = 260;
	SDL_FillRect(screen, &r1, COLOR_PRIMARY);
	r1.x += 3;
	r1.y += 3;
	r1.w -= 6;
	r1.h -= 6;
	SDL_FillRect(screen, &r1, 0);

	// process altitudes to get range
	min = c->alt[0];
	max = c->alt[0];
	for (ii=1; ii<NUMALTS; ii++)
	{
		if (c->alt[ii] > max) max = c->alt[ii];
		if (c->alt[ii] < min) min = c->alt[ii];
	}
	if (max-min == 0.0) {scale = 1.0; min = 0.0;}
	else scale = 30. / (max - min);

	// altitude plot
	width = (int)floor(180.0/NUMALTS);
	for (ii=0; ii<NUMALTS; ii++)
	{
		ind = c->altindex - ii - 1;
		if (ind < 0) ind += NUMALTS;
		r1.x = w->x0 + 130 - ii*120./NUMALTS - width;
		r1.h = scale * (c->alt[ind]-min);
		r1.y = w->y0 + 40 - r1.h;
		r1.w = width;
		SDL_FillRect(screen, &r1, COLOR_SECONDARY);
	}

	// print altitude in text
	ind = c->altindex - 1;
	if (ind < 0) ind += NUMALTS;
	r1.x = 0;
	r1.y = 0;
	r1.w = 200;
	r1.h = 200;
	r2.x = w->x0 + 132;
	r2.y = w->y0 + 16;
	r2.w = 200;
	r2.h = 200;
	sprintf(buffer, "A: %7.2fm", c->alt[ind]);
	text = TTF_RenderText_Solid(font, buffer, SDL_COLOR_SECONDARY);
	SDL_BlitSurface(text, &r1, screen, &r2);
	r2.y = w->y0 + 30;
	sprintf(buffer, "R: %7.2fm", c->alt[ind] - c->alt0);
	text = TTF_RenderText_Solid(font, buffer, SDL_COLOR_SECONDARY);
	SDL_BlitSurface(text, &r1, screen, &r2);

	// lat/lon text
	ind = c->gpsindex - 1;
	if (ind < 0) ind += NUMGPS;
	r2.x = w->x0 + 20;
	r2.y = w->y0 + 40;
	sprintf(buffer, "LON: %11.6f", c->lon[ind]);
	text = TTF_RenderText_Solid(font, buffer, SDL_COLOR_SECONDARY);
	SDL_BlitSurface(text, &r1, screen, &r2);
	r2.y = w->y0 + 50;
	sprintf(buffer, "LAT: %11.6f", c->lat[ind]);
	text = TTF_RenderText_Solid(font, buffer, SDL_COLOR_SECONDARY);
	SDL_BlitSurface(text, &r1, screen, &r2);

	// draw a circle
	Draw_Circle(screen, w->x0 + 100, w->y0 + 160, 90, COLOR_PRIMARY);
	Draw_Circle(screen, w->x0 + 100, w->y0 + 160, 60, COLOR_PRIMARY);
	Draw_Circle(screen, w->x0 + 100, w->y0 + 160, 30, COLOR_PRIMARY);
	Draw_Line(screen, w->x0+100, w->y0+70, w->x0+100, w->y0+250, COLOR_PRIMARY);
	Draw_Line(screen, w->x0+10, w->y0+160, w->x0+190, w->y0+160, COLOR_PRIMARY);

	// determing gps scale in meters for circle radius
	// must be integer multiple of 20.
	max = 0.0;
	for (ii=0; ii<NUMGPS; ii++)
	{
		dx = (c->lon[ii] - c->lon0)*111034.6*cos(c->lon0*0.01745329251);
		dy = (c->lat[ii] - c->lat0)*111034.6;
		dist = sqrt(dx*dx + dy*dy);
		if (dist > max) max = dist;
	}
	scale = ceil(max/20.)*20.;
	if (scale < 20.0) scale = 20.0;
	// plot gps positions
	for (ii=0; ii<NUMGPS; ii++)
	{
		ind = c->gpsindex - ii;
		if (ind < 0) ind += NUMGPS;
		dx = (c->lon[ind] - c->lon0)*111034.6*cos(c->lon0*0.01745329251);
		dy = (c->lat[ind] - c->lat0)*111034.6;
		// convert to pixels
		dx = dx*90./scale;
		dy = dy*90./scale;
		if (fabs(dx) < 90. && fabs(dy) < 90.)
			Draw_FillCircle(screen, w->x0+100+dx, w->y0+160+dy, ((ii==1)?3:1), COLOR_SECONDARY);
	}

	// print map scale
	r2.x = w->x0 + 130;
	r2.y = w->y0 + 245;
	sprintf(buffer, "%4.0fm", scale);
	text = TTF_RenderText_Solid(font, buffer, SDL_COLOR_SECONDARY);
	SDL_BlitSurface(text, &r1, screen, &r2);
}

void window_position_click (int x, int y, window *w, copterinfo *c)
{

}

void window_datastream (window *w, copterinfo *c, SDL_Surface *screen, TTF_Font *font)
{
	int ii, ij, ind;
	SDL_Rect r1;

	r1.w = 2;
	r1.h = 2;
	r1.y = w->y0;
	r1.x = w->x0;

	for (ii=0; ii<DATASTREAMSIZE; ii++)
	{
		ind = ii + c->datastreaminindex;
		if (ind > DATASTREAMSIZE) ind -= DATASTREAMSIZE;
		for (ij=0; ij<8; ij++)
		{
			if (((c->datastreamin[ind]) >> ij) & 0x01) SDL_FillRect(screen, &r1, COLOR_PRIMARY);
			else SDL_FillRect(screen, &r1, COLOR_SECONDARY);
			r1.x += 3;
		}
		if (ii % 2 == 1)
		{
			r1.x -= 49;
			r1.y += 4;
		} else {
			r1.x += 1;
		}
	}
}


void window_screennav (window *w, copterinfo *c, SDL_Surface *screen, TTF_Font *font)
{
	SDL_Rect r1, r2;
	SDL_Surface *text;
	int currscreen;
	char *txt1 = "FLIGHT";
	char *txt2 = " DATA ";
	char *txt3 = "CONTROL";

	// make border
	r1.x = w->x0;
	r1.y = w->y0;
	r1.w = 120;
	r1.h = 55;
	SDL_FillRect(screen, &r1, COLOR_PRIMARY);
	r1.x += 3;
	r1.y += 3;
	r1.w -= 6;
	r1.h -= 6;
	SDL_FillRect(screen, &r1, 0);
	r1.w = 2;
	r1.h = 41;
	r1.x = w->x0+59;
	r1.y = w->y0+14;
	SDL_FillRect(screen, &r1, COLOR_PRIMARY);
	r1.w = 120;
	r1.h = 2;
	r1.x = w->x0;
	r1.y = w->y0+14;
	SDL_FillRect(screen, &r1, COLOR_PRIMARY);

	// label current screen
	r1.x = 0;
	r1.y = 0;
	r1.w = 200;
	r1.h = 200;
	r2.x = w->x0 + 40;
	r2.y = w->y0 + 2;
	r2.w = 200;
	r2.h = 200;
	switch (c->currscreen)
	{
		case 0:
			Draw_FillCircle(screen, w->x0+90, w->y0+33, 10, COLOR_SECONDARY);
			text = TTF_RenderText_Solid(font, txt2, SDL_COLOR_QUATERNARY);
			break;
		case 1:
			Draw_FillCircle(screen, w->x0+30, w->y0+33, 10, COLOR_QUATERNARY);
			Draw_FillCircle(screen, w->x0+90, w->y0+33, 10, COLOR_TERTIARY);
			text = TTF_RenderText_Solid(font, txt1, SDL_COLOR_SECONDARY);
			break;
		case 2:
			Draw_FillCircle(screen, w->x0+30, w->y0+33, 10, COLOR_SECONDARY);
			text = TTF_RenderText_Solid(font, txt3, SDL_COLOR_TERTIARY);
			break;
	}
	SDL_BlitSurface(text, &r1, screen, &r2);

	// left and right

}

void window_screennav_click (int x, int y, window *w, copterinfo *c)
{
	if (x < w->x0 || y < w->y0+13) return;
	if (x > w->x0 + 120 || y > w->y0 + 55) return;
	if (x-(w->x0+60) > 0) // right
	{
		if (c->currscreen < 2) c->currscreen ++;
	} else { // left
		if (c->currscreen > 0) c->currscreen --;
	}
}

void window_exit (window *w, copterinfo *c, SDL_Surface *screen, TTF_Font *font)
{
	SDL_Rect r1, r2;
	SDL_Surface *text;
	char *txt1 = "EXIT";

	// make border
	r1.x = w->x0;
	r1.y = w->y0;
	r1.w = 50;
	r1.h = 50;
	SDL_FillRect(screen, &r1, COLOR_PRIMARY);
	r1.x += 3;
	r1.y += 3;
	r1.w -= 6;
	r1.h -= 6;
	SDL_FillRect(screen, &r1, 0);

	// circle
	Draw_Circle(screen, w->x0+25, w->y0+25, 16, COLOR_TERTIARY);
	// text
	r1.x = 0; r1.y = 0; r1.w=200; r1.h=200;
	r2.x = w->x0+14; r2.y = w->y0+19; r2.w=200;r1.h=200;
	text = TTF_RenderText_Solid(font, txt1, SDL_COLOR_TERTIARY);
	SDL_BlitSurface(text, &r1, screen, &r2);
}

void window_exit_click (int x, int y, window *w, copterinfo *c)
{
	if (x < w->x0 || y < w->y0) return;
	if (x > w->x0 + 50 || y > w->y0 + 50) return;
	printf("Exiting with window click\n");
	c->quit = 1;
}
