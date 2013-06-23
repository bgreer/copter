
#define VERSION "0.5"

// AVR runtime
//#include <avr/io.h>
//#include <avr/eeprom.h>
//#include <avr/pgmspace.h>
#include <math.h>

#define PIN_ARM_BUTTON 14

#define DEBUG 1
#define TIMING 0
#define ALLOW_PHYSICAL_ARMING 0
#define SEND_CAUTIONS 1
#define MOTOR_DEBUG 0

// some math stuff
#define ToRad(x) (x*0.01745329252)
#define ToDeg(x) (x*57.2957795131)

// led pins
#define LED_STATUS 13
#define LED_ARMED 13

// in case i get lazy
#define TRUE (1)
#define FALSE (0)

// flight modes
#define SAFEMODE 0
#define LANDED 1
#define STABILIZE 2
#define ALT_HOLD 3
#define POS_HOLD 4

// serial ports
#define SERIAL_DEBUG Serial
#define SERIAL_WIRELESS Serial3
#define SERIAL_IMU Serial1

#define WIRELESS_BAUD 38400
#define WIRELESS_BYTELIMIT 32
#define IMU_BAUD 57600
#define DEBUG_BAUD 38400

// heartbeat timeout in microseconds
// set to 2x the heartbeat time or something
#define HEARTBEAT_TIMEOUT (10000000) // 10 secs

// if the copter rolls or pitches by more than this, kill motors and die gracefully
#define KILL_ANGLE 100.0 // in degrees

#define TORQUEMAX 180.0
#define PID_INTMAX 1000.0

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
#define OPCODE_THROTTLE 0x05 // set throttle
#define OPCODE_FLIGHTMODE 0x06 // set flight mode
#define OPCODE_USERINPUT 0x07 // set user targetted pitch, roll, yaw, lift
#define OPCODE_SENDSTATS 0x08 // send current stats to basestation
#define OPCODE_PID_KP 0x09 // update PID proportional gain
#define OPCODE_PID_KD 0x10 // update PID derivative gain
#define OPCODE_PID_KI 0x11 // update PID integral gain
#define OPCODE_PID_CHECK 0x12 // send current PID values for checking
#define OPCODE_MOTORDEBUG 0x13 // increment motor for debugging
#define OPCODE_STARTLOG 0x14 // begin logging
#define OPCODE_STOPLOG 0x15 // stop logging
#define OPCODE_CLEARLOG 0x16 // clear log
#define OPCODE_PRINTLOG 0x17 // print log to serial_debug

// for sending data back to the base station
#define COMM_START 0x53
#define COMM_END 0x45
#define COMM_MODE_FREE 0x01
#define COMM_MODE_IMU 0x02
#define COMM_MODE_POS 0x03
#define COMM_MODE_MOTOR 0x04
#define COMM_MODE_BATT 0x05
#define COMM_MODE_HELLO 0x06
#define COMM_MODE_STATS 0x07
#define COMM_MODE_CAUTION 0x08
#define COMM_MODE_PID 0x09
#define COMM_MODE_PID_INT 0x0A

// caution messages
#define CAUTION_MOTOR_MAX 0x80
#define CAUTION_TORQUE_MAX 0x81
#define CAUTION_INT_MAX 0x82
#define CAUTION_COMM_LOST 0x83
#define CAUTION_ANGLE_KILL 0x84

// Motor Control
#define ESC_ARM_VAL 18
#define ESC_MAX_VAL 179

// // // Variables

// state variables
float pitch, roll, yaw, lift, initYaw;
uint8_t gps_quality;
float gps_xpos, gps_ypos, gps_zpos;
float altitude;
float gps_xvel, gps_yvel;
uint8_t batterylevel[6] = {100,100,100,100,100,100};
uint8_t newimu = 0; // is there new imu info?
uint8_t logging = 0; // currently logging data
uint8_t logflash = 0; // used to flash the status led when logging

// motor control
Servo motor[6];
uint8_t motorval[6] = {0,0,0,0,0,0};
uint8_t ESC_PIN[6] = {23,22,21,5,4,3};
//uint8_t BATT_PIN[6] = {A0, A1, A2, A3, A4, A5};
uint8_t armed = 0;
uint8_t throttle = 0;

// for PID controller
float targetPitch, targetRoll, targetYaw, targetLift, safemodeLift;
float kp_roll, ki_roll, kd_roll, kdd_roll;
float kp_pitch, ki_pitch, kd_pitch, kdd_pitch;
float kp_yaw, ki_yaw, kd_yaw, kdd_yaw;
float kftemp;
int8_t userPitch, userRoll;
uint8_t userYaw;
int8_t userLift;
float liftz, torquez, torquex, torquey;
float xpos_hold, ypos_hold, zpos_hold, yaw_hold;

// flight status
// 0 - armed
// 1 - hitting motor bounds
uint8_t flightStats = 0x00;

// wireless
uint8_t wirelessOpcode = 0x00;
uint8_t wirelessLength = 0;
uint8_t wirelessPackage[WIRELESS_BYTELIMIT];
uint8_t debugmode = 0;
uint8_t dosendPID = 0;

// wireless heartbeat
uint8_t heartbeat = 0;
uint32_t lastHeartbeat = 0;
uint32_t commtimer;
uint32_t cautiontimer = 0;

// debug info
// 0 - IMU info
// 1 - position info
// 2 - motor values
// 3 - battery levels
// 4 - flight info
uint8_t debugFlag = 0xff;

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
// state.pde
void checkIMU();


