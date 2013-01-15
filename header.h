
#define VERSION "0.1"

// AVR runtime
//#include <avr/io.h>
//#include <avr/eeprom.h>
//#include <avr/pgmspace.h>
#include <math.h>

#define DEBUG 1

// some math stuff
#define ToRad(x) (x*0.01745329252)
#define ToDeg(x) (x*57.2957795131)

// led pins
#define LED_STATUS 13
#define LED_ARMED 23

// in case i get lazy
#define TRUE (1)
#define FALSE (0)

// flight modes
#define SAFEMODE 0
#define LANDED 1
#define STABILIZE 2
#define ALT_HOLD 3
#define RTL 4

// serial ports
#define SERIAL_DEBUG Serial
#define SERIAL_WIRELESS Serial
#define SERIAL_IMU Serial3

#define WIRELESS_BAUD 115200
#define WIRELESS_BYTELIMIT 8
#define IMU_BAUD 115200
#define DEBUG_BAUD 115200

// heartbeat timeout in microseconds
// set to 2x the heartbeat time or something
#define HEARTBEAT_TIMEOUT (2000000) // 2 secs

// Arduino stuff
#include "Arduino.h"

// wireless comm is in the form:
// START, OPCODE, VALUE, END (kind of like assembly)
// START is a 1 byte signal for the start of a message
// OPCODE is 1 byte for the operation to do
// VALUE is some number of bytes of data
// END is another 1 byte signal for the end of a message

// wireless opcodes
#define WIRELESS_START 0x53 // S
#define WIRELESS_END 0x45 // E

// make sure to keep NOP to 0x00, some logic stuff depends on it
#define OPCODE_NOP 0x00 // no operation, just for fun
#define OPCODE_HEARTBEAT 0x48 // heartbeat (H)
#define OPCODE_ARM 0x02 // arm motors
#define OPCODE_KILL 0x03 // kill motors
#define OPCODE_CALIB 0x04 // run ESC calibration


// for sending data back to the base station
#define COMM_START 0x53
#define COMM_END 0x45
#define COMM_MODE_FREE 0x01
#define COMM_MODE_IMU 0x02
#define COMM_MODE_POS 0x03
#define COMM_MODE_MOTOR 0x04
#define COMM_MODE_BATT 0x05
#define COMM_MODE_HELLO 0x06

// Motor Control
#define ESC_ARM_VAL 20
#define ESC_MAX_VAL 179

// // // Variables

// motor control
Servo motor[6];
uint8_t motorval[6] = {0,0,0,0,0,0};
uint8_t ESC_PIN[6] = {7,8,9,10,11,12};
uint8_t GND_PIN[6] = {26,27,28,29,30,31};
uint8_t armed = 0;

// wireless
uint8_t wirelessOpcode = 0x00;
uint8_t wirelessLength = 0;
uint8_t wirelessPackage[WIRELESS_BYTELIMIT];

// wireless heartbeat
uint8_t heartbeat = 0;
uint32_t lastHeartbeat = 0;

// debug info
// 0 - IMU info
// 1 - position info
// 2 - motor values
// 3 - battery levels
uint8_t debugFlag = 0x00;

// function prototypes

// copter.pde
static void quick_start();
// wireless.pde
static void checkWireless();
static void parseCommand();
static void sendDebug();
// motors.pde TODO: make my naming convention sane
static void write_motors();
static void init_motors();
static void arm_motors();
static void disarm_motors();
static void calibrate_motors();



