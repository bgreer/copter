
/* wireless.pde
	Handles most communication with base station through XBEEs
	Assumes the XBEE modules have been set up properly
	(correct addresses, baud rates, etc)
*/

static void checkWireless()
{
	uint8_t inByte;

	// check timeout
	if (micros()-commtimer > 500 && wirelessLength > 0)
	{
#if DEBUG
		SERIAL_DEBUG.println("WARNING: comm timeout");
#endif
		wirelessLength = 0;
		wirelessOpcode = OPCODE_NOP;
	}

	while (SERIAL_WIRELESS.available())
	{
		inByte = SERIAL_WIRELESS.read();
		if ((wirelessLength == 0 && inByte == WIRELESS_START) || wirelessLength > 0)
		{
			wirelessPackage[wirelessLength] = inByte;
			commtimer = micros();
			if (inByte == WIRELESS_END)
			{
				if (wirelessLength > 1)
					wirelessOpcode = wirelessPackage[1];
				heartbeat = 1;
				lastHeartbeat = millis();
			} else {
				wirelessLength++;
				// check past bounds
				if (wirelessLength == WIRELESS_BYTELIMIT)
				{
#if DEBUG
					SERIAL_DEBUG.println("WARNING: comm buffer full");
#endif
					wirelessLength = 0;
				}
			}
		}
	}
}

// check wireless data availability
// attempt to parse incoming data as opcode + data package
static void checkWireless_old()
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
					SERIAL_DEBUG.println(inByte);
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
				SERIAL_DEBUG.println(wirelessOpcode);
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
//			SERIAL_DEBUG.println("HEARTBEAT");
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
			throttle = wirelessPackage[2];
			break;
		case OPCODE_FLIGHTMODE:
			changeFlightmode(wirelessPackage[2]);
			break;
		case OPCODE_USERINPUT:
			if (wirelessLength >= 7)
			{
				if (verify(wirelessPackage[6]))
				{
					userPitch = wirelessPackage[2];
					userRoll = wirelessPackage[3];
					userYaw = wirelessPackage[4];
					userLift = wirelessPackage[5];
				}
#if DEBUG
/*
				SERIAL_DEBUG.print((uint8_t)userPitch);
				SERIAL_DEBUG.print("\t");
				SERIAL_DEBUG.print((uint8_t)userRoll);
				SERIAL_DEBUG.print("\t");
				SERIAL_DEBUG.print((uint8_t)userYaw);
				SERIAL_DEBUG.print("\t");
				SERIAL_DEBUG.print((uint8_t)userLift);
				SERIAL_DEBUG.print("\t");
				SERIAL_DEBUG.println((uint8_t)wirelessPackage[6]);
*/
#endif
			}
			break;
		case OPCODE_SENDSTATS:
			debugmode = 1;
			break;
		// start PID stuff
		case OPCODE_PID_KP:
			if (wirelessLength >= 6)
			{
				memcpy(&kftemp, wirelessPackage+2, 4);
				if (kftemp >= 0.0 && kftemp < 2.0)
                                {
					kp_roll = kp_pitch = kftemp;
                                        savePIDvals();
                                }
			}
			break;
		case OPCODE_PID_KD:
			if (wirelessLength >= 6)
			{
				memcpy(&kftemp, wirelessPackage+2, 4);
				if (kftemp >= 0.0 && kftemp < 500.0) {
					kd_roll = kd_pitch = kftemp;
                                        savePIDvals();
                                }
			}
			break;
		case OPCODE_PID_KI:
			if (wirelessLength >= 6)
			{
				memcpy(&kftemp, wirelessPackage+2, 4);
				if (kftemp >= 0.0 && kftemp < 10.0) {
					ki_roll = ki_pitch = kftemp;
                                        savePIDvals();
                                }
			}
			break;
		case OPCODE_PID_CHECK:
			dosendPID = 1;
			break;
		case OPCODE_MOTORDEBUG:
			motordebug++;
			if (motordebug==6) motordebug = 0;
			break;
                 case OPCODE_STARTLOG:
			reset_log();
                        logging = 1;
			break;
                 case OPCODE_STOPLOG:
                        logging = 0;
			break;
                 case OPCODE_CLEARLOG:
                        reset_log();
			break;
                 case OPCODE_PRINTLOG:
			print_log();
			break;
	}
	// at the end of execution, reset opcode
	wirelessOpcode = OPCODE_NOP;
	wirelessLength = 0;
}

/* verify checksum for userinput command */
uint8_t verify (uint8_t chk)
{
	uint8_t chk2, ii;
	chk2 = wirelessPackage[0];
	for (ii=1; ii<6; ii++)
		chk2 ^= wirelessPackage[ii];
	
	return (chk == chk2);
}

// send a caution message back to the basestation
void caution(uint8_t message)
{
#ifdef SEND_CAUTIONS
	if (millis() - cautiontimer > 1000)
	{
		SERIAL_WIRELESS.write(COMM_START);
		SERIAL_WIRELESS.write(COMM_MODE_CAUTION);
		SERIAL_WIRELESS.write(message);
		SERIAL_WIRELESS.write(COMM_END);
		cautiontimer = millis();
	}
#endif
}

// send current PID gain values to basestation
static void sendPID()
{
#ifdef DEBUG
	SERIAL_DEBUG.println("sending PID info..");
#endif
	SERIAL_WIRELESS.write(COMM_START);
	SERIAL_WIRELESS.write(COMM_MODE_PID);
	SERIAL_WIRELESS.write((uint8_t*)&kp_roll,4);
	SERIAL_WIRELESS.write((uint8_t*)&kd_roll,4);
	SERIAL_WIRELESS.write((uint8_t*)&ki_roll,4);
	SERIAL_WIRELESS.write(COMM_END);
	dosendPID = 0;
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
	if ((debugFlag>>debugmode)&0x01 || 1)
	{
#ifdef DEBUG
		SERIAL_DEBUG.println("sending stats");
		SERIAL_DEBUG.println(debugmode);
#endif
		SERIAL_WIRELESS.write(COMM_START);
		// now figure out what to send
		switch (debugmode)
		{
			case 1: // IMU
				SERIAL_WIRELESS.write(COMM_MODE_IMU);
				SERIAL_WIRELESS.write((uint8_t*)&pitch,4);
				SERIAL_WIRELESS.write((uint8_t*)&roll,4);
				SERIAL_WIRELESS.write((uint8_t*)&yaw,4);
				break;
			case 2: // position
				SERIAL_WIRELESS.write(COMM_MODE_POS);
				SERIAL_WIRELESS.write((uint8_t*)&gps_xpos,4);
				SERIAL_WIRELESS.write((uint8_t*)&gps_ypos,4);
				SERIAL_WIRELESS.write((uint8_t*)&altitude,4);
				break;
			case 3: // motor values
				SERIAL_WIRELESS.write(COMM_MODE_MOTOR);
				SERIAL_WIRELESS.write(motorval,6);
				break;
			case 4: // battery levels
				SERIAL_WIRELESS.write(COMM_MODE_BATT);
				SERIAL_WIRELESS.write(batterylevel,6);
				break;
			case 5: // flight stats
				SERIAL_WIRELESS.write(COMM_MODE_STATS);
				SERIAL_WIRELESS.write(flightMode);
				SERIAL_WIRELESS.write(armed);
				SERIAL_WIRELESS.write((uint8_t*)&flighttime,4);
				break;
			case 6: // PID integral values
				SERIAL_WIRELESS.write(COMM_MODE_PID_INT);
				SERIAL_WIRELESS.write((uint8_t*)&intPitch,4);
				SERIAL_WIRELESS.write((uint8_t*)&intRoll,4);
				SERIAL_WIRELESS.write((uint8_t*)&intYaw,4);
				break;
		}
		SERIAL_WIRELESS.write(COMM_END);
		SERIAL_WIRELESS.write('\r');
	}
	debugmode++;
	if (debugmode >= 7) debugmode = 0;
}



