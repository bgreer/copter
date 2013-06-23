
/* state.pde
	keep track of current state variables
	like orientation, position, battery life, motor speed, etc.

*/

/* description of flight modes!

	SAFEMODE  - stabilized, slowly de-throttle (for possible in-flight failures)
	LANDED    - zero throttle, determined by proximity to land
	STABILIZE - orientation stabilization, no position constraints
	ALT_HOLD  - adjust throttle to maintain constant altitude
	POS_HOLD  - constant altitude and GPS position (for photography?)

*/


void changeFlightmode(uint8_t newmode)
{
	switch (newmode)
	{
		case SAFEMODE:
			yaw_hold = yaw;
			safemodeLift = targetLift;
			break;
		case LANDED:
			break;
		case STABILIZE:
			yaw_hold = yaw;
			break;
		case ALT_HOLD:
			// store current alt
			yaw_hold = yaw;
			zpos_hold = altitude;
			break;
		case POS_HOLD:
			// store current 3d position
			yaw_hold = yaw;
			xpos_hold = gps_xpos;
			ypos_hold = gps_ypos;
			zpos_hold = altitude;
			break;
		default: // somethings wrong
			changeFlightmode(SAFEMODE);
			return;
	}
	flightMode = newmode;
}


// loop through each batter and get a reading
// raw data needs to be converted to a voltage
// then maybe converted to a capacity estimate
void checkBattery(int index)
{
	// volts = read * 5 * 2.424 / 1024
	//batterylevel[index] = 0.118*analogRead(BATT_PIN[index]);
}

// check serial port for imu data
void checkIMU()
{
	char buffer[4];
        float temp1, temp2, temp3, temp4;
	uint8_t count = 0;

	// allow for multiple things, but dont get stuck here
	while (SERIAL_IMU.available() && count<24)
	{
		// check for start of wireless message
		switch (SERIAL_IMU.read())
		{
			count++;
			case 'I': // orientation
				SERIAL_IMU.readBytes(buffer,4);
				memcpy(&temp1,buffer,4);
				SERIAL_IMU.readBytes(buffer,4);
				memcpy(&temp2,buffer,4);
				SERIAL_IMU.readBytes(buffer,4);
				memcpy(&temp3,buffer,4);
				SERIAL_IMU.readBytes(buffer,4);
				memcpy(&temp4,buffer,4);
                                if (temp1 + temp2 + temp3 == temp4)
                                {
                                  pitch = temp1;
                                  roll = temp2;
                                  yaw = temp3;
                                  newimu = 1;
                                  //SERIAL_DEBUG.println(pitch);
                                //} else {
                                //  SERIAL_DEBUG.print(temp4);
                                //  SERIAL_DEBUG.print("\t");
                                //  SERIAL_DEBUG.println(temp1+temp2+temp3);
                                }
				count += 16;
#ifdef DEBUG
			/*	
				SERIAL_DEBUG.print(pitch);
				SERIAL_DEBUG.print("\t");
				SERIAL_DEBUG.print(roll);
				SERIAL_DEBUG.print("\t");
				SERIAL_DEBUG.println(yaw);
				*/
#endif
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

// poll for imu data
void pollIMU()
{

	SERIAL_IMU.write(0x01);

}
