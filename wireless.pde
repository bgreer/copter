
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
				// TODO: send warning back over wireless about unfinished message?
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
#if DEBUG
	SERIAL_DEBUG.print("parsing command: ");
	SERIAL_DEBUG.println(wirelessOpcode, HEX);
#endif
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
			break;
		case OPCODE_KILL:
			break;
		case OPCODE_CALIB:
			break;
	}
	// at the end of execution, reset opcode
	wirelessOpcode = OPCODE_NOP;
}

