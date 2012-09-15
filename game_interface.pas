unit game_interface;
interface
uses gxtype,gximg,graphix,gxmouse,gximeff;
const
   but_normal=0;
   but_prelight=1;
   but_pressed=2;
   but_insensitive=3;

   but_act_none=0;
   but_act_click=1;
   but_act_press=2;
   but_act_enter=3;
   but_act_leave=4;
   but_act_release=5;

type
   Tproc=procedure;
   tbutton=packed record
      x1,y1,x2,y2:longint;
      img:array[but_normal..but_insensitive]of pimage;
      imgposh,imgposv,state:byte;
      lastaction:byte;
      proc:Tproc;
      end;
   Pbutton=^tbutton;

   Pfont=^Tfont;
   Tfont=array[0..255]of pimage;
   Tmessage_box=packed record
    message:string;
    height:word;
    bgimg:pimage;
    end;

var
  curfont:Tfont;
  curfontsize:double;
  curr,curg,curb:integer;

function new_button(x,y:longint;imgposh,imgposv:byte;pr:Tproc;img_path:string):pbutton;
procedure update_button(but:pbutton);
procedure draw_button(but:pbutton;var targetimg:pimage);
procedure destroy_button(var but:pbutton);
procedure setcurrentfont(path:string);
procedure setcurrentcolor(r,g,b:integer);
procedure outtext(x0,y0:integer;text:string;posx,posy:byte;var targetimg:pimage);
function gettextheight(s:string):longint;
function gettextlength(s:string):longint;

implementation

function ttts(n:integer):byte;
begin
case n of
  0..5:ttts:=n+160;
  6:ttts:=241;
  7..16:ttts:=n+159;
  17..32:ttts:=n+207;
  33..65:ttts:=n-1;
  end;
end;

procedure setcurrentcolor(r,g,b:integer);
begin
curr:=r;curg:=g;curb:=b;
end;

procedure setcurrentfont(path:string);
var f:text;
    i:integer;
begin
assign(f,path);
{$i-}reset(f);{$i+}
if ioresult=0 then
  begin
  close(f);
  for i:=0 to 255 do
    begin
    destroyimage(curfont[ttts(i)]);
    loadimagefile(itdetect,path,curfont[ttts(i)],i+1);
    end;
  end;
end;

function gettextlength(s:string):longint;
var i,res:integer;
begin
res:=0;
if length(s)>0 then
for i:=1 to length(s) do res:=res+getimagewidth(curfont[ord(s[i])])+4;
gettextlength:=round(res/curfontsize);
end;

function gettextheight(s:string):longint;
begin
if length(s)>0 then
gettextheight:=round(getimageheight(curfont[ord(s[1])])/curfontsize) else
gettextheight:=0;
end;

procedure outtext(x0,y0:integer;text:string;posx,posy:byte;var targetimg:pimage);
var x,i,xo,yo:longint;
    t:pimage;
begin
x:=x0;
case posx of
  0:xo:=0;
  1:xo:=gettextlength(text)div 2;
  2:xo:=gettextlength(text);
  end;
case posy of
  0:yo:=0;
  1:yo:=gettextheight(text)div 2;
  2:yo:=gettextheight(text);
  end;

for i:=1 to length(text) do
  if curfont[ord(text[i])]<>nil then
    begin
    t:=createimageWH(round(getimagewidth(curfont[ord(text[i])])/curfontsize),round(getimageheight(curfont[ord(text[i])])/curfontsize));
    setimagetransparencycolor(t,rgbcolorrgb(255,255,255));
    fillimage(t,getimagetransparencycolor(t));
    if curfontsize<>1 then scaleimage(t,curfont[ord(text[i])]) else copyimage(t,curfont[ord(text[i])]);
    imagesaddcolor(t,t,rgbcolorrgb(curr,curg,curb));
    composeimagec(targetimg,t,x-xo,y0-yo);
    x:=x+gettextlength(text[i]);
    destroyimage(t);
    end;
end;

procedure draw_button(but:pbutton;var targetimg:pimage);
var xd,yd:longint;
begin
if but^.img[but^.state]<>nil then
with but^ do
case imgposh of
   0:begin
     xd:=x1;
     end;
   1:begin
     xd:=x1+(x2-x1)div 2-getimagewidth(but^.img[but^.state])div 2;
     end;
   2:begin
     xd:=x2-getimagewidth(but^.img[but^.state]);
     end;
   end;
if but^.img[but^.state]<>nil then
with but^ do
case imgposv of
   0:begin
     yd:=y1;
     end;
   1:begin
     yd:=y1+(y2-y1)div 2-getimageheight(but^.img[but^.state])div 2;
     end;
   2:begin
     yd:=y2-getimageheight(but^.img[but^.state]);
     end;
   end;
if but^.img[but^.state]<>nil then
composeimagec(targetimg,but^.img[but^.state],xd,yd);
end;

function new_button(x,y:longint;imgposh,imgposv:byte;pr:Tproc;img_path:string):pbutton;
var but:pbutton;
begin
new(but);
but^.proc:=pr;
but^.x1:=x;
but^.y1:=y;
with but^ do
  begin
  loadimagefile(itdetect,img_path+'_normal.gif',img[but_normal],0);
  loadimagefile(itdetect,img_path+'_pressed.gif',img[but_pressed],0);
  loadimagefile(itdetect,img_path+'_prelight.gif',img[but_prelight],0);
  loadimagefile(itdetect,img_path+'_insensitive.gif',img[but_insensitive],0);
  end;
but^.x2:=x+getimagewidth(but^.img[but_normal]);
but^.y2:=y+getimageheight(but^.img[but_normal]);
but^.imgposh:=imgposh;
but^.imgposv:=imgposv;
but^.state:=but_normal;
but^.lastaction:=but_act_none;
new_button:=but;
end;

procedure destroy_button(var but:pbutton);
var i:integer;
begin
for i:=but_normal to but_insensitive do destroyimage(but^.img[i]);
dispose(but);
end;

procedure update_button(but:pbutton);
var ms:byte;
begin
with but^ do ms:=ismouseinarea(x1,y1,x2,y2);
with but^ do
case ms of
  0:begin
    case state of
      but_prelight,but_pressed:lastaction:=but_act_leave;
      end;
    state:=but_normal;
    end;
  128:begin
      case state of
        but_normal:lastaction:=but_act_enter;
        but_pressed:lastaction:=but_act_release;
        end;
      state:=but_prelight;
      end;
  129:begin
      case state of
        {but_normal,}but_prelight:begin lastaction:=but_act_press;state:=but_pressed;end;
        end;
      end;
  end;
//if but^.lastaction=but_act_release then if but^.proc<>nil then but^.proc;
end;

begin
end.
