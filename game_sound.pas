unit game_sound;
{$mode delphi}
interface
uses
	windows,directsound;

type
  Tsound=record
    idsb:IDirectSoundBuffer;
    notify:IDirectSoundNotify;
    event:Handle;
    destroypos:DWORD;
    end;

procedure InitializeIDS(var ids:IDirectSound);
procedure SetSoundBalance(var sound:Tsound; left: boolean);
procedure DestroySound(var sound:Tsound);
procedure PlaySound(var sound:Tsound;type_:word);
procedure LoadSound(var ids:IDirectSound;var sound:Tsound;fn:string;autostop:boolean);
procedure swapsoundstatus(var sound:Tsound);
function DSBStatus(sound:Tsound):DWORD;

implementation

procedure InitializeIDS(var ids:IDirectsound);
begin
	// create DirectSound interface, e.g. allocate device
	if (DirectSoundCreate(nil, ids, nil) < DS_OK) then begin
		writeln('DirectSoundCreate failed');
		ids := nil;
		exit
	end;

	// set the cooperative level to normal
	if(ids^^.SetCooperativeLevel(ids,GetForegroundWindow,DSSCL_NORMAL) < DS_OK)
    then
    begin
		writeln('SetCooperativeLevel failed');
		exit
    end;
end;

procedure swapsoundstatus(var sound:Tsound);
var dsbstatus:dword;
begin
with sound do
  begin
  idsb^^.getstatus(idsb,dsbstatus);
  if (dsbstatus=0)
  then playsound(sound,dsbplay_looping) else idsb^^.stop(idsb);
  end;
end;

function DSBStatus(sound:Tsound):DWORD;
var dsbstatus:dword;
begin
with sound do
  idsb^^.getstatus(idsb,dsbstatus);
DSBStatus:=dsbstatus;
end;

procedure SetSoundBalance(var sound:Tsound; left: boolean);
var
	flag : integer;
begin
if left then flag := DSBPAN_LEFT else flag := DSBPAN_RIGHT;
  sound.idsb^^.SetPan(sound.idsb,flag)
end;

procedure PlaySound(var sound:Tsound;type_:word);
var
  hr:HResult;
begin
hr := sound.idsb^^.Play(sound.idsb, 0, 0,type_);
	if (hr < DS_OK) then begin
		writeln('Failed to play static buffer');
		writeln(DSErrorString(hr));
		exit
	end;
end;

procedure DestroySound(var sound:Tsound);
begin
with sound do
  begin
  if notify<>nil then notify^^.release(notify);
  if event<>0 then closeHandle(event);
  if idsb<>nil then idsb^^.Release(idsb);
  notify:=nil;
  event:=0;
  idsb := nil;
  end;
end;

procedure LoadSound(var ids:IDirectSound;var sound:Tsound;fn:string;autostop:boolean);
var
	// the used file handle
	f : file;
	a : array[1..4] of char;
	// some temporary vars used in DirectSound calls
	audio1, audio2 : Pointer;
	audiosize1, audiosize2 : DWord;

	// the buffer descriptions of the two sounds
	bufferdesc : TDSBufferDesc;
	// WAVE format record read from the file
	waveformat : TWaveFormatEx;
	// the actual size of the raw wave data
	wavedatasize : Longint;

  posnotify:TDSBPositionNotify;
  hr:Hresult;
	//
	// searches for the string s in the current open file. Sets
	// the file read/write position after the header and returns true
	// if found, else returns false
	//
	function  Search(s: string): boolean;
	var
		p1,p2 : longint;
		b : char;
	begin
		Seek(f,0); p1 := 0; p2 := 1;
		while (p2 <= Length(s)) and (p1 < FileSize(f)) do begin
			BlockRead(f,b,1);
			if b = s[p2] then Inc(p2) else p2 := 1;
			Inc(p1)
		end;
		result := p2 > Length(s)
	end;

begin
	// open file and check RIFF header
	assign(f, fn); reset(f, 1);
	BlockRead(f, a, 4);
	if a <> 'RIFF' then begin
		writeln('Not a RIFF - file'); Halt(1)
	end;
	// skip some RIFF header data
	BlockRead(f,a,4);
	// check next chunk in file to be a WAVE file
	BlockRead(f,a,4);
	if a <> 'WAVE' then begin
		writeln('Not a WAVE - file'); Halt(1)
	end;
	// find fmt chunk (this one contains the wave format description)
	if not Search('fmt ') then begin
		writeln('Unknown WAVE format'); Halt(1)
	end;

	// read in some properties of the wave data in the file
	with waveformat do begin
		// skip first bytes of WAVE header
		BlockRead(f,a,4);
		BlockRead(f,wFormatTag,2);
		BlockRead(f,nChannels,2);
		BlockRead(f,nSamplesPerSec,4);
		// skip four bytes of WAVE header
		BlockRead(f,a,4);
		BlockRead(f,nBlockAlign,2);
		BlockRead(f,wBitsPerSample,4);
		// calculate rest of required data
		nBlockAlign := wBitsPerSample div 8 * nChannels;
		nAvgBytesPerSec := nSamplesPerSec * nBlockAlign
	end;

	// search for data chunk in file containing actual data
	if not Search('data') then begin
		writeln('No "data" chunk found in wave file )');
		Halt(1)
	end;

	// read size of wave data chunk (the size of the actual data)
	BlockRead(f, wavedatasize, 4);

	// create static buffer description
	fillchar(bufferdesc, sizeof(bufferdesc), 0);
	with bufferdesc do begin
		dwSize := sizeof(bufferdesc);
		// want a static buffer with global focus and allowed pan control
		dwFlags := DSBCAPS_STATIC or DSBCAPS_GLOBALFOCUS or DSBCAPS_CTRLPAN;
		dwBufferBytes := wavedatasize;
		lpwfxFormat := @waveformat;
	end;

	// create buffer
	if (ids^^.CreateSoundBuffer(ids, bufferdesc,sound.idsb, nil) < DS_OK) then begin
		writeln('Failed to create static buffer');
		exit
	end;

	// lock buffer data
	if (sound.idsb^^.Lock(sound.idsb, 0, 0,
		audio1, audiosize1, audio2, audiosize2, DSBLOCK_ENTIREBUFFER) < DS_OK) then begin
    MessageBox(GetActiveWindow,'Failed to lock static buffer','Fatal Sound Error',WM_QUIT);
		exit
	end;

	// write data to buffer
	BlockRead(f, audio1^, wavedatasize); close(f);

	// unlock buffer data
	if (sound.idsb^^.Unlock(sound.idsb,
		audio1, audiosize1, audio2, audiosize2) < DS_OK) then
    begin
    MessageBox(GetActiveWindow,'Failed to unlock static buffer','Fatal Sound Error',WM_QUIT);
		exit;
	  end;

  if autostop then sound.destroypos:=wavedatasize-waveformat.nAvgBytesPerSec
    else sound.destroypos:=wavedatasize+1;
  //notification stuff
  {
  sound.event:=createevent(nil,false,false,nil);
  if sound.event=0 then
    begin
    MessageBox(GetActiveWindow,'Sound Error','Fatal Sound Error',WM_QUIT);
    end;

  with posnotify do
    begin
    dwoffset:=wavedatasize-1;
    hEventNotify:=sound.event;
    end;

  hr:=sound.idsb^^.queryInterface(sound.idsb,IID_IDirectSoundNotify,sound.notify);
  if hr<DS_OK then
    begin
    MessageBox(GetActiveWindow,'Failed to create notification','Fatal Sound Error',WM_QUIT);
    exit;
    end;

  hr:=sound.notify^^.setnotificationpositions(sound.notify,1,posNotify);
  if hr<DS_OK then
    begin
    messageBox(GetActiveWindow,'','Fatal Sound Error',WM_QUIT);
    end;
  }
end;

begin
end.