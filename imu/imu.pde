
// sensor scaling and bias
#define correct_gyroX(x) (x*0.5321 + 32.250) // in millirad/s
#define correct_gyroY(x) (x*-0.5321 + 0.004)
#define correct_gyroZ(x) (x*-0.5321 - 11.989)

#define correct_accelX(x) (x*-0.237406 + 46.4489) // in cm/s^2
#define correct_accelY(x) (x*-0.238303 - 1.75128)
#define correct_accelZ(x) (x*-0.233985 - 117.054)

#define correct_magX(x) (x*-0.860897 - 12.7283) // in mG
#define correct_magY(x) (x*-0.873852 - 104.083)
#define correct_magZ(x) (x*0.981430 - 6.37676)

#define SERIAL_MUX_PIN 7
#define RED_LED_PIN 5
#define BLUE_LED_PIN 6

#define SETTLE_LOOP 50 // times to poll sensors before moving on from setup
#define GPS_DELAY 1000 // update time for gps in milliseconds

#include <SoftwareSerial.h>

float myx[3], myz[3]; // part of dcm
float magX, magY, magZ;

float OFFSET[8], AN[8], grav, mag;
volatile uint8_t MuxSel = 0;
volatile uint8_t analog_reference = DEFAULT;
volatile int16_t analog_buffer[8];
uint32_t time, lasttime;

SoftwareSerial outSerial(9, 8); // RX, TX

void setup()
{
	uint8_t ii, ij;
	float g[3], m[3];
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
	kalman_init();
	gps_init();

	// start calibration / settling cycle
	for (ii=0; ii<SETTLE_LOOP; ii++)
	{
		read_adc_raw();
		Read_Compass();
		grav += sqrt(AN[3]*AN[3] + AN[4]*AN[4] + AN[5]*AN[5])/((float)SETTLE_LOOP);
		for (ij=0; ij<7; ij++)
			OFFSET[ij] += AN[ij];
		// blink some stuff
		digitalWrite(BLUE_LED_PIN, HIGH);
		digitalWrite(RED_LED_PIN, LOW);
		delay(50);
		digitalWrite(BLUE_LED_PIN, LOW);
		digitalWrite(RED_LED_PIN, HIGH);
		delay(50);
	}
	digitalWrite(RED_LED_PIN, LOW);

	// assume sensors have settled, record rough calibration
	for (ii=0; ii<7; ii++)
	{
		OFFSET[ii] /= 1.0*SETTLE_LOOP;
	}

	// determine global coords relative to local coords
	mag = sqrt(AN[3]*AN[3] + AN[4]*AN[4] + AN[5]*AN[5]);
	g[0] = AN[3]/grav;
	g[1] = AN[4]/grav;
	g[2] = AN[5]/grav;
	// magnetic north
	mag = g[0]*magX + g[1]*magY + g[2]*magZ;
	m[0] = magX - g[0]*mag;
	m[1] = magY - g[1]*mag;
	m[2] = magZ - g[2]*mag;
	// normalize, flip to make 'up'
	mag = sqrt(m[0]*m[0] + m[1]*m[1] + m[2]*m[2]);
	m[0] /= mag;
	m[1] /= mag;
	m[2] /= mag;
	// transpose to get local in terms of global
	myx[0] = m[0];
	myx[1] = g[1]*m[2] - g[2]*m[1];
	myx[2] = g[0];

	myz[0] = m[2];
	myz[1] = g[0]*m[1] - g[1]*m[0];
	myz[2] = g[2];

	outSerial.print("g = ");
	outSerial.println(grav);
	outSerial.print(myx[0]);
	outSerial.print("\t");
	outSerial.print(myx[1]);
	outSerial.print("\t");
	outSerial.println(myx[2]);
	outSerial.print(myz[0]);
	outSerial.print("\t");
	outSerial.print(myz[1]);
	outSerial.print("\t");
	outSerial.println(myz[2]);

	// set timers for main loop
	time = millis();
	lasttime = time;
}

void loop()
{
	time = millis();
	// read current accel/gyro measurements
	read_adc_raw();
	// read magnetometer too..
	Read_Compass();
	// read gps
	if (time-lasttime > GPS_DELAY)
	{
		gps_update();
	}

	// calculate DCM? or use kalman state?

	// use DCM to remove gravity from accelerometer measurements
	AN[3] += grav*myz[0];
	AN[4] += grav*myz[1];
	AN[5] += grav*myz[2];

	// add all processed measurements
	kalman_addmeasurement(6, &(AN[3]));
	kalman_addmeasurement(7, &(AN[4]));
	kalman_addmeasurement(8, &(AN[5]));
	// update the filter
	kalman_update();
	//outSerial.println(kalman_getstate(0));
/*	outSerial.print(accelX);
	outSerial.print("\t");
	outSerial.print(accelY);
	outSerial.print("\t");
	outSerial.println(accelZ);
*/
	lasttime = time;
}

