#include "openIMU.h"

#define GPS_NOFIX 0
#define GPS_BAD 1
#define GPS_POOR 2
#define GPS_OK 3
#define GPS_GOOD 4
// sensor scaling and bias
#define correct_gyroX(x) (x*-1.0642 - 44.67405) // in millirad/s
#define correct_gyroY(x) (x*1.0642 + 7.33716)
#define correct_gyroZ(x) (x*-1.0642 + 3.22816)

#define correct_accelX(x) (x*0.117 - 35.0) // in cm/s^2
#define correct_accelY(x) (x*-0.117 + 10.0)
#define correct_accelZ(x) (x*0.117 + 60.0)

#define correct_magX(x) (x*0.860897 + 12.7283) // in mG
#define correct_magY(x) (x*-0.873852 - 104.083)
#define correct_magZ(x) (x*-0.981430 + 6.37676)

#define SERIAL_MUX_PIN 7
#define RED_LED_PIN 5
#define BLUE_LED_PIN 6

#define SETTLE_LOOP 250 // times to poll sensors before moving on from setup
#define GPS_DELAY 10 // update time for gps in milliseconds
#define MAG_DELAY 100 // just because i dont care about the magnetometer

#include <SoftwareSerial.h>

float myx[3], myz[3], temp[3]; // part of dcm
float magX, magY, magZ;

float gps_xpos, gps_ypos, gps_zpos;
float gps_xvel, gps_yvel;
uint8_t new_gpspos, new_gpsvel, gps_quality;
float AN[8], AN2[9], grav, mag, OFFSET[8];
volatile uint8_t MuxSel = 0;
volatile uint8_t analog_reference = DEFAULT;
volatile int16_t analog_buffer[8];
uint32_t time, time_gps, time_mag, lastcalled, lastoutput, lastgps, lastgpsread;
float dt, theta, phi, psi, currpitch;
float g[3], m[3], sum;
uint8_t inbyte;

SoftwareSerial outSerial(9, 8); // RX, TX

openIMU imu(AN+0,AN+1,AN+2,AN+3,AN+4,AN+5,&magX,&magY,&magZ,&dt);

void setup()
{
	uint8_t ii, ij;
	outSerial.begin(57600); // for sending data to main board
	outSerial.setTimeout(1);
	Serial.begin(57600); // for communicating with main board
        Serial.setTimeout(1);
	
	pinMode(SERIAL_MUX_PIN, OUTPUT);
	digitalWrite(SERIAL_MUX_PIN, LOW); // enable main

	pinMode(RED_LED_PIN, OUTPUT);
	pinMode(BLUE_LED_PIN, OUTPUT);

	Compass_Init();
	Analog_Reference(EXTERNAL);
	Analog_Init();
	MPU6000_Init();
	gps_init();

	imu.InitialQuat();
	currpitch = 0.0;
	// start calibration / settling cycle
	for (ii=0; ii<SETTLE_LOOP; ii++)
	{
		read_adc_raw();
		Read_Compass();
		// blink some stuff
		digitalWrite(BLUE_LED_PIN, HIGH);
		digitalWrite(RED_LED_PIN, LOW);
		//imu.AHRSupdate(); // god why was that there??
		delay(5);
		digitalWrite(BLUE_LED_PIN, LOW);
		digitalWrite(RED_LED_PIN, HIGH);
		delay(5);
	}
	digitalWrite(RED_LED_PIN, LOW);

	// set timers for main loop
	time = micros();
	time_gps = time_mag = time;
	lastcalled = lastoutput = lastgps = time;
}

void loop()
{
	time = micros();
	dt = (time - lastcalled)*1e-6;
	lastcalled = time;
	// read all sensors
	read_adc_raw(); // 500 us
	Read_Compass(); // <100 us
	imu.AHRSupdate(); // 400 us

	// check for IMU data request
	if (time-lastoutput > 10000)
	{
		digitalWrite(RED_LED_PIN, HIGH);
		lastoutput = time;
		inbyte = outSerial.read();
		imu.GetEuler();
		sum = imu.pitch + imu.roll + imu.yaw;
		Serial.write('I');
		Serial.write((byte*)&(imu.pitch), 4);
		Serial.write((byte*)&(imu.roll), 4);
		Serial.write((byte*)&(imu.yaw), 4);
		Serial.write((byte*)&(sum), 4);
		Serial.write('\n'); // return
		digitalWrite(RED_LED_PIN, LOW);
		if (fabs(imu.pitch) > 45. || fabs(imu.roll) > 45.)
			digitalWrite(BLUE_LED_PIN, HIGH);
		else
			digitalWrite(BLUE_LED_PIN, LOW);
	}
/*
	if (time-lastgpsread > 10000)
	{
		lastgpsread = time;
		gps_update(); // 1200 us
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
			outSerial.write((uint8_t*)&gps_xpos, 4);
			outSerial.write((uint8_t*)&gps_ypos, 4);
			outSerial.write((uint8_t*)&gps_zpos, 4);
			outSerial.write('\n'); // return	
		}
		if (new_gpsvel && gps_quality >= GPS_POOR)
		{
			outSerial.write('V');
			outSerial.write((uint8_t*)&gps_xvel, 4);
			outSerial.write((uint8_t*)&gps_yvel, 4);
			outSerial.write('\n'); // return	
		}
	}
	*/
}

