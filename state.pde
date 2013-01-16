
/* state.pde
	keep track of current state variables
	like orientation, position, battery life, motor speed, etc.

*/


// check serial port for imu data
void checkIMU()
{
	uint8_t count = 0, ii = 0;
	uint8_t buffer[4];

	while (SERIAL_IMU.available() && count<64)
	{
		// check for start of wireless message
		switch (SERIAL_IMU.read())
		{
			count++;
			case 'I': // orientation
				if (SERIAL_IMU.available() >= 12)
				{
					
				}
				count += 12;
				break;
			case 'S': // gps status
				if (SERIAL_IMU.available() >= 1)
				{
					
				}
				count += 1;
				break;
			case 'P': // gps position
				if (SERIAL_IMU.available() >= 12)
				{
					
				}
				count += 12;
				break;
			case 'V': // gps velocity
				if (SERIAL_IMU.available() >= 8)
				{
					
				}
				count += 8;
				break;
		}
	}
	
}
