#include "openIMU.h"

#define GPS_NOFIX 0
#define GPS_BAD 1
#define GPS_POOR 2
#define GPS_OK 3
#define GPS_GOOD 4
// sensor scaling and bias
#define correct_gyroX(x) (x*-0.2665 - 48.510) // in millirad/s
#define correct_gyroY(x) (x*0.2665 + 7.4287)
#define correct_gyroZ(x) (x*-0.2665 + 6.1119)

#define correct_accelX(x) (x*0.117 - 49.0) // in cm/s^2
#define correct_accelY(x) (x*-0.117 - 8.0)
#define correct_accelZ(x) (x*0.117 + 60.0)

#define correct_magX(x) (x*0.860897 + 12.7283) // in mG
#define correct_magY(x) (x*-0.873852 - 104.083)
#define correct_magZ(x) (x*-0.981430 + 6.37676)

#define SERIAL_MUX_PIN 7
#define RED_LED_PIN 5
#define BLUE_LED_PIN 6

#define SETTLE_LOOP 500 // times to poll sensors before moving on from setup
#define GPS_DELAY 10 // update time for gps in milliseconds
#define MAG_DELAY 100 // just because i dont care about the magnetometer

#include <SoftwareSerial.h>

float myx[3], myz[3], temp[3]; // part of dcm
float magX, magY, magZ;

float gps_xpos, gps_ypos, gps_zpos;
float gps_xvel, gps_yvel;
uint8_t new_gpspos, new_gpsvel, gps_quality;
float AN[8], grav, mag, OFFSET[8];
volatile uint8_t MuxSel = 0;
volatile uint8_t analog_reference = DEFAULT;
volatile int16_t analog_buffer[8];
uint32_t time, time_gps, time_mag, lastcalled, lastoutput, lastgps;
float dt, theta, phi, psi;
float g[3], m[3];

SoftwareSerial outSerial(9, 8); // RX, TX

openIMU imu(AN+0,AN+1,AN+2,AN+3,AN+4,AN+5,&magX,&magY,&magZ,&dt);

void setup()
{
	uint8_t ii, ij;
	outSerial.begin(115200); // for sending data to main board
	Serial.begin(9600); // for communicating with GPS
	
	pinMode(SERIAL_MUX_PIN, OUTPUT);
	digitalWrite(SERIAL_MUX_PIN, HIGH); // enable GPS line

	pinMode(RED_LED_PIN, OUTPUT);
	pinMode(BLUE_LED_PIN, OUTPUT);

	Compass_Init();
	Analog_Reference(EXTERNAL);
	Analog_Init();
	MPU6000_Init();
	gps_init();

	imu.InitialQuat();
	// start calibration / settling cycle
	for (ii=0; ii<SETTLE_LOOP; ii++)
	{
		read_adc_raw();
		Read_Compass();
		// blink some stuff
		digitalWrite(BLUE_LED_PIN, HIGH);
		digitalWrite(RED_LED_PIN, LOW);
		imu.AHRSupdate();
		digitalWrite(BLUE_LED_PIN, LOW);
		digitalWrite(RED_LED_PIN, HIGH);
	}
	digitalWrite(RED_LED_PIN, LOW);

	// set timers for main loop
	time = millis();
	time_gps = time_mag = time;
	lastcalled = lastoutput = lastgps = 0;
}

void loop()
{
	time = micros();
	if (time-lastcalled > 10)
	{
		dt = (time - lastcalled)*0.000001;
		lastcalled = time;
		// read all sensors
		read_adc_raw();
		Read_Compass();
		gps_update();
		imu.AHRSupdate();
	}
	if (time-lastoutput > 10000)
	{
		lastoutput = time;
		imu.GetEuler();
		outSerial.write('I');
		outSerial.write((byte*)&(imu.pitch), 4);
		outSerial.write((byte*)&(imu.roll), 4);
		outSerial.write((byte*)&(imu.yaw), 4);
		outSerial.write('\n'); // return

/*		outSerial.print(imu.pitch, 4);
		outSerial.print("\t");
		outSerial.print(imu.roll, 4);
		outSerial.print("\t");
		outSerial.println(imu.yaw, 4);
*/
	}
	if (time-lastgps > 1000000)
	{
		lastgps = time;
		outSerial.write('S');
		outSerial.write((byte*)&(gps_quality), 1);
		outSerial.write('\n'); // return	
		if (new_gpspos && gps_quality >= GPS_POOR)
		{
			outSerial.write('P');
			outSerial.write((byte*)&(gps_xpos), 4);
			outSerial.write((byte*)&(gps_ypos), 4);
			outSerial.write((byte*)&(gps_zpos), 4);
			outSerial.write('\n'); // return	
		}
		if (new_gpsvel && gps_quality >= GPS_POOR)
		{
			outSerial.write('V');
			outSerial.write((byte*)&(gps_xvel), 4);
			outSerial.write((byte*)&(gps_yvel), 4);
			outSerial.write('\n'); // return	
		}
	}
}

