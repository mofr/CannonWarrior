const maxx=50;maxy=50;
var wave_array:array[0..maxx,0..maxy]of integer;
    found:boolean;
    x1,y1,x2,y2:integer;

procedure create_land_array_from_map;
var x,y,i:integer;
    obj:Pobject_;
begin
for x:=0 to maxx do
for y:=0 to maxy do
  case cell_passable(x,y,obj)of
    0,2,3:wave_array[x,y]:=-1;
    1:wave_array[x,y]:=0;
    end;
end;

procedure create_land_array_from_battle_field;
var x,y:integer;
begin
for x:=0 to maxx do
for y:=0 to maxy do wave_array[x,y]:=-1;
for x:=1 to battle_field_sizex do
for y:=1 to battle_field_sizey do
  if battle_field[x,y]=nil then wave_array[x,y]:=0 else wave_array[x,y]:=-1;
end;

procedure check_n_set(i,j:integer;val:longint);
begin
if not((i<0)or(i>maxx)or(j<0)or(j>maxy)) then
  if (wave_array[i,j]=0) then
     begin
     wave_array[i,j]:=val;
     if (i=x1)and(j=y1) then found:=true;
     end;
end;

procedure waves_to_array;
var i,j,k,t1,t2:integer;
begin
k:=0;
while (k<=maxx*maxy)and not found do
    begin
    k:=k+1;
    i:=x2-k;
    if i<0 then i:=0;
    t1:=maxx-k;
    if t1<0 then t1:=0;
      while (i<=t1)and not found do
          begin
          j:=y2-k;
          if j<0 then j:=0;
          t2:=maxy-k;
          if t2<0 then t2:=0;
          while (j<=t2)and not found do
              if wave_array[i,j]=k then
              begin
              if not found then check_n_set(i-1,j,k+1);
              if not found then check_n_set(i,j-1,k+1);
              if not found then check_n_set(i+1,j,k+1);
              if not found then check_n_set(i,j+1,k+1);
              j:=j+1;
              end else j:=j+1;
          i:=i+1;
          end;
    end;
end;

procedure create_way(var w:Tway);
var x,y:integer;
    near_cells:array[1..8]of integer;
    min,min_indx,i:integer;
begin
w.length:=0;
w.target_coor.T1:=x2;
w.target_coor.T2:=y2;
x:=x1;y:=y1;
while (x<>x2)or(y<>y2) do
  begin
  inc(w.length);
  {}
  min_indx:=0;
  if (y-1>=0)then
    begin
    near_cells[1]:=wave_array[x,y-1];
    if (wave_array[x,y-1]<>0)and(wave_array[x,y-1]<>-1)then min_indx:=1;
    end else near_cells[1]:=-1;
  if (x+1<=maxx)and(y-1>=0)then
    begin
    near_cells[2]:=wave_array[x+1,y-1];
    if (wave_array[x+1,y-1]<>0)and(wave_array[x+1,y-1]<>-1)then if min_indx=0 then min_indx:=2;
    end else near_cells[2]:=-1;
  if (x+1<=maxx)then
    begin
    near_cells[3]:=wave_array[x+1,y];
    if (wave_array[x+1,y]<>0)and(wave_array[x+1,y]<>-1)then if min_indx=0 then min_indx:=3;
    end else near_cells[3]:=-1;
  if (x+1<=maxx)and(y+1<=maxy)then
    begin
    near_cells[4]:=wave_array[x+1,y+1];
    if (wave_array[x+1,y+1]<>0)and(wave_array[x+1,y+1]<>-1)then if min_indx=0 then min_indx:=4;
    end else near_cells[4]:=-1;
  if (y+1<=maxy)then
    begin
    near_cells[5]:=wave_array[x,y+1];
    if (wave_array[x,y+1]<>0)and(wave_array[x,y+1]<>-1)then if min_indx=0 then min_indx:=5;
    end else near_cells[5]:=-1;
  if (x-1>=0)and(y+1<=maxy)then
    begin
    near_cells[6]:=wave_array[x-1,y+1];
    if (wave_array[x-1,y+1]<>0)and(wave_array[x-1,y+1]<>-1)then if min_indx=0 then min_indx:=6;
    end else near_cells[6]:=-1;
  if (x-1>=0)then
    begin
    near_cells[7]:=wave_array[x-1,y];
    if (wave_array[x-1,y]<>0)and(wave_array[x-1,y]<>-1)then if min_indx=0 then min_indx:=7;
    end else near_cells[7]:=-1;
  if (x-1>=0)and(y-1>=0)then
    begin
    near_cells[8]:=wave_array[x-1,y-1];
    if (wave_array[x-1,y-1]<>0)and(wave_array[x-1,y-1]<>-1)then if min_indx=0 then min_indx:=8;
    end else near_cells[8]:=-1;
  {}
//  for i:=1 to 8 do write(near_cells[i]:2);
//  writeln;
  if min_indx<>0 then
  begin
  min:=near_cells[min_indx];
  for i:=min_indx to 8 do
    if (near_cells[i]<min)and(near_cells[i]<>-1)and(near_cells[i]<>0) then
      begin
      min:=near_cells[i];
      min_indx:=i;
      end;
  end;
  {}
//  writeln(w.length,' ',x,' ',y,' ',min_indx);
  wave_array[x,y]:=-1;
  w.path[w.length]:=min_indx;
  case min_indx of
    1:begin x:=x;y:=y-1;end;
    2:begin x:=x+1;y:=y-1;end;
    3:begin x:=x+1;y:=y;end;
    4:begin x:=x+1;y:=y+1;end;
    5:begin x:=x;y:=y+1;end;
    6:begin x:=x-1;y:=y+1;end;
    7:begin x:=x-1;y:=y;end;
    8:begin x:=x-1;y:=y-1;end;
    end;
  wave_array[x,y]:=-1;
  end;
end;

function get_way(x1_,y1_,x2_,y2_:word;typ:string):Tway;
var x,y:integer;
    result_:Tway;
begin
x1:=x1_;y1:=y1_;
x2:=x2_;y2:=y2_;
found:=false;
for x:=0 to maxx do
for y:=0 to maxy do wave_array[x,y]:=0;
if typ='map' then create_land_array_from_map else
if typ='battle' then create_land_array_from_battle_field;
wave_array[x2,y2]:=1;
waves_to_array;
create_way(result_);
get_way:=result_;
end;
