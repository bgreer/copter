import processing.serial.*;

Serial port;
char[] outtext, intext;
int outindex, inindex;
int[] outbyte, inbyte;
int i, j, numlines, index;
int[] motorspeed, battlevel, heartbeat;
int heartbeatindex, numpos, posindex;
float[] xpos, ypos, zpos;
float posscale, maxpos, vertscale, maxvert;
float currposhor, currpostot;

void setup()
{
  numlines = 23;
  numpos = 100;
  
  outtext = new char[numlines];
  intext = new char[numlines];
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
  
  
  colorMode(HSB, 100);
  size(1200, 800);
  background(20);
  smooth();
  
  // init
  for (i=0; i<numlines; i++)
  {
    intext[i] = '.';
    outtext[i] = '.';
    inbyte[i] = 0x00;
    outbyte[i] = 0x00;
  }
  motorspeed[0] = 90;
  motorspeed[1] = 100;
  motorspeed[2] = 90;
  motorspeed[3] = 70;
  motorspeed[4] = 80;
  motorspeed[5] = 70;
  battlevel[0] = 100;
  battlevel[1] = 100;
  battlevel[2] = 100;
  battlevel[3] = 100;
  battlevel[4] = 100;
  battlevel[5] = 100;
  
  heartbeatrecv();
  
  rectMode(CORNERS);

  
  textAlign(LEFT);
  textFont(createFont("Courier New", 18));
  
  port = new Serial(this, "/dev/ttyACM0", 115200);
  
}

void draw()
{
  drawall();
  
  // grab data coming through the wireless
  while (port.available()>0)
  {
    inindex = (inindex+1)%numlines;
    inbyte[inindex] = port.read();
    intext[inindex] = (char)inbyte[inindex];
  }

  
  // heartbeat needs to increment all the time, i guess
  heartbeatindex = (heartbeatindex+1)%100;
  heartbeat[heartbeatindex] = 0;
  
  // fake some position data
  addpos(random(3)+1.5,random(3)-7.5,random(1)+1);
  
  motorspeed[0] = motorspeed[0]+(int)(random(4)-2.0);
  motorspeed[1] = motorspeed[1]+(int)(random(4)-2.0);
  motorspeed[2] = motorspeed[2]+(int)(random(4)-2.0);
  battlevel[0] = battlevel[0]+(int)(random(4)-2.02);
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
    if (abs(zpos[i]) > maxvert) maxvert = abs(zpos[i]);
  }
  posscale = 120./maxpos;
  vertscale = 60./maxvert;
  currposhor = sqrt(x*x+y*y);
  currpostot = sqrt(x*x+y*y+z*z);
}

void heartbeatrecv()
{
  heartbeat[heartbeatindex] = 100;
}

void keyPressed() {
  int keyIndex = -1;
  if (key >= 'A' && key <= 'Z') {
    keyIndex = key - 'A';
  } else if (key >= 'a' && key <= 'z') {
    keyIndex = key - 'a';
  }
}

void drawall()
{
  background(20);
  fill(0);
  // in text
  stroke(60,30,80);
  strokeWeight(4);
  rect(900,10,1190,390);
  // out text
  stroke(30,30,80);
  rect(900,400,1190,790);
  // motor speed
  stroke(10,30,80);
  rect(700,500,890,790);
  // position
  stroke(70,30,80);
  rect(570,90,890,490);
  // heartbeat
  stroke(0,30,80);
  rect(10,10,890,80);
  
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
  stroke(0,60,70);
  line(730,210,730,330);
  // divider
  stroke(70,30,80);
  line(570,180,890,180);
  
  strokeWeight(2);
  stroke(10,20,80);
  rect(860,510,880,740);
  rect(830,510,850,740);
  rect(800,510,820,740);
  rect(770,510,790,740);
  rect(740,510,760,740);
  rect(710,510,730,740);
  
  rect(710,750,730,780);
  rect(740,750,760,780);
  rect(770,750,790,780);
  rect(800,750,820,780);
  rect(830,750,850,780);
  rect(860,750,880,780);
  
    // draw text
  textAlign(LEFT);
  fill(60,20,90);
  for (i=0; i<numlines; i++)
  {
    text(intext[(inindex+i+1)%numlines], 940, 380-i*16);
    text(outtext[(outindex+i+1)%numlines], 940, 780-i*16);
  }
  fill(60,10,100);
  for (i=0; i<numlines; i++)
  {
    text(hex(inbyte[(inindex+i+1)%numlines]).substring(6,8), 910, 380-i*16);
    text(hex(outbyte[(outindex+i+1)%numlines]).substring(6,8), 910, 780-i*16);
  }
  
  // bit boxes
  noStroke();
  for (i=0; i<numlines; i++)
  {
    index = (inindex+i+1)%numlines;
    for (j=0;j<8;j++)
    {
      fill(60,50+((inbyte[index]>>j)&1)*60,100-i*40/numlines);
      rect(1166-j*18,380-i*16,1180-j*18,368-i*16);
    }
    index = (outindex+i+1)%numlines;
    for (j=0;j<8;j++)
    {
      fill(60,50+((outbyte[index]>>j)&1)*60,100-i*40/numlines);
      rect(1166-j*18,780-i*16,1180-j*18,768-i*16);
    }
  }
  
  strokeWeight(0);
  for (i=0; i<6; i++)
  {
    fill(50-motorspeed[i]*(50./180.),70,90);
    rect(710+i*30,740-motorspeed[i]*(230./180.),730+i*30,740);
    fill(30*(0.01*battlevel[i]),100,100);
    rect(710+i*30,750,730+i*30,780);
  }
  
  stroke(0,10,100);
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
    fill(70,i*90/numpos,100);
    index = (i+posindex+1)%numpos;
    ellipse(730+xpos[index]*posscale,330-ypos[index]*posscale,3,3);
  }
  // vertical plot
  strokeWeight(2);
  stroke(80,100,100);
  for (i=0; i<numpos; i++)
  {
    index = (i+posindex+1)%numpos;
    line(580+i*3,170-zpos[index]*vertscale,580+i*3,170);
  }
  textAlign(LEFT);
  fill(40-currpostot*40/800.,100,100);
  text("V: "+round(zpos[posindex])+"m", 590, 210);
  text("H: "+round(currposhor)+"m", 790, 210);
  text("R: "+round(currpostot)+"m", 690, 470);
}
