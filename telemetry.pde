


static void checkTelemetry()
{
	uint8_t ii = 0, done = 0;
	uint8_t inByte;

	if (SERIAL_TELEM.available())
	{
		// check for start of telem message
		if (SERIAL_TELEM.read() == TELEM_START)
		{
			done = 0;
			ii = 0;
			telemLength = 0;
			// read the whole message
			while (!done && SERIAL_TELEM.available() && ii<TELEM_BYTELIMIT)
			{
				// if first byte, read into opcode space
				if (!ii)
				{
					telemOpcode = SERIAL_TELEM.read();
				} else { // else, read message
					inByte = SERIAL_TELEM.read();
					// check for end
					if (inByte == TELEM_END)
					{
						done = 1;
					} else {
						// if we still have space for values
						if (telemLength < TELEM_BYTELIMIT)
						{
							telemPackage[telemLength] = inByte;
							telemLength++;
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
				telemOpcode = OPCODE_NOP;
				telemLength = 0;
				// TODO: send warning back over telem about unfinished message?
#if DEBUG
				SERIAL_DEBUG.println("unfinished command, clearing buffer");
#endif
			}

		}
	}
	
}

static void parseCommand()
{
#if DEBUG
	SERIAL_DEBUG.print("parsing command: ");
	SERIAL_DEBUG.println(telemOpcode, HEX);
#endif
	switch (telemOpcode)
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
	telemOpcode = OPCODE_NOP;
}

