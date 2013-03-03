#include <fcntl.h>
#include <termios.h>
#include <stdio.h>

int fd;
struct termios options;

void openComm (char *port)
{
	fd = open("/dev/ttyS0", O_RDWR | O_NOCTTY | O_NDELAY);
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

}
