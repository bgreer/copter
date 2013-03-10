#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include "SDL.h"
#include "header.h"
#include <errno.h>

int fd;
struct termios options;
int bufferlength, bufferindex;
Uint8 *inbuffer;
int8_t outbuffer[8];

/* computes checksum for outbuffer[0:num-1] */
uint8_t checksum (uint8_t num)
{
	uint8_t ret, ii;
	ret = outbuffer[0];
	for (ii=1; ii<num; ii++)
		ret ^= outbuffer[ii];

	return ret;
}

void parseCommand ()
{
	/* just conform the command format */
	if (inbuffer[0] != 'S')
	{
		printf("ERROR: problem with command: %s\n", inbuffer);
		return;
	}

	switch (inbuffer[1])
	{
		case 'H': /* heartbeat */
			printf("<HB> ");
			fflush(stdout);
			break;
		case 0x02: /* imu stats */
			memcpy(&imu_pitch, inbuffer+2, 4);
			memcpy(&imu_roll, inbuffer+6, 4);
			memcpy(&imu_yaw, inbuffer+10, 4);
			printf("\nIMU: < %f, %f, %f >\n", imu_pitch, imu_roll, imu_yaw);
			break;
		case 0x03: /* position */
			memcpy(&xpos, inbuffer+2, 4);
			memcpy(&ypos, inbuffer+6, 4);
			memcpy(&altitude, inbuffer+10, 4);
			printf("\nPosition: < %f, %f, %f >\n", xpos, ypos, altitude);
			break;
		case 0x04: /* motors */
			printf("motors\n");
			break;
		case 0x05: /* battery */
			printf("battery\n");
			break;
		case 0x06: /* hello */
			printf("\nCopter says hello.\n");
			break;
		case 0x07: /* flight stats */
			printf("Flight Mode = %d\n", (uint8_t)inbuffer[2]);
			printf("Armed = %d\n", (uint8_t)inbuffer[3]);
			break;
		default:
			printf("Unmatched: %d\n", (uint8_t)inbuffer[1]);
			break;
	}
}

void sendControls()
{
	outbuffer[0] = 'S';
	outbuffer[1] = 0x07;
	outbuffer[2] = sendPitch;
	outbuffer[3] = sendRoll;
	outbuffer[4] = sendYaw;
	outbuffer[5] = sendLift;
	outbuffer[6] = checksum(6);
	outbuffer[7] = 'E';
	printf("(send %d) ", (uint8_t)outbuffer[6]);
	fflush(stdout);
	write(fd, outbuffer, 8);
}

void sendHeartbeat ()
{
	write(fd, "SHE", 3);
}

void armMotors ()
{
	printf("Arming motors.\n");
	outbuffer[0] = 'S';
	outbuffer[1] = 0x02;
	outbuffer[2] = 'E';
	write(fd, outbuffer, 3);
}

void sendFlightmode (uint8_t mode)
{
	printf("Setting flight mode to %d.\n", mode);
	outbuffer[0] = 'S';
	outbuffer[1] = 0x06;
	outbuffer[3] = mode;
	outbuffer[4] = 'E';
	write(fd, outbuffer, 4);
}


void killSwitch ()
{
	printf("KILLING MOTORS\n");
	outbuffer[0] = 'S';
	outbuffer[1] = 0x03;
	outbuffer[2] = 'E';
	write(fd, outbuffer, 3);
}

void requestStats ()
{
	printf("Requesting copter stats..\n");
	outbuffer[0] = 'S';
	outbuffer[1] = 0x08;
	outbuffer[2] = 'E';
	write(fd, outbuffer, 3);
	statstimer = SDL_GetTicks();
}


void checkWireless ()
{
	int stat, num, ii;
	Uint8 inbyte[64];

	/* allow timeout on a command */
	if (bufferindex > 0 && SDL_GetTicks() - commtimer > 500)
	{
		printf("WARNING: comm timeout\n");
		bufferindex = 0;
	}

	/* read a single byte */
	num = read(fd, &inbyte, 64);
	for (ii=0; ii<num; ii++)
	{
		if ((bufferindex == 0 && inbyte[ii] == 'S') || bufferindex > 0)
		{
			inbuffer[bufferindex] = inbyte[ii];
			commtimer = SDL_GetTicks();
			if (inbyte[ii] == 'E')
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
	fd = open(joyname, O_RDWR | O_NOCTTY | O_NDELAY | O_NONBLOCK);
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
/*	options.c_cflag &= ~( ICANON | ECHO | ECHOE |ISIG );
	options.c_iflag &= ~(IXON | IXOFF | IXANY );
	options.c_oflag &= ~OPOST;
*/
	tcsetattr(fd, TCSANOW, &options);

	fcntl(fd, F_SETFL, FNDELAY);

	bufferlength = 64;
	bufferindex = 0;
	inbuffer = (Uint8*) malloc(bufferlength);
}

void closeComm ()
{
	close(fd);
}
