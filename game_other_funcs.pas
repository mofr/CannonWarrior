unit game_other_funcs;
interface

function str_between(s:string;ch:char;nr:integer):string;
function str_value(ss:string;nr:integer):integer;
function str_wo_str_between(s:ansistring;ch:char):ansistring;
function pos_num(s1,s2:ansistring;num:word):longint;
function str_insert(s1:string;var s2:string;pos_:word):string;
function int_to_str(int:longint):string;
function str_wo(s:string;ch:char):string;

implementation

function str_wo(s:string;ch:char):string;
var i:integer;
begin
str_wo:='';
for i:=1 to length(s) do if s[i]<>ch then str_wo:=str_wo+s[i];
end;

function int_to_str(int:longint):string;
begin
str(int,int_to_str);
end;

function str_insert(s1:string;var s2:string;pos_:word):string;
var s:string;
begin
s:=copy(s2,1,pos_-1);
s:=s+s1;
s:=s+copy(s2,pos_,length(s2)-pos_+1);
s2:=s;
str_insert:=s;
end;

function pos_num(s1,s2:ansistring;num:word):longint;
var i:longint;
begin
for i:=1 to num-1 do s2:=copy(s2,pos(s1,s2)+length(s1),length(s2)-pos(s1,s2)-length(s1));
if length(s2)>0 then pos_num:=pos(s1,s2);
end;

function str_wo_str_between(s:ansistring;ch:char):ansistring;
var b:boolean;
    i:longint;
    res:ansistring;
begin
b:=true;
res:='';
for i:=1 to length(s) do
   begin
   if s[i]=ch then if b then b:=false else b:=true;
   if b then res:=res+s[i];
   end;
str_wo_str_between:=res;
end;

function str_between(s:string;ch:char;nr:integer):string;
var i:integer;
begin
for i:=1 to (nr-1)*2+1 do s:=copy(s,pos(ch,s)+1,length(s)-pos(ch,s));
s:=copy(s,1,pos(ch,s)-1);
str_between:=s;
end;

function str_value(ss:string;nr:integer):integer;
var i:integer;
    s:string;
begin
s:=ss;
repeat
s:=copy(s,1,pos('"',s)-1)+copy(s,pos('"',s)+length(str_between(s,'"',1))+1,length(s)-pos('"',s)-length(str_between(s,'"',1)));
until str_between(s,'"',1)='';

while (nr>1)and(length(s)>0)do
   begin
   while not((((ord(s[1])>=48)and(ord(s[1])<=57)))or(s[1]='-'))and(length(s)>0) do
      s:=copy(s,2,length(s)-1);
   while (((ord(s[1])>=48)and(ord(s[1])<=57))or(s[1]='-'))and(length(s)>0) do
      s:=copy(s,2,length(s)-1);
   dec(nr);
   end;
while not((((ord(s[1])>=48)and(ord(s[1])<=57)))or(s[1]='-'))and(length(s)>0) do
   s:=copy(s,2,length(s)-1);
i:=2;
while (((ord(s[i])>=48)and(ord(s[i])<=57))or(s[i]='-'))and(i<=length(s)) do i:=i+1;
s:=copy(s,1,i-1);
val(s,i);
str_value:=i;
end;

begin
end.
