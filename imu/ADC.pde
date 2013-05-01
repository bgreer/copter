float accelX, accelY, accelZ;
float gyroX, gyroY, gyroZ;

void read_adc_raw()
{
	MPU6000_Read();
	AN[0] = (correct_gyroX(gyroX))*0.001;
	AN[1] = (correct_gyroY(gyroY))*0.001;
	AN[2] = (correct_gyroZ(gyroZ))*0.001;
	AN[3] = correct_accelX(accelX)*0.02;
	AN[4] = correct_accelY(accelY)*0.02;
	AN[5] = correct_accelZ(accelZ)*0.02;
	memcpy(AN2, AN, 24);
/*	outSerial.print(AN[3],5);
	outSerial.print("\t");
	outSerial.print(AN[4],5);
	outSerial.print("\t");
	outSerial.println(AN[5],5);
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
