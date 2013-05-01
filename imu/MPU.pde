
#define MPU6000_CHIP_SELECT_PIN 4

#include "MPU.h"
#include <SPI.h>

volatile uint8_t MPU6000_newdata;

void MPU6000_Init()
{
	pinMode(MPU6000_CHIP_SELECT_PIN, OUTPUT);
	digitalWrite(MPU6000_CHIP_SELECT_PIN, HIGH);

	SPI.begin();
	SPI.setClockDivider(SPI_CLOCK_DIV16);
	delay(10);

	// chip reset
	MPU6000_SPI_write(MPUREG_PWR_MGMT_1, BIT_H_RESET);
	delay(100);
	// wake up and select gyroz clock
	MPU6000_SPI_write(MPUREG_PWR_MGMT_1, MPU_CLK_SEL_PLLGYROZ);
	delay(1);
	// disable I2C bus
	MPU6000_SPI_write(MPUREG_USER_CTRL, BIT_I2C_IF_DIS);
	delay(1);
	// sample rate
	MPU6000_SPI_write(MPUREG_SMPLRT_DIV, 0x04);
	delay(1);
	// low pass filter
	MPU6000_SPI_write(MPUREG_CONFIG, BITS_DLPF_CFG_256HZ_NOLPF2);
	delay(1);
	// gyro scale
	MPU6000_SPI_write(MPUREG_GYRO_CONFIG, BITS_FS_2000DPS);
	delay(1);
	// accel scale
	MPU6000_SPI_write(MPUREG_ACCEL_CONFIG, 0x10);
	delay(1);
	// interrupt on data ready
	MPU6000_SPI_write(MPUREG_INT_ENABLE, BIT_RAW_RDY_EN);
	delay(1);
	// clear on read
	MPU6000_SPI_write(MPUREG_INT_PIN_CFG, BIT_INT_ANYRD_2CLEAR);
	delay(1);

	attachInterrupt(0, MPU6000_data_int, RISING);
}

void MPU6000_Read()
{
	int byte_H, byte_L;

	// read accelX
	byte_H = MPU6000_SPI_read(MPUREG_ACCEL_XOUT_H);
	byte_L = MPU6000_SPI_read(MPUREG_ACCEL_XOUT_L);
	accelX = (float) ((byte_H<<8) | byte_L);
	// read accelY
	byte_H = MPU6000_SPI_read(MPUREG_ACCEL_YOUT_H);
	byte_L = MPU6000_SPI_read(MPUREG_ACCEL_YOUT_L);
	accelY = (float) ((byte_H<<8) | byte_L);
	// read accelZ
	byte_H = MPU6000_SPI_read(MPUREG_ACCEL_ZOUT_H);
	byte_L = MPU6000_SPI_read(MPUREG_ACCEL_ZOUT_L);
	accelZ = (float) ((byte_H<<8) | byte_L);

	// read gyroX
	byte_H = MPU6000_SPI_read(MPUREG_GYRO_XOUT_H);
	byte_L = MPU6000_SPI_read(MPUREG_GYRO_XOUT_L);
	gyroX = (float) ((byte_H<<8) | byte_L);
	// read gyroY
	byte_H = MPU6000_SPI_read(MPUREG_GYRO_YOUT_H);
	byte_L = MPU6000_SPI_read(MPUREG_GYRO_YOUT_L);
	gyroY = (float) ((byte_H<<8) | byte_L);
	// read gyroZ
	byte_H = MPU6000_SPI_read(MPUREG_GYRO_ZOUT_H);
	byte_L = MPU6000_SPI_read(MPUREG_GYRO_ZOUT_L);
	gyroZ = (float) ((byte_H<<8) | byte_L);
}

byte MPU6000_SPI_read(byte reg)
{
	byte dump, return_value;
	byte addr = reg | 0x80;
	digitalWrite(MPU6000_CHIP_SELECT_PIN, LOW);
	dump = SPI.transfer(addr);
	return_value = SPI.transfer(0);
	digitalWrite(MPU6000_CHIP_SELECT_PIN, HIGH);
	return(return_value);
}

void MPU6000_SPI_write(byte reg, byte data)
{
	byte dump;
	digitalWrite(MPU6000_CHIP_SELECT_PIN, LOW);
	dump = SPI.transfer(reg);
	dump = SPI.transfer(data);
	digitalWrite(MPU6000_CHIP_SELECT_PIN, HIGH);
}

// interrupt
void MPU6000_data_int()
{
	MPU6000_newdata++;
}
