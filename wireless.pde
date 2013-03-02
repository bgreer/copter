
/* wireless.pde
	Handles most communication with base station through XBEEs
	Assumes the XBEE modules have been set up properly
	(correct addresses, baud rates, etc)
*/

// check wireless data availability
// attempt to parse incoming data as opcode + data package
static void checkWireless()
{
	uint8_t ii = 0, done = 0;
	uint8_t inByte;

	if (SERIAL_WIRELESS.available())
	{
		// check for start of wireless message
		if (SERIAL_WIRELESS.read() == WIRELESS_START)
		{
			done = 0;
			ii = 0;
			wirelessLength = 0;
			// read the whole message
			while (!done && SERIAL_WIRELESS.available() && ii<WIRELESS_BYTELIMIT)
			{
				// if first byte, read into opcode space
				if (!ii)
				{
					wirelessOpcode = SERIAL_WIRELESS.read();
				} else { // else, read message
					inByte = SERIAL_WIRELESS.read();
					// check for end
					if (inByte == WIRELESS_END)
					{
						done = 1;
					} else {
						// if we still have space for values
						if (wirelessLength < WIRELESS_BYTELIMIT)
						{
							wirelessPackage[wirelessLength] = inByte;
							wirelessLength++;
						} else {
							// hit limit of package, no end
							done = 1; // ?
#if DEBUG
							SERIAL_DEBUG.println("hit limit of buffer");
#endif
						}
					}
				}
				ii++;
			}

			// check for early termination
			if (!done)
			{
				// clear out the operation
				wirelessOpcode = OPCODE_NOP;
				wirelessLength = 0;
#if DEBUG
				SERIAL_DEBUG.println("unfinished command, clearing buffer");
#endif
			}

		}
	}
	
}


// parse the 1 byte opcode and execute some code
// reset the opcode at the end
static void parseCommand()
{
//#if DEBUG
//	SERIAL_DEBUG.print("parsing command: ");
//	SERIAL_DEBUG.println(wirelessOpcode, HEX);
//#endif
	switch (wirelessOpcode)
	{
		case OPCODE_HEARTBEAT:
			heartbeat = 1;
			lastHeartbeat = micros();
#if DEBUG
			SERIAL_DEBUG.println("HEARTBEAT");
#endif
			break;
		case OPCODE_ARM:
			if (!armed) arm_motors();
			break;
		case OPCODE_KILL:
			disarm_motors();
			break;
		case OPCODE_CALIB:
			calibrate_motors();
			break;
		case OPCODE_THROTTLE:
			throttle = wirelessPackage[0];
			break;
		case OPCODE_FLIGHTMODE:
			changeFlightmode(wirelessPackage[0]);
			break;
		case OPCODE_USERINPUT:
			if (wirelessLength >= 4)
			{
				userPitch = wirelessPackage[0];
				userRoll = wirelessPackage[1];
				userYaw = wirelessPackage[2];
				userLift = wirelessPackage[3];
#if DEBUG
				SERIAL_DEBUG.print(userPitch);
				SERIAL_DEBUG.print("\t");
				SERIAL_DEBUG.print(userRoll);
				SERIAL_DEBUG.print("\t");
				SERIAL_DEBUG.print(userYaw);
				SERIAL_DEBUG.print("\t");
				SERIAL_DEBUG.println(userLift);
#endif
			}
			break;
	}
	// at the end of execution, reset opcode
	wirelessOpcode = OPCODE_NOP;
}

static void sendHeartbeat()
{
	SERIAL_WIRELESS.write(COMM_START);
	SERIAL_WIRELESS.write(OPCODE_HEARTBEAT);
	SERIAL_WIRELESS.write(COMM_END);
}

// send debug info over wireless
// there are flags deciding what to send and how often
static void sendDebug()
{
	// only enter loop if the debug flag bit is set
	if ((debugFlag>>debugmode)&0x01)
	{
		SERIAL_WIRELESS.write(COMM_START);
		// now figure out what to send
		switch (debugmode)
		{
			case 0: // IMU
				SERIAL_WIRELESS.write(COMM_MODE_IMU);
				SERIAL_WIRELESS.write((uint8_t*)&pitch,4);
				SERIAL_WIRELESS.write((uint8_t*)&roll,4);
				SERIAL_WIRELESS.write((uint8_t*)&yaw,4);
				break;
			case 1: // position
				SERIAL_WIRELESS.write(COMM_MODE_POS);
				SERIAL_WIRELESS.write((uint8_t*)&gps_xpos,4);
				SERIAL_WIRELESS.write((uint8_t*)&gps_ypos,4);
				SERIAL_WIRELESS.write((uint8_t*)&altitude,4);
				break;
			case 2: // motor values
				SERIAL_WIRELESS.write(COMM_MODE_MOTOR);
				SERIAL_WIRELESS.write(motorval,6);
				break;
			case 3: // battery levels
				SERIAL_WIRELESS.write(COMM_MODE_BATT);
				SERIAL_WIRELESS.write(batterylevel,6);
				break;
			case 4: // flight stats
				SERIAL_WIRELESS.write(COMM_MODE_STATS);
				SERIAL_WIRELESS.write(flightMode);
				SERIAL_WIRELESS.write(armed);
				break;
		}
		SERIAL_WIRELESS.write(COMM_END);
		SERIAL_WIRELESS.write('\r');
	}
	debugmode++;
	if (debugmode >= 5) debugmode = 0;
}



