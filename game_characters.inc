function get_hit_chance(ch1,ch2:Pcharacter):longint;
begin
get_hit_chance:=round(ch1^.attack*50/(0.2*ch1^.attack+0.8*ch2^.defense));
end;

function char_hit_char(ch1,ch2:Pcharacter):boolean;
begin
randomize;
char_hit_char:=random(101)<=get_hit_chance(ch1,ch2);
end;

procedure  char_attack_char(var ch1,ch2:Pcharacter);
var dmg:longint;
begin
if char_hit_char(ch1,ch2) then
	begin
  ch1^.bat^.tr_inf.xoff:=0;
  ch1^.bat^.tr_inf.yoff:=0;
  ch1^.bat^.tr_inf.cur_offstep:=0;
  dmg:=ch1^.damage.T1+random(ch1^.damage.T2-ch1^.damage.T1)-ch2^.armor;
  if dmg<0 then dmg:=0;
  dec(ch2^.HP.T1,dmg);
  if ch2^.HP.T1<=0 then
  	begin
    ch2^.bat^.dead:=true;
    ch2:=nil;
    end;
  end;
end;

function get_level_exp(lvl:integer):longint;
begin
lvl:=lvl+1;
get_level_exp:=100*(lvl*lvl*lvl-1)div lvl;
end;

function get_level_attr_bonus(lvl:integer):integer;
begin
get_level_attr_bonus:=3+3*(lvl div 10);
end;

function exp_remain_percent(char:Pcharacter):longint;
begin
with char^ do
  exp_remain_percent:=round((EXP-get_level_exp(level))/(nextEXP-EXP)*100);
end;

function HP_remain_percent(char:Pcharacter):longint;
begin
if char^.HP.T2=0 then HP_remain_percent:=0 else
with char^ do
  HP_remain_percent:=round(HP.T1/HP.T2*100);
end;

function MP_remain_percent(char:Pcharacter):longint;
begin
if char^.MP.T2=0 then MP_remain_percent:=0 else
with char^ do
  MP_remain_percent:=round(MP.T1/MP.T2*100);
end;

procedure set_character_derivative_parameters(char:Pcharacter);
begin
with char^ do
  begin
  nextEXP:=get_level_exp(level);
  HP.T2:=(vit+str div 2)*2;
  HP.T1:=HP.T2;
  MP.T2:=round(mag*2.5);
  MP.T1:=MP.T2;
  damage.T1:=str div 5+dex div 10;
  damage.T2:=str div 5+dex div 10+2;
  range:=3+dex div 10+str div 10;
  attack:=dex*2 div 3;
  defense:=dex*4 div 9;
  armor:=str div 20+dex div 25;
  writeln(outfile,'armor for <',char^.name,'> = ',armor);
  end;
end;

function get_char_exp_cost(char:Pcharacter):longint;
begin
get_char_exp_cost:=round(char^.level*100+char^.exp/11);
end;

procedure level_up(char:Pcharacter);
begin
with char^ do
  begin
  inc(level);
  nextEXP:=get_level_exp(level);
  HP.T1:=HP.T2;
  MP.T1:=MP.T2;
  inc(attr_points,get_level_attr_bonus(level));
  end;
end;

function check_character(var char:Pcharacter):Pcharacter;
begin
if char<>nil then
  if char^.HP.T1<=0 then
    begin
    if char^.bat<>nil then begin dispose(char^.bat);char^.bat:=nil;end;
    dispose(char);
    char:=nil;
    end else
  begin
  if char^.exp>=char^.nextEXP then level_up(char);
  end;
check_character:=char;
end;

procedure char_group_incEXP(obj:Pobject_;kol:longint);
var i:integer;
begin
if obj^.type_=ot_character_group then
for i:=1 to 6 do
	if obj^.chars[i]<>nil then
  	begin
  	inc(obj^.chars[i]^.exp,kol div get_obj_char_kol(obj));
    check_character(obj^.chars[i]);
    end;
end;
