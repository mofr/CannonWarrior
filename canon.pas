program cannon_warior;
uses graphix,gxtype,gximg,crt,gx2d,gximeff,math,gxmedia,{gxttf,}
     mouselib,gxmouse,gxtext;
type ppoint=^point;
     ppoligon=^my_poligon;
     my_poligon=record
      m:ppoint;
      length:longint;
      perimeter:real;
     end;
     point=record
      x,y:integer;
     end;
     my_terrain=record
      A,B:point;
      image:pimage;
      wind:byte;
      poligon:my_poligon;
     end;
     my_bulliet=record
      p:point;
      pdraw:point;
      anim:string;
      m:byte;
      v:real;
      alfa:integer;
      beta:real;
      name:string;
     end;
     my_cannon=record
      obt:array [1..4]of point;
      w,h,gw,gh:integer;
      alfa:integer;
      Capacity:integer;
      image:pimage;
      image2:pimage;
      bulliet:my_bulliet;
     end;
     my_player=record
      cannon:my_cannon;
      name:string;
     end;
     setting=record
      scale:byte;
      restX,rstY:integer;
     end;
     Tmessagebox=record
      message:ansistring;
      x,y:integer;
      w,h:integer;
     end;

var Bexit,Bfire,Bupangle,Bdownangle,Bpowerup,Bpowerdown:Tbutton;
label 1;
procedure loadmap(var t:my_terrain;var ca,cb:my_player;name:string);
var f:file of my_terrain;
begin
 assign(f,'map\'+name);
 read(f,t);
 close(f);
end;

procedure loadbulliet(var a:my_player;way:string);
var f:file of my_bulliet;
begin
 assign(f,'\sistem'+way);
 read(f,a.cannon.bulliet);
 close(f);
end;

procedure move(var blt:my_bulliet;tr:my_terrain;scale,t:real);
const g=9.8;
var x,y:integer;
begin
 t:=t/1000;
 if (blt.pdraw.x<>0)and(blt.pdraw.y<>0) then
  begin x:=blt.pdraw.x;y:=blt.pdraw.y;end else begin x:=blt.p.x;y:=blt.p.y;end;
 blt.pdraw.x:=round(blt.p.x+scale*(blt.v+tr.wind)*cos(blt.alfa*pi/180)*t);
 blt.pdraw.y:=round(blt.p.y-scale*((blt.v)*sin(blt.alfa*pi/180)*t-g*t*t/2));
 if ((x<>blt.pdraw.x)and(y<>blt.pdraw.y))or(x<>blt.pdraw.x) then
  blt.beta:=arctan((-blt.pdraw.y+y)/(blt.pdraw.x-x))*180/pi
 else blt.beta:=blt.alfa;
end;

function check_intropoly(blt:my_bulliet;poli:my_poligon):boolean;
var i:integer; P:real;
begin
 for i:=1 to poli.length do
  p:=p+sqrt(sqr(poli.m[i].x-blt.p.x)+sqr(poli.m[i].y-blt.p.y));
 if p>poli.perimeter then check_intropoly:=true
 else check_intropoly:=false;
end;

function check_introcannon(blt:my_bulliet;c:my_cannon):boolean;
var i:integer; p:real;
begin
 for i:=1 to 4 do
  p:=p+sqrt(sqr(c.obt[i].y-blt.p.y)+sqr(c.obt[i].x-blt.p.x));
 if p>(2*(c.w+c.h)) then check_introcannon:=true
 else check_introcannon:=false;
end;

procedure drawbulliet(blt:my_bulliet;imgback:pimage;time:longint);
var  plr:pmediagif; backimg,rimage,img:pimage;
const w=50;h=50;
begin
 new (plr,openmedia(blt.anim));
 backimg:=createimagewh(w,h);
 getimage(blt.pdraw.x-w div 2,blt.pdraw.y-h div 2,backimg);
 while not plr^.endofmedia do
  begin
   rimage:=createimagewh(2*w,2*h);
   fillimage(rimage,rgbcolorrgb(255,255,255));
   img:=createimagewh(w,h);
   scaleimage(img,plr^.grabframe);
   rotateimage(rimage,img,w div 2,h div 2,getimagewidth(img) div 2,getimageheight(img) div 2,w,h,round(182*blt.beta));
   setimagetransparencycolor(rimage,rgbcolorrgb(255,255,255));
   putimageC(blt.pdraw.x-w div 2,blt.pdraw.y-h div 2,rimage);
   delay({plr^.getframetime}time div plr^.getnumframe);
   putimage(blt.pdraw.x-w div 2,blt.pdraw.y-h div 2,backimg);
  end;
  destroyimage(rimage);
  destroyimage(backimg);
 dispose(plr,closemedia);
end;

procedure calc_cannonobt(var pl,pl2:my_player;terra:my_terrain);
begin
 pl.cannon.obt[1].x:=terra.a.x-pl.cannon.w;
 pl.cannon.obt[1].y:=terra.a.y-pl.cannon.h;
 pl.cannon.obt[2].x:=terra.a.x+pl.cannon.w;
 pl.cannon.obt[2].y:=terra.a.y-pl.cannon.h;
 pl.cannon.obt[3].x:=terra.a.x+pl.cannon.w;
 pl.cannon.obt[3].y:=terra.a.y+pl.cannon.h;
 pl.cannon.obt[4].x:=terra.a.x-pl.cannon.w;
 pl2.cannon.obt[4].y:=terra.b.y+pl.cannon.h;
 pl2.cannon.obt[1].x:=terra.b.x-pl.cannon.w;
 pl2.cannon.obt[1].y:=terra.b.y-pl.cannon.h;
 pl2.cannon.obt[2].x:=terra.b.x+pl.cannon.w;
 pl2.cannon.obt[2].y:=terra.b.y-pl.cannon.h;
 pl2.cannon.obt[3].x:=terra.b.x+pl.cannon.w;
 pl2.cannon.obt[3].y:=terra.b.y+pl.cannon.h;
 pl2.cannon.obt[4].x:=terra.b.x-pl.cannon.w;
 pl2.cannon.obt[4].y:=terra.b.y+pl.cannon.h;
end;

procedure drawcannon(c:my_cannon{;img:pimage});
var imagebody,imagegun,rimage:pimage;
begin
 imagebody:=createimage(c.obt[1].x,c.obt[1].y,c.obt[3].x,c.obt[3].y); //Создаю картину для масштабирования и записываю в неё тело//
 scaleimage(imagebody,c.image);
 imagegun:=createimagewh(c.gw,c.gh);
 scaleimage(imagegun,c.image2);
 rimage:=createimagewh(4*c.w,4*c.h);
 getimage(c.obt[1].x-2*c.w,c.obt[1].y-2*c.h,rimage);
 rotateimage(rimage,imagegun,0,4*c.h,0,c.h,c.w,c.h,c.alfa*182);
 putimageC(c.obt[1].x,c.obt[1].y,rimage);
end;
procedure drawbg(t:my_terrain);
begin
 zoomimagec(0,0,getmaxx,getmaxy,t.image)
end;

procedure processing(plrA,plrB:my_player;tr:my_terrain;imga:pimage;setg:setting);
var t:integer;
begin
 plrA.cannon.bulliet.alfa:=plra.cannon.alfa;
 plrA.cannon.bulliet.v:=sqrt(plrA.cannon.capacity*2/plrA.cannon.bulliet.m);
 repeat
  move(plrA.cannon.bulliet,tr,setg.scale,t);
  drawbulliet(plrA.cannon.bulliet,imga,t);
  inc(t,10);
 until (check_introcannon(plrA.cannon.bulliet,plrB.cannon)=true)or(check_intropoly(plrA.cannon.bulliet,tr.poligon)=true)or
       (check_introcannon(plrA.cannon.bulliet,plrB.cannon)=true);
       //проверка условия движения //
end;
procedure drawBlow(x,y:integer;way:string{;var image:pimage});
var mplr:pmediagif; backimage,temp:pimage;
begin
 new(mplr,openmedia(way));
 backimage:=createimagewh(mplr^.getwidth,mplr^.getheight);
 temp:=createimagewh(mplr^.getwidth,mplr^.getheight);
 getimage(x-mplr^.getwidth div 2,y-mplr^.getheight,backimage);
 composeimageC(temp,backimage,0,0);
 while not mplr^.endofmedia do
  begin
   composeimageC(temp,mplr^.grabframe,0,0);
   putimageC(x-mplr^.getwidth div 2,y-mplr^.getheight,{x+mplr^.getwidth div 2,y+mplr^.getheight,}temp);
   delay(mplr^.getframetime);
  end;
 putimageC(x-mplr^.getwidth div 2,y-mplr^.getheight,backimage);
end;
procedure readsetting(var pl:my_player);
begin
repeat
if buttonstat(Bupangle)=129 then begin inc(pl.cannon.alfa);{drawcannon(pl.cannon);}end;
if buttonstat(Bdownangle)=129 then begin dec(pl.cannon.alfa);{drawcannon(pl.cannon);}end;
{if buttonstat(Bpowerup)=129 then inc(pl.cannon.capacity);
if buttonstat(Bpowerdown)=129 then dec(pl.cannon.capacity); }
if buttonstat(Bexit)=129 then goto 1;
until buttonstat(Bfire)=129;
end;

{procedure main(var a,b:my_player;t:my_terrain;s:setting);
var i:longint;
begin
i:=1;
repeat
 if i mod 2 =0 then
  begin
   readsetting(b);
   processing(b,a,t, ,s);
  end;
 else
 begin
  readsetting(a);
  processing(a,b,t, ,s);
 end;
 inc(i);
until false;
end;
}

var playerA,playerB:my_player; terra:my_terrain; setg:setting; t:integer;
    imagefront,imageBack:pimage;  font:tfontCHR;
begin
 initgraphix(ig_vesa,ig_lfb);
 setmodegraphix(1024,768,ig_col32);
 initmouse;
 mouseoff;
//
 buttoncreate(Bexit,900,0,124,50,'picture\exit.gif','picture\exitalloc.gif','c:\fpc\project\cannon warior\picture\exitclick.gif');
 buttoncreate(bfire,0,0,100,50,'picture\fire.gif','picture\firealloc.gif','c:\fpc\project\cannon warior\picture\fireclick.gif');
 buttoncreate(Bdownangle,900,100,25,25,'picture\downangle.gif','picture\downangle.gif','c:\fpc\project\cannon warior\picture\downangle.gif');
 buttoncreate(bupangle,960,100,25,25,'picture\upangle.gif','picture\upangle.gif','c:\fpc\project\cannon warior\picture\upangle.gif');
//
 loadimagefile(itdetect,'picture\map.jpg',terra.image,0);
 playera.cannon.bulliet.alfa:=45;
 playera.cannon.bulliet.v:=20;
 playera.cannon.bulliet.p.x:=100;
 playera.cannon.bulliet.p.y:=450;
 playera.cannon.bulliet.anim:='picture\bulliet.gif';
 imagefront:=createimage(0,0,getmaxx,getmaxy);
 loadimagefile(itdetect,'picture\body.jpg',playera.cannon.image,0);
 loadimagefile(itdetect,'picture\gun.jpg',playera.cannon.image2,0);
//
 drawbg(terra);
 mouseon;
 readsetting(playerA);
 playera.cannon.bulliet.alfa:=playera.cannon.alfa;
 font.loadfont('trip.chr');
  repeat
   move(playera.cannon.bulliet,terra,10,t);
   drawbulliet(playera.cannon.bulliet,imagefront,100);
   inc(t,100); font.outtext(300,400,'ПРЕВЕД',rgbcolorrgb(0,0,0));
  until false;

//
1:
end.
