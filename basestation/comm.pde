byte wirelessOpcode = 0x00;
int wirelessLength = 0;
byte[] wirelessPackage = new byte[100];

void checkWireless()
{
  int ii = 0, done = 0;
  byte inByte, tempin;

  if (port.available()>0)
  {
    // check for start of wireless message
    if (readdata() == 'S')
    {
      done = 0;
      ii = 0;
      wirelessLength = 0;
      // read the whole message
      while (done==0 && port.available()>0 && ii<100)
      {
        // if first byte, read into opcode space
        if (ii==0)
        {
          wirelessOpcode = (byte)readdata();
        } else { // else, read message
          inByte = (byte)readdata();
          // check for end
          if (inByte == 'E')
          {
            done = 1;
          } else {
            // if we still have space for values
            if (wirelessLength < 100)
            {
              wirelessPackage[wirelessLength] = inByte;
              wirelessLength++;
            } else {
              // hit limit of package, no end
              done = 1; // ?
              println("hit limit of buffer");
            }
          }
        }
        ii++;
      }

      // check for early termination
      if (done==0)
      {
        // clear out the operation
        wirelessOpcode = byte(0);
        wirelessLength = 0;
        println("unfinished command, clearing buffer");
      }

    }
  }
  
}


void parseCommand()
{
  print("parsing command: ");
  println(hex(wirelessOpcode));

  switch (wirelessOpcode)
  {
    case 'H':
      heartbeatrecv();
      println("HEARTBEAT");
      break;
  }
  // at the end of execution, reset opcode

  wirelessOpcode = byte(0);
  
}

void senddata(int data)
{
  outindex = (outindex+1)%numlines;
  outbyte[outindex] = data;
  outtext[outindex] = ""+(char)outbyte[outindex];
  port.write(data&0xff);
}

int readdata()
{
  int temp;
  temp = port.read();
  inindex = (inindex+1)%numlines;
  inbyte[inindex] = temp;
  intext[inindex] = ""+(char)inbyte[inindex];
  if (inbyte[inindex] == 'S') intext[inindex] = "SRTMSG";
  if (inbyte[inindex] == 'E') intext[inindex] = "ENDMSG";
  if (inbyte[inindex] == 'H') intext[inindex] = "HB";
  return temp;
}
