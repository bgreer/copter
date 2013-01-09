
#define GPS_SETTLE 5
#define GPS_BUFFERSIZE 100
#define NMEA_OUTPUT_SENTENCES   "$PMTK314,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0*28\r\n" //Set GPGGA and GPVTG
#define NMEA_BAUD_RATE_4800     "$PSRF100,1,4800,8,1,0*0E\r\n"
#define NMEA_BAUD_RATE_9600     "$PSRF100,1,9600,8,1,0*0D\r\n"
#define NMEA_BAUD_RATE_19200    "$PSRF100,1,19200,8,1,0*38\r\n"
#define NMEA_BAUD_RATE_38400    "$PSRF100,1,38400,8,1,0*3D\r\n"  
#define NMEA_BAUD_RATE_57600    "$PSRF100,1,57600,8,1,0*36\r\n"
#define NMEA_OUTPUT_1HZ   "$PMTK220,1000*1F\r\n"
#define NMEA_OUTPUT_2HZ   "$PMTK220,500*2B\r\n"
#define NMEA_OUTPUT_4HZ   "$PMTK220,250*29\r\n"
#define NMEA_OTUPUT_5HZ   "$PMTK220,200*2C\r\n"
#define NMEA_OUTPUT_10HZ  "$PMTK220,100*2F\r\n"
#define SBAS_ON     "$PMTK313,1*2E\r\n"
#define SBAS_OFF    "$PMTK313,0*2F\r\n"
#define WAAS_ON     "$PSRF151,1*3F\r\n"
#define WAAS_OFF    "$PSRF151,0*3E\r\n"
#define DGPS_OFF    "$PMTK301,0*2C\r\n"
#define DGPS_RTCM   "$PMTK301,1*2D\r\n"
#define DGPS_SBAS   "$PMTK301,2*2E\r\n"
#define DATUM_GOOGLE    "$PMTK330,0*2E\r\n"

	long	utctime;			///< GPS time in milliseconds from the start of the week
	long	latitude;		///< latitude in degrees * 10,000,000
	long	longitude;		///< longitude in degrees * 10,000,000
	long	altitude;		///< altitude in cm
	long	ground_speed;	///< ground speed in cm/sec
	long	ground_course;	///< ground course in 100ths of a degree
	uint8_t num_sats;		///< Number of visible satelites
	uint8_t fix, HDOP;

uint8_t GPS_checksum, GPS_checksum_calc;
int bufferidx;
char buffer[GPS_BUFFERSIZE];
uint8_t gps_counter;
long origin_lon, origin_lat, origin_alt;
float cos_origin_lat;

uint8_t msg1[] = {0xB5, 0x62, 0x06, 0x08, 0x00, 0x00, 0x0E, 0x30};

void gps_init()
{
//	Serial.write(msg1, 8);
//  Serial.print(NMEA_OUTPUT_SENTENCES);
//  Serial.print(NMEA_OUTPUT_4HZ);
//  Serial.print(SBAS_ON);
//  Serial.print(DGPS_SBAS);
//  Serial.print(DATUM_GOOGLE);
	gps_counter = 0;
	origin_lon = origin_lat, origin_alt = 0L;
	gps_xpos = gps_ypos = gps_zpos = 0.0;
	gps_xvel = gps_yvel = 0.0;
	new_gpspos = new_gpsvel = 0;
}

void gps_update ()
{
  char c;
  int numc, i;
  
  numc = Serial.available();
  
  if (numc > 0)
  {
    for (i=0; i<numc; i++)
    {
      c = Serial.read();
      if (c=='$')
      {
        bufferidx = 0;
        buffer[bufferidx++] = c;
        GPS_checksum = 0;
        GPS_checksum_calc = 1;
        continue;
      }
      if (c=='\r')
      {
        buffer[bufferidx++] = '\0';
        parse_nmea_gps();
				bufferidx = 0;
      } else {
        if (bufferidx < (GPS_BUFFERSIZE-1) && bufferidx > 0)
        {
          if (c=='*')
            GPS_checksum_calc = 0;
          buffer[bufferidx++] = c;
          if (GPS_checksum_calc)
            GPS_checksum ^= c; // xor
        } else {
          bufferidx = 0;
        }
      }
    }
  }
}

void parse_nmea_gps ()
{
  uint8_t NMEA_check;
	long aux_deg;
	long aux_min;
	char *parseptr;
	if (strncmp(buffer,"$GPGGA",6)==0) // position
	{
		if (buffer[bufferidx-4]=='*')
		{
			NMEA_check = parseHex(buffer[bufferidx - 3]) * 16 + parseHex(buffer[bufferidx - 2]);		// Read the checksums characters
			if (GPS_checksum == NMEA_check){			// Checksum validation
				parseptr = strchr(buffer, ',')+1;
				utctime = parsenumber(parseptr, 2);					// GPS UTC time hhmmss.ss
				parseptr = strchr(parseptr, ',')+1;
				aux_deg = parsedecimal(parseptr, 2);			// degrees
				aux_min = parsenumber(parseptr + 2, 4);		 // minutes (sexagesimal) => Convert to decimal
				latitude = aux_deg * 10000000. + (aux_min * 50.) / 3.;	 // degrees + minutes / 0.6	( * 10000000) (0.6 = 3 / 5)
				parseptr = strchr(parseptr, ',')+1;
				if ( * parseptr == 'S')
					latitude = -1 * latitude;							// South latitudes are negative
				parseptr = strchr(parseptr, ',')+1;
				aux_deg = parsedecimal(parseptr, 3);			// degrees
				aux_min = parsenumber(parseptr + 3, 4);		 // minutes (sexagesimal)
				longitude = aux_deg * 10000000. + (aux_min * 50.) / 3.;	// degrees + minutes / 0.6 ( * 10000000)
				parseptr = strchr(parseptr, ',')+1;
				if ( * parseptr == 'W')
					longitude = -1 * longitude;							// West longitudes are negative
				parseptr = strchr(parseptr, ',')+1;
				fix = parsedecimal(parseptr, 1);
				parseptr = strchr(parseptr, ',')+1;
				num_sats = parsedecimal(parseptr, 2);
				parseptr = strchr(parseptr, ',')+1; 
				HDOP = parsenumber(parseptr, 1);					// HDOP * 10
				parseptr = strchr(parseptr, ',')+1;
				altitude = parsenumber(parseptr, 1) * 1000.;	// altitude in meters * 1000 = milimeters
				if (fix < 1)
					gps_quality = GPS_NOFIX;			// No FIX
				else if(num_sats < 5)
					gps_quality = GPS_BAD;			// Bad (Num sats < 5)
				else if(HDOP > 30)
					gps_quality = GPS_POOR;			// Poor (HDOP > 30)
				else if(HDOP > 25)
					gps_quality = GPS_OK;			// Medium (HDOP > 25)
				else
					gps_quality = GPS_GOOD;			// Good (HDOP < 25)
				if (gps_counter < GPS_SETTLE)
				{
					gps_counter++;
				}
				else if (gps_counter == GPS_SETTLE)
				{
					origin_lat = latitude;
					cos_origin_lat = cos(((float)origin_lat)*0.01745329251/10000000.);
					origin_lon = longitude;
					origin_alt = altitude;
					gps_counter++;
				}
				else
				{
					gps_ypos = (float)(latitude - origin_lat)*0.01113; // 0.01113 meters per lowest digit
					gps_xpos = (float)(longitude - origin_lon)*0.01113*cos_origin_lat; // dont remember if this is actually right
					gps_zpos = (float)(altitude - origin_alt)/1000.;
					new_gpspos = 1;
				}
			} else {
				// ERROR: checksum error
//				outSerial.println("ERROR: checksum problem 1");
			}
		}
	}
	else if (strncmp(buffer,"$GPVTG",6)==0) // course over ground
	{
		if (buffer[bufferidx-4]=='*')
		{
			NMEA_check = parseHex(buffer[bufferidx - 3]) * 16 + parseHex(buffer[bufferidx - 2]);		// Read the checksums characters
			if (GPS_checksum == NMEA_check){			// Checksum validation
				parseptr = strchr(buffer, ',')+1;
				ground_course = parsenumber(parseptr, 1) * 10;			// Ground course in degrees * 100
				parseptr = strchr(parseptr, ',')+1;
				parseptr = strchr(parseptr, ',')+1;
				parseptr = strchr(parseptr, ',')+1;
				parseptr = strchr(parseptr, ',')+1;
				parseptr = strchr(parseptr, ',')+1;
				parseptr = strchr(parseptr, ',')+1;
				ground_speed = parsenumber(parseptr, 1) * 100 / 36; // Convert Km / h to m / s ( * 100)
				if (gps_counter > GPS_SETTLE)
				{
					gps_xvel = ((float)ground_speed)*sin(((float)ground_course)/100.)/100.;
					gps_yvel = ((float)ground_speed)*cos(((float)ground_course)/100.)/100.;
					new_gpsvel = 1;
				}
			} else {
				// ERROR: checksum error
//				outSerial.println("ERROR: checksum error 2");
			}
		}
	} else {
		bufferidx = 0;
		// ERROR: bad sentence
//		outSerial.println("ERROR: bad sentence");
	}
}

 // Parse hexadecimal numbers
uint8_t parseHex(char c) {
		if (c < '0')
			return (0);
		if (c <= '9')
			return (c - '0');
		if (c < 'A')
			 return (0);
		if (c <= 'F')
			 return ((c - 'A')+10);
}

// Decimal number parser
long parsedecimal(char *str, uint8_t num_car) {
	long d = 0;
	uint8_t i;
	
	i = num_car;
	while ((str[0] != 0) && (i > 0)) {
		if ((str[0] > '9') || (str[0] < '0'))
			return d;
		d *= 10;
		d += str[0] - '0';
		str++;
		i--;
	}
	return d;
}

// Function to parse fixed point numbers (numdec=number of decimals)
long parsenumber(char *str, uint8_t numdec) {
	long d = 0;
	uint8_t ndec = 0;
	
	while (str[0] != 0) {
		 if (str[0] == '.'){
			 ndec = 1;
		} else {
			if ((str[0] > '9') || (str[0] < '0'))
				return d;
			d *= 10;
			d += str[0] - '0';
			if (ndec > 0)
				ndec++;
			if (ndec > numdec)	 // we reach the number of decimals...
				return d;
		}
		str++;
	}
	return d;
}
