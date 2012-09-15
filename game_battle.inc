function get_obj_char_kol_alive(obj:Pobject_):longint;
var res,i:integer;
begin
res:=0;
if obj^.type_=ot_character_group then
for i:=1 to 6 do
	if(obj^.chars[i]<>nil)and(obj^.chars[i]^.bat<>nil)and(not obj^.chars[i]^.bat^.dead) then res:=res+1;
get_obj_char_kol_alive:=res;
end;

procedure destroy_battle_forces;
var i,j:integer;
begin
for i:=1 to battle_field_sizex do
for j:=1 to battle_field_sizey do battle_field[i,j]:=nil;
battle_char_moving:=false;
for i:=1 to 6 do
    begin
    if (battle_obj1^.chars[i]<>nil)and(battle_obj1^.chars[i]^.bat<>nil) then
      begin
      if battle_obj1^.chars[i]^.bat^.tr_inf.step_timer<>nil then
      g_timer_destroy(battle_obj1^.chars[i]^.bat^.tr_inf.step_timer);
      if battle_obj1^.chars[i]^.bat<>nil then dispose(battle_obj1^.chars[i]^.bat);
      end;
    if (battle_obj2^.chars[i]<>nil)and(battle_obj2^.chars[i]^.bat<>nil) then
      begin
      if battle_obj2^.chars[i]^.bat^.tr_inf.step_timer<>nil then
      g_timer_destroy(battle_obj2^.chars[i]^.bat^.tr_inf.step_timer);
      if battle_obj2^.chars[i]^.bat<>nil then dispose(battle_obj2^.chars[i]^.bat);
      end;
    end;
end;

procedure create_battle_forces;
var i:integer;
begin
for i:=1 to 6 do
    begin
    if battle_obj1^.chars[i]<>nil then
      begin
      new(battle_obj1^.chars[i]^.bat);
      with battle_obj1^.chars[i]^.bat^ do
        begin
        x:=1;y:=i*2;
        force:=1;
        tr_inf.way.length:=0;
        tr_inf.step_cooldown_time:=(100-battle_obj1^.chars[i]^.dex)/550;
        tr_inf.step_timer:=g_timer_new;
        tr_inf.can_step:=true;
        tr_inf.num_steps:=10;
        tr_inf.xoff:=0;
        tr_inf.yoff:=0;
        tr_inf.cur_offstep:=0;
        dead:=false;
        battle_field[x,y]:=battle_obj1^.chars[i];
        end;
      end;
    if battle_obj2^.chars[i]<>nil then
      begin
      new(battle_obj2^.chars[i]^.bat);
      with battle_obj2^.chars[i]^.bat^ do
        begin
        x:=battle_field_sizex;y:=i*2;
        force:=2;
        tr_inf.way.length:=0;
        tr_inf.step_cooldown_time:=(100-battle_obj2^.chars[i]^.dex)/550;
        tr_inf.step_timer:=g_timer_new;
        tr_inf.can_step:=true;
        tr_inf.num_steps:=10;
        tr_inf.xoff:=0;
        tr_inf.yoff:=0;
        tr_inf.cur_offstep:=0;
        dead:=false;
        battle_field[x,y]:=battle_obj2^.chars[i];
        end;
      end;
    end;
end;

procedure create_battle_queue;
var p:pointer;
    i,k:integer;
begin
battle_queue_kol:=0;
{create array}
for i:=1 to 6 do
  begin
  if battle_obj1^.chars[i]<>nil then
    begin
    inc(battle_queue_kol);
    battle_queue[battle_queue_kol]:=battle_obj1^.chars[i];
    end;
  if battle_obj2^.chars[i]<>nil then
    begin
    inc(battle_queue_kol);
    battle_queue[battle_queue_kol]:=battle_obj2^.chars[i];
    end;
  end;
{sort array by character attributes(level)}
for k:=1 to battle_queue_kol do
  for i:=1 to battle_queue_kol-k do
    if battle_queue[i]^.level>battle_queue[i+1]^.level then
       begin
       p:=battle_queue[i];
       battle_queue[i]:=battle_queue[i+1];
       battle_queue[i+1]:=p;
       end;
battle_queue_cur:=1;
battle_cur_char:=battle_queue[battle_queue_cur];
end;

procedure next_queue_char;
begin
inc(battle_queue_cur);
if battle_queue_cur>battle_queue_kol then battle_queue_cur:=1;
battle_cur_char:=battle_queue[battle_queue_cur];
battle_cur_char^.bat^.tr_inf.can_step:=true;
battle_cur_char_prelight_int:=0;
battle_cur_char_prelight_int_step:=abs(battle_cur_char_prelight_int_step);
if battle_cur_char^.bat^.dead then next_queue_char;
end;

procedure battle_keyboard;
var key:char;
begin
if keypressed then
  begin
  key:=readkey;
  case key of
    #27:if not battle_char_moving then battle_end:=true;
    #32:if not battle_char_moving then next_queue_char;
    '`':if show_fps then show_fps:=false else show_fps:=true;
    'g':if battle_show_grid then battle_show_grid:=false else battle_show_grid:=true;
    'p':if battle_show_passable_cells then battle_show_passable_cells:=false else battle_show_passable_cells:=true;
    end;
  end;
end;

procedure battle_animations;
begin
end;

function get_field_coorx(x:integer):integer;
begin
get_field_coorx:=battle_bound_x1+(x-1)*((getmaxx-battle_bound_x1-battle_bound_x2)div battle_field_sizex);
end;

function get_field_coory(y:integer):integer;
begin
get_field_coory:=battle_bound_y1+(y-1)*((getmaxy-battle_bound_y1-battle_bound_y2)div battle_field_sizey);
end;

function get_fieldx_bycoor(x:integer):byte;
begin
get_fieldx_bycoor:=(x-battle_bound_x1)div(get_field_coorx(1)-get_field_coorx(0))+1;
if get_fieldx_bycoor>battle_field_sizex then get_fieldx_bycoor:=battle_field_sizex;
end;

function get_fieldy_bycoor(y:integer):byte;
begin
get_fieldy_bycoor:=(y-battle_bound_y1)div(get_field_coory(1)-get_field_coory(0))+1;
if get_fieldy_bycoor>battle_field_sizey then get_fieldy_bycoor:=battle_field_sizey;
end;

function distance_from_char(ch:Pcharacter;x,y:integer):integer;
begin
distance_from_char:=round(sqrt(sqr(x-ch^.bat^.x)+sqr(y-ch^.bat^.y)));
end;

function get_field_cell_sizex:integer;
begin
get_field_cell_sizex:=get_field_coorx(1)-get_field_coorx(0)
end;

function get_field_cell_sizey:integer;
begin
get_field_cell_sizey:=get_field_coory(1)-get_field_coory(0)
end;

function get_mouse_char:Pcharacter;
var mx,my:longint;
begin
mousecoords(mx,my);
get_mouse_char:=(battle_field[get_fieldx_bycoor(mx),get_fieldy_bycoor(my)]);
end;

procedure battle_mouse;
var mx,my:longint;
begin
mousecoords(mx,my);
if ((get_mouse_char=nil)or(battle_field[get_fieldx_bycoor(mx),get_fieldy_bycoor(my)]^.bat^.force<>battle_cur_char^.bat^.force))
and(distance_from_char(battle_cur_char,get_fieldx_bycoor(mx),get_fieldy_bycoor(my))<=battle_cur_char^.range)
and(distance_from_char(battle_cur_char,get_fieldx_bycoor(mx),get_fieldy_bycoor(my))>0) then cur_cursor:=10 else cur_cursor:=0;

if ((get_mouse_char=nil)or(get_mouse_char^.bat^.force<>battle_cur_char^.bat^.force))and
not battle_char_moving and(mousebutton=0)and(old_mousebutton=1)
  and(distance_from_char(battle_cur_char,get_fieldx_bycoor(mx),get_fieldy_bycoor(my))<=battle_cur_char^.range)
  then
  begin
  battle_char_moving:=true;
  battle_cur_char^.bat^.tr_inf.way:=get_way(battle_cur_char^.bat^.x,battle_cur_char^.bat^.y,get_fieldx_bycoor(mx),get_fieldy_bycoor(my),'battle');
  battle_cur_char^.bat^.tr_inf.cur_way_step:=1;
  end;
old_mousebutton:=mousebutton;
end;

procedure battle_turn;
var dx,dy:integer;
begin
if not battle_cur_char^.bat^.tr_inf.can_step then
  begin
  if g_timer_elapsed(battle_cur_char^.bat^.tr_inf.step_timer,nil)>=battle_cur_char^.bat^.tr_inf.step_cooldown_time/battle_cur_char^.bat^.tr_inf.num_steps then
    begin
    g_timer_reset(battle_cur_char^.bat^.tr_inf.step_timer);
    g_timer_stop(battle_cur_char^.bat^.tr_inf.step_timer);
    battle_cur_char^.bat^.tr_inf.can_step:=true;
    end;
  end;
if (battle_cur_char<>nil)and(battle_cur_char^.bat^.tr_inf.way.length>0)and battle_cur_char^.bat^.tr_inf.can_step then
  begin
  if battle_cur_char^.bat^.tr_inf.cur_way_step<=battle_cur_char^.bat^.tr_inf.way.length then
    begin
    with battle_cur_char^.bat^ do
    case battle_cur_char^.bat^.tr_inf.way.path[battle_cur_char^.bat^.tr_inf.cur_way_step] of
      1:begin dx:=x;dy:=y-1;end;
      2:begin dx:=x+1;dy:=y-1;end;
      3:begin dx:=x+1;dy:=y;end;
      4:begin dx:=x+1;dy:=y+1;end;
      5:begin dx:=x;dy:=y+1;end;
      6:begin dx:=x-1;dy:=y+1;end;
      7:begin dx:=x-1;dy:=y;end;
      8:begin dx:=x-1;dy:=y-1;end;
      end;
    if (battle_field[dx,dy]<>nil)and(battle_field[dx,dy]^.bat^.force<>battle_cur_char^.bat^.force) then
      begin{attack}
      char_attack_char(battle_cur_char,battle_field[dx,dy]);
      inc(battle_cur_char^.bat^.tr_inf.cur_way_step);
      if battle_cur_char^.bat^.tr_inf.cur_way_step>battle_cur_char^.bat^.tr_inf.way.length then
        begin
        next_queue_char;
        battle_char_moving:=false;
        end;
      end{\attack}else
    begin
    with battle_cur_char^.bat^.tr_inf do
    case battle_cur_char^.bat^.tr_inf.way.path[battle_cur_char^.bat^.tr_inf.cur_way_step] of
      1:yoff:=yoff-get_field_cell_sizey div battle_cur_char^.bat^.tr_inf.num_steps;
      2:begin xoff:=xoff+get_field_cell_sizex div battle_cur_char^.bat^.tr_inf.num_steps;yoff:=yoff-get_field_cell_sizey div battle_cur_char^.bat^.tr_inf.num_steps;end;
      3:xoff:=xoff+get_field_cell_sizex div battle_cur_char^.bat^.tr_inf.num_steps;
      4:begin xoff:=xoff+get_field_cell_sizex div battle_cur_char^.bat^.tr_inf.num_steps;yoff:=yoff+get_field_cell_sizey div battle_cur_char^.bat^.tr_inf.num_steps;end;
      5:yoff:=yoff+get_field_cell_sizey div battle_cur_char^.bat^.tr_inf.num_steps;
      6:begin xoff:=xoff-get_field_cell_sizex div battle_cur_char^.bat^.tr_inf.num_steps;yoff:=yoff+get_field_cell_sizey div battle_cur_char^.bat^.tr_inf.num_steps;end;
      7:xoff:=xoff-get_field_cell_sizex div battle_cur_char^.bat^.tr_inf.num_steps;
      8:begin xoff:=xoff-get_field_cell_sizex div battle_cur_char^.bat^.tr_inf.num_steps;yoff:=yoff-get_field_cell_sizey div battle_cur_char^.bat^.tr_inf.num_steps;end;
      end;
    inc(battle_cur_char^.bat^.tr_inf.cur_offstep);
    if battle_cur_char^.bat^.tr_inf.cur_offstep=battle_cur_char^.bat^.tr_inf.num_steps then
    begin
      battle_cur_char^.bat^.tr_inf.xoff:=0;
      battle_cur_char^.bat^.tr_inf.yoff:=0;
      battle_cur_char^.bat^.tr_inf.cur_offstep:=0;
      with battle_cur_char^.bat^ do battle_field[x,y]:=nil;
      battle_cur_char^.bat^.x:=dx;
      battle_cur_char^.bat^.y:=dy;
      battle_field[dx,dy]:=battle_cur_char;
      inc(battle_cur_char^.bat^.tr_inf.cur_way_step);
      if battle_cur_char^.bat^.tr_inf.cur_way_step>battle_cur_char^.bat^.tr_inf.way.length then
        begin
        next_queue_char;
        battle_char_moving:=false;
        end;
    end;
    battle_cur_char^.bat^.tr_inf.can_step:=false;
    g_timer_start(battle_cur_char^.bat^.tr_inf.step_timer);
    end;
    end;
  end;
end;{\procedure}

procedure battle_;
begin
if (get_obj_char_kol_alive(battle_obj1)<=0)or(get_obj_char_kol_alive(battle_obj2)<=0) then battle_end:=true;
end;

procedure battle_create_screen_image;
var timg:pimage;
    i,j:integer;
begin
screenimg:=createimageWH(getmaxx,getmaxy);
composeimagec(screenimg,battle_main_background,0,0);
draw_frame(iframe,0,0,getmaxx,getmaxy,screenimg);
mousecoords(mx,my);
{passable cells}
if battle_show_passable_cells and not battle_char_moving then
for i:=battle_cur_char^.bat^.x-battle_cur_char^.range to battle_cur_char^.bat^.x+battle_cur_char^.range do
for j:=battle_cur_char^.bat^.y-battle_cur_char^.range to battle_cur_char^.bat^.y+battle_cur_char^.range do
if (i>0)and(i<=battle_field_sizex)and(j>0)and(j<=battle_field_sizey) then
if {get_way(battle_cur_char^.bat^.x,battle_cur_char^.bat^.y,i,j,'battle').length<=battle_cur_char^.range//}distance_from_char(battle_cur_char,i,j)<=battle_cur_char^.range
then
begin
timg:=createimageWH(get_field_coorx(1)-get_field_coorx(0)+1,get_field_coory(1)-get_field_coory(0)+1);
imagecaptureimage(screenimg,get_field_coorx(i),get_field_coory(j),get_field_coorx(i+1),get_field_coory(j+1),timg);
imagesaddcolor(timg,timg,rgbcolorrgb(20,20,20));
composeimagec(screenimg,timg,get_field_coorx(i),get_field_coory(j));
destroyimage(timg);
end;
{}
{grid}
if battle_show_grid then
begin
for i:=1 to battle_field_sizex+1 do
imagelinepattern(screenimg,get_field_coorx(i),battle_bound_y1,get_field_coorx(i),get_field_coory(battle_field_sizey+1),
  rgbcolorrgb(198,198,198),grid_line_pat,grid_line_bits);
for j:=1 to battle_field_sizey+1 do
imagelinepattern(screenimg,battle_bound_x1,get_field_coory(j),get_field_coorx(battle_field_sizex+1),get_field_coory(j),
  rgbcolorrgb(198,198,198),grid_line_pat,grid_line_bits);
end;
{}
{characters}
for j:=1 to battle_field_sizey do
for i:=1 to battle_queue_kol do
  if battle_queue[i]<>nil then
  if not battle_queue[i]^.bat^.dead then
  if battle_queue[i]^.bat^.y=j then
  begin
  timg:=createimageWH(getimagewidth(get_gr_image(battle_queue[i]^.gr^)),getimageheight(get_gr_image(battle_queue[i]^.gr^)));
  copyimage(timg,get_gr_image(battle_queue[i]^.gr^));
  if (battle_queue[i]=battle_cur_char)and(battle_queue[i]<>nil)then imagesaddcolor(timg,timg,rgbcolorrgb(battle_cur_char_prelight_int,battle_cur_char_prelight_int,battle_cur_char_prelight_int div 2));
  composeimagec(screenimg,timg,get_field_coorx(battle_queue[i]^.bat^.x)+get_field_cell_sizex div 2-getimagewidth(timg)div 2+battle_queue[i]^.bat^.tr_inf.xoff,
    get_field_coory(battle_queue[i]^.bat^.y)-getimageheight(timg)+get_field_cell_sizey*3div 4+battle_queue[i]^.bat^.tr_inf.yoff);
  if not((battle_queue[i]=battle_cur_char)and battle_char_moving) then
  	begin
  	draw_progressive_bar(get_field_coorx(battle_queue[i]^.bat^.x)+get_field_cell_sizex div 2-get_field_cell_sizex*3 div 8+battle_queue[i]^.bat^.tr_inf.xoff-1,
  		get_field_coory(battle_queue[i]^.bat^.y)-getimageheight(timg)+get_field_cell_sizey*3div 4+battle_queue[i]^.bat^.tr_inf.yoff-9,
    	get_field_cell_sizex*3 div 4+2,8,100,0,rgbcolorrgb(150,150,0),screenimg);
  	draw_progressive_bar(get_field_coorx(battle_queue[i]^.bat^.x)+get_field_cell_sizex div 2-get_field_cell_sizex*3 div 8+battle_queue[i]^.bat^.tr_inf.xoff,
  		get_field_coory(battle_queue[i]^.bat^.y)-getimageheight(timg)+get_field_cell_sizey*3div 4+battle_queue[i]^.bat^.tr_inf.yoff-8,
  		get_field_cell_sizex*3 div 4,2,HP_remain_percent(battle_queue[i]),0,rgbcolorrgb(255,0,0),screenimg);
  	draw_progressive_bar(get_field_coorx(battle_queue[i]^.bat^.x)+get_field_cell_sizex div 2-get_field_cell_sizex*3 div 8+battle_queue[i]^.bat^.tr_inf.xoff,
  		get_field_coory(battle_queue[i]^.bat^.y)-getimageheight(timg)+get_field_cell_sizey*3div 4+battle_queue[i]^.bat^.tr_inf.yoff-4,
  		get_field_cell_sizex*3 div 4,2,MP_remain_percent(battle_queue[i]),0,rgbcolorrgb(0,0,255),screenimg);
    end;
  destroyimage(timg);
  end;
{character attributes}
if get_mouse_char<>nil then
case get_mouse_char^.bat^.force of
	1:begin
  	draw_char_attributes(0,getmaxy-getmaxy div 3,getmaxx div 5,getmaxy,get_mouse_char,screenimg);
    draw_frame(iframe,0,getmaxy-getmaxy div 3-getimageheight(iframe.fr[2]),getmaxx div 5+getimagewidth(iframe.fr[1]),getmaxy,screenimg);
    end;
  2:begin
  	draw_char_attributes(getmaxx-getmaxx div 5,getmaxy-getmaxy div 3,getmaxx,getmaxy,get_mouse_char,screenimg);
    draw_frame(iframe,getmaxx-getmaxx div 5-getimagewidth(iframe.fr[1]),getmaxy-getmaxy div 3-getimageheight(iframe.fr[2]),getmaxx,getmaxy,screenimg);
    end;
  end;
{}
if show_fps then draw_fps_str(screenimg);
draw_cursor(screenimg);
end;

procedure battle_main_loop;
var mx,my:longint;
    pos:DWORD;
    prev_loop_time:double;
begin
prev_loop_time:=g_timer_elapsed(loop_timer,nil);
g_timer_reset(loop_timer);

fps:=1/prev_loop_time;
{}
if gamesound.idsb<>nil then
  begin
  gamesound.idsb^^.getcurrentposition(gamesound.idsb,@pos,@pos);
  if pos>gamesound.destroypos then destroysound(gamesound);
  end;
{}
battle_cur_char_prelight_int:=battle_cur_char_prelight_int+battle_cur_char_prelight_int_step;
if (battle_cur_char_prelight_int>50)or(battle_cur_char_prelight_int<1) then battle_cur_char_prelight_int_step:=-battle_cur_char_prelight_int_step;
{}
battle_keyboard;
battle_mouse;
battle_animations;
battle_turn;
battle_;
{draw screen}
battle_create_screen_image;
putimage(0,0,screenimg);
destroyimage(screenimg);
{\draw screen}
end;

procedure battle(var force1,force2:Pobject_);
var i,j:integer;
  game_mus_pos:DWORD;
begin
if (force1^.type_=ot_character_group)and(force2^.type_=ot_character_group) then
  begin
  battle_obj1:=force1;
  battle_obj2:=force2;
  gamesound.idsb^^.getcurrentposition(gamesound.idsb,@game_mus_pos,@game_mus_pos);
  destroysound(gamesound);
  loadsound(IDS,gamesound,'sounds\battle_beginning.wav',true);
  playsound(gamesound,DSBplay_looping);
  destroy_battle_forces;
  create_battle_forces;
  create_battle_queue;
  old_mousebutton:=0;
  battle_cur_char_prelight_int_step:=4;
  battle_end:=false;
  winner:=nil;
  loadimagefile(itdetect,'pic\battle grounds\grass.gif',battle_main_background,0);
  repeat battle_main_loop until battle_end;
  destroyimage(battle_main_background);
  battle_force1EXPreward:=0;
  battle_force2EXPreward:=0;
  for i:=1 to 6 do
    begin
    if (force1^.chars[i]<>nil)and(force1^.chars[i]^.bat^.dead) then inc(battle_force2EXPreward,get_char_exp_cost(force1^.chars[i]));
    if (force2^.chars[i]<>nil)and(force2^.chars[i]^.bat^.dead) then inc(battle_force1EXPreward,get_char_exp_cost(force2^.chars[i]));
    end;
  destroy_battle_forces;
  for i:=1 to 6 do
    begin
    check_character(force1^.chars[i]);
    check_character(force2^.chars[i]);
    end;

  char_group_incEXP(force1,battle_force1EXPreward);
  char_group_incEXP(force2,battle_force2EXPreward);

  if get_obj_char_kol(force1)<=0 then if player^.obj<>force1 then destroy_object(force1);
  if get_obj_char_kol(force2)<=0 then if player^.obj<>force2 then destroy_object(force2);
  if get_obj_char_kol(player^.obj)<=0 then game_over;
  destroysound(gamesound);
  loadsound(IDS,gamesound,'sounds\main.wav',false);
  gamesound.idsb^^.setcurrentposition(gamesound.idsb,game_mus_pos);
  playsound(gamesound,DSBplay_looping);
  end;
end;
