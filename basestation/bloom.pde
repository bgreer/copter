// writen by Christopher Webb
// found on http://www.openprocessing.org/sketch/30110

public class BloomPProcess
{
   
  private PImage    bloomTarget; 
  private int       BloomThreshold   = 20; //the minimum brightness that will be "bloomed"
  private int       BloomRadius      = 4;   //the radius of the bloom
   
  BloomPProcess()
  {
    SetUpTarget();
  }
   
   
  //dont use this normally
  public void UpdateParams()
  {
    BloomThreshold = int( width / 255 ) * mouseX;
    BloomRadius = mouseY/10;
  }
   
  //creates a transparent texture/image to use to create and apply the bloom
  private void SetUpTarget()
  {
    bloomTarget = createImage( width , height , RGB);
    bloomTarget.loadPixels();
    for (int i = 0; i < bloomTarget.pixels.length; i++)
    {
      bloomTarget.pixels[i] = color(0, 0, 0 );
    }
  }
   
  //called at the end of a draw loop, this applies bloom to everything on screen
  public void ApplyBloom()
  {
    SetUpTarget();
    BloomExtract();
    Blur( bloomTarget , BloomRadius );
    //draw the bloomed image over the scene using addtive blending
    blend( bloomTarget , 0 , 0 , width , height , 0 , 0 , width , height , ADD );   
  }
   
  //removes the pixels which we wish to apply bloom to ( according to the bloom threshold )
  private void BloomExtract()
  {
    loadPixels();
    bloomTarget.loadPixels();
    for (int i = 0; i < bloomTarget.pixels.length; i++)
    {
      if( brightness( pixels[i] ) >= BloomThreshold )
      {
        bloomTarget.pixels[i] = pixels[i];
      }  
    }
    bloomTarget.updatePixels();
  }
   
   
  //blurs an image
  void Blur( PImage _img , int radius )
  {
    if (radius<1)
    {
      return;
    }
     
    int w=_img.width;
    int h=_img.height;
    int wm=w-1;
    int hm=h-1;
    int wh=w*h;
    int div=radius+radius+1;
    int r[]=new int[wh];
    int g[]=new int[wh];
    int b[]=new int[wh];
    int rsum,gsum,bsum,x,y,i,p,p1,p2,yp,yi,yw;
    int vmin[] = new int[max(w,h)];
    int vmax[] = new int[max(w,h)];
    int[] pix=_img.pixels;
    int dv[]=new int[256*div];
    for (i=0;i<256*div;i++){
       dv[i]=(i/div);
    }   
     
    yw=yi=0;  
     
    for (y=0;y<h;y++)
    {
      rsum=gsum=bsum=0;
      for(i=-radius;i<=radius;i++){
        p=pix[yi+min(wm,max(i,0))];
        rsum+=(p & 0xff0000)>>16;
        gsum+=(p & 0x00ff00)>>8;
        bsum+= p & 0x0000ff;
     }
      for (x=0;x<w;x++)
      {
       
        r[yi]=dv[rsum];
        g[yi]=dv[gsum];
        b[yi]=dv[bsum];
   
        if(y==0)
        {
          vmin[x]=min(x+radius+1,wm);
          vmax[x]=max(x-radius,0);
         }
         p1=pix[yw+vmin[x]];
         p2=pix[yw+vmax[x]];
   
        rsum+=((p1 & 0xff0000)-(p2 & 0xff0000))>>16;
        gsum+=((p1 & 0x00ff00)-(p2 & 0x00ff00))>>8;
        bsum+= (p1 & 0x0000ff)-(p2 & 0x0000ff);
        yi++;
      }
      yw+=w;
    }
     
    for (x=0;x<w;x++)
    {
      rsum=gsum=bsum=0;
      yp=-radius*w;
      for(i=-radius;i<=radius;i++)
      {
        yi=max(0,yp)+x;
        rsum+=r[yi];
        gsum+=g[yi];
        bsum+=b[yi];
        yp+=w;
      }
      yi=x;
      for (y=0;y<h;y++)
      {
        pix[yi]=0xff000000 | (dv[rsum]<<16) | (dv[gsum]<<8) | dv[bsum];
        if(x==0){
          vmin[y]=min(y+radius+1,hm)*w;
          vmax[y]=max(y-radius,0)*w;
        }
        p1=x+vmin[y];
        p2=x+vmax[y];
   
        rsum+=r[p1]-r[p2];
        gsum+=g[p1]-g[p2];
        bsum+=b[p1]-b[p2];
   
        yi+=w;
      }
    } 
  }
 
 
   
 
}

