
#define VERSION "0.1"

// AVR runtime
#include <avr/io.h>
#include <avr/eeprom.h>
#include <avr/pgmspace.h>
#include <math.h>

#define DEBUG 1

// some math stuff
#define ToRad(x) (x*0.01745329252)
#define ToDeg(x) (x*57.2957795131)

// led pins
#define LED_STATUS 13

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
#define SERIAL_IMU Serial2

#define WIRELESS_BAUD 115200
#define WIRELESS_BYTELIMIT 8
#define IMU_BAUD 115200
#define DEBUG_BAUD 115200

// heartbeat timeout in microseconds
// set to 2x the heartbeat time or something
#define HEARTBEAT_TIMEOUT (2000000) // 2 secs

// Arduino stuff
#include "Arduino.h"
// remove dumb macros
#undef round
#undef abs

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

uint8_t wirelessOpcode = 0x00;
uint8_t wirelessLength = 0;
uint8_t wirelessPackage[WIRELESS_BYTELIMIT];


// wireless heartbeat
uint8_t heartbeat = 0;
uint32_t lastHeartbeat = 0;

// function prototypes
static void quick_start();
static void checkWireless();
static void parseCommand();
