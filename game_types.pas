unit game_types;
interface
uses glib,gxtype,gxmedia;
type
   object_type=(ot_terrain,ot_character_group,ot_structure,
        ot_doodad,ot_passage_area,ot_simple_structure);

   Trgbcolor=record
    r,g,b:byte;
    end;

   Tframe=packed record
    fr:array[1..4]of pimage;
    corn:array[1..4]of pimage;
    end;

   Pdoubint=^Tdoubint;
   Tdoubint=record
    T1,T2:longint;
    end;

   Panimation=^Tanimation;
   Tanimation=packed record
    pl:PmediaGIF;
    frametimer:pgtimer;
    paused:boolean;
    end;

   Tway=record
    length:integer;
    path:array[1..100]of byte;
    target_coor:Tdoubint;
    end;

   Ttravel_information=record
    way:Tway;
      can_step:boolean;
      step_timer:pgtimer;
      step_cooldown_time:double;
      cur_way_step:longint;
      xoff,yoff,num_steps,cur_offstep:integer;
    end;

   Ppassmap=^Tpassmap;
   Tpassmap=array[0..100,0..100]of byte;

   Pobjgraph=^Tobjgraph;
   Tobjgraph=packed record
      imgposV,imgposH,sizex,sizey:byte;
      passmap:Ppassmap;
      case animated:boolean of
         true:(anim:Panimation);
         false:(img:pimage);
      end;

   Ppassage_area=^Tpassage_area;
   Tpassage_area=record
    player_new_posx,player_new_posy,camera_new_posx,camera_new_posy:longint;
    route:string;
    end;

   Pbattle_character_information=^Tbattle_character_information;
   Tbattle_character_information=packed record
    x,y:byte;
    tr_inf:Ttravel_information;
    gr:Pobjgraph;
    force:byte;
    dead:boolean;
    end;

   Pcharacter=^Tcharacter;
   Tcharacter=packed record
    EXP,nextEXP,level:longint;
    {primary attributes}
    attr_points:integer;
    str,dex,vit,mag:integer;
    {derivative attributes}
    armor,defense,attack:longint;
    damage,HP,MP:Tdoubint;
    {private character parameters}
    name:string;
    battlegrpath:string;
    gr:Pobjgraph;
    {battle}
    range:byte;
    bat:Pbattle_character_information;
    end;

   Pobject_=^Tobject_;
   Tobject_=packed record
      x,y:longint;
      gr:Pobjgraph;
      name:string;
      case type_:object_type of
         ot_character_group:(
              chars:array[1..6]of Pcharacter;
              primary:byte;
              );
         ot_passage_area:(
              passage_area:Tpassage_area;
              );
      end;

//   Pmap=^Tmap;
   Tmap=packed record
      objects:array[0..30000]of Pobject_;
      kol_objects,kol_passmaps,kol_obj_graphs,
        sizex,sizey:longint;
      name,filename:string;
      obj_graphs:array[0..100]of Pobjgraph;
      passmaps:array[0..100]of Ppassmap;
      end;

   Tcamera=record
      x,y:longint;
      end;

   Pplayer=^Tplayer;
   Tplayer=packed record
      direc,imgposh,imgposv:byte;
      images:array[1..8]of pimage;
      obj:Pobject_;
      tr_inf:Ttravel_information;
      end;

implementation

begin
end.
