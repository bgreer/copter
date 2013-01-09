float accelX, accelY, accelZ;
float gyroX, gyroY, gyroZ;

void read_adc_raw()
{
	MPU6000_Read();
	AN[0] = gyroX;
	AN[1] = gyroY;
	AN[2] = gyroZ;
	AN[3] = correct_accelX(accelX)*0.01;
	AN[4] = correct_accelY(accelY)*0.01;
	AN[5] = correct_accelZ(accelZ)*0.01;
/*	outSerial.print(AN[3],4);
	outSerial.print("\t");
	outSerial.print(AN[4],4);
	outSerial.print("\t");
	outSerial.println(AN[5],4);
*/
}

void Analog_Reference(uint8_t mode)
{
	analog_reference = mode;
}

void Analog_Init()
{
	ADCSRA |= (1<<ADIE) | (1<<ADEN);
	ADCSRA |= (1<<ADSC);
}

ISR(ADC_vect)
{
	volatile uint8_t low, high;
	low = ADCL;
	high = ADCH;
	analog_buffer[MuxSel] = (high<<8) | low;
	MuxSel++;
	if (MuxSel >= 8) MuxSel = 0;
	ADMUX = (analog_reference << 6) | (MuxSel & 0x07);
	ADCSRA |= (1<<ADSC);
}