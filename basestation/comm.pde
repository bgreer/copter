byte wirelessOpcode = 0x00;
int wirelessLength = 0;
int wirelessNewData = 0;
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
  int temp;
  //print("parsing command: ");
  //println(hex(wirelessOpcode));

  switch (wirelessOpcode)
  {
    case 'H':
      heartbeatrecv();
      println("HEARTBEAT");
      break;
     case 0x02:
       println("IMU DATA");
       pitch = b2f(wirelessPackage,0);
       roll = b2f(wirelessPackage,4);
       yaw = b2f(wirelessPackage,8);
       println(yaw);
       break;
     case 0x03:
       println("POS DATA");
       addpos(b2f(wirelessPackage,0), b2f(wirelessPackage,4), b2f(wirelessPackage,8));
       break;
     case 0x04:
       println("MOTOR DATA");
       for (i=0; i<6; i++)
       {
         motorspeed[i] = (int)(wirelessPackage[i]);
         if (motorspeed[i] < 0) motorspeed[i] = 255+motorspeed[i];
       }
       break;
     case 0x05:
       println("BATT DATA");
       for (i=0; i<6; i++)
         battlevel[i] = (int)(wirelessPackage[i]);
       break;
     case 0x07:
       println("FLIGHT STATS");
       flightmode = (int)(wirelessPackage[0]);
       armed = (int)(wirelessPackage[1]);
       break;
  }
  // at the end of execution, reset opcode

  wirelessOpcode = byte(0);
  
}

float b2f(byte[] data, int offset) {
  String hexint=hex(data[offset+3])+hex(data[offset+2])+hex(data[offset+1])+hex(data[offset+0]);
  return Float.intBitsToFloat(unhex(hexint));
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
