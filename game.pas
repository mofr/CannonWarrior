program GAME;
{$apptype GUI}
uses game_interface,graphix,gxmouse,gximg,gxtype,game_main_unit,
  game_other_funcs,game_sound,directsound;

begin
   assign(outFile,'game.txt');
   rewrite(outFile);

   gr_mode_resx:=1024;
   gr_mode_resy:=768;
   gr_mode_kol_colors:=ig_col32;

   initgraphix(ig_vga,ig_lfb);
   setmodegraphix(gr_mode_resx,gr_mode_resy,gr_mode_kol_colors);

   write(outfile,'Graph mode: ',gr_mode_resx,'x',gr_mode_resy);
   case gr_mode_kol_colors of
    ig_col32:writeln(outfile,'x32');
    ig_col24:writeln(outfile,'x24');
    ig_col16:writeln(outfile,'x16');
    ig_col15:writeln(outfile,'x15');
    ig_col8:writeln(outfile,'x8');
   end;
   writeln(outfile);

   load_cursor_images('pic\cursor\2');

   initializeIDS(IDS);

   loadsound(IDS,gamesound,'sounds\main.wav',false);
   playsound(gamesound,DSBplay_looping);

   screnshotimagetype:=ittga;
   scr_cell_sizex:=40;
   scr_cell_sizey:=40;
   char_window_height:=getmaxy*37 div 100;
   camera.x:=0;
   camera.y:=0;
   main_quit:=false;
   gametime_koef:=300;
   scroll_delay:=0;
   camera_on_player:=false;
   max_night_intension:=115;
   day_night_change:=true;
   show_day_night_indicator:=true;
   night.begin_:=24*60;
   night.end_:=5*60;
   night.middle:=round(2.5*60);
   day.begin_:=9*60;
   day.end_:=20*60;
   day.middle:=round(14.5*60);
   gametime.hour:=day.middle div 60;
   with gametime do
    begin
    year:=816;
    month:=3;
    day:=16;
    min:=0;
    end;

   {create ipanel}
   load_images;
   with ipanel do
    begin
    width:=scr_cell_sizex*6;
    end;
   with ipanel.time do
      begin
      x:=getmaxx-getimagewidth(ipanel.time.bg)-getimagewidth(iframe.fr[1]);
      y:=getimageheight(iframe.fr[2]);
      end;
   with ipanel.year do
      begin
      x:=getmaxx-ipanel.width+getimagewidth(iframe.fr[1]);
      y:=getimageheight(iframe.fr[2]);
      end;
   with ipanel.month do
      begin
      x:=ipanel.year.x+getimagewidth(ipanel.year.bg);
      y:=getimageheight(iframe.fr[2]);
      end;
   with ipanel.day do
      begin
      x:=ipanel.month.x+getimagewidth(ipanel.month.bg);
      y:=getimageheight(iframe.fr[2]);
      end;
   ipanel.characters.cur_object:=nil;
   {create messabe box}
   with message_box do
   	begin
   	height:=scr_cell_sizex;
   	message:='';
    loadimagefile(itdetect,'pic\interface\msgboxBG.tga',bgimg,0);
    end;
   {create battle messabe box}
   with battle_msgbox do
  	begin
    height:=scr_cell_sizex;
    message:='';
   	loadimagefile(itdetect,'pic\interface\msgboxBG.tga',bgimg,0);
    end;
   {}
   day_night_indicator.x:=getmaxx-ipanel.width;
   day_night_indicator.y:=0;
   cur_screenx:=(getmaxx-ipanel.width) div scr_cell_sizex;
   cur_screeny:=(getmaxy-message_box.height) div scr_cell_sizey;
   max_dist_from_board:=cur_screenx div 2;

   create_new_player;
   randomize;
   destroy_map(curmap);
   case random(1) of
    0:load_map(curmap,'maps\testmap1',true,true);
    1:load_map(curmap,'maps\testmap2',true,true);
    2:load_map(curmap,'maps\testmap3',true,true);
    end;

   initmouse;
   disablemouse;

   txt.loadfont('fonts\fontfix2.fnt');

   setcurrentfont('fonts\testfont.gif');

   repeat main_loop until main_quit;

   destroysound(gamesound);
   donegraphix;
   close(outFile);
end.
