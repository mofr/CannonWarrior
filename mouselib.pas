unit mouselib;
interface
uses graphix,gxtype,gxmouse,gximeff,gximg,crt;
type Pbutton=^Tbutton;
     Tbutton=record
      image,imagealloc,imageclick:pimage;
      w,h:integer;
      x,y:integer;
      stat:integer;
     end;

procedure buttoncreate(var b:Tbutton;x,y,w,h:integer;way,way2,way3:string);
function buttonstat(var b:tbutton):byte;

implementation
procedure buttoncreate(var b:Tbutton;x,y,w,h:integer;way,way2,way3:string);
begin
 b.x:=x;
 b.y:=y;
 b.w:=w;
 b.h:=h;
 loadimagefile(itdetect,way,b.image,0);
 loadimagefile(itdetect,way2,b.imagealloc,0);
 loadimagefile(itdetect,way3,b.imageclick,0);
 b.stat:=-1;
end;
function buttonstat(var b:tbutton):byte;
label 1;
begin
 if b.stat<>ismouseinarea(b.x,b.y,b.x+b.w,b.y+b.h) then
  begin
1: b.stat:=ismouseinarea(b.x,b.y,b.x+b.w,b.y+b.h);
   mouseoff;
   case b.stat of
    0:zoomimageC(b.x,b.y,b.x+b.w,b.y+b.h,b.image);
    128:zoomimageC(b.x,b.y,b.x+b.w,b.y+b.h,b.imagealloc);
    else zoomimageC(b.x,b.y,b.x+b.w,b.y+b.h,b.imageclick);
   end;
   mouseon;
  end;
 if b.stat>128 then
  begin
   waitbuttonreleased;
   if ismouseinarea(b.x,b.y,b.x+b.w,b.y+b.h)<128 then goto 1;
  end;
 buttonstat:=b.stat;
end;

begin
end.
