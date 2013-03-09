import java.io.*;
import net.java.games.input.*;

// /dev/input/js0
// /dev/input/event20
// sudo xboxdrv --deadzone 6000 --deadzone-trigger 100

import processing.serial.*;

Serial port;
InputStream js;
String[] outtext, intext;
int outindex, inindex;
int[] outbyte, inbyte;
int i, j, numlines, index;
int[] motorspeed, battlevel, heartbeat;
int heartbeatindex, numpos, posindex;
float[] xpos, ypos, zpos;
float posscale, maxpos, vertscale, maxvert;
float currposhor, currpostot;
int lasthb, armed, gpslock, ohshit, lowbatt, flightmode, distwarn;
float yaw, roll, pitch, speed, alt_zero;
int userLift, userPitch, userRoll, userYaw;

BloomPProcess bloom;

void setup()
{
  frameRate(30);
  numlines = 23;
  numpos = 100;
  armed = 0;
  gpslock = 0;
  ohshit = 0;
  flightmode = 1;
  yaw = 45;
  distwarn = 0;
  speed = 0.0;
  bloom = new BloomPProcess();
  
  outtext = new String[numlines];
  intext = new String[numlines];
  outbyte = new int[numlines];
  inbyte = new int[numlines];
  motorspeed = new int[6];
  battlevel = new int[6];
  heartbeat = new int[100];
  xpos = new float[numpos];
  ypos = new float[numpos];
  zpos = new float[numpos];
  
  heartbeatindex = 0;
  outindex = inindex = 0;
  posindex = 0;
  posscale = 1.0;
  vertscale = 1.0;
  
  alt_zero = 1600.0;
  for (i=0; i<numpos; i++)
    zpos[i] = alt_zero;
  
  colorMode(HSB, 100);
  size(1200, 800);
  background(20);
  smooth();
  
  // init
  for (i=0; i<numlines; i++)
  {
    intext[i] = "";
    outtext[i] = "";
    inbyte[i] = 0x00;
    outbyte[i] = 0x00;
  }
  
  heartbeatrecv();
  
  rectMode(CORNERS);

  
  textAlign(LEFT);
  textFont(createFont("Courier New", 18));
  
  port = new Serial(this, "/dev/ttyUSB0", 38400);
  js = new FileInputStream("/dev/input/js0");
  
  sendheartbeat();
  lasthb = millis();
  
}

void draw()
{
  drawall();
  systemcheck();
  
  // grab data coming through the wireless
  checkWireless();
  if (wirelessLength>0) parseCommand();
  checkJoystick();
  //while (port.available()>0)
  //{
  //  inindex = (inindex+1)%numlines;
  //  inbyte[inindex] = port.read();
  //  intext[inindex] = (char)inbyte[inindex];
  //}
  
  if (millis()-lasthb > 800)
  {
    sendheartbeat();
    lasthb = millis();
  }
  
  // heartbeat needs to increment all the time, i guess
  heartbeatindex = (heartbeatindex+1)%100;
  heartbeat[heartbeatindex] = 0;
  
  // fake some position data
  //addpos(xpos[posindex]+random(1.5)-0.5,ypos[posindex]+random(1)-0.5,random(1)+1);
  //yaw = yaw + 1;
  
  //bloom.ApplyBloom();
}

void addpos(float x, float y, float z)
{
  posindex = (posindex+1)%numpos;
  xpos[posindex] = x;
  ypos[posindex] = y;
  zpos[posindex] = z;
  // search for max
  maxpos = 0.0;
  maxvert = 0.0;
  for (i=0; i<numpos; i++)
  {
    if (sqrt(xpos[i]*xpos[i]+ypos[i]*ypos[i]) > maxpos) maxpos = sqrt(xpos[i]*xpos[i]+ypos[i]*ypos[i]);
    if (abs(zpos[i]-alt_zero) > maxvert) maxvert = abs(zpos[i]-alt_zero);
  }
  posscale = 120./maxpos;
  vertscale = 60./maxvert;
  currposhor = sqrt(x*x+y*y);
  currpostot = sqrt(x*x+y*y+(z-alt_zero)*(z-alt_zero));
}

void systemcheck()
{
  // check battery levels
  lowbatt = 0;
  for (i=0; i<6; i++)
  {
    if (battlevel[i] < 50) lowbatt = 1;
  }
  for (i=0; i<6; i++)
  {
    if (battlevel[i] < 25) lowbatt = 2;
  }
  distwarn = 0;
  if (currpostot > 400) distwarn = 1;
  if (currpostot > 600) distwarn = 2;
  if (currpostot > 800) distwarn = 3;
}

void sendheartbeat()
{
  /*
  senddata('S');
  senddata('H');
  senddata('E')*/
}

void heartbeatrecv()
{
  heartbeat[heartbeatindex] = 100;
}

void keyPressed() {
  println(keyCode);
  switch (keyCode)
  {
    case 16:
      // up
      userLift=10;
      sendInput();
      userLift=0;
      break;
    case 17:
      // down
      userLift=-10;
      sendInput();
      userLift=0;
      break;
    case 8:
      // esc, kill motors
      userLift = 0;
      senddata('S');
      senddata(0x03);
      senddata('E');
      break;
    case 65:
      // a, arm motors
      userLift = 0;
      senddata('S');
      senddata(0x02);
      senddata('E');
      break;
    case 39:
      // right
      userRoll=50;
      sendInput();
      break;
    case 37:
      // left
      userRoll=-50;
      sendInput();
      break;
      
    case 38:
      // up
      userPitch=-50;
      sendInput();
      break;
    case 40:
      // down
      userPitch=+50;
      sendInput();
      break;
      
    case 81:
      // yaw left (Q)
      userYaw=-5;
      sendInput();
      userYaw=0;
      break;
    case 69:
      // yaw right (E)
      userYaw=+5;
      sendInput();
      userYaw=0;
      break;
      
    case 83: // s, flightmode = stabilize
      senddata('S');
      senddata(0x06);
      senddata(0x02);
      senddata('E');
      break;
    
      
    case 48: // 0, zero out the altitude
      alt_zero = zpos[posindex];
      break;
  }
}

void keyReleased()
{
  switch (keyCode)
  {
    case 39:
      // right
      userRoll=0;
      sendInput();
      break;
    case 37:
      // left
      userRoll=0;
      sendInput();
      break;
    case 38:
      // up
      userPitch=0;
      sendInput();
      break;
    case 40:
      // down
      userPitch=0;
      sendInput();
      break;
  }
}

void sendInput()
{
  senddata('S');
  senddata(0x07);
  senddata(userPitch);
  senddata(userRoll);
  senddata(userYaw);
  senddata(userLift);
  senddata('E');
}

void drawall()
{
  background(60,60,7);
  fill(0);
  // in text
  stroke(55,60,100);
  strokeWeight(1);
  rect(900,10,1190,390);
  // out text
  rect(900,400,1190,790);
  // motor speed
  rect(500,500,890,790);
  // position
  rect(570,90,890,490);
  // heartbeat
  rect(10,10,890,80);
  // status lights
  rect(10,420,560,490);
  // orientation
  rect(10,90,560,410);
  
  // position circle
  strokeWeight(1);
  stroke(10,0,60);
  ellipseMode(RADIUS);
  ellipse(730,330,120,120);
  ellipse(730,330,90,90);
  ellipse(730,330,60,60);
  ellipse(730,330,30,30);
  line(610,330,850,330);
  line(730,210,730,450);
  // north
  stroke(5,60,70);
  line(730,210,730,330);
  // yaw
  stroke(12,60,70);
  strokeWeight(2);
  line(730+90*sin(yaw*0.01745),330-90*cos(yaw*0.01745),730+120*sin(yaw*0.01745),330-120*cos(yaw*0.01745));
  // divider
  stroke(55,60,100);
  line(570,180,890,180);
  
  // tiny copter pic
  strokeWeight(2);
  stroke(55,60,30);
  ellipse(745,558,50,50); // motor 1
  ellipse(795,645,50,50); // motor 2
  ellipse(745,732,50,50); // motor 3
  ellipse(645,732,50,50); // motor 4
  ellipse(595,645,50,50); // motor 5
  ellipse(645,558,50,50); // motor 6
  ellipse(745,558,25,25); // motor 1
  ellipse(795,645,25,25); // motor 2
  ellipse(745,732,25,25); // motor 3
  ellipse(645,732,25,25); // motor 4
  ellipse(595,645,25,25); // motor 5
  ellipse(645,558,25,25); // motor 6
  
  // battery boxes
  strokeWeight(2);
  rect(805,528,815,588); // battery 1
  rect(855,615,865,675); // battery 2
  rect(805,702,815,762); // battery 3
  rect(585,702,575,762); // battery 4
  rect(535,615,525,675); // battery 5
  rect(585,528,575,588); // battery 6
  
    // draw text
  textAlign(LEFT);
  fill(60,20,90);
  for (i=0; i<numlines; i++)
  {
    text(intext[(inindex+i+1)%numlines], 940, 30+i*16);
    text(outtext[(outindex+i+1)%numlines], 940, 425+i*16);
  }
  fill(60,10,100);
  for (i=0; i<numlines; i++)
  {
    text(hex(inbyte[(inindex+i+1)%numlines]).substring(6,8), 910, 30+i*16);
    text(hex(outbyte[(outindex+i+1)%numlines]).substring(6,8), 910, 425+i*16);
  }
  
  // bit boxes
  noStroke();
  for (i=0; i<numlines; i++)
  {
    index = (inindex+i+1)%numlines;
    for (j=0;j<8;j++)
    {
      fill(12,50+((inbyte[index]>>j)&1)*60,20+i*40/numlines);
      rect(1166-j*18,30+i*16,1180-j*18,22+i*16);
    }
    index = (outindex+i+1)%numlines;
    for (j=0;j<8;j++)
    {
      fill(55,50+((outbyte[index]>>j)&1)*60,20+i*40/numlines);
      rect(1166-j*18,425+i*16,1180-j*18,417+i*16);
    }
  }
  
  // motor speed
  strokeWeight(0);
  fill(55+max(0,motorspeed[0]-120.),70,90,50);
  ellipse(746,559,motorspeed[0]*(50./180.),motorspeed[0]*(50./180.)); // motor 1
  fill(55+max(0,motorspeed[1]-120.),70,90,50);
  ellipse(796,646,motorspeed[1]*(50./180.),motorspeed[1]*(50./180.)); // motor 2
  fill(55+max(0,motorspeed[2]-120.),70,90,50);
  ellipse(746,733,motorspeed[2]*(50./180.),motorspeed[2]*(50./180.)); // motor 3
  fill(55+max(0,motorspeed[3]-120.),70,90,50);
  ellipse(646,733,motorspeed[3]*(50./180.),motorspeed[3]*(50./180.)); // motor 4
  fill(55+max(0,motorspeed[4]-120.),70,90,50);
  ellipse(596,646,motorspeed[4]*(50./180.),motorspeed[4]*(50./180.)); // motor 5
  fill(55+max(0,motorspeed[5]-120.),70,90,50);
  ellipse(646,559,motorspeed[5]*(50./180.),motorspeed[5]*(50./180.)); // motor 6
  
  
  // battery level
  fill(55-min(0,battlevel[0]-50),100,100);
  rect(805,588-battlevel[0]*0.6,815,588); // battery 1
  fill(55-min(0,battlevel[1]-50),100,100);
  rect(855,675-battlevel[1]*0.6,865,675); // battery 2
  fill(55-min(0,battlevel[2]-50),100,100);
  rect(805,762-battlevel[2]*0.6,815,762); // battery 3
  fill(55-min(0,battlevel[3]-50),100,100);
  rect(585,762-battlevel[3]*0.6,575,762); // battery 4
  fill(55-min(0,battlevel[4]-50),100,100);
  rect(535,675-battlevel[4]*0.6,525,675); // battery 5
  fill(55-min(0,battlevel[5]-50),100,100);
  rect(585,588-battlevel[5]*0.6,575,588); // battery 6
  
  
  // heartbeat
  stroke(12,60,60);
  strokeWeight(2);
  for (i=1; i<100; i++)
  {
    index = (heartbeatindex+i+1)%100;
    line(890-i*8-8,50-0.3*heartbeat[index],890-i*8,50-0.3*heartbeat[(heartbeatindex+i)%100]);
  }
  
  // position
  noStroke();
  for (i=0; i<numpos; i++)
  {
    if (i==numpos-1) {
      fill(12,i*90/numpos,100*i/numpos);
    } else {
      fill(12,i*60/numpos,70*i/numpos);
    }
    index = (i+posindex+1)%numpos;
    ellipse(730+xpos[index]*posscale,330-ypos[index]*posscale,3,3);
  }
  // vertical plot
  strokeWeight(2);
  stroke(12,100,100);
  for (i=0; i<numpos; i++)
  {
    index = (i+posindex+1)%numpos;
    line(580+i*3,170-(zpos[index]-alt_zero)*vertscale,580+i*3,170);
  }
  textAlign(LEFT);
  fill(12,100,100);
  text("V: "+round((zpos[posindex]-alt_zero)*10.)/10.+"m", 590, 210);
  text("H: "+round(currposhor*10.)/10.+"m", 790, 210);
  text("R: "+round(currpostot*10.)/10.+"m", 690, 470);
  
  // status lights
  textAlign(CENTER);
  noStroke();
  if (armed>0)
  {
    fill(12,80,80);
  } else {
    fill(55,80,30);
  }
  rect(110,430,190,450);
  fill(0,0,0);
  text("ARMED", 150, 445);
  
  if (lowbatt>1)
  {
    fill(1,90,80);
  } else if (lowbatt>0) {
    fill(5,80,80);
  } else {
    fill(55,80,30);
  }
  rect(20,430,100,450);
  fill(0,0,0);
  text("BATT", 60, 445);
  
  if (gpslock>0)
  {
    fill(12,80,80);
  } else {
    fill(55,80,30);
  }
  rect(200,430,280,450);
  fill(0,0,0);
  text("GPS", 240, 445);
  
  if (distwarn>0)
  {
    fill(10-distwarn*3,80,80);
  } else {
    fill(55,80,30);
  }
  rect(200,430,280,450);
  fill(0,0,0);
  text("DIST", 240, 445);
  
  if (flightmode==0)
  {
    fill(12,80,80);
  } else {
    fill(55,80,30);
  }
  rect(20,460,100,480);
  fill(0,0,0);
  text("SAFE", 60, 475);
  
  if (flightmode==1)
  {
    fill(12,80,80);
  } else {
    fill(55,80,30);
  }
  rect(110,460,190,480);
  fill(0,0,0);
  text("LANDED", 150, 475);
  
  if (flightmode==2)
  {
    fill(12,80,80);
  } else {
    fill(55,80,30);
  }
  rect(200,460,280,480);
  fill(0,0,0);
  text("STABIL", 240, 475);
  
  if (flightmode==3)
  {
    fill(12,80,80);
  } else {
    fill(55,80,30);
  }
  rect(290,460,370,480);
  fill(0,0,0);
  text("ALTHLD", 330, 475);
  
  if (flightmode==4)
  {
    fill(12,80,80);
  } else {
    fill(55,80,30);
  }
  rect(380,460,460,480);
  fill(0,0,0);
  text("RTL", 420, 475);
  
  // orientation stuff
  textAlign(RIGHT);
  stroke(12,100,100);
  strokeWeight(2);
  line(20,100,80,100);
  line(20,400,80,400);
  line(80,100,80,400);
  line(550,100,490,100);
  line(550,400,490,400);
  line(490,100,490,400);
  stroke(12-max(pitch,20)+20,100,100);
  line(80,250,90,260);
  line(80,250,90,240);
  fill(12,100,100);
  stroke(12,100,100);
  for (i=-90; i<=90; i+=5)
  {
    if (abs(pitch-i) <= 29)
    {
      text(""+i, 60, 255+(pitch-i)*5);
      line(70,250+(pitch-i)*5,80,250+(pitch-i)*5);
    }
  }
  
  // roll lines
  line(255,252,280,252);
  line(255,248,280,248);
  line(290,252,315,252);
  line(290,248,315,248);

  line(285-150*cos(-roll*0.01745),250-150*sin(-roll*0.01745)+pitch*2,285+150*cos(-roll*0.01745),250+150*sin(-roll*0.01745)+pitch*2);
  line(285-10*sin(roll*0.01745),250-10*cos(-roll*0.01745)+pitch*2,285+10*sin(roll*0.01745),250+10*cos(-roll*0.01745)+pitch*2);
  
  if (pitch > -50)
    line(285-20*cos(-roll*0.01745),200-20*sin(-roll*0.01745)+pitch*2,285+20*cos(-roll*0.01745),200+20*sin(-roll*0.01745)+pitch*2);
  if (pitch > -30)
    line(285-20*cos(-roll*0.01745),150-20*sin(-roll*0.01745)+pitch*2,285+20*cos(-roll*0.01745),150+20*sin(-roll*0.01745)+pitch*2);
  if (pitch < 50)
    line(285-20*cos(-roll*0.01745),300-20*sin(-roll*0.01745)+pitch*2,285+20*cos(-roll*0.01745),300+20*sin(-roll*0.01745)+pitch*2);
  if (pitch < 30)
    line(285-20*cos(-roll*0.01745),350-20*sin(-roll*0.01745)+pitch*2,285+20*cos(-roll*0.01745),350+20*sin(-roll*0.01745)+pitch*2);
  
  textAlign(CENTER);
  if (yaw < 45.0 || yaw >= 315)
    text(round(yaw)+"N", 160, 400);
  if (yaw < 225 && yaw >= 135)
    text(round(yaw)+"S", 160, 400);
  if (yaw < 135.0 && yaw >= 45)
    text(round(yaw)+"E", 160, 400);
  if (yaw < 315.0 && yaw >= 225)
    text(round(yaw)+"W", 160, 400);
  
  text(round(speed)+" m/s", 375, 400);
  
  line(490,250,480,260);
  line(490,250,480,240);
  //text(""+round(round(zpos[posindex]*3.28) - floor(zpos[posindex]*0.328)*10.), 550, 255);
  textAlign(LEFT);
  for (i=-1000; i<=1000; i+=10)
  {
    if (abs(zpos[posindex]*3.28-i) <= 29)
    {
      text(""+i, 510, 255+(zpos[posindex]*3.28-i)*5);
      line(490,250+(zpos[posindex]*3.28-i)*5,500,250+(zpos[posindex]*3.28-i)*5);
    }
  }
  
}
