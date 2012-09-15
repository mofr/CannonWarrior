unit game_main_unit;
interface
uses game_other_funcs,game_types,gximg,graphix,gxtype,gxcrt,glib,gxmouse,
     gximeff,gxmedia,gxtext,gx2d,game_interface,game_sound,directsound,
     gxdrw,sysutils;

const
  battle_field_sizex=17;
  battle_field_sizey=13;
  battle_bound_x1=50;
  battle_bound_x2=50;
  battle_bound_y1=50;
  battle_bound_y2=50;
  grid_line_pat:longint=528;
  grid_line_bits:longint=10;

var
   outFile:text;

   camera:Tcamera;
   scr_cell_sizex,scr_cell_sizey,cur_screenx,cur_screeny
      :word;
   curmap:Tmap;
   player:Pplayer;
   main_quit:boolean;
   gametime_koef,scroll_delay:double;
   gametime:record
      year,month,day,hour,min:double;
      end;
   loop_timer,scroll_timer:pgtimer;
   can_scroll:boolean;
   max_night_intension,max_dist_from_board:integer;
   day_night_change,show_coords,show_fps,show_day_night_indicator,
    camera_on_player:boolean;
   fps:double;
   txt:tfontFNT;

   IDS:IDirectsound;
   gamesound:Tsound;

   mainBG,mainBG2,event_msg_BG,screenimg:pimage;

   char_window_height:integer;
   ipanel:packed record
    width:word;
    time,year,month,day:packed record
      x,y:word;
      bg:pimage;
      end;
    characters:packed record
      bgimg:pimage;
      cur_object:Pobject_;
      end;
    end;

   message_box:Tmessage_box;

   night,day:record
    begin_,end_,middle:longint;
    end;

   day_night_indicator:packed record
    cornerimg,img,frameimg:pimage;
    x,y:integer;
    end;

   iframe:Tframe;

   cursor:array[0..10]of pimage;
   cur_cursor:byte;
   mx,my:longint;

   gr_mode_resx,gr_mode_resy,gr_mode_kol_colors:word;
   screnshotimagetype:Timagetype;
   {battle}
  battle_obj1,battle_obj2:Pobject_;
  battle_end:boolean;
  winner:pointer;
  battle_main_background:pimage;
  battle_field:array[1..battle_field_sizex,1..battle_field_sizey]of Pcharacter;
  battle_show_grid,battle_show_passable_cells,
    battle_char_moving:boolean;
  battle_cur_char:Pcharacter;
  old_mousebutton,battle_force1EXPreward,battle_force2EXPreward:longint;
  battle_queue_kol,battle_queue_cur:byte;
  battle_queue:array[1..12]of Pcharacter;
  battle_cur_char_prelight_int,battle_cur_char_prelight_int_step:integer;
  battle_msgbox:Tmessage_box;
   {\battle}

procedure load_frame_from_folder(var frame:Tframe;path:string);
procedure load_map(var map:Tmap;path:string;map_properties_load,objects_load:boolean);
procedure destroy_map(var map:Tmap);
procedure main_loop;
procedure start_animation;
procedure event_message(path:string);
procedure load_images;
procedure load_cursor_images(path:string);
procedure clear_keyboard;
procedure create_new_player;
function cell_passable(x,y:longint;var cell_obj:Pobject_):byte;
procedure draw_frame(fr:Tframe;x1,y1,x2,y2:longint;targetimg:pimage);
procedure draw_cursor(targetimg:pimage);
procedure draw_fps_str(targetimg:pimage);
procedure draw_char_attributes(x1,y1,x2,y2:longint;char:Pcharacter;targetimg:pimage);
procedure new_obj_graph(var p:Pobjgraph;anim_:byte;img_path:string;imgposh,imgposv,sizex,sizey:byte);
function get_gr_image(gr:Tobjgraph):pointer;
function get_obj_char_kol(obj:Pobject_):integer;
procedure destroy_object(var obj:Pobject_);
procedure game_over;

implementation
{$include game_characters.inc}

procedure createscreenimage(dr_cur:boolean);forward;

procedure screen_shot;
begin
createscreenimage(false);
case screnshotimagetype of
  itbmp:saveimageBMP('screenshots\screenshot'+int_to_str(datetimetotimestamp(now).time)+'.bmp',screenimg);
  ittga:saveimageTGA('screenshots\screenshot'+int_to_str(datetimetotimestamp(now).time)+'.tga',screenimg);
  end;
destroyimage(screenimg);
end;

function mouse_in_trans_color(img:pimage;x1,y1:longint):boolean;
var mx,my:longint;
begin
mousecoords(mx,my);
mouse_in_trans_color:=imagegetpixel(img,mx-x1,my-y1)=getimagetransparencycolor(img);
end;

procedure draw_progressive_bar(x,y,w,h,fullpart:integer;dir:byte;col:longint;targetimg:pimage);
begin
case dir of
  0:imagebar(targetimg,x,y,x+w*fullpart div 100,y+h,col);
  1:imagebar(targetimg,x,y,x+w,y+h*fullpart div 100,col);
  end;
end;

{$include game_path_search.inc}
{$include game_battle.inc}

procedure create_new_player;
begin
new(player);
new(player^.obj);
player^.obj^.x:=3;
player^.obj^.y:=5;
player^.obj^.primary:=1;
player^.obj^.type_:=ot_character_group;
player^.direc:=1;
player^.imgposV:=2;
player^.imgposH:=1;
loadimagefile(itdetect,'pic\player\1\d1.gif',player^.images[1],0);
loadimagefile(itdetect,'pic\player\1\d1.gif',player^.images[2],0);
loadimagefile(itdetect,'pic\player\1\d1.gif',player^.images[3],0);
loadimagefile(itdetect,'pic\player\1\d1.gif',player^.images[4],0);
loadimagefile(itdetect,'pic\player\1\d1.gif',player^.images[5],0);
loadimagefile(itdetect,'pic\player\1\d1.gif',player^.images[6],0);
loadimagefile(itdetect,'pic\player\1\d1.gif',player^.images[7],0);
loadimagefile(itdetect,'pic\player\1\d1.gif',player^.images[8],0);
player^.tr_inf.step_timer:=g_timer_new;
player^.tr_inf.can_step:=true;
player^.tr_inf.step_cooldown_time:=0.01;
player^.tr_inf.cur_way_step:=0;
player^.tr_inf.cur_offstep:=0;
player^.tr_inf.num_steps:=5;
player^.tr_inf.xoff:=0;
player^.tr_inf.yoff:=0;
{characters}
player^.obj^.chars[1]:=nil;
player^.obj^.chars[2]:=nil;
player^.obj^.chars[3]:=nil;
player^.obj^.chars[4]:=nil;
player^.obj^.chars[5]:=nil;
player^.obj^.chars[6]:=nil;
new(player^.obj^.chars[1]);
with player^.obj^.chars[1]^ do
  begin
  level:=1;
  EXP:=0;
  attr_points:=0;
  name:='главный герой';
  new_obj_graph(gr,0,'pic\characters\pelling.gif',1,2,1,1);
  dex:=20;
  str:=23;
  vit:=15;
  mag:=20;
  set_character_derivative_parameters(player^.obj^.chars[1]);
  bat:=nil;
  end;
player^.obj^.gr:=player^.obj^.chars[player^.obj^.primary]^.gr;
end;

procedure load_frame_from_folder(var frame:Tframe;path:string);
begin
with frame do
  begin
  loadimagefile(itdetect,path+'\frame1.tga',fr[1],0);
  loadimagefile(itdetect,path+'\frame2.tga',fr[2],0);
  loadimagefile(itdetect,path+'\frame3.tga',fr[3],0);
  loadimagefile(itdetect,path+'\frame4.tga',fr[4],0);
  loadimagefile(itdetect,path+'\corner1.tga',corn[1],0);
  loadimagefile(itdetect,path+'\corner2.tga',corn[2],0);
  loadimagefile(itdetect,path+'\corner3.tga',corn[3],0);
  loadimagefile(itdetect,path+'\corner4.tga',corn[4],0);
  end;
end;

procedure draw_frame(fr:Tframe;x1,y1,x2,y2:longint;targetimg:pimage);
var i:integer;
    timg:pimage;
begin
  timg:=createimageWH(x2-x1,y2-y1);
  fillimage(timg,getimagetransparencycolor(timg));
  for i:=0 to (y2-y1)div getimageheight(fr.fr[1])+1 do
    composeimagec(timg,fr.fr[1],0,i*getimageheight(fr.fr[1]));
  for i:=0 to (x2-x1)div getimagewidth(fr.fr[2])+1 do
    composeimagec(timg,fr.fr[2],i*getimagewidth(fr.fr[2]),0);
  for i:=0 to (y2-y1)div getimageheight(fr.fr[3])+1 do
    composeimagec(timg,fr.fr[3],x2-x1-getimagewidth(fr.fr[3]),i*getimageheight(fr.fr[3]));
  for i:=0 to (x2-x1)div getimagewidth(fr.fr[4])+1 do
    composeimagec(timg,fr.fr[4],i*getimagewidth(fr.fr[4]),y2-y1-getimageheight(fr.fr[4]));
  composeimagec(timg,fr.corn[1],0,0);
  composeimagec(timg,fr.corn[2],x2-x1-getimagewidth(fr.corn[2]),0);
  composeimagec(timg,fr.corn[3],x2-x1-getimagewidth(fr.corn[3]),y2-y1-getimageheight(fr.corn[3]));
  composeimagec(timg,fr.corn[4],0,y2-y1-getimageheight(fr.corn[4]));
  composeimagec(targetimg,timg,x1,y1);
  destroyimage(timg);
end;

procedure composeimagetrans(target:pimage;x,y:longint;img:pimage;alpha:byte);
var bg,t2:pimage;
begin
t2:=createimageWH(getimagewidth(img),getimageheight(img));
t2:=cloneimage(img);
bg:=createimageWH(getimagewidth(img),getimageheight(img));
setimageflags(bg,img_transparency);
fillimage(bg,getimagetransparencycolor(bg));
composeimagec(bg,img,0,0);
imagegetimage(target,x,y,bg);
blendimageALPHAimage(t2,t2,alpha,bg);
composeimagec(target,t2,x,y);
destroyimage(bg);
destroyimage(t2);
end;

procedure draw_bar(template:pimage;x1,y1,x2,y2:longint;targetimg:pimage);
var i,j:integer;
    timg:pimage;
begin
timg:=createimageWH(x2-x1,y2-y1);
fillimage(timg,getimagetransparencycolor(timg));
for i:=0 to (x2-x1)div getimagewidth(template) do
for j:=0 to (y2-y1)div getimageheight(template) do
  composeimagec(timg,template,i*getimagewidth(template),j*getimageheight(template));
composeimagec(targetimg,timg,x1,y1);
destroyimage(timg);
end;

procedure draw_fps_str(targetimg:pimage);
var s1:string;
begin
txt.setimage(targetimg);
str(fps:3:2,s1);
txt.outtext(10,10,'FPS: '+s1,rgbcolorrgb(250,250,250));
end;

procedure draw_cursor(targetimg:pimage);
var mx,my:longint;
begin
mousecoords(mx,my);
case cur_cursor of
  4:begin
    mx:=mx-getimagewidth(cursor[cur_cursor]);
    my:=my-getimageheight(cursor[cur_cursor]);
    end;
  3:begin
    mx:=mx-getimagewidth(cursor[cur_cursor]);
    end;
  5:begin
    my:=my-getimageheight(cursor[cur_cursor]);
    end;
  6:begin
    my:=my-getimageheight(cursor[cur_cursor]);
    end;
  2:begin
    mx:=mx-getimagewidth(cursor[cur_cursor]);
    end;
  end;
composeimagec(targetimg,cursor[cur_cursor],mx,my);
end;

procedure draw_char_attributes(x1,y1,x2,y2:longint;char:Pcharacter;targetimg:pimage);
var timg:pimage;
	width,height,part1,part2,part3,part4,sep,top,b1,b2:longint;
begin
width:=abs(x2-x1);
height:=abs(y2-y1);
timg:=createimageWH(width,height);
fillimage(timg,getimagetransparencycolor(timg));
draw_bar(mainBG2,0,0,width,height,timg);
if char<>nil then
	begin
	curfontsize:=3;
  part1:=height*10 div 100;{title}
  part2:=height*14 div 100;{lvl,exp}
  part3:=height*28 div 100;{str,dex,vit,int}
  part4:=height*42 div 100;{dmg,armor,defense,attack,HP,MP}
  sep:=(height-part1-part2-part3-part4)div 3;
  setcurrentcolor(30,30,30);
{  imageline(timg,0,part1,width,part1,rgbcolorrgb(255,255,255));
  imageline(timg,0,part1+part2,width,part1+part2,rgbcolorrgb(255,255,255));
  imageline(timg,0,part1+part2+part3,width,part1+part2+part3,rgbcolorrgb(255,255,255));
  imageline(timg,0,part1+part2+part3+part4,width,part1+part2+part3+part4,rgbcolorrgb(255,255,255));}
  outtext(width div 2,part1 div 2,char^.name,1,1,timg);
  curfontsize:=4;
  b1:=width div 20;
  b2:=width-width div 5;
  top:=part1;
  outtext(b1,top+part2*0 div 2+part2 div 4,'уровень '+int_to_str(char^.level),0,1,timg);
  outtext(b1,top+part2*1 div 2+part2 div 4,'опыт '+int_to_str(char^.exp)+'/'+int_to_str(char^.nextexp),0,1,timg);
  top:=top+part2+sep;
  outtext(b1,top+part3*0 div 4+part3 div 8,'сила '+int_to_str(char^.str),0,1,timg);
  outtext(b1,top+part3*1 div 4+part3 div 8,'ловкость '+int_to_str(char^.dex),0,1,timg);
  outtext(b1,top+part3*2 div 4+part3 div 8,'выносливость '+int_to_str(char^.vit),0,1,timg);
  outtext(b1,top+part3*3 div 4+part3 div 8,'интеллект '+int_to_str(char^.mag),0,1,timg);
  top:=top+part3+sep;
  outtext(b1,top+part4*0 div 6+part4 div 12,'здоровье '+int_to_str(char^.hp.t1)+'/'+int_to_str(char^.hp.t2),0,1,timg);
  outtext(b1,top+part4*1 div 6+part4 div 12,'мана '+int_to_str(char^.mp.t1)+'/'+int_to_str(char^.mp.t2),0,1,timg);
  outtext(b1,top+part4*2 div 6+part4 div 12,'урон '+int_to_str(char^.damage.t1)+'-'+int_to_str(char^.damage.t2),0,1,timg);
  outtext(b1,top+part4*3 div 6+part4 div 12,'атака '+int_to_str(char^.attack),0,1,timg);
  outtext(width div 20,top+part4*4 div 6+part4 div 12,'броня '+int_to_str(char^.armor),0,1,timg);
  outtext(b1,top+part4*5 div 6+part4 div 12,'защита '+int_to_str(char^.defense),0,1,timg);
  end
else begin
	blendimagealpha(timg,timg,190);
	end;
composeimagec(targetimg,timg,x1,y1);
destroyimage(timg);
end;

function dialog_window(text:string):boolean;
var
  scr:pimage;
  but_ok,but_cancel:Pbutton;
  x1,x2,y1,y2,x,sx,sy:integer;
begin
createscreenimage(false);
g_timer_stop(loop_timer);
curfontsize:=2.5;
sx:=getmaxx div 2;
sy:=round(0.6*sx);
x1:=getmaxx div 2-sx div 2;
y1:=getmaxy div 2-sy div 2;
x2:=getmaxx div 2+sx div 2;
y2:=getmaxy div 2+sy div 2;
scr:=createimageWH(getmaxx,getmaxy);

but_ok:=new_button(0,0,1,1,nil,'pic\interface\buttons\ok');
but_cancel:=new_button(0,0,1,1,nil,'pic\interface\buttons\cancel');
but_ok^.x1:=x1+(sx-(but_ok^.x2-but_ok^.x1)-(but_cancel^.x2-but_cancel^.x1)-getmaxx div 30)div 2;
but_ok^.x2:=but_ok^.x1+getimagewidth(but_ok^.img[0]);
but_ok^.y1:=y2-getimageheight(but_ok^.img[0])-sy div 10;
but_ok^.y2:=but_ok^.y1+getimageheight(but_ok^.img[0]);
but_cancel^.x1:=but_ok^.x2+getmaxx div 30;
but_cancel^.y1:=but_ok^.y1;
but_cancel^.x2:=but_cancel^.x1+getimagewidth(but_cancel^.img[0]);
but_cancel^.y2:=but_cancel^.y1+getimageheight(but_cancel^.img[0]);
cur_cursor:=0;
repeat
  composeimagec(scr,screenimg,0,0);
  draw_bar(event_msg_BG,x1,y1,x1+sx,y1+sy,scr);
  draw_frame(iframe,x1,y1,x1+sx,y1+sy,scr);

  update_button(but_ok);
  update_button(but_cancel);
  draw_button(but_ok,scr);
  draw_button(but_cancel,scr);
  setcurrentcolor(0,0,60);
  outtext(x1+sx div 2,y1+(but_ok^.y1-y1)div 2,text,1,1,scr);

  draw_cursor(scr);
  putimagec(0,0,scr);
until (but_ok^.lastaction=but_act_release)or(but_cancel^.lastaction=but_act_release);
if but_ok^.lastaction=but_act_release then dialog_window:=true else dialog_window:=false;
destroy_button(but_ok);
destroy_button(but_cancel);
destroyimage(scr);
destroyimage(screenimg);
clear_keyboard;
g_timer_start(loop_timer);
end;

procedure load_images;
begin
{interface}
loadimagefile(itdetect,'pic\interface\timebg.tga',ipanel.time.bg,0);
loadimagefile(itdetect,'pic\interface\yearbg.tga',ipanel.year.bg,0);
loadimagefile(itdetect,'pic\interface\monthbg.tga',ipanel.month.bg,0);
loadimagefile(itdetect,'pic\interface\ipanel_char_bg.gif',ipanel.characters.bgimg,0);
loadimagefile(itdetect,'pic\interface\daybg.tga',ipanel.day.bg,0);
loadimagefile(itdetect,'pic\interface\event_msg_bg.gif',event_msg_BG,0);
loadimagefile(itdetect,'pic\interface\mainbg.gif',mainBG,0);
loadimagefile(itdetect,'pic\interface\mainbg2.gif',mainBG2,0);
loadimagefile(itdetect,'pic\interface\day_night_indicator.gif',day_night_indicator.img,0);
loadimagefile(itdetect,'pic\interface\day_night_indicator_frame.gif',day_night_indicator.frameimg,0);
loadimagefile(itdetect,'pic\interface\day_night_indicator_corner.gif',day_night_indicator.cornerimg,0);
load_frame_from_folder(iframe,'pic\interface\fr1');
end;

procedure load_cursor_images(path:string);
var i:integer;
begin
loadimagefile(itdetect,path+'\normal.gif',cursor[0],0);
loadimagefile(itdetect,path+'\scroll1.gif',cursor[1],0);
loadimagefile(itdetect,path+'\scroll2.gif',cursor[2],0);
loadimagefile(itdetect,path+'\scroll3.gif',cursor[3],0);
loadimagefile(itdetect,path+'\scroll4.gif',cursor[4],0);
loadimagefile(itdetect,path+'\scroll5.gif',cursor[5],0);
loadimagefile(itdetect,path+'\scroll6.gif',cursor[6],0);
loadimagefile(itdetect,path+'\scroll7.gif',cursor[7],0);
loadimagefile(itdetect,path+'\scroll8.gif',cursor[8],0);
loadimagefile(itdetect,path+'\action.gif',cursor[10],0);
end;

procedure draw_player(dx,dy:longint;targetimg:pimage);
var xo,yo:integer;
begin
if player<>nil then
   begin
   xo:=0;
   yo:=0;
   case player^.imgposH of
      1:xo:=scr_cell_sizex div 2-getimagewidth(player^.images[player^.direc])div 2;
      2:xo:=scr_cell_sizex-getimagewidth(player^.images[player^.direc]);
      end;
   case player^.imgposV of
      1:yo:=scr_cell_sizey div 2-getimageheight(player^.images[player^.direc])div 2;
      2:yo:=scr_cell_sizey-getimageheight(player^.images[player^.direc]);
      end;
    composeimagec(targetimg,player^.images[player^.direc],(player^.obj^.x-dx)*scr_cell_sizex+xo+player^.tr_inf.xoff,(player^.obj^.y-dy)*scr_cell_sizey+yo+player^.tr_inf.yoff);
   end;
end;

function get_gr_image(gr:Tobjgraph):pointer;
begin
if gr.animated then get_gr_image:=gr.anim^.pl^.framebuf
  else get_gr_image:=gr.img;
end;

procedure draw_graphic(gr:Tobjgraph;x,y:longint;targetimg:pimage);
begin
composeimagec(targetimg,get_gr_image(gr),x,y);
end;

function get_obj_img_posx(obj:Pobject_;camx:longint):longint;
var xo:integer;
begin
xo:=0;
case obj^.gr^.imgposH of
  1:xo:=(obj^.gr^.sizex*scr_cell_sizex) div 2-getimagewidth(get_gr_image(obj^.gr^))div 2;
  2:xo:=(obj^.gr^.sizex*scr_cell_sizex)-getimagewidth(get_gr_image(obj^.gr^));
  end;
get_obj_img_posx:=(obj^.x-camx)*scr_cell_sizex+xo;
end;

function get_obj_img_posy(obj:Pobject_;camy:longint):longint;
var yo:integer;
begin
yo:=0;
case obj^.gr^.imgposV of
  1:yo:=(obj^.gr^.sizey*scr_cell_sizey) div 2-getimageheight(get_gr_image(obj^.gr^))div 2;
  2:yo:=(obj^.gr^.sizey*scr_cell_sizey)-getimageheight(get_gr_image(obj^.gr^));
  end;
get_obj_img_posy:=(obj^.y-camy)*scr_cell_sizey+yo;
end;

function get_prelight_obj:Pobject_;
var mx,my,i:longint;
    obj:Pobject_;
begin
obj:=nil;
mousecoords(mx,my);
i:=0;
while (i<=curmap.kol_objects-1) do
	begin
  if curmap.objects[i]<>nil then
  if (ismouseinarea(
  	get_obj_img_posx(curmap.objects[i],camera.x),
  	get_obj_img_posy(curmap.objects[i],camera.y),
  	get_obj_img_posx(curmap.objects[i],camera.x)+getimagewidth(get_gr_image(curmap.objects[i]^.gr^)),
  	get_obj_img_posy(curmap.objects[i],camera.y)+getimageheight(get_gr_image(curmap.objects[i]^.gr^)))<>0)
  and(imagegetpixel(get_gr_image(curmap.objects[i]^.gr^),mx-get_obj_img_posx(curmap.objects[i],camera.x),my-get_obj_img_posy(curmap.objects[i],camera.y))<>getimagetransparencycolor(get_gr_image(curmap.objects[i]^.gr^)))
  and(curmap.objects[i]^.type_<>ot_terrain)
  	then obj:=curmap.objects[i];
	inc(i);
  end;
get_prelight_obj:=obj;
end;

procedure draw_object(obj:Pobject_;camx,camy:longint;targetimg:pimage);
begin
draw_graphic(obj^.gr^,get_obj_img_posx(obj,camx),get_obj_img_posy(obj,camy),targetimg);
end;

procedure put_in_order_camera;
begin
if camera.x<0 then camera.x:=0;
if camera.y<0 then camera.y:=0;
if camera.x+cur_screenx>curmap.sizex then camera.x:=curmap.sizex-cur_screenx;
if camera.y+cur_screeny>curmap.sizey then camera.y:=curmap.sizey-cur_screeny;
end;

function get_obj_char_kol(obj:Pobject_):integer;
var res,i:integer;
begin
res:=0;
for i:=1 to 6 do if obj^.chars[i]<>nil then res:=res+1;
get_obj_char_kol:=res;
end;

procedure destroy_object(var obj:Pobject_);
var j:integer;
begin
if obj<>nil then
  begin
  if obj^.type_=ot_character_group then
  for j:=1 to 6 do
  if obj^.chars[j]<>nil then
    dispose(obj^.chars[j]);
  freemem(obj,sizeof(obj^));
  end;
obj:=nil;
end;

procedure destroy_map(var map:Tmap);
var i,j:longint;
begin
for i:=0 to map.kol_passmaps-1 do freemem(map.passmaps[i],sizeof(map.passmaps[i]^));
for i:=0 to map.kol_objects-1 do destroy_object(map.objects[i]);
for i:=0 to map.kol_obj_graphs-1 do
  begin
  if map.obj_graphs[i]^.animated then
    begin
    dispose(map.obj_graphs[i]^.anim^.pl,closemedia);
    g_timer_destroy(map.obj_graphs[i]^.anim^.frametimer);
    freemem(map.obj_graphs[i]^.anim,sizeof(map.obj_graphs[i]^.anim^));
    end
  else
    begin
    destroyimage(map.obj_graphs[i]^.img);
    end;
  freemem(map.obj_graphs[i],sizeof(map.obj_graphs[i]^));
  end;
map.kol_objects:=0;
map.kol_obj_graphs:=0;
map.kol_passmaps:=0;
end;

procedure new_obj_graph(var p:Pobjgraph;anim_:byte;img_path:string;imgposh,imgposv,sizex,sizey:byte);
begin
new(p);
case anim_ of
0:begin
  p^.animated:=false;
  loadimagefile(itdetect,img_path,p^.img,0);
  end;
1:begin
  p^.animated:=true;
  new(p^.anim);
  new(p^.anim^.pl,openmedia(img_path));
  p^.anim^.pl^.setrendermode(gmrm_transparency);
  p^.anim^.pl^.grabframe;
  p^.anim^.frametimer:=g_timer_new;
  p^.anim^.paused:=false;
  end;
end;
p^.imgposh:=imgposh;
p^.imgposv:=imgposv;
p^.sizex:=sizex;
p^.sizey:=sizey;
end;

procedure load_map(var map:Tmap;path:string;map_properties_load,objects_load:boolean);
var mapf,f,f2:text;
    s1,s2:ansistring;
    tgr:Pobjgraph;
    tpass:Ppassmap;
    file2path,param_str:string;
    obj_indx,kol_obj_in_str,i,j,sizex,sizey,i2,j2:longint;
    typ:object_type;

begin
assign(mapf,path);
{$i-}reset(mapf);{$i+}
if ioresult=0 then
   begin
   map.kol_objects:=0;
   map.kol_obj_graphs:=0;
   map.kol_passmaps:=0;
   writeln(outFile,'Map loading(',path,')...');
   {LOADING}
   while not eof(mapf) do
   begin
   readln(mapf,s1);
   s1:=str_wo_str_between(s1,'*');
   {MAP PROPERTIES}
   if map_properties_load then
   if (pos('\map',s1)<>0) then
         begin
         readln(mapf,s1);
         map.name:=str_between(s1,'"',1);
         readln(mapf,s1);
         map.sizex:=str_value(s1,1);
         readln(mapf,s1);
         map.sizey:=str_value(s1,1);
         end;
   {\MAP PROPERTIES}
   {OBJECTS}
   if objects_load then
   if (pos('\objects',s1)<>0) then
      while (pos('\end objects',s1)=0)do
         begin
         readln(mapf,s1);
         file2path:=str_between(s1,'"',1);
         if (pos('\end objects',s1)=0)then
         begin
         {open file with object parameters}
         assign(f,file2path);
         {$i-}reset(f);{$i+}
         if ioresult<>0 then writeln(outFile,'File not found: <',file2path,'>');
         {\open file with object parameters}
         readln(f,s2);
               if str_between(s2,'"',1)='structure' then typ:=ot_structure;
               if str_between(s2,'"',1)='passage area' then typ:=ot_passage_area;
               if str_between(s2,'"',1)='simple structure' then typ:=ot_simple_structure;
               if str_between(s2,'"',1)='doodad' then typ:=ot_doodad;
               if str_between(s2,'"',1)='terrain' then typ:=ot_terrain;
               if str_between(s2,'"',1)='character group' then typ:=ot_character_group;
         if typ<>ot_character_group then
          begin
               readln(f,s2);
               sizex:=str_value(s2,4);
               sizey:=str_value(s2,5);
               new_obj_graph(map.obj_graphs[map.kol_obj_graphs],str_value(s2,1),str_between(s2,'"',1),str_value(s2,2),str_value(s2,3),sizex,sizey);
               tgr:=map.obj_graphs[map.kol_obj_graphs];
               inc(map.kol_obj_graphs);
               {passmap}
               new(map.passmaps[map.kol_passmaps]);
               for i:=0 to sizey-1 do
                begin
                readln(f,s2);
                for j:=0 to sizex-1 do
                  begin
                  val(s2[j+1],map.passmaps[map.kol_passmaps]^[j,i]);
                  end;
                end;
               tpass:=map.passmaps[map.kol_passmaps];
               inc(map.kol_passmaps);
               {\passmap}
          end;
         {load coordinates}
         repeat readln(mapf,s1) until pos('{',s1)<>0;
         readln(mapf,s1);

         while pos('}',s1)=0 do
            begin
            kol_obj_in_str:=0;
            while str_between(s1,'"',kol_obj_in_str+1)<>'' do inc(kol_obj_in_str);
            for obj_indx:=1 to kol_obj_in_str do
               begin
               new(map.objects[map.kol_objects]);
               map.objects[map.kol_objects]^.type_:=typ;
               map.objects[map.kol_objects]^.x:=str_value(str_between(s1,'"',obj_indx),1);
               map.objects[map.kol_objects]^.y:=str_value(str_between(s1,'"',obj_indx),2);

               if typ<>ot_character_group then
                begin
                reset(f);
                for i:=1 to sizey+2 do readln(f,s2);
                readln(f,s2);
                map.objects[map.kol_objects]^.name:=str_between(s2,'"',1);
                map.objects[map.kol_objects]^.gr:=tgr;
                map.objects[map.kol_objects]^.gr^.passmap:=tpass;
                end;

               {load private object parameters}
               param_str:=str_between(str_between(s1,'"',obj_indx),'~',1);
               case typ of
                ot_passage_area:with map.objects[map.kol_objects]^.passage_area do
                  begin
                  route:=str_between(param_str,'.',1);
                  player_new_posx:=str_value(str_between(param_str,'.',2),1);
                  player_new_posy:=str_value(str_between(param_str,'.',2),2);
                  camera_new_posx:=str_value(str_between(param_str,'.',3),1);
                  camera_new_posy:=str_value(str_between(param_str,'.',3),2);
                  end;
                ot_character_group:
                  begin
                  for i:=1 to 6 do
                  if str_between(param_str,'|',i)<>'*' then
                    begin
                    new(map.objects[map.kol_objects]^.chars[i]);
                    assign(f2,str_between(param_str,'|',i));
                    {$i-}reset(f2);{$i+}
                    if ioresult<>0 then
                    	begin
                    	writeln(outfile,'File not found<',str_between(param_str,'|',i),'>');
                      close(f2);
                      halt;
                      end;
                    map.objects[map.kol_objects]^.chars[i]^.exp:=0;
                    while not eof(f2) do
                      begin
                      readln(f2,s2);
                      if pos('name',s2)<>0 then map.objects[map.kol_objects]^.chars[i]^.name:=str_between(s2,'"',1);
                      if pos('battlegrpath',s2)<>0 then map.objects[map.kol_objects]^.chars[i]^.battlegrpath:=str_between(s2,'"',1);
                      if pos('lvl',s2)<>0 then map.objects[map.kol_objects]^.chars[i]^.level:=str_value(str_between(s2,'"',1),1);
                      if pos('vitality',s2)<>0 then map.objects[map.kol_objects]^.chars[i]^.vit:=str_value(str_between(s2,'"',1),1);
                      if pos('dexterity',s2)<>0 then map.objects[map.kol_objects]^.chars[i]^.dex:=str_value(str_between(s2,'"',1),1);
                      if pos('intellect',s2)<>0 then map.objects[map.kol_objects]^.chars[i]^.mag:=str_value(str_between(s2,'"',1),1);
                      if pos('strength',s2)<>0 then map.objects[map.kol_objects]^.chars[i]^.str:=str_value(str_between(s2,'"',1),1);
                      if pos('mapgrpath',s2)<>0 then
                        begin
                        writeln(outFile,str_between(s2,'"',1));
                        new_obj_graph(map.obj_graphs[map.kol_obj_graphs],str_value(s2,1),str_between(s2,'"',1),str_value(s2,2),str_value(s2,3),str_value(s2,4),str_value(s2,5));
                        map.objects[map.kol_objects]^.chars[i]^.gr:=map.obj_graphs[map.kol_obj_graphs];
                        inc(map.kol_obj_graphs);
                        end;
                      if pos('\passmap',s2)<>0 then
                        begin
                        {passmap}
                        new(map.passmaps[map.kol_passmaps]);
                        for i2:=0 to map.objects[map.kol_objects]^.chars[i]^.gr^.sizey-1 do
                          begin
                          readln(f2,s2);
                          for j2:=0 to map.objects[map.kol_objects]^.chars[i]^.gr^.sizex-1 do
                          begin
                          val(s2[j2+1],map.passmaps[map.kol_passmaps]^[j2,i2]);
                          end;
                        end;
                        map.objects[map.kol_objects]^.chars[i]^.gr^.passmap:=map.passmaps[map.kol_passmaps];
                        inc(map.kol_passmaps);
                        {\passmap}
                        end;
                      end;
                    close(f2);
                    map.objects[map.kol_objects]^.chars[i]^.exp:=str_value(str_wo_str_between(param_str,'|'),i+1);
                    set_character_derivative_parameters(map.objects[map.kol_objects]^.chars[i]);
                    {}
                    with map.objects[map.kol_objects]^.chars[i]^ do
                      begin
                      writeln(outFile,'name = "',name,'"');
                      writeln(outFile,'maxhp = ',hp.t2);
                      writeln(outFile,'maxmp = ',mp.t2);
                      writeln(outFile,'damage = ',damage.t1,'-',damage.t2);
                      writeln(outFile,'lvl = ',level);
                      writeln(outFile,'battle gr path = "',battlegrpath,'"');
                      end;
                    {}
                    map.objects[map.kol_objects]^.chars[i]^.bat:=nil;
                    map.objects[map.kol_objects]^.gr:=map.objects[map.kol_objects]^.chars[i]^.gr;
                    end else
                    begin
                    map.objects[map.kol_objects]^.chars[i]:=nil;
                    end;
                  map.objects[map.kol_objects]^.primary:=str_value(str_wo_str_between(param_str,'|'),1);
                  writeln(outfile,'primary character =',map.objects[map.kol_objects]^.primary);
                  map.objects[map.kol_objects]^.name:=str_between(param_str,'|',7);
                  end;
                end;{case}
               {\load private object parameters}
               inc(map.kol_objects);
               end;
            readln(mapf,s1);
            close(f);
            end;
         {\load coordinates}
         end;
      end;
   {\OBJECTS}
   end;
   {\LOADING}
   close(mapf);
   writeln(outFile);
   writeln(outFile,'MAP LOADED:');
   writeln(outFile,'name = ',map.name);
   writeln(outFile,'kol objects = ',map.kol_objects);
   writeln(outFile,'kol passmaps = ',map.kol_passmaps);
   writeln(outFile,'mem avail ',memavail);
   writeln(outFile,'max avail ',maxavail);
   writeln(outFile);
   end;
end;

procedure putinorder_gametime;
var stack:word;
begin
with gametime do
   begin
   stack:=trunc(min/60);
   min:=min-stack*60;
   hour:=hour+stack;

   stack:=trunc(hour/24);
   hour:=hour-stack*24;
   day:=day+stack;

   stack:=trunc(day/30);
   day:=day-stack*30;
   month:=month+stack;

   stack:=trunc(month/12);
   month:=month-stack*12;
   year:=year+stack;
   end;
end;

function point_in_object(x,y:longint;obj:Pobject_):boolean;
begin
point_in_object:=false;
if obj<>nil then
if (x>=obj^.x)and(y>=obj^.y)and(x<=obj^.x+obj^.gr^.sizex-1)and(y<=obj^.y+obj^.gr^.sizey-1)
  then point_in_object:=true;
end;

function mouse_on_char_panel:Pcharacter;
var mx,my:longint;
begin
mouse_on_char_panel:=nil;
if (ipanel.characters.cur_object<>nil)and(ipanel.characters.cur_object^.type_=ot_character_group)then
if ismouseinarea(getmaxx-ipanel.width,getmaxy-getimageheight(ipanel.characters.bgimg)*2,getmaxx,getmaxy)>0 then
	begin
  mousecoords(mx,my);
  mx:=mx-(getmaxx-ipanel.width);
  my:=my-(getmaxy-getimageheight(ipanel.characters.bgimg)*2);
  mx:=mx div getimagewidth(ipanel.characters.bgimg)+1;
  my:=my div getimageheight(ipanel.characters.bgimg)+1;
  if (my-1)*3+mx<=6 then
  mouse_on_char_panel:=ipanel.characters.cur_object^.chars[(my-1)*3+mx];
  end;
end;

function cell_passable(x,y:longint;var cell_obj:Pobject_):byte;
var result_:byte;
    i,tx,ty:longint;
begin
result_:=1;
i:=0;
while (i<curmap.kol_objects) do
  begin
      if (curmap.objects[i]<>nil)and point_in_object(x,y,curmap.objects[i])
      then
        begin
        tx:=x-curmap.objects[i]^.x;
        ty:=y-curmap.objects[i]^.y;
        result_:=curmap.objects[i]^.gr^.passmap^[tx,ty];
        end;
  inc(i);
  end;

if (x<0)or(y<0)or(x>curmap.sizex-1)or(y>curmap.sizey-1)
   then result_:=0;

cell_obj:=nil;
if result_<>1 then
for i:=0 to curmap.kol_objects-1 do
  if (curmap.objects[i]<>nil)and(point_in_object(x,y,curmap.objects[i]))
      then cell_obj:=curmap.objects[i];

cell_passable:=result_;
end;

procedure game_over;
var i:integer;
	timer:pgtimer;
  img:pimage;
begin
destroysound(gamesound);
loadsound(IDS,gamesound,'sounds\game_end1.wav',false);
playsound(gamesound,DSBplay_looping);
randomize;
bar(0,0,getmaxx+1,getmaxy+1,rgbcolorrgb(0,0,0));
{img:=createimageWH(getmaxx+1,getmaxy+1);
fillimage(img,rgbcolorrgb(0,0,0));
getimage(getmaxx,getmaxy,img);
timer:=g_timer_new;
g_timer_start(timer);
i:=1;
while (i<=250)and(not keypressed)and(mousebutton=0) do
	if g_timer_elapsed(timer,nil)>=0.01 then
	begin
	blendimagealpha(img,img,255-i);
  putimagec(getmaxx div 2-getimagewidth(img) div 2,getmaxy div 2-getimageheight(img) div 2,img);
  g_timer_reset(timer);
  inc(i);
  end;
g_timer_destroy(timer);
destroyimage(img);
img:=nil; }
main_quit:=true;
loadimagefile(itdetect,'pic\other\game_end'+int_to_str(1+random(2))+'.gif',screenimg,0);
img:=createimageWH(getimagewidth(screenimg),getimageheight(screenimg));
timer:=g_timer_new;
g_timer_start(timer);
i:=1;
while (i<=255)and(not keypressed)and(mousebutton=0) do
	if g_timer_elapsed(timer,nil)>=0.025 then
	begin
  copyimage(img,screenimg);
	blendimagealpha(img,img,i);
  putimagec(getmaxx div 2-getimagewidth(img) div 2,getmaxy div 2-getimageheight(img) div 2,img);
  g_timer_reset(timer);
  inc(i);
  end;
g_timer_destroy(timer);
destroyimage(img);
putimagec(getmaxx div 2-getimagewidth(screenimg) div 2,getmaxy div 2-getimageheight(screenimg) div 2,screenimg);
repeat until (keypressed) or (mousebutton<>0);
destroyimage(screenimg);
destroysound(gamesound);
end;

procedure map;
var mapimg,mapimgzoom,img:pimage;
    mx,my,cy,i,xo,yo:longint;
    zoom:double;
    ok_but:pbutton;
begin
zoom:=2;

mapimg:=createimageWH(round(scr_cell_sizex*curmap.sizex),round(scr_cell_sizey*curmap.sizey));
fillimage(mapimg,getimagetransparencycolor(mapimg));
{objects}
{terrain}
for i:=0 to curmap.kol_objects-1 do
  if curmap.objects[i]^.type_=ot_terrain then
  draw_object(curmap.objects[i],0,0,mapimg);
{\terrain}
for cy:=0 to curmap.sizey do
  begin
  for i:=0 to curmap.kol_objects-1 do
    if (curmap.objects[i]<>nil)and(curmap.objects[i]^.type_<>ot_terrain)then
    with curmap.objects[i]^ do
    if (y+gr^.sizey-1=cy) then
    draw_object(curmap.objects[i],0,0,mapimg);
  if (player^.obj^.y=cy)then draw_player(0,0,mapimg);
  end;
{\objects}
mapimgzoom:=createimageWH(round(scr_cell_sizex/zoom*curmap.sizex),round(scr_cell_sizey/zoom*curmap.sizey));
scaleimage(mapimgzoom,mapimg);
draw_frame(iframe,0,0,getimagewidth(mapimgzoom),getimageheight(mapimgzoom),mapimgzoom);

  g_timer_stop(loop_timer);
  ok_but:=new_button(getmaxx-ipanel.width-getimagewidth(iframe.fr[1])-100,getmaxy-message_box.height-getimageheight(iframe.fr[2])-50,1,1,nil,'pic\interface\buttons\ok');

  setmousearea(0,0,getmaxx-ipanel.width-getimagewidth(iframe.fr[1]),getmaxy-message_box.height-getimageheight(iframe.fr[2]));
  cur_cursor:=0;
  graphwin(0,0,getmaxx-ipanel.width,getmaxy-message_box.height);
  img:=createimageWH(getmaxx-ipanel.width,getmaxy-message_box.height);
  repeat
    begin
    if (mousebutton=1)and(zoom>2) then
      begin
      zoom:=zoom-0.1;
      destroyimage(mapimgzoom);
      mapimgzoom:=createimageWH(round(scr_cell_sizex/zoom*curmap.sizex),round(scr_cell_sizey/zoom*curmap.sizey));
      scaleimage(mapimgzoom,mapimg);
      draw_frame(iframe,0,0,getimagewidth(mapimgzoom),getimageheight(mapimgzoom),mapimgzoom);
      end;
    if (mousebutton=2)and(zoom<4) then
      begin
      zoom:=zoom+0.1;
      destroyimage(mapimgzoom);
      mapimgzoom:=createimageWH(round(scr_cell_sizex/zoom*curmap.sizex),round(scr_cell_sizey/zoom*curmap.sizey));
      scaleimage(mapimgzoom,mapimg);
      draw_frame(iframe,0,0,getimagewidth(mapimgzoom),getimageheight(mapimgzoom),mapimgzoom);
      end;

    draw_bar(event_msg_BG,0,0,getmaxx-ipanel.width,getmaxy-message_box.height,img);
    composeimagec(img,mapimgzoom,getimagewidth(img)div 2-getimagewidth(mapimgzoom)div 2,getimageheight(img)div 2-getimageheight(mapimgzoom)div 2);

    curfontsize:=1;
    setcurrentcolor(0,0,0);
    outtext((getmaxx-ipanel.width)div 2,gettextheight(curmap.name),curmap.name,1,1,img);

    update_button(ok_but);
    draw_button(ok_but,img);

    draw_frame(iframe,0,0,getmaxx-ipanel.width,getmaxy-message_box.height,img);
    draw_cursor(img);

    putimage(0,0,img);
    end
  until (ok_but^.lastaction=but_act_release)or((keypressed)and(readkey=#27));//mousebutton<>0;

  clear_keyboard;
  setmousearea(0,0,getmaxx,getmaxy);
  maxgraphwin;
  g_timer_start(loop_timer);
destroy_button(ok_but);
destroyimage(img);
destroyimage(mapimg);
destroyimage(mapimgzoom);
end;

procedure event_message(path:string);
var f:text;
    s:ansistring;
    i,mx,my,curstr,kolstr,prev:longint;
    img,txtimg:pimage;
    ok_but:pbutton;
begin
assign(f,path);

{$i-}reset(f);{$i+}
if ioresult=0 then
  begin
  g_timer_stop(loop_timer);
  ok_but:=new_button(getmaxx-ipanel.width-getimagewidth(iframe.fr[1])-100,getmaxy-message_box.height-getimageheight(iframe.fr[2])-50,1,1,nil,'pic\interface\buttons\ok');

  txtimg:=createimageWH(getmaxx-ipanel.width*2,getmaxy-message_box.height-ipanel.width div 2);
  curstr:=0;
  prev:=-1;
  while not eof(f) do begin readln(f);inc(kolstr);end;
  reset(f);

  setmousearea(0,0,getmaxx-ipanel.width-getimagewidth(iframe.fr[1]),getmaxy-message_box.height-getimageheight(iframe.fr[2]));
  graphwin(0,0,getmaxx-ipanel.width,getmaxy-message_box.height);
  repeat
    begin
    img:=createimageWH(getmaxx-ipanel.width,getmaxy-message_box.height);
    draw_bar(event_msg_BG,0,0,getmaxx-ipanel.width,getmaxy-message_box.height,img);

    if prev<>curstr then
      begin
      fillimage(txtimg,getimagetransparencycolor(txtimg));
      i:=0;
      setcurrentcolor(0,0,0);
      while (i<=getimageheight(txtimg))and not eof(f) do
        begin
        readln(f,s);
        outtext(0,i*gettextheight(s),s,0,0,txtimg);
        inc(i);
        end;
      end;
    prev:=curstr;

    composeimagec(img,txtimg,(getmaxx-ipanel.width-getimagewidth(txtimg))div 2,(getmaxy-message_box.height-getimageheight(txtimg))div 2);

    update_button(ok_but);
    draw_button(ok_but,img);

    draw_frame(iframe,0,0,getmaxx-ipanel.width,getmaxy-message_box.height,img);
    draw_cursor(img);

    putimage(0,0,img);
    destroyimage(img);
    end
  until (ok_but^.lastaction=but_act_release)or((keypressed)and(readkey=#27));//mousebutton<>0;

  close(f);
  clear_keyboard;
  setmousearea(0,0,getmaxx,getmaxy);
  destroy_button(ok_but);
  destroyimage(txtimg);
  maxgraphwin;
  g_timer_start(loop_timer);
  end;
end;

procedure clear_keyboard;
begin
while keypressed do readkey;
end;

procedure passage(psg:Tpassage_area);
begin
destroy_map(curmap);
load_map(curmap,psg.route,true,true);
player^.obj^.x:=psg.player_new_posx;
player^.obj^.y:=psg.player_new_posy;
camera.x:=psg.camera_new_posx;
camera.y:=psg.camera_new_posy;
put_in_order_camera;
waitbuttonreleased;
end;

procedure move_player(dir:byte;chdirec:boolean);
var dx,dy:longint;
    obj_:Pobject_;
begin
if chdirec then player^.direc:=dir;
with player^.obj^ do
case dir of
  1:begin dx:=x;dy:=y-1;end;
  2:begin dx:=x+1;dy:=y-1;end;
  3:begin dx:=x+1;dy:=y;end;
  4:begin dx:=x+1;dy:=y+1;end;
  5:begin dx:=x;dy:=y+1;end;
  6:begin dx:=x-1;dy:=y+1;end;
  7:begin dx:=x-1;dy:=y;end;
  8:begin dx:=x-1;dy:=y-1;end;
  end;
with player^ do
case cell_passable(dx,dy,obj_)of
  1:begin obj^.x:=dx;obj^.y:=dy;clear_keyboard;end;
  2:case obj_^.type_ of
    ot_passage_area:if dialog_window('перейти в другую локацию?') then passage(obj_^.passage_area);
    end;
  3:if dialog_window('напасть на "'+obj_^.name+'"?') then battle(obj,obj_);
  end;
{camera}
if camera_on_player then
  begin
  if player^.obj^.x-max_dist_from_board<camera.x then camera.x:=player^.obj^.x-max_dist_from_board;
  if player^.obj^.y-max_dist_from_board<camera.y then camera.y:=player^.obj^.y-max_dist_from_board;
  if player^.obj^.x+max_dist_from_board>camera.x+cur_screenx-1 then camera.x:=player^.obj^.x+max_dist_from_board-cur_screenx+1;
  if player^.obj^.y+max_dist_from_board>camera.y+cur_screeny-1 then camera.y:=player^.obj^.y+max_dist_from_board-cur_screeny+1;
  if camera.x<0 then camera.x:=0;
  if camera.y<0 then camera.y:=0;
  if camera.x+cur_screenx>curmap.sizex then camera.x:=curmap.sizex-cur_screenx;
  if camera.y+cur_screeny>curmap.sizey then camera.y:=curmap.sizey-cur_screeny;
  end;
end;

procedure player_issue_order(nx,ny:longint);
begin
if (player^.tr_inf.way.target_coor.T1<>nx)or(player^.tr_inf.way.target_coor.T2<>ny)
and (player^.tr_inf.cur_offstep=0)and player^.tr_inf.can_step then
  begin
  player^.tr_inf.way:=get_way(player^.obj^.x,player^.obj^.y,nx,ny,'map');
  player^.tr_inf.cur_way_step:=1;
  end;
end;

procedure _animations;
var i:integer;
begin
for i:=0 to curmap.kol_obj_graphs-1 do
  begin
  if curmap.obj_graphs[i]^.animated then
  if (g_timer_elapsed(curmap.obj_graphs[i]^.anim^.frametimer,nil)>curmap.obj_graphs[i]^.anim^.pl^.getframetime/1000)
  and not curmap.obj_graphs[i]^.anim^.paused then
    begin
    if curmap.obj_graphs[i]^.anim^.pl^.endofmedia then curmap.obj_graphs[i]^.anim^.pl^.startmedia;
    g_timer_reset(curmap.obj_graphs[i]^.anim^.frametimer);
//    fillimage(curmap.obj_graphs[i]^.anim^.pl^.framebuf,getimagetransparencycolor(curmap.obj_graphs[i]^.anim^.pl^.framebuf));
    curmap.obj_graphs[i]^.anim^.pl^.grabframe;
    end
  end;
end;

procedure start_animation;
var i:integer;
begin
for i:=0 to curmap.kol_obj_graphs-1 do
    if curmap.obj_graphs[i]^.animated then
    begin
    g_timer_start(curmap.obj_graphs[i]^.anim^.frametimer);
    curmap.obj_graphs[i]^.anim^.paused:=false;
    end;
end;

procedure stop_animation;
var i:integer;
begin
for i:=0 to curmap.kol_obj_graphs-1 do
    if curmap.obj_graphs[i]^.animated then
    begin
    g_timer_stop(curmap.obj_graphs[i]^.anim^.frametimer);
    curmap.obj_graphs[i]^.anim^.paused:=true;
    end;
end;

procedure _keyboard;
var action:char;
begin
if keypressed then
  begin
  action:=readkey;
  case action of
    #75:move_player(7,true);
    #77:move_player(3,true);
    #72:move_player(1,true);
    #80:move_player(5,true);
    '`':if show_fps then show_fps:=false else show_fps:=true;
    '1':if camera_on_player then camera_on_player:=false else camera_on_player:=true;
    '2':stop_animation;
    '3':start_animation;
    '5':if day_night_change then day_night_change:=false else day_night_change:=true;
    '6':if show_coords then show_coords:=false else show_coords:=true;
    '7':if show_day_night_indicator then show_day_night_indicator:=false else show_day_night_indicator:=true;
    'm':map;
    's':swapsoundstatus(gamesound);
    #27:main_quit:=true;
    #0:case readkey of
        #88:screen_shot;
        end;
    end;
  end;
end;

procedure _player;
begin
if player^.tr_inf.cur_way_step>player^.tr_inf.way.length then
  begin
  player^.tr_inf.way.target_coor.t1:=0;
  player^.tr_inf.way.target_coor.t2:=0;
  player^.tr_inf.way.length:=0;
  player^.tr_inf.cur_way_step:=1;
  end
  else
if (player^.tr_inf.cur_way_step>0)and(player^.tr_inf.cur_way_step<=player^.tr_inf.way.length)
   and player^.tr_inf.can_step then
  begin
  with player^.tr_inf do
    case player^.tr_inf.way.path[player^.tr_inf.cur_way_step] of
      1:yoff:=yoff-scr_cell_sizey div num_steps;
      2:begin xoff:=xoff+scr_cell_sizex div num_steps;yoff:=yoff-scr_cell_sizey div num_steps;end;
      3:xoff:=xoff+scr_cell_sizex div num_steps;
      4:begin xoff:=xoff+scr_cell_sizex div num_steps;yoff:=yoff+scr_cell_sizey div num_steps;end;
      5:yoff:=yoff+scr_cell_sizey div num_steps;
      6:begin xoff:=xoff-scr_cell_sizex div num_steps;yoff:=yoff+scr_cell_sizey div num_steps;end;
      7:xoff:=xoff-scr_cell_sizex div num_steps;
      8:begin xoff:=xoff-scr_cell_sizex div num_steps;yoff:=yoff-scr_cell_sizey div num_steps;end;
      end;
  inc(player^.tr_inf.cur_offstep);
  if player^.tr_inf.cur_offstep>=player^.tr_inf.num_steps then
    begin
    player^.tr_inf.cur_offstep:=0;
    player^.tr_inf.xoff:=0;
    player^.tr_inf.yoff:=0;
    move_player(player^.tr_inf.way.path[player^.tr_inf.cur_way_step],true);
    inc(player^.tr_inf.cur_way_step);
    end;
  g_timer_start(player^.tr_inf.step_timer);
  player^.tr_inf.can_step:=false;
  end;
if not player^.tr_inf.can_step and
  (g_timer_elapsed(player^.tr_inf.step_timer,nil)>=player^.tr_inf.step_cooldown_time/player^.tr_inf.num_steps) then
  begin
  player^.tr_inf.can_step:=true;
  g_timer_reset(player^.tr_inf.step_timer);
  g_timer_stop(player^.tr_inf.step_timer);
  end;
end;

procedure _mouse;
var
    pcx,pcy:longint;
    p:byte;
    s:string;
    prelight_obj:Pobject_;
begin
mousecoords(mx,my);
p:=cur_cursor;
{SCROLLING}
if not can_scroll then
  begin
  if (g_timer_elapsed(scroll_timer,nil)>scroll_delay)
    then
    begin
    can_scroll:=true;
    g_timer_stop(scroll_timer);
    g_timer_reset(scroll_timer);
    end;
  end;

if can_scroll then
begin
pcx:=camera.x;
pcy:=camera.y;
if (my<1) then
  begin
  dec(camera.y);
  cur_cursor:=1;
  end;
if (my>getmaxy-1) then
  begin
  inc(camera.y);
  cur_cursor:=5;
  end;
if (mx<1) then
  begin
  dec(camera.x);
  cur_cursor:=7;
  end;
if (mx>getmaxx-1) then
  begin
  inc(camera.x);
  cur_cursor:=3;
  end;
if (my<1)and(mx>getmaxx-1) then
  begin
  dec(camera.y);
  inc(camera.x);
  cur_cursor:=2;
  end;
if (my>getmaxy-1)and(mx<1) then
  begin
  inc(camera.y);
  dec(camera.x);
  cur_cursor:=6;
  end;
if (mx<1)and(my<1) then
  begin
  dec(camera.x);
  dec(camera.y);
  cur_cursor:=8;
  end;
if (mx>getmaxx-1)and(my>getmaxy-1) then
  begin
  inc(camera.x);
  inc(camera.y);
  cur_cursor:=4;
  end;
if ismouseinarea(1,1,getmaxx-1,getmaxy-1)<>0 then if cur_cursor<>0 then cur_cursor:=0;

put_in_order_camera;
if (pcx<>camera.x)or(pcy<>camera.y) then
  begin
  can_scroll:=false;
  g_timer_start(scroll_timer);
  end;
end;
{\SCROLLING}
if ismouseinarea(0,0,getmaxx-ipanel.width-getimagewidth(iframe.fr[1]),getmaxy-message_box.height-getimageheight(iframe.fr[2]))<>0 then
  begin
  if show_coords then
  begin
  str(mx div scr_cell_sizex+camera.x,s);
  message_box.message:=' ('+s+',';
  str(my div scr_cell_sizey+camera.y,s);
  message_box.message:=message_box.message+s+')';
  end;
  if (player^.obj^.x=mx div scr_cell_sizex+camera.x)and(player^.obj^.y=my div scr_cell_sizey+camera.y) then str_insert('главный герой',message_box.message,1) else
    begin
    prelight_obj:=nil;
    if (cell_passable(mx div scr_cell_sizex+camera.x,my div scr_cell_sizey+camera.y,prelight_obj)=2)
    or (cell_passable(mx div scr_cell_sizex+camera.x,my div scr_cell_sizey+camera.y,prelight_obj)=3)
      then if cur_cursor=0 then cur_cursor:=10;
    if (mousebutton=1)and(cell_passable(mx div scr_cell_sizex+camera.x,my div scr_cell_sizey+camera.y,prelight_obj)<>0)
      then player_issue_order(mx div scr_cell_sizex+camera.x,my div scr_cell_sizey+camera.y);
//    prelight_obj:=get_prelight_obj;
    if (prelight_obj<>nil) then
    	str_insert(prelight_obj^.name,message_box.message,1);
    if (prelight_obj<>nil)and(prelight_obj^.type_=ot_character_group) then ipanel.characters.cur_object:=prelight_obj;
    if prelight_obj=nil then ipanel.characters.cur_object:=player^.obj;
    end;
  end else
if ismouseinarea(ipanel.year.x,ipanel.year.y,ipanel.day.x+getimagewidth(ipanel.day.bg),ipanel.day.y+getimageheight(ipanel.day.bg))<>0 then
  begin
  message_box.message:='дата';
  end;
if ismouseinarea(ipanel.time.x,ipanel.time.y,ipanel.time.x+getimagewidth(ipanel.time.bg),ipanel.time.y+getimageheight(ipanel.time.bg))<>0 then
  begin
  message_box.message:='время';
  end;
end;

procedure createscreenimage(dr_cur:boolean);
var i,cx,cy,darkres,time:integer;
    c1,c2:longint;
    s1,s2:string;
    ttt:pimage;
begin
screenimg:=createimageWH(getmaxx,getmaxy);
{objects}
{terrain}
for i:=0 to curmap.kol_objects-1 do
  if curmap.objects[i]^.type_=ot_terrain then
  draw_object(curmap.objects[i],camera.x,camera.y,screenimg);
{\terrain}
for cy:=camera.y-10 to camera.y+cur_screeny+11 do
  begin
  for i:=0 to curmap.kol_objects-1 do
    if (curmap.objects[i]<>nil)and(curmap.objects[i]^.type_<>ot_terrain)then
    with curmap.objects[i]^ do
    if (y+gr^.sizey-1=cy) then
      begin
      draw_object(curmap.objects[i],camera.x,camera.y,screenimg);
      end;
  if (player^.obj^.y=cy)then draw_player(camera.x,camera.y,screenimg);
  end;
{\objects}

{darkening according game time}
if day_night_change then
begin
time:=round(gametime.hour*60+gametime.min);
if (time>=day.begin_)and(time<=day.end_) then darkres:=255 else
if (time>=night.end_+1)and(time<=day.begin_) then darkres:=max_night_intension+round((time-night.end_)*(255-max_night_intension)/(day.begin_-night.end_)) else
if (time>=day.end_)and(time<=night.begin_) then darkres:=255-round((time-day.end_)*(255-max_night_intension)/(night.begin_-day.end_))
else darkres:=max_night_intension;
if darkres<255 then blendimagealpha(screenimg,screenimg,darkres);
end;
{}
{day\night indicator}
if show_day_night_indicator then
begin
time:=round(gametime.hour*60+gametime.min);
i:=round((time-day.middle)/(day.middle-night.middle)*180);
i:=(i+360)mod 360;
with day_night_indicator do
ttt:=createimageWH(getimagewidth(img),getimageheight(img));
setimagetransparencycolor(ttt,rgbcolorrgb(255,255,255));
fillimage(ttt,getimagetransparencycolor(ttt));
with day_night_indicator do
rotateimage(ttt,img,getimagewidth(img)div 2,getimageheight(img)div 2,getimagewidth(img)div 2,getimageheight(img)div 2,getimagewidth(img),getimageheight(img),i*182);
composeimagec(screenimg,ttt,day_night_indicator.x-getimagewidth(ttt)div 2,day_night_indicator.y-getimageheight(ttt)div 2);
composeimagec(screenimg,day_night_indicator.cornerimg,day_night_indicator.x-getimagewidth(day_night_indicator.cornerimg),day_night_indicator.y);
composeimagec(screenimg,day_night_indicator.frameimg,day_night_indicator.x-getimagewidth(day_night_indicator.frameimg)div 2,day_night_indicator.y-getimageheight(day_night_indicator.frameimg)div 2);
destroyimage(ttt);
end;
{}
{frames}
draw_frame(iframe,0,0,getmaxx-ipanel.width,getmaxy-message_box.height,screenimg);
{}
{TIME}
c1:=round(gametime.hour);
c2:=round(gametime.min);
str(c1,s1);
str(c2,s2);
if length(s1)=1 then str_insert('0',s1,1);
if length(s2)=1 then str_insert('0',s2,1);
curfontsize:=3.5;

setcurrentcolor(0,0,0);
composeimagec(screenimg,ipanel.time.bg,ipanel.time.x,ipanel.time.y);
outtext(ipanel.time.x+getimagewidth(ipanel.time.bg)div 2-gettextlength(s1+':'+s2)div 2,
        ipanel.time.y+getimageheight(ipanel.time.bg)div 2-gettextheight(s1+':'+s2)div 2,s1+':'+s2,0,0,screenimg);
{year}
c1:=round(gametime.year);
str(c1,s1);
while length(s1)<4 do str_insert('0',s1,1);

composeimagec(screenimg,ipanel.year.bg,ipanel.year.x,ipanel.year.y);
outtext(ipanel.year.x+getimagewidth(ipanel.year.bg)div 2-gettextlength(s1)div 2,
        ipanel.year.y+getimageheight(ipanel.year.bg)div 2-gettextheight(s1)div 2,s1,0,0,screenimg);
{month}
c1:=round(gametime.month);
str(c1,s1);
if length(s1)=1 then str_insert('0',s1,1);

composeimagec(screenimg,ipanel.month.bg,ipanel.month.x,ipanel.month.y);
outtext(ipanel.month.x+getimagewidth(ipanel.month.bg)div 2-gettextlength(s1)div 2,
        ipanel.month.y+getimageheight(ipanel.month.bg)div 2-gettextheight(s1)div 2,s1,0,0,screenimg);
{day}
c1:=round(gametime.day);
str(c1,s1);
if length(s1)=1 then str_insert('0',s1,1);

composeimagec(screenimg,ipanel.day.bg,ipanel.day.x,ipanel.day.y);
outtext(ipanel.day.x+getimagewidth(ipanel.day.bg)div 2-gettextlength(s1)div 2,
        ipanel.day.y+getimageheight(ipanel.day.bg)div 2-gettextheight(s1)div 2,s1,0,0,screenimg);

{message_box}
draw_bar(message_box.bgimg,0,getmaxy-message_box.height,getmaxx-ipanel.width,getmaxy,screenimg);
curfontsize:=3;
outtext((getmaxx-ipanel.width)div 2,getmaxy-message_box.height+message_box.height div 2,message_box.message,1,1,screenimg);
draw_frame(iframe,0,getmaxy-message_box.height,getmaxx-ipanel.width,getmaxy,screenimg);
message_box.message:='';
{characters}
for i:=1 to 3 do composeimagec(screenimg,ipanel.characters.bgimg,getmaxx-ipanel.width+(i-1)*getimagewidth(ipanel.characters.bgimg),getmaxy-getimageheight(ipanel.characters.bgimg)*2);
for i:=1 to 3 do composeimagec(screenimg,ipanel.characters.bgimg,getmaxx-ipanel.width+(i-1)*getimagewidth(ipanel.characters.bgimg),getmaxy-getimageheight(ipanel.characters.bgimg));
if (ipanel.characters.cur_object<>nil)and(ipanel.characters.cur_object^.type_=ot_character_group) then
begin
for i:=1 to 6 do
  if ipanel.characters.cur_object^.chars[i]<>nil then
  begin
  draw_graphic(ipanel.characters.cur_object^.chars[i]^.gr^,
    getmaxx-ipanel.width+getimagewidth(ipanel.characters.bgimg)*(i-1-3*(i div 4))+getimagewidth(ipanel.characters.bgimg)div 2-getimagewidth(get_gr_image(ipanel.characters.cur_object^.gr^))div 2,
    getmaxy-getimageheight(ipanel.characters.bgimg)*(3*(i div 4+1)-(i div 4)*5)div 2-getimageheight(get_gr_image(ipanel.characters.cur_object^.gr^))div 2,screenimg);
  draw_progressive_bar(getmaxx-ipanel.width+getimagewidth(ipanel.characters.bgimg)*(i-3*(i div 4)-1)+(getimagewidth(ipanel.characters.bgimg)-40)div 2-1,
    getmaxy-getimageheight(ipanel.characters.bgimg)div(4*(i div 4)+1)-getimageheight(ipanel.characters.bgimg)*((6-i+1) div 4)div 6-1,42,4,100,0,rgbcolorrgb(150,150,0),screenimg);
  draw_progressive_bar(getmaxx-ipanel.width+getimagewidth(ipanel.characters.bgimg)*(i-3*(i div 4)-1)+(getimagewidth(ipanel.characters.bgimg)-40)div 2,
    getmaxy-getimageheight(ipanel.characters.bgimg)div(4*(i div 4)+1)-getimageheight(ipanel.characters.bgimg)*((6-i+1) div 4)div 6,40,2,HP_remain_percent(ipanel.characters.cur_object^.chars[i]),0,rgbcolorrgb(255,0,0),screenimg);
  draw_progressive_bar(getmaxx-ipanel.width+getimagewidth(ipanel.characters.bgimg)*(i-3*(i div 4)-1)+(getimagewidth(ipanel.characters.bgimg)-40)div 2-1,
    getmaxy-getimageheight(ipanel.characters.bgimg)div(4*(i div 4)+1)-getimageheight(ipanel.characters.bgimg)*((6-i+1) div 4)div 6+3,42,4,100,0,rgbcolorrgb(150,150,0),screenimg);
  draw_progressive_bar(getmaxx-ipanel.width+getimagewidth(ipanel.characters.bgimg)*(i-3*(i div 4)-1)+(getimagewidth(ipanel.characters.bgimg)-40)div 2,
    getmaxy-getimageheight(ipanel.characters.bgimg)div(4*(i div 4)+1)-getimageheight(ipanel.characters.bgimg)*((6-i+1) div 4)div 6+4,40,2,MP_remain_percent(ipanel.characters.cur_object^.chars[i]),0,rgbcolorrgb(0,0,255),screenimg);
  end;
end;
{\characters}
{character attributes}
draw_char_attributes(getmaxx-ipanel.width,getmaxy-getimageheight(ipanel.characters.bgimg)*2-char_window_height,getmaxx,getmaxy-getimageheight(ipanel.characters.bgimg)*2,mouse_on_char_panel,screenimg);
{}
draw_bar(mainBG,getmaxx-ipanel.width,ipanel.time.y+getimageheight(iframe.fr[2])+getimageheight(ipanel.time.bg),getmaxx,getmaxy-getimageheight(ipanel.characters.bgimg)*2-char_window_height,screenimg);
{frames}
draw_frame(iframe,getmaxx-ipanel.width,0,ipanel.day.x+getimagewidth(ipanel.day.bg),ipanel.time.y+getimageheight(ipanel.time.bg)+getimageheight(iframe.fr[2]),screenimg);
draw_frame(iframe,ipanel.time.x,0,getmaxx,ipanel.time.y+getimageheight(ipanel.time.bg)+getimageheight(iframe.fr[2]),screenimg);
draw_frame(iframe,getmaxx-ipanel.width,ipanel.time.y+getimageheight(iframe.fr[2])+getimageheight(ipanel.time.bg),getmaxx,getmaxy-getimageheight(ipanel.characters.bgimg)*2-char_window_height,screenimg);
draw_frame(iframe,getmaxx-ipanel.width,getmaxy-getimageheight(ipanel.characters.bgimg)*2,getmaxx,getmaxy,screenimg);
{}
if show_fps then draw_fps_str(screenimg);
if dr_cur then draw_cursor(screenimg);
end;

procedure main_loop;
var prev_loop_time:double;
begin
prev_loop_time:=g_timer_elapsed(loop_timer,nil);
g_timer_reset(loop_timer);

if prev_loop_time<>0 then fps:=1/prev_loop_time;
gametime.min:=gametime.min+prev_loop_time/60*gametime_koef;
putinorder_gametime;
{main}
_keyboard;
_mouse;
_animations;
if player<>nil then _player;
{\main}
if not main_quit then
  begin
  createscreenimage(true);
  putimage(0,0,screenimg);
  destroyimage(screenimg);
  end;
end;

begin
loop_timer:=g_timer_new();
scroll_timer:=g_timer_new();
can_scroll:=true;
battle_show_grid:=true;
battle_show_passable_cells:=true;
end.
