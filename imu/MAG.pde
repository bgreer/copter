#include <Wire.h>

#define COMPASS_ADDRESS      0x1E
#define ConfigRegA           0x00
#define ConfigRegB           0x01
#define ModeRegister         0x02
#define DataOutputXMSB       0x03
#define DataOutputXLSB       0x04
#define DataOutputZMSB       0x05
#define DataOutputZLSB       0x06
#define DataOutputYMSB       0x07
#define DataOutputYLSB       0x08
#define StatusRegister       0x09
#define IDRegisterA          0x0A
#define IDRegisterB          0x0B
#define IDRegisterC          0x0C

// default gain value
#define magGain              0x20

// ModeRegister valid modes
#define ContinuousConversion 0x00
#define SingleConversion     0x01

// ConfigRegA valid sample averaging
#define SampleAveraging_1    0x00
#define SampleAveraging_2    0x01
#define SampleAveraging_4    0x02
#define SampleAveraging_8    0x03

// ConfigRegA valid data output rates
#define DataOutputRate_0_75HZ 0x00
#define DataOutputRate_1_5HZ  0x01
#define DataOutputRate_3HZ    0x02
#define DataOutputRate_7_5HZ  0x03
#define DataOutputRate_15HZ   0x04
#define DataOutputRate_30HZ   0x05
#define DataOutputRate_75HZ   0x06

// ConfigRegA valid measurement configuration bits
#define NormalOperation      0x10
#define PositiveBiasConfig   0x11
#define NegativeBiasConfig   0x12

#define MAGNETIC_DECLINATION -6.0    // not used now -> magnetic bearing


void Compass_Init()
{
  Wire.begin();
  delay(10);
  Wire.beginTransmission(COMPASS_ADDRESS);
  Wire.write((uint8_t)ConfigRegA);
  Wire.write(0x18);
  Wire.endTransmission();
  delay(50);
  Wire.beginTransmission(COMPASS_ADDRESS);
  Wire.write((uint8_t)ModeRegister);
  Wire.write((uint8_t)ContinuousConversion);   // Set continouos mode (default to 10Hz)
  Wire.endTransmission(); //end transmission
  delay(50);
}

void Read_Compass()
{
  int i = 0;
  byte buff[6];

  Wire.beginTransmission(COMPASS_ADDRESS); 
  Wire.write(0x03);        //sends address to read from
  Wire.endTransmission(); //end transmission

    //Wire.beginTransmission(CompassAddress); 
  Wire.requestFrom(COMPASS_ADDRESS, 6);    // request 6 bytes from device
  while(Wire.available())   // ((Wire.available())&&(i<6))
  { 
    buff[i] = Wire.read();  // receive one byte
    i++;
  }
  Wire.endTransmission(); //end transmission

    if (i==6)  // All bytes received?
  {
    // MSB byte first, then LSB, X,Y,Z
    magX = (float)((((int)buff[0]) << 8) | buff[1]);    // X axis (internal y axis)
    magY = (float)((((int)buff[4]) << 8) | buff[5]);    // Y axis (internal x axis)
    magZ = (float)((((int)buff[2]) << 8) | buff[3]);    // Z axis
    // correct measurements
    magX = correct_magX(magX);
    magY = correct_magY(magY);
    magZ = correct_magZ(magZ);
/*
    Serial.print(magX);
    Serial.print("\t");
    Serial.print(magY);
    Serial.print("\t");
    Serial.print(magZ);
    Serial.println("\t");
*/
  }
}

