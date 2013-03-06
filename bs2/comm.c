#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include "SDL.h"
#include "header.h"

int fd;
struct termios options;
int bufferlength, bufferindex;
Uint8 *inbuffer;

void parseCommand ()
{
	/* just conform the command format */
	if (inbuffer[0] != 'S' || inbuffer[bufferlength] != 'E')
	{
		printf("ERROR: problem with command: %s", inbuffer);
		return;
	}

	switch (inbuffer[1])
	{
		case 'H': /* heartbeat */
			printf("heartbeat received\n");
			break;
	}
}

void sendControls()
{
	printf("(send) ");
	fflush(stdout);
	write(fd, "S", 1);
	write(fd, 0x07, 1);
	write(fd, sendPitch, 1);
	write(fd, sendRoll, 1);
	write(fd, sendYaw, 1);
	write(fd, sendLift, 1);
	write(fd, "E", 1);
}

void sendHeartbeat ()
{
	write(fd, "SHE", 3);
}

void armMotors ()
{
	printf("Arming motors.\n");
	write(fd, "S", 1);
	write(fd, 0x02, 1);
	write(fd, "E", 1);
}

void killSwitch ()
{
	printf("KILLING MOTORS\n");
	write(fd, "S", 1);
	write(fd, 0x03, 1);
	write(fd, "E", 1);
}

void requestStats ()
{
	printf("Requesting copter stats..\n");
	write(fd, "S", 1);
	write(fd, 0x08, 1);
	write(fd, "E", 1);
	statstimer = SDL_GetTicks();
}


void checkWireless ()
{
	int stat;
	Uint8 inbyte;

	/* allow timeout on a command */
	if (bufferindex > 0 && SDL_GetTicks() - commtimer > 2000)
	{
		printf("WARNING: comm timeout\n");
		bufferindex = 0;
	}

	/* read a single byte */
	while (stat=read(fd, &inbyte, 1) > 0)
	{
		if ((bufferindex == 0 && inbyte == 'S') || bufferindex > 0)
		{
			inbuffer[bufferindex] = inbyte;
			commtimer = SDL_GetTicks();
			if (inbyte == 'E')
			{
				parseCommand();
				bufferindex = 0;
			} else {
				bufferindex ++;
				if (bufferindex == bufferlength)
				{
					printf("WARNING: input buffer full\n");
					bufferindex = 0;
				}
			}
		}
	}
}

void openComm ()
{
	fd = open("/dev/ttyACM0", O_RDWR | O_NOCTTY | O_NDELAY);
	if (fd == -1)
	{
		printf("ERROR: Unable to open comm port!\n");
	} else {
		fcntl(fd, F_SETFL, 0);
	}
	tcgetattr(fd, &options);
	cfsetispeed(&options, B38400);
	cfsetispeed(&options, B38400);
	options.c_cflag |= (CLOCAL | CREAD);
	options.c_cflag &= ~PARENB;
	options.c_cflag &= ~CSTOPB;
	options.c_cflag &= ~CSIZE;
	options.c_cflag |= CS8;
	options.c_cflag &= ~( ICANON | ECHO | ECHOE |ISIG );
	options.c_iflag &= ~(IXON | IXOFF | IXANY );
	options.c_oflag &= ~OPOST;

	tcsetattr(fd, TCSANOW, &options);

	fcntl(fd, F_SETFL, FNDELAY);

	bufferlength = 32;
	bufferindex = 0;
	inbuffer = (Uint8*) malloc(bufferlength);
}

void closeComm ()
{
	close(fd);
}
