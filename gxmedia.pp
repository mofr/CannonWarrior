{
    This file is a part of the graphics library GraphiX
    Copyright (C) 2001 Michael Knapp

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
}

{
                  ------------------------------------
                  GXMEDIA - G r a p h i X    M e d i a
                  ------------------------------------
                                v1.20
                  ------------------------------------


VERSION HISTORY

Version 1.30 (xx.01.2000)
  + MNG-Player
      MNG, MNG-LC, MNG-VLC

Version 1.20 (09.01.2000)
  + GIF-Animator

}

{$I gxglobal.cfg}
UNIT gxmedia;

INTERFACE

USES gxtype;
{$I gxlocal.cfg}

TYPE

  plongint=^longint;

  PMedia=^TMedia;
  TMedia=OBJECT
    MediaF:file;
    fileopen,filesupported:boolean;
    numframe,curframe:word;
    framexd,frameyd:word;
    framebuf:pimage;
    frametime:longint;
    timeofmedia:longint;
    frameidxlist:plongint;
    flags,rendermode:longint;
    processbuf:pointer;
    CONSTRUCTOR OpenMedia(name:string);
    PROCEDURE StartMedia;virtual;
    PROCEDURE SeekMedia(pos:word);virtual;
    PROCEDURE SetRenderMode(mode:longint);virtual;
    FUNCTION GrabFrame:pimage;virtual;
    FUNCTION GetFrameTime:word;virtual;
    FUNCTION GetNumFrame:word;virtual;
    FUNCTION GetCurFrame:word;virtual;
    FUNCTION GetDuration:longint;virtual;
    FUNCTION GetWidth:word;virtual;
    FUNCTION GetHeight:word;virtual;
    FUNCTION EndofMedia:boolean;virtual;
    DESTRUCTOR CloseMedia;
  END;

  Tfourcc=array[0..3] of char;

  PChunk=^TChunk;
  TChunk=RECORD
           fourcc:Tfourcc;
           size:longint;
         END;

{--- ANI-Cursor (by Benjamin Kalytta, modified for GXMEDIA by M.K. ----------}

  Tanih=record
    anihSize,
    IconCount,
    FrameCount,
    width,
    height,
    BitCount,
    Planes,
    Jifrate,
    Format:dword;
  end;

  PImageList=^TImageList;
  TImageList=record
    image:pimage;
    next:PImageList;
  end;

  PMediaAni=^TMediaAni;
  TMediaAni=object(Tmedia)
    anih:Tanih;
    rate,seq:plongint;
    INAM,IART:pchar;
    INAMsize,IARTsize,seqsize,ratesize:longint;
    CachedFrames:PImageList;
    CONSTRUCTOR OpenMedia(name:string);
    FUNCTION GetFrameTime:word;virtual;
    FUNCTION GrabFrame:pimage;virtual;
    PROCEDURE SeekMedia(pos:word);virtual;
    DESTRUCTOR CloseMedia;
    function GetMediaInfoIART:pchar;
    function GetMediaInfoINAM:pchar;
  end;

{------------------------------- AVI-Video ----------------------------------}

  Tavih=RECORD
    microseconds:longint;
    maxbytespersecond:longint;
    padgranularity:longint;
    flags:longint; {[4]=idx1-chunk, [5]=must use idx1}
    totalframes:longint;
    initialframes:longint;
    streams:longint;
    suggbufsize:longint;
    width,height:longint;
    scale,rate:longint;
    start:longint;
    lenth:longint;
  END;

  Tstrh=RECORD
    streamtype:tfourcc;
    streamhandler:tfourcc;
    flags:longint;
    priority:longint;
    intialframes:longint;
    scale,rate:longint;
    start:longint;
    length:longint;
    suggbufsize:longint;
    quality:longint;
    samplesize:longint;
    res:array[$30..$37] of byte;
  END;

  Tstrfvideo=RECORD
    size:longint;
    width,height:longint;
    planes:word;
    bitdepth:word;
    compression:Tfourcc;
    imagesize:longint;
    xpelsmeter:longint;
    ypelsmeter:longint;
    numcolors:longint;
    impcolors:longint;
    palette:array[0..255] of longint;
  END;

  Tstrfaudio=RECORD
    wformattag:word;
    channels:word;
    samplespersec:longint;
    averagebytespersec:longint;
    nblockalign:word;
    bitspersample:word;
  END;

  PmediaAVI=^TmediaAVI;
  TmediaAVI=OBJECT(TMedia)
    avih:Tavih;
    strh:Tstrh;
    strfvideo:Tstrfvideo;
    strfaudio:Tstrfaudio;
    CONSTRUCTOR OpenMedia(name:string);
    FUNCTION GrabFrame:pimage;virtual;
    DESTRUCTOR CloseMedia;
  END;

{------------------------------- FLI/FLC-Animator ---------------------------}

  TFLIheader=RECORD
    size:longint;
    magic:word; {AF11h}
    frames:word;
    width:word;
    height:word;
    depth:word;
    flags:word;
    speed:word;
    next:longint;
    frit:longint;
    reserved:array[1..102] of byte;
  END;

  TFLIframeheader=RECORD
    size:longint;
    magic:word; {F1FAh}
    chunks:word;
    reserved:array[1..8] of byte;
  END;

  TFLIframechunkheader=RECORD
    size:longint;
    _type:word;
  END;

  PmediaFLC=^TmediaFLC;
  TmediaFLC=OBJECT(TMedia)
    CONSTRUCTOR OpenMedia(name:string);
    FUNCTION GrabFrame:pimage;virtual;
    DESTRUCTOR CloseMedia;
  END;

{------------------------------- GIF-Animator -------------------------------}

  ppal=^tpal;
  tpal=array[0..255] of longint;

  TGIFSignature=array[1..6] of char;

  TGIFScreenDescriptor=RECORD
    width,height:word;
    flags,background,aspectratio:byte;
  END;

  TGIFImageDescriptor=RECORD
    x,y,xd,yd:word;
    flags:byte;
  END;

  TGIFExtensionBlock=RECORD
    functioncode:byte;
  END;

  TGIFGraphicControlExtension=RECORD
    flags:byte;
    delaytime:word;
    transcolor:byte;
  END;

  TRGB=RECORD
    r,g,b:byte;
  END;

  PMediaGIF=^TMediaGIF;
  TMediaGIF=OBJECT(TMedia)
    globalpal,localpal:tpal;
    gifver:word;
    background:boolean;
    backgroundcolor,transparencycolor:longint;
    oldGIFImageDescriptor:TGIFImageDescriptor;
    oldGIFGraphicControlExtension:TGIFGraphicControlExtension;
    CONSTRUCTOR OpenMedia(name:string);
    PROCEDURE SetRenderMode(mode:longint);virtual;
    FUNCTION GrabFrame:pimage;virtual;
    DESTRUCTOR CloseMedia;
  END;

{------------------------------- MNG-Animation ------------------------------}

  PmediaMNG=^TmediaMNG;
  TmediaMNG=OBJECT(TMedia)
    CONSTRUCTOR OpenMedia(name:string);
    FUNCTION GrabFrame:pimage;virtual;
    DESTRUCTOR CloseMedia;
  END;

{------------------------------- Quicktime MOV-Player -----------------------}

  TstsdQT=RECORD
    r1:longint;
    r2:longint;
    version:word;
    revision:word;
    vendor:tfourcc;
    tempqual:longint;
    spatqual:longint;
    width,height:word;
    hres:longint;
    vres:longint;
    datasize:longint;
    framecount:word;
    compressorname:string[31];
    colordepth:word;
    colortableID:word;
   END;

  TmvhdQT=RECORD
    version:longint;
    creation:longint;
    modtime:longint;
    timescale:longint;
    duration:longint;
    rate:longint;
    volume:word;
    res1:longint;
    res2:longint;
    matrix:array[0..2,0..2] of longint;
    res3:word;
    pvtime:longint;
    pvduration:longint;
    postime:longint;
    seltime:longint;
    selduration:longint;
    curtime:longint;
    nexttkid:longint;
  END;

  TtkhdQT=RECORD
    version:longint;
    creation:longint;
    modtime:longint;
    trakid:longint;
    timescale:longint;
    duration:longint;
    timeoff:longint;
    priority:longint;
    layer:word;
    altgroup:word;
    volume:word;
    matrix:array[0..2,0..2] of longint;
    tkwidth:longint;
    tkheight:longint;
    pad:word;
  END;

  TmdhdQT=RECORD
    version:longint;
    creation:longint;
    modtime:longint;
    timescale:longint;
    duration:longint;
    language:word;
    quality:word;
  END;

  ThdlrQT=RECORD
    version:longint;
    typ,subtyp,vendor:Tfourcc;
    flags:longint;
    mask:longint;
    info:string;
  END;

  PmediaMOV=^TmediaMOV;
  TmediaMOV=OBJECT(TMedia)
    stsd:TstsdQT;
    mvhd:TmvhdQT;
    tkhd:TtkhdQT;
    mdhd:TmdhdQT;
    hdlr:ThdlrQT;
    timeidxlist:pointer;
    CONSTRUCTOR OpenMedia(name:string);
    FUNCTION GetFrameTime:word;virtual;
    FUNCTION GrabFrame:pimage;virtual;
    DESTRUCTOR CloseMedia;
  END;

{----------------------------------------------------------------------------}

CONST gmrm_solid        =$00000000;
      gmrm_transparency =$00000001;

IMPLEMENTATION

USES gxcrtext,gxbase,graphix,gxmdecod,objects,gximg;

{----------------------------------------------------------------------------}

FUNCTION cmp(f1,f2:tfourcc):boolean;
BEGIN
  cmp:=((f1[0]=f2[0]) AND (f1[1]=f2[1]) AND (f1[2]=f2[2]) AND (f1[3]=f2[3]));
END;

{------------------------------- TMedia -------------------------------------}

CONSTRUCTOR TMedia.OpenMedia(name:string);
BEGIN
  assign(MediaF,name);
  reset(MediaF,1);
  fileopen:=(ioresult=0);
  filesupported:=FALSE;
  framebuf:=nil;
  numframe:=0;
  curframe:=0;
  framexd:=0;
  frameyd:=0;
{  framesize:=0; }
  timeofMedia:=0;
  flags:=0;
  rendermode:=gmrm_solid;
END;

PROCEDURE TMedia.StartMedia;
BEGIN
  curframe:=0;
END;

PROCEDURE TMedia.SeekMedia(pos:word);
BEGIN
  IF (pos>0) AND (pos<=numframe) THEN curframe:=pos-1;
END;

PROCEDURE TMedia.SetRenderMode(mode:longint);
BEGIN
  rendermode:=mode;
END;

FUNCTION TMedia.GrabFrame:pimage;
BEGIN
  Grabframe:=framebuf;
END;

FUNCTION TMedia.GetFrameTime:word;
BEGIN
  GetFrameTime:=frametime;
END;

FUNCTION TMedia.GetNumFrame:word;
BEGIN
  GetNumFrame:=NumFrame;
END;

FUNCTION TMedia.GetCurFrame:word;
BEGIN
  GetCurFrame:=CurFrame;
END;

FUNCTION TMedia.GetDuration:longint;
BEGIN
  GetDuration:=timeofMedia;
END;

FUNCTION TMedia.GetWidth:word;
BEGIN
  GetWidth:=framexd;
END;

FUNCTION TMedia.GetHeight:word;
BEGIN
  GetHeight:=frameyd;
END;

FUNCTION TMedia.EndofMedia:boolean;
BEGIN
  EndofMedia:=(curframe=numframe);
END;

DESTRUCTOR TMedia.CloseMedia;
BEGIN
  IF fileopen THEN close(MediaF);
END;

{------------------------------- ANI-Cursor ---------------------------------}

  CONSTRUCTOR TMediaAni.OpenMedia(name:string);
  VAR StreamIO:PBufStream;

    PROCEDURE ProcessChunks(listsize:longint);
    VAR Chunk:TChunk;
        startpos:longint;
        iml,i:PImageList;
    BEGIN
      REPEAT
        StreamIO^.Read(Chunk,8);
        Chunk.size:=(Chunk.size+1) AND $FFFFFFFE;
{DBG(Chunk.fourcc,Chunk.size);}
        IF (Chunk.fourcc='RIFF') OR (Chunk.fourcc='LIST') OR (Chunk.fourcc='FORM') THEN
          BEGIN
            StreamIO^.read(chunk,4);
            ProcessChunks(chunk.size-4);
          END
        ELSE
          BEGIN
            if (Chunk.fourcc='icon') then
              begin
                startpos:=StreamIO^.GetPos;
                new(iml);
                iml^.next:=nil;
                loadimageStream(itICO,StreamIO,iml^.image,1);
                if (CachedFrames=nil) then
                  begin
                    CachedFrames:=iml;
                  end
                else
                  begin
                    i:=CachedFrames;
                    while i^.next<>nil do i:=i^.next;
                    i^.next:=iml;
                  end;
                StreamIO^.Seek(StartPos+chunk.size);
              end
            else if (Chunk.fourcc='anih') then
              begin
                StreamIO^.Read(anih,chunk.size);
              end
            else if Chunk.fourcc='rate' then
              begin
                ratesize:=chunk.size;
                getmem(rate,ratesize);
                StreamIO^.Read(rate^,ratesize);
              end
            else if (Chunk.fourcc='seq ') or (Chunk.fourcc='seq'#0) then
              begin
                seqsize:=chunk.size;
                getmem(seq,seqsize);
                StreamIO^.Read(seq^,seqsize);
              end
            else if (Chunk.fourcc='IART') then
              begin
                IARTsize:=chunk.size;
                getmem(IART,IARTsize);
                StreamIO^.Read(IART^,IARTsize);
              end
            else if Chunk.fourcc='INAM' then
              begin
                INAMsize:=chunk.size;
                getmem(INAM,INAMsize);
                StreamIO^.Read(INAM^,INAMsize);
              end
            else
              begin (* ignore chunk *)
                StreamIO^.seek(StreamIO^.getpos+chunk.size);
              end;
          END;
        dec(listsize,chunk.size+8);
      UNTIL (listsize<=8);
      StreamIO^.seek(StreamIO^.getpos+listsize);
    END;

  var l:longint;

  begin
{    assign(MediaF,name);
    reset(MediaF,1);
    fs:=filesize(MediaF);
    close(MediaF);     }
    new(StreamIO,Init(name,stOpenRead,4096));
    if StreamIO^.status=stInitError then
      begin
        Dispose(StreamIO,Done);
        exit;
      end;
    fileopen:=false;
    filesupported:=FALSE;
    framebuf:=nil;
    numframe:=0;
    curframe:=0;
    framexd:=0;
    frameyd:=0;
    timeofMedia:=0;
    flags:=0;
    rendermode:=0;

    rate:=nil;
    seq:=nil;
    IART:=nil;
    INAM:=nil;

    CachedFrames:=nil;

    ProcessChunks(-1);

    curframe:=0;
    numframe:=anih.FrameCount;
    framexd:=CachedFrames^.image^.width;
    frameyd:=CachedFrames^.image^.height;
    timeofMedia:=rate^;
    frametime:=timeofMedia;
    framebuf:=CachedFrames^.image;

    if seq=nil then
      begin
        seqsize:=anih.IconCount*4;
        getmem(seq,seqsize);
        for l:=0 to anih.IconCount-1 do seq[l]:=l;
      end;

    if rate=nil then
      begin
        ratesize:=anih.FrameCount*4;
        getmem(rate,ratesize);
        for l:=0 to anih.FrameCount-1 do rate[l]:=anih.JifRate;
      end;

    Dispose(StreamIO,Done);
  end;

  PROCEDURE TMediaANI.SeekMedia(pos:word);
    BEGIN
      if pos<=0 then pos:=1;
      if pos-1>numframe then curframe:=numframe
      else curframe:=pos-1;
      timeofMedia:=rate[curframe];
      frametime:=timeofMedia;
    END;

  FUNCTION TMediaAni.GetFrameTime:word;
  BEGIN
    GetFrameTime:=rate[curframe-1]*17;
  END;

  FUNCTION TMediaAni.GrabFrame:pimage;
    var
      idxImg,l:longint;
      iml:PImageList;
    begin
      IdxImg:=seq[curframe];
      iml:=CachedFrames;
      l:=0;
      while (l<IdxImg)  do
        begin
          iml:=iml^.next;
          if iml^.next=nil then break;
          inc(l);
        end;
      if iml<>nil then framebuf:=iml^.image;
      inc(curframe);
      if curframe>numframe then curframe:=numframe;
      GrabFrame:=framebuf;
    end;

  DESTRUCTOR TMediaAni.CloseMedia;
    var
      iml,i:PImageList;
    begin
{DBG('A');}
      iml:=CachedFrames;
      repeat
        i:=iml^.next;
        if iml<>nil then
          begin
          {  freemem(iml^.image,iml^.image^.size);  }
          {  if (iml^.image<>nil) THEN} destroyimage(iml^.image);
            dispose(iml);
          end;
        iml:=i;
      until iml=nil;
{DBG('B');}
      if INAM<>nil then freemem(INAM,INAMsize);
{DBG('C');}
      if IART<>nil then freemem(IART,IARTsize);
{DBG('D');}
      if rate<>nil then freemem(rate,ratesize);
{DBG('E');}
      if seq<>nil then freemem(seq,seqsize);
    end;

  function TMediaAni.GetMediaInfoIART:pchar;
    begin
      GetMediaInfoIART:=IART;
    end;

  function TMediaAni.GetMediaInfoINAM:pchar;
    begin
      GetMediaInfoINAM:=INAM;
    end;

{------------------------------- AVI-Video ----------------------------------}

CONSTRUCTOR TmediaAVI.OpenMedia(name:string);
VAR fpos:longint;

  PROCEDURE Decode_idx1(size:longint);
  TYPE Tidx1entry=RECORD
         fourcc:tfourcc;
         flags:longint;
         index:longint;
         size:longint;
       END;
  VAR idx1entry:Tidx1entry;
      io,addofs:longint;
  BEGIN
    curframe:=0;
    addofs:=-1;
    WHILE (size>0) DO
      BEGIN
        blockread(mediaF,idx1entry,16,io);
        IF (addofs=-1) THEN
          IF (idx1entry.index<=4) THEN
            addofs:=fpos ELSE addofs:=0;
        IF cmp(idx1entry.fourcc,'00db') OR cmp(idx1entry.fourcc,'00dc') OR
           cmp(idx1entry.fourcc,'00id') OR cmp(idx1entry.fourcc,'00iv') THEN
          BEGIN
            inc(curframe);
           { longint((frameidxlist+curframe*4)^):=idx1entry.index+addofs }
            (frameidxlist+curframe)^:=idx1entry.index+addofs;
          END;
        dec(size,16);
      END;
    numframe:=curframe;
  END;

  PROCEDURE ProcessChunkListAVI(listsize:longint);
  VAR chunk:tchunk;
      list:tfourcc;
      io:longint;
  BEGIN
    REPEAT
      blockread(mediaF,chunk,8,io);
      chunk.size:=(chunk.size+1) AND $FFFFFFFE;
      IF cmp(Chunk.fourcc,'LIST') THEN
        BEGIN
          blockread(mediaF,list,4,io);
          IF cmp(list,'movi') THEN
            BEGIN
              fpos:=filepos(mediaF)-4;
              IF (avih.flags AND $00000010>0) THEN
                BEGIN
                  seek(mediaF,filepos(mediaF)+chunk.size-4);
                END
              ELSE
                BEGIN
                  ProcessChunkListAVI(chunk.size-4);
                  numframe:=curframe;
                END;
            END
          ELSE
            BEGIN
              ProcessChunkListAVI(chunk.size-4);
            END;
        END
      ELSE IF cmp(Chunk.fourcc,'00db') OR cmp(Chunk.fourcc,'00dc') OR
              cmp(Chunk.fourcc,'00id') OR cmp(Chunk.fourcc,'00iv') THEN
        BEGIN
          inc(curframe);
        {  longint((frameidxlist+curframe*4)^):=filepos(mediaF)-8; }
          (frameidxlist+curframe)^:=filepos(mediaF)-8;
          seek(mediaF,filepos(mediaF)+chunk.size);
        END
      ELSE IF cmp(Chunk.fourcc,'01wb') THEN seek(mediaF,filepos(mediaF)+chunk.size)
      ELSE IF cmp(Chunk.fourcc,'avih') THEN blockread(mediaF,avih,chunk.size,io)
      ELSE IF cmp(Chunk.fourcc,'strh') THEN blockread(mediaF,strh,chunk.size,io)
      ELSE IF cmp(Chunk.fourcc,'strf') THEN
        BEGIN
          IF cmp(strh.streamtype,'vids') THEN
            BEGIN
              blockread(mediaF,strfvideo,chunk.size,io);
              IF cmp(strh.streamhandler,'mrle') THEN flags:=$20;
              IF cmp(strh.streamhandler,'RLE ') THEN flags:=$20;
              IF cmp(strh.streamhandler,'cvid') OR cmp(strh.streamhandler,'CVID') THEN flags:=$30;
              IF cmp(strh.streamhandler,#0#0#0#0) THEN
                BEGIN
                  IF cmp(strfvideo.compression,#0#0#0#0) THEN
                    CASE (strfvideo.bitdepth) OF
                      8:flags:=$F0;
                     16:flags:=$F1;
                     24:flags:=$F2;
                     32:flags:=$F3;
                    END;
                  IF cmp(strfvideo.compression,'CRAM') THEN
                    CASE (strfvideo.bitdepth) OF
                      8:flags:=$10;
                     16:flags:=$11;
                    END;
                END;
              IF cmp(strh.streamhandler,'msvc') OR cmp(strh.streamhandler,'MSVC') THEN
                BEGIN
                  IF cmp(strfvideo.compression,'CRAM') THEN
                    CASE (strfvideo.bitdepth) OF
                      8:flags:=$10;
                     16:flags:=$11;
                    END;
                END;
              IF cmp(strh.streamhandler,'DIB ') THEN
                CASE (strfvideo.bitdepth) OF
                  8:flags:=$F0;
                 16:flags:=$F1;
                 24:flags:=$F2;
                 32:flags:=$F3;
                END;
       {       writedebugstring(hexbyte(flags));
              writelndebug; }

              framexd:=strfvideo.width;
              frameyd:=strfvideo.height;
              framebuf:=CreateImageWH(framexd,(frameyd+3) AND $7FFC);
              framebuf^.height:=frameyd;

              frametime:=avih.microseconds DIV 1000;
              timeofmedia:=strh.length;

              numframe:=avih.totalframes;
           {   writedebuglongint(numframe); }
              IF (numframe>16379) THEN numframe:=16379;
              getmem(frameidxlist,(numframe+1)*4);
              fillchar(frameidxlist^,(numframe+1)*4,0);
              frameidxlist^:=(numframe+1)*4;
              curframe:=0;
              FOR io:=0 TO 255 DO
                longint((processbuf+io*4)^):=rgbcolor(strfvideo.palette[io]);
              IF (flags<>0) THEN filesupported:=TRUE;
            END
          ELSE IF cmp(strh.streamtype,'auds') THEN
            BEGIN
              blockread(mediaF,strfaudio,chunk.size,io)
            END
          ELSE
            BEGIN
              seek(mediaF,filepos(mediaF)+chunk.size);
            END;
        END
      ELSE IF cmp(Chunk.fourcc,'idx1') THEN Decode_idx1(chunk.size)
      ELSE IF cmp(Chunk.fourcc,'JUNK') THEN seek(mediaF,filepos(mediaF)+chunk.size)
      ELSE seek(mediaF,filepos(mediaF)+chunk.size);
      dec(listsize,chunk.size+8);
    UNTIL (listsize<=8);
    seek(mediaF,filepos(mediaF)+listsize);
  END;

VAR io:longint;
    chunk:tfourcc;
    size:longint;
BEGIN
  INHERITED OpenMedia(name);
  IF fileopen THEN
    BEGIN
      getmem(processbuf,32768);
      blockread(mediaF,Chunk,4,io);
      IF cmp(Chunk,'RIFF') THEN
        BEGIN
          blockread(mediaF,size,4,io);
          blockread(mediaF,Chunk,4,io);
          IF cmp(Chunk,'AVI ') THEN ProcessChunkListAVI(size-4);
        END;
    END;
  curframe:=0;
END;

FUNCTION TmediaAVI.GrabFrame:pimage;
VAR io:longint;
    databuf:pointer;
    chunk:tchunk;
BEGIN
  IF (curframe>=0) AND (curframe<numframe) THEN
    BEGIN
      inc(curframe);
      IF (flags AND $FF>0) THEN
        BEGIN
          seek(mediaF,(frameidxlist+curframe)^);
          blockread(mediaF,chunk,8,io);
          chunk.size:=(chunk.size+1) AND $FFFFFFFE;
          IF (chunk.size>0) THEN
            BEGIN
              getmem(databuf,chunk.size);
              blockread(mediaF,databuf^,chunk.size,io);
              CASE flags OF
                $10:DecodeCRAM8(framexd,frameyd,databuf,framebuf,processbuf);
                $11:DecodeCRAM16(framexd,frameyd,databuf,framebuf);
                $20:DecodeMRLE8(framexd,frameyd,databuf,framebuf,processbuf);
                $30:DecodeCVID24(framexd,frameyd,databuf,framebuf,processbuf);
                $F0:DecodeDIB8(framexd,frameyd,databuf,framebuf,processbuf);
                $F1:DecodeDIB16(framexd,frameyd,databuf,framebuf);
                $F2:DecodeDIB24(framexd,frameyd,databuf,framebuf);
                $F3:DecodeDIB32(framexd,frameyd,databuf,framebuf);
              END;
              freemem(databuf,chunk.size);
            END;
        END;
    END;
  Grabframe:=framebuf;
END;

DESTRUCTOR TmediaAVI.CloseMedia;
BEGIN
  INHERITED CloseMedia;
  IF fileopen THEN
    BEGIN
      freemem(processbuf,32768);
      IF filesupported THEN
        BEGIN
          freemem(frameidxlist,frameidxlist^);
          DestroyImage(framebuf);
        END;
    END;
END;

{------------------------------- FLI/FLC-Animator ---------------------------}

CONSTRUCTOR TmediaFLC.OpenMedia(name:string);
VAR FLIheader:TFLIheader;
    FLIframeheader:TFLIframeheader;
    i:word;
    io:longint;
    curpos:longint;
BEGIN
  INHERITED OpenMedia(name);
  IF fileopen THEN
    BEGIN
      getmem(processbuf,1024);
      blockread(mediaF,FLIheader,sizeof(FLIheader),io);
      IF (FLIheader.magic=$AF11) OR (FLIheader.magic=$AF12) THEN
        BEGIN
          framexd:=FLIheader.width;
          frameyd:=FLIheader.height;
          framebuf:=CreateImageWH(framexd,frameyd);
          numframe:=FLIheader.frames;
          getmem(frameidxlist,(numframe+1)*4);
          fillchar(frameidxlist^,(numframe+1)*4,0);
          frameidxlist^:=(numframe+1)*4;
          curframe:=0;
          frametime:=70;
          CASE FLIheader.magic OF
            $4F11:frametime:=70;
            $4F12:frametime:=FLIheader.speed;
          END;
          FOR i:=1 TO numframe DO
            BEGIN
              curpos:=filepos(mediaF);
              blockread(mediaF,FLIframeheader,sizeof(FLIframeheader),io);
              IF (FLIframeheader.magic=$F1FA) THEN
                BEGIN
                  inc(curframe);
                  (frameidxlist+curframe)^:=curpos;
                END;
              seek(mediaF,curpos+FLIframeheader.size);
            END;
          filesupported:=TRUE;
          seek(mediaF,0);
        END;
    END;
  curframe:=0;
END;

FUNCTION TmediaFLC.GrabFrame:pimage;
VAR FLIframeheader:TFLIframeheader;
    FLIframechunkheader:TFLIframechunkheader;
    chunknr:word;
    databuf:pointer;
    io:longint;

  PROCEDURE FLI_256_COLOR_4;
  VAR curpacket,packets:word;
      curcol,skip_count,size_count,x:byte;
      offs:pointer;
  BEGIN
    offs:=databuf;
    packets:=word(offs^);
    inc(offs,2);
    curcol:=0;
    FOR curpacket:=1 TO packets DO
      BEGIN
        skip_count:=byte(offs^);
        inc(offs);
        inc(curcol,skip_count);
        size_count:=byte(offs^)-1;
        inc(offs);
        FOR x:=0 TO size_count DO
          BEGIN
            longint((processbuf+curcol*4)^):=
              rgbcolorRGB(byte(offs^),byte((offs+1)^),byte((offs+2)^));
            inc(curcol);
            inc(offs,3);
          END;
      END;
  END;

  PROCEDURE FLI_COLOR_11;
  VAR curpacket,packets:word;
      curcol,skip_count,size_count,x:byte;
      offs:pointer;
  BEGIN
    offs:=databuf;
    packets:=word(offs^);
    inc(offs,2);
    curcol:=0;
    FOR curpacket:=1 TO packets DO
      BEGIN
        skip_count:=byte(offs^);
        inc(offs);
        inc(curcol,skip_count);
        size_count:=byte(offs^)-1;
        inc(offs);
        FOR x:=0 TO size_count DO
          BEGIN
            longint((processbuf+curcol*4)^):=
              rgbcolorRGB(byte(offs^) SHL 2,byte((offs+1)^) SHL 2,byte((offs+2)^) SHL 2);
            inc(curcol);
            inc(offs,3);
          END;
      END;
  END;

  PROCEDURE DecodeBLACK13;
  VAR buf:pointer;
      framesize:longint;
  BEGIN
    buf:=framebuf;
    framesize:=framebuf^.size;
    ASM
      MOV ECX,framesize
      SHR ECX,2
      MOV EDI,buf
      MOV EDI,[EDI+timage.pixeldata]
  {    ADD EDI,imagedatastart }
      XOR EAX,EAX
      REP STOSD
    END;
  END;

BEGIN
  inc(curframe);
  seek(mediaF,(frameidxlist+curframe)^);
  blockread(mediaF,FLIframeheader,sizeof(FLIframeheader),io);
  IF (FLIframeheader.magic=$F1FA) THEN
    BEGIN
      FOR chunknr:=1 TO FLIframeheader.chunks DO
        BEGIN
          blockread(mediaF,FLIframechunkheader,sizeof(FLIframechunkheader),io);
          getmem(databuf,FLIframechunkheader.size-sizeof(TFLIframechunkheader));
       {   writedebugstring(long2str(FLIframechunkheader._type)+' '); }
          blockread(mediaF,databuf^,FLIframechunkheader.size-sizeof(TFLIframechunkheader),io);
          CASE FLIframechunkheader._type OF
            4:FLI_256_COLOR_4;
            7:DecodeDELTA7(framexd,frameyd,databuf,processbuf,framebuf);
           11:FLI_COLOR_11;
           12:DecodeLC12(framexd,frameyd,databuf,processbuf,framebuf);
           13:DecodeBLACK13;
           15:DecodeBRUN15(framexd,frameyd,databuf,processbuf,framebuf);
           16:DecodeCOPY16(framexd,frameyd,databuf,processbuf,framebuf);
           18:;
           END;
           freemem(databuf,FLIframechunkheader.size-sizeof(TFLIframechunkheader));
        END;
  {    writelndebug; }
    END;
  GrabFrame:=Framebuf;
END;

DESTRUCTOR TmediaFLC.CloseMedia;
BEGIN
  INHERITED CloseMedia;
  IF fileopen THEN
    BEGIN
      freemem(processbuf,1024);
      IF filesupported THEN
        BEGIN
          freemem(frameidxlist,frameidxlist^);
          DestroyImage(framebuf);
        END;
    END;
END;

{-------------------------------- GIF-Animator ------------------------------}

PROCEDURE fillimage(xs,ys,xd,yd:longint;img:pimage;color:longint);
VAR xp,yp:pointer;
    x,y:longint;
BEGIN
  yp:=img^.pixeldata+dword(ys)*img^.bytesperline+dword(xs)*bytperpix;
  FOR y:=0 TO yd-1 DO
    BEGIN
      xp:=yp;
      FOR x:=0 TO xd-1 DO
        BEGIN
          move(color,xp^,bytperpix);
          inc(xp,bytperpix);
        END;
      inc(yp,img^.bytesperline);
    END;
END;

CONSTRUCTOR TMediaGIF.OpenMedia(name:string);

TYPE PStack=^TStack;
     TStack=RECORD
       l:longint;
       next:PStack;
     END;

VAR GIFSignature:TGIFSignature;
    GIFScreenDescriptor:TGIFScreenDescriptor;
    GIFBlockID:char;
    GIFImageDescriptor:TGIFImageDescriptor;
    GIFExtensionBlock:TGIFExtensionBlock;
    stack:Pstack;
    i:longint;
    rgb:trgb;
    io:longint;
    extension,colfound:boolean;

  PROCEDURE DumpData;
  VAR count:byte;
      io:longint;
  BEGIN
    REPEAT
      blockread(mediaF,count,1,io);
      seek(mediaF,filepos(mediaF)+count);
    UNTIL (count=0) OR eof(mediaF);
  END;

  PROCEDURE Push(l:longint);
  VAR h:PStack;
  BEGIN
    new(h);
    h^.l:=l;
    h^.next:=stack;
    stack:=h;
  END;

  FUNCTION Pop:longint;
  VAR h:PStack;
  BEGIN
    h:=stack;
    Pop:=h^.l;
    stack:=h^.next;
    dispose(h);
  END;

BEGIN
  INHERITED OpenMedia(name);
  IF fileopen THEN
    BEGIN
      blockread(mediaF,GIFSignature,sizeof(GIFSignature),io);
      IF (GIFSignature[1]='G') AND (GIFSignature[2]='I') AND (GIFSignature[3]='F') THEN
        BEGIN
          gifver:=89;
          IF (GIFSignature[4]='8') AND (GIFSignature[5]='7') AND (GIFSignature[6]='a') THEN gifver:=87;
          IF (GIFSignature[4]='8') AND (GIFSignature[5]='9') AND (GIFSignature[6]='a') THEN gifver:=89;
          numframe:=0;
          stack:=nil;
          background:=FALSE;
          extension:=FALSE;
          fillchar(oldGIFGraphicControlExtension,sizeof(TGIFGraphicControlExtension),0);
          blockread(mediaF,GIFScreenDescriptor,sizeof(GIFScreenDescriptor),io);
          framexd:=GIFScreenDescriptor.width;
          frameyd:=GIFScreenDescriptor.height;
          framebuf:=CreateImageWH(framexd,frameyd);
          IF (GIFScreenDescriptor.flags AND $80=$80) THEN
            BEGIN
              FOR i:=0 TO (1 SHL (GIFScreenDescriptor.flags AND $07+1))-1 DO
                BEGIN
                  blockread(mediaF,rgb,3,io);
                  globalpal[i]:=rgbcolorRGB(rgb.r,rgb.g,rgb.b);
                END;
              background:=TRUE;
              backgroundcolor:=globalpal[GIFScreenDescriptor.background];

              io:=10;
              REPEAT
                transparencycolor:=rgbcolor(random($00FFFFFF));
                colfound:=FALSE;
                FOR i:=0 TO (1 SHL (GIFScreenDescriptor.flags AND $07+1))-1 DO
                  colfound:=colfound OR (globalpal[i]=transparencycolor);
              UNTIL NOT colfound OR (io<=0);
           {   backgroundcolor:=transparencycolor; }

           {   IF (gifver=89) THEN
                BEGIN
                  setimageflags(framebuf,img_transparency);
                  framebuf^.transparencycolor:=backgroundcolor;
                END;  }

              WITH GIFScreenDescriptor DO
                fillimage(0,0,width,height,framebuf,backgroundcolor);
              move(GIFImageDescriptor,oldGIFImageDescriptor,sizeof(TGIFImageDescriptor));
            END;
          REPEAT
            blockread(mediaF,GIFBlockID,sizeof(GIFBlockID),io);
            CASE GIFBlockID OF
            ';':;
            ',':BEGIN  { Image separator }
                  IF NOT extension THEN
                    BEGIN
                      inc(numframe);
                      push(filepos(mediaF)-1);
                    END;
                  blockread(mediaF,GIFImageDescriptor,sizeof(GIFImageDescriptor),io);
                  IF (GIFImageDescriptor.flags AND $80=$80) THEN
                    seek(mediaF,filepos(mediaF)+3*(2 SHL (GIFImageDescriptor.flags AND $07)));
                  seek(mediaF,filepos(mediaF)+1);
                  DumpData;
                  extension:=FALSE;
                END;
            '!':BEGIN
                  blockread(mediaF,GIFExtensionBlock,sizeof(GIFExtensionBlock),io);
                  IF (GIFExtensionBlock.functioncode=$F9) THEN
                    BEGIN
                      inc(numframe);
                      push(filepos(mediaF)-2);
                      extension:=TRUE;
                    END;
                  DumpData;
                END;
            END;
          UNTIL (GIFBlockID=';') OR ((GIFBlockID<>',') AND (GIFBlockID<>'!')) OR eof(mediaF);
          getmem(frameidxlist,(numframe+1)*4);
          fillchar(frameidxlist^,(numframe+1)*4,0);
          frameidxlist^:=(numframe+1)*4;
          FOR i:=numframe DOWNTO 1 DO (frameidxlist+i)^:=Pop;
          curframe:=0;
          frametime:=100;
        END;
    END;
END;

PROCEDURE TMediaGIF.SetRenderMode(mode:longint);
BEGIN
  INHERITED SetRenderMode(mode);
  IF background THEN
    IF (rendermode AND gmrm_transparency=gmrm_transparency)
      THEN fillimage(0,0,framexd,frameyd,framebuf,transparencycolor)
      ELSE fillimage(0,0,framexd,frameyd,framebuf,backgroundcolor);
END;

FUNCTION TMediaGIF.GrabFrame:pimage;
VAR GIFBlockID:char;
    GIFImageDescriptor:TGIFImageDescriptor;
    GIFExtensionBlock:TGIFExtensionBlock;
    GIFGraphicControlExtension:TGIFGraphicControlExtension;
    count:byte;
    pal:ppal;
    io,i:longint;
    rgb:Trgb;
    extension,transparency:boolean;
    transparencyindex:longint;

  PROCEDURE DumpData;
  VAR count:byte;
      io:longint;
  BEGIN
    REPEAT
      blockread(mediaF,count,1,io);
      seek(mediaF,filepos(mediaF)+count);
    UNTIL (count=0) OR eof(mediaF);
  END;

  PROCEDURE decodeGIFLZW(x,y,xd,yd:longint;image:pimage;pal:ppal;interlaced:boolean);
  CONST tablen=4095;
        ilstart:array[1..4] of longint=(0,4,2,1);
        ilstep:array[1..4] of longint=(8,8,4,2);
  TYPE Pstr=^Tstr;
       Tstr=RECORD
         prefix:Pstr;
         suffix:longint;
       END;
       Pstrtab=^Tstrtab;
       Tstrtab=array[0..tablen] of Tstr;

  VAR strtab:Pstrtab;
      oldcode,curcode,clearcode,endcode:longint;
      codesize,codelen,codemask:longint;
      stridx:longint;
      bitbuf,bitsinbuf:longint;
      bytbuf:array[0..255] of byte;
      bytinbuf,bytbufidx:byte;
      endofsrc:boolean;
      xcnt,ycnt,ystep,pass:longint;
      imageypos:pointer;
      io:longint;

    PROCEDURE InitStringTable;
    VAR i:longint;
    BEGIN
      new(strtab);
      clearcode:=1 SHL codesize;
      endcode:=clearcode+1;
      stridx:=endcode+1;
      codelen:=codesize+1;
      codemask:=(1 SHL codelen)-1;
      FOR i:=0 TO clearcode-1 DO
        BEGIN
          strtab^[i].prefix:=nil;
          strtab^[i].suffix:=i;
        END;
      FOR i:=clearcode TO tablen DO
        BEGIN
          strtab^[i].prefix:=nil;
          strtab^[i].suffix:=0;
        END;
    END;

    PROCEDURE ClearStringTable;
    VAR i:longint;
    BEGIN
      clearcode:=1 SHL codesize;
      endcode:=clearcode+1;
      stridx:=endcode+1;
      codelen:=codesize+1;
      codemask:=(1 SHL codelen)-1;
      FOR i:=clearcode TO tablen DO
        BEGIN
          strtab^[i].prefix:=nil;
          strtab^[i].suffix:=0;
        END;
    END;

    PROCEDURE DoneStringTable;
    BEGIN
      dispose(strtab);
    END;

    FUNCTION GetNextCode:longint;
    BEGIN
      WHILE (bitsinbuf<codelen) DO
        BEGIN
          IF (bytinbuf=0) THEN
            BEGIN
              blockread(mediaF,bytinbuf,1,io);
              IF (bytinbuf=0) THEN endofsrc:=TRUE;
              blockread(mediaF,bytbuf,bytinbuf,io);
              bytbufidx:=0;
            END;
          bitbuf:=bitbuf OR (longint(byte(bytbuf[bytbufidx])) SHL bitsinbuf);
          inc(bytbufidx);
          dec(bytinbuf);
          inc(bitsinbuf,8);
        END;
      getnextcode:=bitbuf AND codemask;
      bitbuf:=bitbuf SHR codelen;
      dec(bitsinbuf,codelen);
    END;

    PROCEDURE AddStr2Tab(prefix:Pstr;suffix:longint);
    BEGIN
      strtab^[stridx].prefix:=prefix;
      strtab^[stridx].suffix:=suffix;
      inc(stridx);
      CASE stridx OF
      0..1:codelen:=1;
      2..3:codelen:=2;
      4..7:codelen:=3;
      8..15:codelen:=4;
      16..31:codelen:=5;
      32..63:codelen:=6;
      64..127:codelen:=7;
      128..255:codelen:=8;
      256..511:codelen:=9;
      512..1023:codelen:=10;
      1024..2047:codelen:=11;
      2048..4096:codelen:=12;
      END;
      codemask:=(1 SHL codelen)-1;
    END;

    FUNCTION Code2Str(code:longint):Pstr;
    BEGIN
      Code2Str:=addr(strtab^[code]);
    END;

    PROCEDURE WriteStr(s:Pstr);
    BEGIN
      IF (s^.prefix<>nil) THEN WriteStr(s^.prefix);
      IF (ycnt>=yd) THEN
        BEGIN
          IF interlaced THEN
            BEGIN
              WHILE (ycnt>=yd) AND (pass<5) DO
                BEGIN
                  inc(pass);
                  ycnt:=ilstart[pass];
                  ystep:=ilstep[pass];
                  imageypos:=image^.pixeldata+dword(y+ycnt)*image^.bytesperline+dword(x)*bytperpix;
                END;
            END;
        END;
      IF NOT transparency OR (transparency AND (s^.suffix<>transparencyindex)) THEN
        move(pal^[s^.suffix],(imageypos+dword(xcnt)*bytperpix)^,bytperpix);
      inc(xcnt);
      IF (xcnt>=xd) THEN
        BEGIN
          xcnt:=0;
          inc(ycnt,ystep);
          inc(imageypos,dword(ystep)*image^.bytesperline);
          IF NOT interlaced THEN
            IF (ycnt>=yd) THEN
              BEGIN
                inc(pass);
              END;
        END;
    END;

    FUNCTION firstchar(s:Pstr):byte;
    BEGIN
      WHILE (s^.prefix<>nil) DO s:=s^.prefix;
      firstchar:=s^.suffix;
    END;

  BEGIN
    endofsrc:=FALSE;
    xcnt:=0;
    IF interlaced THEN
      BEGIN
        pass:=1;
        ycnt:=ilstart[pass];
        ystep:=ilstep[pass];
      END
    ELSE
      BEGIN
        pass:=4;
        ycnt:=0;
        ystep:=1;
      END;
    imageypos:=image^.pixeldata+dword(y+ycnt)*image^.bytesperline+dword(x)*bytperpix;
    oldcode:=0;
    bitbuf:=0;
    bitsinbuf:=0;
    bytinbuf:=0;
    bytbufidx:=0;
    codesize:=0;
    blockread(mediaF,codesize,1,io);
    InitStringTable;
    curcode:=getnextcode;
    WHILE (curcode<>endcode) AND (pass<5) AND NOT endofsrc{ AND NOT finished} DO
      BEGIN
        IF (curcode=clearcode) THEN
          BEGIN
            ClearStringTable;
            REPEAT
              curcode:=getnextcode;
            UNTIL (curcode<>clearcode);
            IF (curcode=endcode) THEN break;
            WriteStr(code2str(curcode));
            oldcode:=curcode;
          END
        ELSE
          BEGIN
            IF (curcode<stridx) THEN
              BEGIN
                WriteStr(Code2Str(curcode));
                AddStr2Tab(Code2Str(oldcode),firstchar(Code2Str(curcode)));
                oldcode:=curcode;
              END
            ELSE
              BEGIN
                IF (curcode>stridx) THEN break;
                AddStr2Tab(Code2Str(oldcode),firstchar(Code2Str(oldcode)));
                WriteStr(Code2Str(stridx-1));
                oldcode:=curcode;
              END;
          END;
        curcode:=getnextcode;
      END;
    DoneStringTable;
    IF NOT endofsrc THEN DumpData;
  END;

BEGIN
  inc(curframe);
  seek(mediaF,(frameidxlist+curframe)^);
  extension:=FALSE;
  transparency:=TRUE;
  REPEAT
    blockread(mediaF,GIFBlockID,sizeof(GIFBlockID),io);
    CASE GIFBlockID OF
    ',':BEGIN
          pal:=@globalpal;
          blockread(mediaF,GIFImageDescriptor,sizeof(GIFImageDescriptor),io);
          IF (GIFImageDescriptor.flags AND $80=$80) THEN
            BEGIN
              pal:=@localpal;
              FOR i:=0 TO (2 SHL (GIFImageDescriptor.flags AND $07))-1 DO
                BEGIN
                  blockread(mediaF,rgb,3,io);
                  localpal[i]:=rgbcolorRGB(rgb.r,rgb.g,rgb.b);
                END;
            END;
          CASE (oldGIFGraphicControlExtension.flags AND $1C) OF
          $08:BEGIN
                IF background THEN
                  WITH oldGIFImageDescriptor DO
                    IF (rendermode AND gmrm_transparency=gmrm_transparency)
                      THEN fillimage(x,y,xd,yd,framebuf,transparencycolor)
                      ELSE fillimage(x,y,xd,yd,framebuf,backgroundcolor);
              END;
          END;
          move(GIFImageDescriptor,oldGIFImageDescriptor,sizeof(TGIFImageDescriptor));
          IF extension THEN
            BEGIN
              transparency:=(GIFGraphicControlExtension.flags AND $01=$01);
{DBG(GIFGraphicControlExtension.flags AND $01);}
              transparencyindex:=GIFGraphicControlExtension.transcolor;
              IF (GIFGraphicControlExtension.delaytime<>0) THEN
                frametime:=GIFGraphicControlExtension.delaytime*10;
              move(GIFGraphicControlExtension,oldGIFGraphicControlExtension,sizeof(TGIFGraphicControlExtension));

              IF (rendermode AND gmrm_transparency=gmrm_transparency)
                THEN framebuf^.transparencycolor:=transparencycolor
                ELSE framebuf^.transparencycolor:=backgroundcolor;

              clearimageflags(framebuf,img_transparency);
              IF (rendermode AND gmrm_transparency=gmrm_transparency) THEN
                setimageflags(framebuf,img_transparency);


         {     transparency:=transparency AND (rendermode AND gmrm_transparency=gmrm_solid); }
            END;
          WITH GIFImageDescriptor DO
            DecodeGIFLZW(x,y,xd,yd,framebuf,pal,(flags AND $40=$40));
        END;
    '!':BEGIN
          blockread(mediaF,GIFExtensionBlock,sizeof(GIFExtensionBlock),io);
          CASE GIFExtensionBlock.functioncode OF
          $F9:BEGIN
                blockread(mediaF,count,1,io);
                blockread(mediaF,GIFGraphicControlExtension,count,io);
                DumpData;
                extension:=TRUE;
              END;
          ELSE
              BEGIN
                DumpData;
              END;
          END;
        END;
    END;
  UNTIL (GIFBlockID<>'!');
  Grabframe:=framebuf;
END;

DESTRUCTOR TMediaGIF.CloseMedia;
BEGIN
  INHERITED CloseMedia;
  IF fileopen THEN
    BEGIN
      freemem(frameidxlist,frameidxlist^);
      DestroyImage(framebuf);
    END;
END;

{------------------------------- MNG - Animation ----------------------------}

CONSTRUCTOR TmediaMNG.OpenMedia(name:string);
BEGIN
  INHERITED OpenMedia(name);
  IF fileopen THEN
    BEGIN
    END;
  curframe:=0;
END;

FUNCTION TmediaMNG.GrabFrame:pimage;
BEGIN
  Grabframe:=framebuf;
END;

DESTRUCTOR TmediaMNG.CloseMedia;
BEGIN
  INHERITED CloseMedia;
  IF fileopen THEN
    BEGIN
    END;
END;

{------------------------------- Quicktime MOV-Player -----------------------}

CONSTRUCTOR TmediaMOV.OpenMedia(name:string);
TYPE Tstream=(unknown,audio,video);
VAR stream:Tstream;
    sampnum:longint;

  PROCEDURE CreateStandardPalette8bit;
  VAR r,g,b:byte;
      i:word;
  BEGIN
    i:=0;
    FOR r:=5 DOWNTO 0 DO
      FOR g:=5 DOWNTO 0 DO
        FOR b:=5 DOWNTO 0 DO
          BEGIN
            longint((processbuf+i*4)^):=rgbcolorRGB(r*51,g*51,b*51);
            inc(i);
          END;
    i:=216;
    FOR r:=9 DOWNTO 0 DO
      BEGIN
        longint((processbuf+i*4)^):=rgbcolorRGB(r*28,0,0);
        inc(i);
      END;
    FOR g:=9 DOWNTO 0 DO
      BEGIN
        longint((processbuf+i*4)^):=rgbcolorRGB(0,g*28,0);
        inc(i);
      END;
    FOR b:=9 DOWNTO 0 DO
      BEGIN
        longint((processbuf+i*4)^):=rgbcolorRGB(0,0,b*28);
        inc(i);
      END;
    i:=245;
    FOR r:=10 DOWNTO 0 DO
      BEGIN
        longint((processbuf+i*4)^):=rgbcolorRGB(r*25,r*25,r*25);
        inc(i);
      END;
  END;

  PROCEDURE ProcessChunkListMOV(listsize:longint);
  VAR chunk,id:tfourcc;
      size,version,len,num,i,j,k,io,akku:longint;
      count:longint;
      last,first_chk,samp_per,chunk_tag:longint;
      idxoffs:pointer;
  BEGIN
    WHILE (listsize>0) AND NOT eof(MediaF) DO
    BEGIN
      blockread(mediaF,size,4,io);
      blockread(mediaF,chunk,4,io);
      swap32(size);
      size:=size-8;
      IF cmp(chunk,'moov') OR
         cmp(chunk,'mdia') OR
         cmp(chunk,'minf') OR
         cmp(chunk,'stbl') OR
         cmp(chunk,'trak') THEN
        BEGIN
          ProcessChunkListMOV(size);
        END
      ELSE IF cmp(Chunk,'mvhd') THEN blockread(mediaF,mvhd,size,io)
      ELSE IF cmp(Chunk,'mdhd') THEN blockread(mediaF,mdhd,size,io)
      ELSE IF cmp(Chunk,'tkhd') THEN blockread(mediaF,tkhd,size,io)
      ELSE IF cmp(Chunk,'hdlr') THEN blockread(mediaF,hdlr,size,io)
      ELSE IF cmp(Chunk,'stsd') THEN
        BEGIN
          blockread(mediaF,version,4,io);
          blockread(mediaF,num,4,io);
          swap32(num);
          FOR i:=1 TO num DO
            BEGIN
              blockread(mediaF,len,4,io);
              blockread(mediaF,id,4,io);
              swap32(len);
              blockread(mediaF,stsd,len-8,io);
              IF (i=1) THEN
                IF (stream=video) THEN
                  BEGIN
                    flags:=0;
                    IF cmp(id,'rle ') THEN
                      CASE bytswp16(stsd.colordepth) OF
                 {      1:flags:=$20;
                       2:flags:=$21;
                       4:flags:=$22;}
                       8:flags:=$23;
                      16:flags:=$24;
                      24:flags:=$25;
               {       32:flags:=$26; }
                      END;
                    IF cmp(id,'cvid') THEN flags:=$30;
                 {   IF (id='rpza') THEN flags:=$80; }
                    IF (bytswp16(stsd.colortableID)=8) THEN CreateStandardPalette8bit;
                    swap16(stsd.width);
                    swap16(stsd.height);
                    framexd:=stsd.width;
                    frameyd:=stsd.height;
                    framebuf:=CreateImageWH(framexd,(frameyd+3) AND $7FFC{+1000});
                    framebuf^.height:=frameyd;
                    curframe:=0;
                    IF (flags<>0) THEN filesupported:=TRUE;
                  END;
            END;
        END
      ELSE IF cmp(Chunk,'stts') AND (stream=video) THEN
        BEGIN
          blockread(mediaF,version,4,io);
          blockread(mediaF,len,4,io);
          swap32(len);
          idxoffs:=pointer(timeidxlist);
          FOR i:=1 TO len DO
            BEGIN
              blockread(mediaF,num,4,io);
              blockread(mediaF,k,4,io);
              swap32(num);
              swap32(k);
              FOR j:=1 TO num DO
                BEGIN
                  inc(idxoffs,4);
                  longint(idxoffs^):=(k*1000) DIV bytswp32(mdhd.timescale);
                END;
            END;
        END
      ELSE IF cmp(Chunk,'stss') AND (stream=video) THEN
        BEGIN
          seek(mediaF,filepos(mediaF)+size);
        END
      ELSE IF cmp(Chunk,'stsc') AND (stream=video) THEN
        BEGIN
          idxoffs:=pointer(frameidxlist)+4;
          blockread(mediaF,version,4,io);
          blockread(mediaF,num,4,io);
          swap32(num);
          len:=(size-8) DIV num;

          blockread(mediaF,first_chk,4,io);
          IF (len=4) THEN blockread(mediaF,io,4,io);
          blockread(mediaF,samp_per,4,io);
          blockread(mediaF,chunk_tag,4,io);
          swap32(first_chk);
          swap32(samp_per);
          last:=first_chk;
          FOR i:=2 TO num DO
            BEGIN
              blockread(mediaF,first_chk,4,io);
              swap32(first_chk);
              FOR j:=last TO first_chk-1 DO
                BEGIN
                  word((idxoffs+0)^):=last;
                  word((idxoffs+2)^):=samp_per;
                  inc(idxoffs,samp_per*4);
                END;
              last:=first_chk;
              IF (len=4) THEN blockread(mediaF,io,4,io);
              blockread(mediaF,samp_per,4,io);
              blockread(mediaF,chunk_tag,4,io);
              swap32(samp_per);
            END;
          WHILE (word(idxoffs-pointer(frameidxlist))<32700) DO
            BEGIN
              word((idxoffs+0)^):=last;
              word((idxoffs+2)^):=samp_per;
              inc(idxoffs,samp_per*4);
            END;
        END
      ELSE IF cmp(Chunk,'stsz') AND (stream=video) THEN
        BEGIN
          idxoffs:=pointer(frameidxlist)+4;
          blockread(mediaF,version,4,io);
          blockread(mediaF,len,4,io);
          blockread(mediaF,num,4,io);
          swap32(len);
          swap32(num);
          sampnum:=num;
          IF (len=0) THEN
            BEGIN
              i:=0;
              WHILE (i<=num) DO
                BEGIN
                  first_chk:=word((idxoffs+0)^);
                  samp_per:=word((idxoffs+2)^);
                  akku:=0;
                  FOR j:=1 TO samp_per DO
                    BEGIN
                      inc(i);
                      IF (i<=num) THEN
                        BEGIN
                          blockread(mediaF,k,4,io);
                          swap32(k);
                          inc(akku,k);
                          inc(idxoffs,4);
                          IF (j<samp_per) THEN longint(idxoffs^):=akku;
                        END;
                    END;
                END;
            END
          ELSE
            BEGIN
              i:=0;
              WHILE (i<=num) DO
                BEGIN
                  first_chk:=word((idxoffs+0)^);
                  samp_per:=word((idxoffs+2)^);
                  akku:=0;
                  FOR j:=1 TO samp_per DO
                    BEGIN
                      inc(i);
                      IF (i<=num) THEN
                        BEGIN
                          inc(akku,len);
                          inc(idxoffs,4);
                          IF (j<samp_per) THEN longint(idxoffs^):=akku;
                        END;
                    END;
                END;
            END;
        END
      ELSE IF cmp(Chunk,'stco') AND (stream=video) THEN
        BEGIN
          blockread(mediaF,version,4,io);
          blockread(mediaF,num,4,io);
          swap32(num);
          idxoffs:=pointer(frameidxlist)+4;
          count:=0;
          FOR i:=1 TO num DO
            BEGIN
              first_chk:=word((idxoffs+0)^);
              samp_per:=word((idxoffs+2)^);
              blockread(mediaF,k,4,io);
              swap32(k);
              FOR j:=0 TO samp_per-1 DO
                BEGIN
                  inc(count);
                  IF (count<=sampnum) THEN
                    BEGIN
                      IF (j=0) THEN longint((idxoffs+j*4)^):=0;
                      inc(longint((idxoffs+j*4)^),k);
                    END;
                END;
              inc(idxoffs,samp_per*4);
            END;
        END
      ELSE IF cmp(Chunk,'vmhd') THEN
        BEGIN
          stream:=video;
          seek(mediaF,filepos(mediaF)+size);
        END
      ELSE IF cmp(Chunk,'smhd') THEN
        BEGIN
          stream:=audio;
          seek(mediaF,filepos(mediaF)+size);
        END
      ELSE IF cmp(Chunk,'mdat') THEN seek(mediaF,filepos(mediaF)+size)
      ELSE IF cmp(Chunk,'free') THEN seek(mediaF,filepos(mediaF)+size)
      ELSE
        BEGIN
          seek(mediaF,filepos(mediaF)+size);
        END;
      dec(listsize,size+8);
    END;
  END;

BEGIN
  INHERITED OpenMedia(name);
  IF fileopen THEN
    BEGIN
      getmem(processbuf,32768);
      getmem(frameidxlist,32768);
      getmem(timeidxlist,32768);
      fillchar(frameidxlist^,32768,0);
      fillchar(timeidxlist^,32768,0);
      stream:=unknown;
      ProcessChunkListMOV(filesize(mediaF));
      numframe:=sampnum;
    END;
  curframe:=0;
END;

FUNCTION TMediaMOV.GetFrameTime:word;
BEGIN
  GetFrameTime:=0;
  IF (curframe>=0) AND (curframe<=numframe) THEN
    GetFrameTime:=longint((timeidxlist+curframe*4)^);
END;

FUNCTION TmediaMOV.GrabFrame:pimage;
VAR size,io,toseek:longint;
    databuf:pointer;
BEGIN
  IF (curframe>=0) AND (curframe<=numframe) THEN
    BEGIN
      inc(curframe);
      IF (flags AND $FF>0) THEN
        BEGIN
          toseek:=(frameidxlist+curframe)^;
          seek(mediaF,toseek);
          blockread(mediaF,size,4,io);
          seek(mediaF,toseek);
          swap32(size);
          size:=(size+1) AND $00FFFFFE;
{writedebugstring(long2str(toseek)+'-'+long2str(size));
writelndebug;}
          IF (size>0) THEN
            BEGIN
              getmem(databuf,size);
              blockread(mediaF,databuf^,size,io);
              CASE flags OF
             {   $23:DecodeAPPLANIM8(framexd,frameyd,databuf,framebuf,processbuf^);
                $24:DecodeAPPLANIM16(framexd,frameyd,databuf,framebuf);
                $25:DecodeAPPLANIM24(framexd,frameyd,databuf,framebuf); }
                $30:DecodeCVID24(framexd,frameyd,databuf,framebuf,processbuf);
              END;
              freemem(databuf,size);
            END;
        END;
    END;
  Grabframe:=framebuf;
END;

DESTRUCTOR TmediaMOV.CloseMedia;
BEGIN
  INHERITED CloseMedia;
  IF fileopen THEN
    BEGIN
      freemem(processbuf,32768);
      freemem(frameidxlist,32768);
      freemem(timeidxlist,32768);
      DestroyImage(framebuf);
    END;
END;

{----------------------------------------------------------------------------}

END.

