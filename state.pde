
/* state.pde
	keep track of current state variables
	like orientation, position, battery life, motor speed, etc.

*/



// check serial port for imu data
void checkIMU()
{
	uint8_t count = 0;
	char buffer[4], readin;

	// allow for multiple things, but dont get stuck here
	while (SERIAL_IMU.available() && count<64)
	{
		// check for start of wireless message
		switch (SERIAL_IMU.read())
		{
			count++;
			case 'I': // orientation
				SERIAL_IMU.readBytes(buffer,4);
				memcpy(&pitch,buffer,4);
				SERIAL_IMU.readBytes(buffer,4);
				memcpy(&roll,buffer,4);
				SERIAL_IMU.readBytes(buffer,4);
				memcpy(&yaw,buffer,4);
				count += 12;
				break;
			case 'S': // gps status
				SERIAL_IMU.readBytes((char*)&gps_quality,1);
				count += 1;
				break;
			case 'P': // gps position
				SERIAL_IMU.readBytes(buffer,4);
				memcpy(&gps_xpos,buffer,4);
				SERIAL_IMU.readBytes(buffer,4);
				memcpy(&gps_ypos,buffer,4);
				SERIAL_IMU.readBytes(buffer,4);
				memcpy(&gps_zpos,buffer,4);
				count += 12;
				break;
			case 'V': // gps velocity
				SERIAL_IMU.readBytes(buffer,4);
				memcpy(&gps_xvel,buffer,4);
				SERIAL_IMU.readBytes(buffer,4);
				memcpy(&gps_yvel,buffer,4);
				count += 8;
				break;
		}
	}
	
}
