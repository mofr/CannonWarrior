(*==========================================================================;
 *
 *  Copyright (C) 1995-1997 Microsoft Corporation.  All Rights Reserved.
 *
 *  File:       dsound.h
 *  Content:    DirectSound include file
 *
 *  DirectX 7.0 Delphi adaptation by Erik Unger
 *
 *  Modified: 22-Feb-2000
 *
 *  Download: http://www.delphi-jedi.org/DelphiGraphics/
 *  E-Mail: DelphiDirectX@next-reality.com
 *
 ***************************************************************************)

{
  Windows 98 and debug versions DInput and DSound

  Under Windows 98, the "debug" setup of the DirectX SDK 6.x skips DInput.DLL
  and DSound.DLL, i.e. makes you end up with the retail version of these two
  files without any notice.
  The debug versions of DInput.DLL and DSound.DLL can be found in the
  \extras\Win98\Win98Dbg folder of the SDK CD; they need to be installed
  "manually".
}

unit DirectSound;

{$I SWITCHES.INC}

interface

uses
  Windows,
  SysUtils,
  {$IFDEF DELPHI}MMSystem,{$ENDIF}
	{$IFDEF FPC}ole2{$ENDIF};

var
  DSoundDLL : HMODULE;

function DSErrorString(Value: HResult) : string;

const
  _FACDS = $878;
function MAKE_DSHResult(code: DWORD) : HResult;

const
  FLT_MIN = 1.175494351E-38;
  FLT_MAX = 3.402823466E+38;

const
// Direct Sound Component GUID {47D4D946-62E8-11cf-93BC-444553540000}
  CLSID_DirectSound: TGUID =
  	(D1:$47D4D946;D2:$62E8;D3:$11cf;D4:($93,$BC,$44,$45,$53,$54,$00,$00));

// DirectSound Capture Component GUID {B0210780-89CD-11d0-AF08-00A0C925CD16}
  CLSID_DirectSoundCapture: TGUID =
  	(D1:$47D4D946;D2:$62E8;D3:$11cf;D4:($93,$BC,$44,$45,$53,$54,$00,$00));

//
// Structures
//
type
{$IFDEF DELPHI}
  IDirectSound = interface;
  IDirectSoundBuffer = interface;
  IDirectSound3DListener = interface;
  IDirectSound3DBuffer = interface;
  IDirectSoundCapture = interface;
  IDirectSoundCaptureBuffer = interface;
  IDirectSoundNotify = interface;
  IKsPropertySet = interface;
{$ELSE}
	IDirectSound = ^__IDirectSoundThis;
	IDirectSoundBuffer = ^__IDirectSoundBufferThis;
	IDirectSound3DListener = ^__IDirectSound3DListenerThis;
	IDirectSound3DBuffer = ^__IDirectSound3DBufferThis;
	IDirectSoundCapture = ^__IDirectSoundCaptureThis;
	IDirectSoundCaptureBuffer = ^__IDirectSoundCaptureBufferThis;
	IDirectSoundNotify = ^__IDirectSoundNotifyThis;
	IKsPropertySet = ^__IKsPropertySetThis;

{$ENDIF}

  PDSCaps = ^TDSCaps;
  TDSCaps = packed record
    dwSize: DWORD;
    dwFlags: DWORD;
    dwMinSecondarySampleRate: DWORD;
    dwMaxSecondarySampleRate: DWORD;
    dwPrimaryBuffers: DWORD;
    dwMaxHwMixingAllBuffers: DWORD;
    dwMaxHwMixingStaticBuffers: DWORD;
    dwMaxHwMixingStreamingBuffers: DWORD;
    dwFreeHwMixingAllBuffers: DWORD;
    dwFreeHwMixingStaticBuffers: DWORD;
    dwFreeHwMixingStreamingBuffers: DWORD;
    dwMaxHw3DAllBuffers: DWORD;
    dwMaxHw3DStaticBuffers: DWORD;
    dwMaxHw3DStreamingBuffers: DWORD;
    dwFreeHw3DAllBuffers: DWORD;
    dwFreeHw3DStaticBuffers: DWORD;
    dwFreeHw3DStreamingBuffers: DWORD;
    dwTotalHwMemBytes: DWORD;
    dwFreeHwMemBytes: DWORD;
    dwMaxContigFreeHwMemBytes: DWORD;
    dwUnlockTransferRateHwBuffers: DWORD;
    dwPlayCpuOverheadSwBuffers: DWORD;
    dwReserved1: DWORD;
    dwReserved2: DWORD;
  end;
  PCDSCaps = ^TDSCaps;

  PDSBCaps = ^TDSBCaps;
  TDSBCaps = packed record
    dwSize: DWORD;
    dwFlags: DWORD;
    dwBufferBytes: DWORD;
    dwUnlockTransferRate: DWORD;
    dwPlayCpuOverhead: DWORD;
  end;
  PCDSBCaps = ^TDSBCaps;

  TDSBufferDesc_DX6 = packed record
    dwSize: DWORD;
    dwFlags: DWORD;
    dwBufferBytes: DWORD;
    dwReserved: DWORD;
    lpwfxFormat: PWaveFormatEx;
  end;

  TDSBufferDesc1 = TDSBufferDesc_DX6;
  PDSBufferDesc1 = ^TDSBufferDesc1;
  PCDSBufferDesc1 = PDSBufferDesc1;

  TDSBufferDesc_DX7 = packed record
    dwSize: DWORD;
    dwFlags: DWORD;
    dwBufferBytes: DWORD;
    dwReserved: DWORD;
    lpwfxFormat: PWaveFormatEx;
    guid3DAlgorithm: TGUID;
  end;

{$IFDEF DIRECTX6}
  TDSBufferDesc = TDSBufferDesc_DX6;
{$ELSE}
  TDSBufferDesc = TDSBufferDesc_DX7;
{$ENDIF}

  PDSBufferDesc = ^TDSBufferDesc;
  PCDSBufferDesc = PDSBufferDesc;


  TD3DValue = Single;

  PD3DVector = ^TD3DVector;
  TD3DVector = packed record
    case Integer of
    0: (
      x: TD3DValue;
      y: TD3DValue;
      z: TD3DValue;
     );
    1: (
      dvX: TD3DValue;
      dvY: TD3DValue;
      dvZ: TD3DValue;
     );
  end;

  PDS3DBuffer = ^TDS3DBuffer;
  TDS3DBuffer = packed record
    dwSize: DWORD;
    vPosition: TD3DVector;
    vVelocity: TD3DVector;
    dwInsideConeAngle: DWORD;
    dwOutsideConeAngle: DWORD;
    vConeOrientation: TD3DVector;
    lConeOutsideVolume: LongInt;
    flMinDistance: TD3DValue;
    flMaxDistance: TD3DValue;
    dwMode: DWORD;
  end;
  TCDS3DBuffer = ^TDS3DBuffer;

  PDS3DListener = ^TDS3DListener;
  TDS3DListener = packed record
    dwSize: DWORD;
    vPosition: TD3DVector;
    vVelocity: TD3DVector;
    vOrientFront: TD3DVector;
    vOrientTop: TD3DVector;
    flDistanceFactor: TD3DValue;
    flRolloffFactor: TD3DValue;
    flDopplerFactor: TD3DValue;
  end;
  PCDS3DListener = ^TDS3DListener;

  PDSCCaps = ^TDSCCaps;
  TDSCCaps = packed record
    dwSize: DWORD;
    dwFlags: DWORD;
    dwFormats: DWORD;
    dwChannels: DWORD;
  end;
  PCDSCCaps = ^TDSCCaps;

  PDSCBufferDesc = ^TDSCBufferDesc;
  TDSCBufferDesc = packed record
    dwSize: DWORD;
    dwFlags: DWORD;
    dwBufferBytes: DWORD;
    dwReserved: DWORD;
    lpwfxFormat: PWaveFormatEx;
  end;
  PCDSCBufferDesc = ^TDSCBufferDesc;

  PDSCBCaps = ^TDSCBCaps;
  TDSCBCaps = packed record
    dwSize: DWORD;
    dwFlags: DWORD;
    dwBufferBytes: DWORD;
    dwReserved: DWORD;
  end;
  PCDSCBCaps = ^TDSCBCaps;

  PDSBPositionNotify = ^TDSBPositionNotify;
  TDSBPositionNotify = packed record
    dwOffset: DWORD;
    hEventNotify: THandle;
  end;
  PCDSBPositionNotify = ^TDSBPositionNotify;

//
// DirectSound API
//
  TDSEnumCallbackW = function (lpGuid: PGUID; lpstrDescription: PWideChar;
      lpstrModule: PWideChar; lpContext: Pointer) : BOOL; stdcall;
  TDSEnumCallbackA = function (lpGuid: PGUID; lpstrDescription: PAnsiChar;
      lpstrModule: PAnsiChar; lpContext: Pointer) : BOOL; stdcall;
{$IFDEF UNICODE}
  TDSEnumCallback = TDSEnumCallbackW;
{$ELSE}
  TDSEnumCallback = TDSEnumCallbackA;
{$ENDIF}

{$IFDEF DELPHI}
//
// IDirectSound
//
  IDirectSound = interface (IUnknown)
    ['{279AFA83-4981-11CE-A521-0020AF0BE560}']
    // IDirectSound methods
    function CreateSoundBuffer(const lpDSBufferDesc: TDSBufferDesc;
        out lpIDirectSoundBuffer: IDirectSoundBuffer;
        pUnkOuter: IUnknown) : HResult; stdcall;
    function GetCaps(var lpDSCaps: TDSCaps) : HResult; stdcall;
    function DuplicateSoundBuffer(lpDsbOriginal: IDirectSoundBuffer;
        out lpDsbDuplicate: IDirectSoundBuffer) : HResult; stdcall;
    function SetCooperativeLevel(hwnd: HWND; dwLevel: DWORD) : HResult; stdcall;
    function Compact: HResult; stdcall;
    function GetSpeakerConfig(var lpdwSpeakerConfig: DWORD) : HResult; stdcall;
    function SetSpeakerConfig(dwSpeakerConfig: DWORD) : HResult; stdcall;
    function Initialize(lpGuid: PGUID) : HResult; stdcall;
  end;

//
// IDirectSoundBuffer
//
  IDirectSoundBuffer = interface (IUnknown)
    ['{279AFA85-4981-11CE-A521-0020AF0BE560}']
    // IDirectSoundBuffer methods
    function GetCaps(var lpDSCaps: TDSBCaps) : HResult; stdcall;
    function GetCurrentPosition
        (lpdwCapturePosition, lpdwReadPosition : PDWORD) : HResult; stdcall;
    function GetFormat(lpwfxFormat: PWaveFormatEx; dwSizeAllocated: DWORD;
        lpdwSizeWritten: PWORD) : HResult; stdcall;
    function GetVolume(var lplVolume: integer) : HResult; stdcall;
    function GetPan(var lplPan: integer) : HResult; stdcall;
    function GetFrequency(var lpdwFrequency: DWORD) : HResult; stdcall;
    function GetStatus(var lpdwStatus: DWORD) : HResult; stdcall;
    function Initialize(lpDirectSound: IDirectSound;
        const lpcDSBufferDesc: TDSBufferDesc) : HResult; stdcall;
    function Lock(dwWriteCursor, dwWriteBytes: DWORD;
        var lplpvAudioPtr1: Pointer; var lpdwAudioBytes1: DWORD;
        var lplpvAudioPtr2: Pointer; var lpdwAudioBytes2: DWORD;
        dwFlags: DWORD) : HResult; stdcall;
    function Play(dwReserved1,dwReserved2,dwFlags: DWORD) : HResult; stdcall;
    function SetCurrentPosition(dwPosition: DWORD) : HResult; stdcall;
    function SetFormat(const lpcfxFormat: TWaveFormatEx) : HResult; stdcall;
    function SetVolume(lVolume: integer) : HResult; stdcall;
    function SetPan(lPan: integer) : HResult; stdcall;
    function SetFrequency(dwFrequency: DWORD) : HResult; stdcall;
    function Stop: HResult; stdcall;
    function Unlock(lpvAudioPtr1: Pointer; dwAudioBytes1: DWORD;
        lpvAudioPtr2: Pointer; dwAudioBytes2: DWORD) : HResult; stdcall;
    function Restore: HResult; stdcall;
  end;

//
// IDirectSound3DListener
//
  IDirectSound3DListener = interface (IUnknown)
    ['{279AFA84-4981-11CE-A521-0020AF0BE560}']
    // IDirectSound3D methods
    function GetAllParameters(var lpListener: TDS3DListener) : HResult; stdcall;
    function GetDistanceFactor(var lpflDistanceFactor: TD3DValue) : HResult; stdcall;
    function GetDopplerFactor(var lpflDopplerFactor: TD3DValue) : HResult; stdcall;
    function GetOrientation
        (var lpvOrientFront, lpvOrientTop: TD3DVector) : HResult; stdcall;
    function GetPosition(var lpvPosition: TD3DVector) : HResult; stdcall;
    function GetRolloffFactor(var lpflRolloffFactor: TD3DValue) : HResult; stdcall;
    function GetVelocity(var lpvVelocity: TD3DVector) : HResult; stdcall;
    function SetAllParameters
        (const lpcListener: TDS3DListener; dwApply: DWORD) : HResult; stdcall;
    function SetDistanceFactor
        (flDistanceFactor: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetDopplerFactor
        (flDopplerFactor: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetOrientation(xFront, yFront, zFront, xTop, yTop, zTop: TD3DValue;
        dwApply: DWORD) : HResult; stdcall;
    function SetPosition(x, y, z: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetRolloffFactor
        (flRolloffFactor: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetVelocity(x, y, z: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function CommitDeferredSettings: HResult; stdcall;
  end;


//
// IDirectSound3DBuffer
//
  IDirectSound3DBuffer = interface (IUnknown)
    ['{279AFA86-4981-11CE-A521-0020AF0BE560}']
    // IDirectSoundBuffer3D methods
    function GetAllParameters(var lpDs3dBuffer: TDS3DBuffer) : HResult; stdcall;
    function GetConeAngles
        (var lpdwInsideConeAngle, lpdwOutsideConeAngle: DWORD) : HResult; stdcall;
    function GetConeOrientation(var lpvOrientation: TD3DVector) : HResult; stdcall;
    function GetConeOutsideVolume(var lplConeOutsideVolume: integer) : HResult; stdcall;
    function GetMaxDistance(var lpflMaxDistance: TD3DValue) : HResult; stdcall;
    function GetMinDistance(var lpflMinDistance: TD3DValue) : HResult; stdcall;
    function GetMode(var lpdwMode: DWORD) : HResult; stdcall;
    function GetPosition(var lpvPosition: TD3DVector) : HResult; stdcall;
    function GetVelocity(var lpvVelocity: TD3DVector) : HResult; stdcall;
    function SetAllParameters
        (const lpcDs3dBuffer: TDS3DBuffer; dwApply: DWORD) : HResult; stdcall;
    function SetConeAngles
        (dwInsideConeAngle, dwOutsideConeAngle, dwApply: DWORD) : HResult; stdcall;
    function SetConeOrientation(x, y, z: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetConeOutsideVolume
        (lConeOutsideVolume: LongInt; dwApply: DWORD) : HResult; stdcall;
    function SetMaxDistance(flMaxDistance: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetMinDistance(flMinDistance: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetMode(dwMode: DWORD; dwApply: DWORD) : HResult; stdcall;
    function SetPosition(x, y, z: TD3DValue; dwApply: DWORD) : HResult; stdcall;
    function SetVelocity(x, y, z: TD3DValue; dwApply: DWORD) : HResult; stdcall;
  end;


//
// IDirectSoundCapture
//
  IDirectSoundCapture = interface (IUnknown)
    ['{b0210781-89cd-11d0-af08-00a0c925cd16}']
    // IDirectSoundCapture methods
    function CreateCaptureBuffer(const lpDSCBufferDesc: TDSCBufferDesc;
        var lplpDirectSoundCaptureBuffer: IDirectSoundCaptureBuffer;
        pUnkOuter: IUnknown) : HResult; stdcall;
    function GetCaps(var lpdwCaps: TDSCCaps) : HResult; stdcall;
    function Initialize(lpGuid: PGUID) : HResult; stdcall;
  end;


//
// IDirectSoundCaptureBuffer
//
  IDirectSoundCaptureBuffer = interface (IUnknown)
    ['{b0210782-89cd-11d0-af08-00a0c925cd16}']
    // IDirectSoundCaptureBuffer methods
    function GetCaps(var lpdwCaps: TDSCBCaps) : HResult; stdcall;
    function GetCurrentPosition
        (lpdwCapturePosition, lpdwReadPosition: PDWORD) : HResult; stdcall;
    function GetFormat(lpwfxFormat: PWaveFormatEx; dwSizeAllocated: DWORD;
        lpdwSizeWritten : PDWORD) : HResult; stdcall;
    function GetStatus(var lpdwStatus: DWORD) : HResult; stdcall;
    function Initialize(lpDirectSoundCapture: IDirectSoundCapture;
        const lpcDSBufferDesc: TDSCBufferDesc) : HResult; stdcall;
    function Lock(dwReadCursor, dwReadBytes: DWORD;
        var lplpvAudioPtr1: Pointer; var lpdwAudioBytes1: DWORD;
        var lplpvAudioPtr2: Pointer; var lpdwAudioBytes2: DWORD;
        dwFlags: DWORD) : HResult; stdcall;
    function Start(dwFlags: DWORD) : HResult; stdcall;
    function Stop: HResult; stdcall;
    function Unlock(lpvAudioPtr1: Pointer; dwAudioBytes1: DWORD;
        lpvAudioPtr2: Pointer; dwAudioBytes2: DWORD) : HResult; stdcall;
  end;

//
// IDirectSoundNotify
//
  IDirectSoundNotify = interface (IUnknown)
    ['{b0210783-89cd-11d0-af08-00a0c925cd16}']
    // IDirectSoundNotify methods
    function SetNotificationPositions(cPositionNotifies: DWORD;
        const lpcPositionNotifies: TDSBPositionNotify) : HResult; stdcall;
  end;

//
// IKsPropertySet
//
  IKsPropertySet = interface (IUnknown)
    ['{31efac30-515c-11d0-a9aa-00aa0061be93}']
    // IKsPropertySet methods
    function Get(const rguidPropSet: TGUID; ulId: DWORD; var pInstanceData;
        ulInstanceLength: DWORD; var pPropertyData; ulDataLength: DWORD;
        var pulBytesReturned: DWORD) : HResult; stdcall;
    // Warning: The following method is defined as Set() in DirectX
    //          which is a reserved word in Delphi!
    function SetProperty(const rguidPropSet: TGUID; ulId: DWORD;
        var pInstanceData; ulInstanceLength: DWORD;
        var pPropertyData; pulDataLength: DWORD) : HResult; stdcall;
    function QuerySupport(const rguidPropSet: TGUID; ulId: DWORD;
        var pulTypeSupport: DWORD) : HResult; stdcall;
  end;



//
// GUID's for all the objects
//
type
  IID_IDirectSound = IDirectSound;
  IID_IDirectSoundBuffer = IDirectSoundBuffer;
  IID_IDirectSound3DListener = IDirectSound3DListener;
  IID_IDirectSound3DBuffer = IDirectSound3DBuffer;
  IID_IDirectSoundCapture = IDirectSoundCapture;
  IID_IDirectSoundCaptureBuffer = IDirectSoundCaptureBuffer;
  IID_IDirectSoundNotify = IDirectSoundNotify;
  IID_IKsPropertySet = IKsPropertySet;
{$ELSE}
	__IDirectSoundThis = ^__IDirectSoundMethods;
	__IDirectSoundMethods = packed record
		// IDirectSound methods
		QueryInterface : function (idd : IDirectSound; const IID : TGUID; var obj) : HRESULT; stdcall;
		AddRef : function (idd : IDirectSound) : Longint; stdcall;
		Release : function (idd : IDirectSound) : Longint; stdcall;

		CreateSoundBuffer : function (idd : IDirectSound; const lpDSBufferDesc : TDSBufferDesc; var lpIDirectSoundBuffer : IDirectSoundBuffer; pUnkOuter : IUnknown) : HResult; stdcall;
		GetCaps : function (idd : IDirectSound; var lpDSCaps : TDSCaps) : HResult; stdcall;
		DuplicateSoundBuffer : function (idd : IDirectSound; lpDsbOriginal : IDirectSoundBuffer; var lpDsbDuplicate : IDirectSoundBuffer) : HResult; stdcall;
		SetCooperativeLevel : function (idd : IDirectSound; hwnd : HWND; dwLevel : DWORD) : HResult; stdcall;
		Compact : function (idd : IDirectSound) : HResult; stdcall;
		GetSpeakerConfig : function (idd : IDirectSound; var lpdwSpeakerConfig : DWORD) : HResult; stdcall;
		SetSpeakerConfig : function (idd : IDirectSound; dwSpeakerConfig : DWORD) : HResult; stdcall;
		Initialize : function (idd : IDirectSound; lpGuid : PGUID) : HResult; stdcall;
	end;

	__IDirectSoundBufferThis = ^__IDirectSoundBufferMethods;
	__IDirectSoundBufferMethods = packed record
		// IDirectSoundBuffer methods

		QueryInterface : function (idd : IDirectSoundBuffer; const IID : TGUID; var obj) : HRESULT; stdcall;
		AddRef : function (idd : IDirectSoundBuffer) : Longint; stdcall;
		Release : function (idd : IDirectSoundBuffer) : Longint; stdcall;

		GetCaps : function (idd : IDirectSoundBuffer; var lpDSCaps : TDSBCaps) : HResult; stdcall;
		GetCurrentPosition : function (idd : IDirectSoundBuffer; lpdwCapturePosition , lpdwReadPosition : PDWORD) : HResult; stdcall;
		GetFormat : function (idd : IDirectSoundBuffer; lpwfxFormat : PWaveFormatEx; dwSizeAllocated : DWORD; lpdwSizeWritten : PWORD) : HResult; stdcall;
		GetVolume : function (idd : IDirectSoundBuffer; var lplVolume : integer) : HResult; stdcall;
		GetPan : function (idd : IDirectSoundBuffer; var lplPan : integer) : HResult; stdcall;
		GetFrequency : function (idd : IDirectSoundBuffer; var lpdwFrequency : DWORD) : HResult; stdcall;
		GetStatus : function (idd : IDirectSoundBuffer; var lpdwStatus : DWORD) : HResult; stdcall;
		Initialize : function (idd : IDirectSoundBuffer; lpDirectSound : IDirectSound; const lpcDSBufferDesc : TDSBufferDesc) : HResult; stdcall;
		Lock : function (idd : IDirectSoundBuffer; dwWriteCursor , dwWriteBytes : DWORD; var lplpvAudioPtr1 : Pointer; var lpdwAudioBytes1 : DWORD; var lplpvAudioPtr2 : Pointer; var lpdwAudioBytes2 : DWORD; dwFlags : DWORD) : HResult; stdcall;
		Play : function (idd : IDirectSoundBuffer; dwReserved1 , dwReserved2 , dwFlags : DWORD) : HResult; stdcall;
		SetCurrentPosition : function (idd : IDirectSoundBuffer; dwPosition : DWORD) : HResult; stdcall;
		SetFormat : function (idd : IDirectSoundBuffer; const lpcfxFormat : TWaveFormatEx) : HResult; stdcall;
		SetVolume : function (idd : IDirectSoundBuffer; lVolume : integer) : HResult; stdcall;
		SetPan : function (idd : IDirectSoundBuffer; lPan : integer) : HResult; stdcall;
		SetFrequency : function (idd : IDirectSoundBuffer; dwFrequency : DWORD) : HResult; stdcall;
		Stop : function (idd : IDirectSoundBuffer) : HResult; stdcall;
		Unlock : function (idd : IDirectSoundBuffer; lpvAudioPtr1 : Pointer; dwAudioBytes1 : DWORD; lpvAudioPtr2 : Pointer; dwAudioBytes2 : DWORD) : HResult; stdcall;
		Restore : function (idd : IDirectSoundBuffer) : HResult; stdcall;
	end;

	__IDirectSound3DListenerThis = ^__IDirectSound3DListenerMethods;
	__IDirectSound3DListenerMethods = packed record
		// IDirectSound3DListener methods
		QueryInterface : function (idd : IDirectSound3DListener; const IID : TGUID; var obj) : HRESULT; stdcall;
		AddRef : function (idd : IDirectSound3DListener) : Longint; stdcall;
		Release : function (idd : IDirectSound3DListener) : Longint; stdcall;

		GetAllParameters : function (idd : IDirectSound3DListener; var lpListener : TDS3DListener) : HResult; stdcall;
		GetDistanceFactor : function (idd : IDirectSound3DListener; var lpflDistanceFactor : TD3DValue) : HResult; stdcall;
		GetDopplerFactor : function (idd : IDirectSound3DListener; var lpflDopplerFactor : TD3DValue) : HResult; stdcall;
		GetOrientation : function (idd : IDirectSound3DListener; var lpvOrientFront , lpvOrientTop : TD3DVector) : HResult; stdcall;
		GetPosition : function (idd : IDirectSound3DListener; var lpvPosition : TD3DVector) : HResult; stdcall;
		GetRolloffFactor : function (idd : IDirectSound3DListener; var lpflRolloffFactor : TD3DValue) : HResult; stdcall;
		GetVelocity : function (idd : IDirectSound3DListener; var lpvVelocity : TD3DVector) : HResult; stdcall;
		SetAllParameters : function (idd : IDirectSound3DListener; const lpcListener : TDS3DListener; dwApply : DWORD) : HResult; stdcall;
		SetDistanceFactor : function (idd : IDirectSound3DListener; flDistanceFactor : TD3DValue; dwApply : DWORD) : HResult; stdcall;
		SetDopplerFactor : function (idd : IDirectSound3DListener; flDopplerFactor : TD3DValue; dwApply : DWORD) : HResult; stdcall;
		SetOrientation : function (idd : IDirectSound3DListener; xFront , yFront , zFront , xTop , yTop , zTop : TD3DValue; dwApply : DWORD) : HResult; stdcall;
		SetPosition : function (idd : IDirectSound3DListener; x , y , z : TD3DValue; dwApply : DWORD) : HResult; stdcall;
		SetRolloffFactor : function (idd : IDirectSound3DListener; flRolloffFactor : TD3DValue; dwApply : DWORD) : HResult; stdcall;
		SetVelocity : function (idd : IDirectSound3DListener; x , y , z : TD3DValue; dwApply : DWORD) : HResult; stdcall;
		CommitDeferredSettings : function (idd : IDirectSound3DListener) : HResult; stdcall;
	end;

	__IDirectSound3DBufferThis = ^__IDirectSound3DBufferMethods;
	__IDirectSound3DBufferMethods = packed record
		// IDirectSound3DBuffer methods

		QueryInterface : function (idd : IDirectSound3DBuffer; const IID : TGUID; var obj) : HRESULT; stdcall;
		AddRef : function (idd : IDirectSound3DBuffer) : Longint; stdcall;
		Release : function (idd : IDirectSound3DBuffer) : Longint; stdcall;

		GetAllParameters : function (idd : IDirectSound3DBuffer; var lpDs3dBuffer : TDS3DBuffer) : HResult; stdcall;
		GetConeAngles : function (idd : IDirectSound3DBuffer; var lpdwInsideConeAngle , lpdwOutsideConeAngle : DWORD) : HResult; stdcall;
		GetConeOrientation : function (idd : IDirectSound3DBuffer; var lpvOrientation : TD3DVector) : HResult; stdcall;
		GetConeOutsideVolume : function (idd : IDirectSound3DBuffer; var lplConeOutsideVolume : integer) : HResult; stdcall;
		GetMaxDistance : function (idd : IDirectSound3DBuffer; var lpflMaxDistance : TD3DValue) : HResult; stdcall;
		GetMinDistance : function (idd : IDirectSound3DBuffer; var lpflMinDistance : TD3DValue) : HResult; stdcall;
		GetMode : function (idd : IDirectSound3DBuffer; var lpdwMode : DWORD) : HResult; stdcall;
		GetPosition : function (idd : IDirectSound3DBuffer; var lpvPosition : TD3DVector) : HResult; stdcall;
		GetVelocity : function (idd : IDirectSound3DBuffer; var lpvVelocity : TD3DVector) : HResult; stdcall;
		SetAllParameters : function (idd : IDirectSound3DBuffer; const lpcDs3dBuffer : TDS3DBuffer; dwApply : DWORD) : HResult; stdcall;
		SetConeAngles : function (idd : IDirectSound3DBuffer; dwInsideConeAngle , dwOutsideConeAngle , dwApply : DWORD) : HResult; stdcall;
		SetConeOrientation : function (idd : IDirectSound3DBuffer; x , y , z : TD3DValue; dwApply : DWORD) : HResult; stdcall;
		SetConeOutsideVolume : function (idd : IDirectSound3DBuffer; lConeOutsideVolume : LongInt; dwApply : DWORD) : HResult; stdcall;
		SetMaxDistance : function (idd : IDirectSound3DBuffer; flMaxDistance : TD3DValue; dwApply : DWORD) : HResult; stdcall;
		SetMinDistance : function (idd : IDirectSound3DBuffer; flMinDistance : TD3DValue; dwApply : DWORD) : HResult; stdcall;
		SetMode : function (idd : IDirectSound3DBuffer; dwMode : DWORD; dwApply : DWORD) : HResult; stdcall;
		SetPosition : function (idd : IDirectSound3DBuffer; x , y , z : TD3DValue; dwApply : DWORD) : HResult; stdcall;
		SetVelocity : function (idd : IDirectSound3DBuffer; x , y , z : TD3DValue; dwApply : DWORD) : HResult; stdcall;
	end;

	__IDirectSoundCaptureThis = ^__IDirectSoundCaptureMethods;
	__IDirectSoundCaptureMethods = packed record
		// IDirectSoundCapture methods
		QueryInterface : function (idd : IDirectSoundCapture; const IID : TGUID; var obj) : HRESULT; stdcall;
		AddRef : function (idd : IDirectSoundCapture) : Longint; stdcall;
		Release : function (idd : IDirectSoundCapture) : Longint; stdcall;

		CreateCaptureBuffer : function (idd : IDirectSoundCapture; const lpDSCBufferDesc : TDSCBufferDesc; var lplpDirectSoundCaptureBuffer : IDirectSoundCaptureBuffer; pUnkOuter : IUnknown) : HResult; stdcall;
		GetCaps : function (idd : IDirectSoundCapture; var lpdwCaps : TDSCCaps) : HResult; stdcall;
		Initialize : function (idd : IDirectSoundCapture; lpGuid : PGUID) : HResult; stdcall;
	end;

	__IDirectSoundCaptureBufferThis = ^__IDirectSoundCaptureBufferMethods;
	__IDirectSoundCaptureBufferMethods = packed record
		// IDirectSoundCaptureBuffer methods
		QueryInterface : function (idd : IDirectSoundCaptureBuffer; const IID : TGUID; var obj) : HRESULT; stdcall;
		AddRef : function (idd : IDirectSoundCaptureBuffer) : Longint; stdcall;
		Release : function (idd : IDirectSoundCaptureBuffer) : Longint; stdcall;

		GetCaps : function (idd : IDirectSoundCaptureBuffer; var lpdwCaps : TDSCBCaps) : HResult; stdcall;
		GetCurrentPosition : function (idd : IDirectSoundCaptureBuffer; lpdwCapturePosition , lpdwReadPosition : PDWORD) : HResult; stdcall;
		GetFormat : function (idd : IDirectSoundCaptureBuffer; lpwfxFormat : PWaveFormatEx; dwSizeAllocated : DWORD; lpdwSizeWritten : PDWORD) : HResult; stdcall;
		GetStatus : function (idd : IDirectSoundCaptureBuffer; var lpdwStatus : DWORD) : HResult; stdcall;
		Initialize : function (idd : IDirectSoundCaptureBuffer; lpDirectSoundCapture : IDirectSoundCapture; const lpcDSBufferDesc : TDSCBufferDesc) : HResult; stdcall;
		Lock : function (idd : IDirectSoundCaptureBuffer; dwReadCursor , dwReadBytes : DWORD; var lplpvAudioPtr1 : Pointer; var lpdwAudioBytes1 : DWORD; var lplpvAudioPtr2 : Pointer; var lpdwAudioBytes2 : DWORD; dwFlags : DWORD) : HResult; stdcall;
		Start : function (idd : IDirectSoundCaptureBuffer; dwFlags : DWORD) : HResult; stdcall;
		Stop : function (idd : IDirectSoundCaptureBuffer) : HResult; stdcall;
		Unlock : function (idd : IDirectSoundCaptureBuffer; lpvAudioPtr1 : Pointer; dwAudioBytes1 : DWORD; lpvAudioPtr2 : Pointer; dwAudioBytes2 : DWORD) : HResult; stdcall;
	end;

	__IDirectSoundNotifyThis = ^__IDirectSoundNotifyMethods;
	__IDirectSoundNotifyMethods = packed record
		// IDirectSoundNotify methods
		QueryInterface : function (idd : IDirectSoundNotify; const IID : TGUID; var obj) : HRESULT; stdcall;
		AddRef : function (idd : IDirectSoundNotify) : Longint; stdcall;
		Release : function (idd : IDirectSoundNotify) : Longint; stdcall;

		SetNotificationPositions : function (idd : IDirectSoundNotify; cPositionNotifies : DWORD; const lpcPositionNotifies : TDSBPositionNotify) : HResult; stdcall;
	end;

	__IKsPropertySetThis = ^__IKsPropertySetMethods;
	__IKsPropertySetMethods = packed record
		// IKsPropertySet methods
		QueryInterface : function (idd : IKsPropertySet; const IID : TGUID; var obj) : HRESULT; stdcall;
		AddRef : function (idd : IKsPropertySet) : Longint; stdcall;
		Release : function (idd : IKsPropertySet) : Longint; stdcall;

		Get : function (idd : IKsPropertySet; const rguidPropSet : TGUID; ulId : DWORD; var pInstanceData; ulInstanceLength : DWORD; var pPropertyData; ulDataLength : DWORD; var pulBytesReturned : DWORD) : HResult; stdcall;
		SetProperty : function (idd : IKsPropertySet; const rguidPropSet : TGUID; ulId : DWORD; var pInstanceData; ulInstanceLength : DWORD; var pPropertyData; pulDataLength : DWORD) : HResult; stdcall;
		QuerySupport : function (idd : IKsPropertySet; const rguidPropSet : TGUID; ulId : DWORD; var pulTypeSupport : DWORD) : HResult; stdcall;
	end;

const
	IID_IDirectSound : TGUID = (D1:$279AFA83;D2:$4981;D3:$11CE;D4:($A5,$21,$00,$20,$AF,$0B,$E5,$60));
	IID_IDirectSoundBuffer : TGUID = (D1:$279AFA85;D2:$4981;D3:$11CE;D4:($A5,$21,$00,$20,$AF,$0B,$E5,$60));
	IID_IDirectSound3DListener : TGUID = (D1:$279AFA84;D2:$4981;D3:$11CE;D4:($A5,$21,$00,$20,$AF,$0B,$E5,$60));
	IID_IDirectSound3DBuffer : TGUID = (D1:$279AFA86;D2:$4981;D3:$11CE;D4:($A5,$21,$00,$20,$AF,$0B,$E5,$60));
	IID_IDirectSoundCapture : TGUID = (D1:$b0210781;D2:$89cd;D3:$11d0;D4:($af,$08,$00,$a0,$c9,$25,$cd,$16));
	IID_IDirectSoundCaptureBuffer : TGUID = (D1:$b0210782;D2:$89cd;D3:$11d0;D4:($af,$08,$00,$a0,$c9,$25,$cd,$16));
	IID_IDirectSoundNotify : TGUID = (D1:$b0210783;D2:$89cd;D3:$11d0;D4:($af,$08,$00,$a0,$c9,$25,$cd,$16));
	IID_IKsPropertySet : TGUID = (D1:$31efac30;D2:$515c;D3:$11d0;D4:($a9,$aa,$00,$aa,$00,$61,$be,$93));

{$ENDIF}
const
  KSPROPERTY_SUPPORT_GET = $00000001;
  KSPROPERTY_SUPPORT_SET = $00000002;


//
// Creation Routines
//
var
    DirectSoundCreate : function ( lpGuid: PGUID; var ppDS: IDirectSound;
        pUnkOuter: IUnknown) : HResult; stdcall;

    DirectSoundEnumerateW : function (lpDSEnumCallback: TDSEnumCallbackW;
        lpContext: Pointer) : HResult; stdcall;
    DirectSoundEnumerateA : function (lpDSEnumCallback: TDSEnumCallbackA;
        lpContext: Pointer) : HResult; stdcall;
    DirectSoundEnumerate : function (lpDSEnumCallback: TDSEnumCallback;
        lpContext: Pointer) : HResult; stdcall;

    DirectSoundCaptureCreate : function (lpGUID: PGUID;
        var lplpDSC: IDirectSoundCapture;
        pUnkOuter: IUnknown) : HResult; stdcall;

    DirectSoundCaptureEnumerateW : function (lpDSEnumCallback: TDSEnumCallbackW;
        lpContext: Pointer) : HResult; stdcall;
    DirectSoundCaptureEnumerateA : function (lpDSEnumCallback: TDSEnumCallbackA;
        lpContext: Pointer) : HResult; stdcall;
    DirectSoundCaptureEnumerate : function(lpDSEnumCallback: TDSEnumCallback;
        lpContext: Pointer) : HResult; stdcall;


//
// Return Codes
//

const
  MAKE_DSHRESULT_ = HResult($88780000);

  DS_OK = 0;

// The function completed successfully, but we had to substitute the 3D algorithm
  DS_NO_VIRTUALIZATION = MAKE_DSHRESULT_ + 10;

// The call failed because resources (such as a priority level)
// were already being used by another caller.
  DSERR_ALLOCATED = MAKE_DSHRESULT_ + 10;

// The control (vol,pan,etc.) requested by the caller is not available.
  DSERR_CONTROLUNAVAIL = MAKE_DSHRESULT_ + 30;

// An invalid parameter was passed to the returning function
  DSERR_INVALIDPARAM = E_INVALIDARG;

// This call is not valid for the current state of this object
  DSERR_INVALIDCALL = MAKE_DSHRESULT_ + 50;

// An undetermined error occured inside the DirectSound subsystem
  DSERR_GENERIC = E_FAIL;

// The caller does not have the priority level required for the function to
// succeed.
  DSERR_PRIOLEVELNEEDED = MAKE_DSHRESULT_ + 70;

// Not enough free memory is available to complete the operation
  DSERR_OUTOFMEMORY = E_OUTOFMEMORY;

// The specified WAVE format is not supported
  DSERR_BADFORMAT = MAKE_DSHRESULT_ + 100;

// The function called is not supported at this time
  DSERR_UNSUPPORTED = E_NOTIMPL;

// No sound driver is available for use
  DSERR_NODRIVER = MAKE_DSHRESULT_ + 120;

// This object is already initialized
  DSERR_ALREADYINITIALIZED = MAKE_DSHRESULT_ + 130;

// This object does not support aggregation
  DSERR_NOAGGREGATION = HRESULT($80040110);

// The buffer memory has been lost, and must be restored.
  DSERR_BUFFERLOST = MAKE_DSHRESULT_ + 150;

// Another app has a higher priority level, preventing this call from
// succeeding.
  DSERR_OTHERAPPHASPRIO = MAKE_DSHRESULT_ + 160;

// This object has not been initialized
  DSERR_UNINITIALIZED = MAKE_DSHRESULT_ + 170;

// The requested COM interface is not available
  DSERR_NOINTERFACE = E_NOINTERFACE;

// Access is denied
  DSERR_ACCESSDENIED = E_ACCESSDENIED;

//
// Flags
//

  DSCAPS_PRIMARYMONO = $00000001;
  DSCAPS_PRIMARYSTEREO = $00000002;
  DSCAPS_PRIMARY8BIT = $00000004;
  DSCAPS_PRIMARY16BIT = $00000008;
  DSCAPS_CONTINUOUSRATE = $00000010;
  DSCAPS_EMULDRIVER = $00000020;
  DSCAPS_CERTIFIED = $00000040;
  DSCAPS_SECONDARYMONO = $00000100;
  DSCAPS_SECONDARYSTEREO = $00000200;
  DSCAPS_SECONDARY8BIT = $00000400;
  DSCAPS_SECONDARY16BIT = $00000800;

  DSSCL_NORMAL = $00000001;
  DSSCL_PRIORITY = $00000002;
  DSSCL_EXCLUSIVE = $00000003;
  DSSCL_WRITEPRIMARY = $00000004;

  DSSPEAKER_HEADPHONE = $00000001;
  DSSPEAKER_MONO = $00000002;
  DSSPEAKER_QUAD = $00000003;
  DSSPEAKER_STEREO = $00000004;
  DSSPEAKER_SURROUND = $00000005;
  DSSPEAKER_5POINT1 = $00000006;

  DSSPEAKER_GEOMETRY_MIN     = $00000005;  //   5 degrees
  DSSPEAKER_GEOMETRY_NARROW  = $0000000A;  //  10 degrees
  DSSPEAKER_GEOMETRY_WIDE    = $00000014;  //  20 degrees
  DSSPEAKER_GEOMETRY_MAX     = $000000B4;  // 180 degrees

function DSSPEAKER_COMBINED(c, g: variant) : DWORD;
function DSSPEAKER_CONFIG(a: variant) : byte;
function DSSPEAKER_GEOMETRY(a: variant) : byte;

const
  DSBCAPS_PRIMARYBUFFER = $00000001;
  DSBCAPS_STATIC = $00000002;
  DSBCAPS_LOCHARDWARE = $00000004;
  DSBCAPS_LOCSOFTWARE = $00000008;
  DSBCAPS_CTRL3D = $00000010;
  DSBCAPS_CTRLFREQUENCY = $00000020;
  DSBCAPS_CTRLPAN = $00000040;
  DSBCAPS_CTRLVOLUME = $00000080;
  DSBCAPS_CTRLPOSITIONNOTIFY = $00000100;
  DSBCAPS_STICKYFOCUS = $00004000;
  DSBCAPS_GLOBALFOCUS = $00008000;
  DSBCAPS_GETCURRENTPOSITION2 = $00010000;
  DSBCAPS_MUTE3DATMAXDISTANCE = $00020000;
  DSBCAPS_LOCDEFER            = $00040000;

  DSBPLAY_LOOPING = $00000001;
  DSBPLAY_LOCHARDWARE = $00000002;
  DSBPLAY_LOCSOFTWARE = $00000004;
  DSBPLAY_TERMINATEBY_TIME = $00000008;
  DSBPLAY_TERMINATEBY_DISTANCE = $000000010;
  DSBPLAY_TERMINATEBY_PRIORITY = $000000020;

  DSBSTATUS_PLAYING = $00000001;
  DSBSTATUS_BUFFERLOST = $00000002;
  DSBSTATUS_LOOPING = $00000004;
  DSBSTATUS_LOCHARDWARE = $00000008;
  DSBSTATUS_LOCSOFTWARE = $00000010;
  DSBSTATUS_TERMINATED = $00000020;

  DSBLOCK_FROMWRITECURSOR = $00000001;
  DSBLOCK_ENTIREBUFFER = $00000002;

  DSBFREQUENCY_MIN = 100;
  DSBFREQUENCY_MAX = 100000;
  DSBFREQUENCY_ORIGINAL = 0;

  DSBPAN_LEFT = -10000;
  DSBPAN_CENTER = 0;
  DSBPAN_RIGHT = 10000;

  DSBVOLUME_MIN = -10000;
  DSBVOLUME_MAX = 0;

  DSBSIZE_MIN = 4;
  DSBSIZE_MAX = $0FFFFFFF;

  DS3DMODE_NORMAL = $00000000;
  DS3DMODE_HEADRELATIVE = $00000001;
  DS3DMODE_DISABLE = $00000002;

  DS3D_IMMEDIATE = $00000000;
  DS3D_DEFERRED = $00000001;

  DS3D_MINDISTANCEFACTOR = FLT_MIN;
  DS3D_MAXDISTANCEFACTOR = FLT_MAX;
  DS3D_DEFAULTDISTANCEFACTOR = 1.0;

  DS3D_MINROLLOFFFACTOR = 0.0;
  DS3D_MAXROLLOFFFACTOR = 10.0;
  DS3D_DEFAULTROLLOFFFACTOR = 1.0;

  DS3D_MINDOPPLERFACTOR = 0.0;
  DS3D_MAXDOPPLERFACTOR = 10.0;
  DS3D_DEFAULTDOPPLERFACTOR = 1.0;

  DS3D_DEFAULTMINDISTANCE = 1.0;
  DS3D_DEFAULTMAXDISTANCE = 1000000000.0;

  DS3D_MINCONEANGLE = 0;
  DS3D_MAXCONEANGLE = 360;
  DS3D_DEFAULTCONEANGLE = 360;

  DS3D_DEFAULTCONEOUTSIDEVOLUME = DSBVOLUME_MAX;

  DSCCAPS_EMULDRIVER = $00000020;
  DSCCAPS_CERTIFIED = DSCAPS_CERTIFIED;

  DSCBCAPS_WAVEMAPPED = $80000000;



  DSBCAPS_CTRLDEFAULT = $000000E0;
  DSBCAPS_CTRLALL = $000001F0;

  DSCBLOCK_ENTIREBUFFER = $00000001;

  DSCBSTATUS_CAPTURING = $00000001;
  DSCBSTATUS_LOOPING = $00000002;

  DSCBSTART_LOOPING = $00000001;

  DSBPN_OFFSETSTOP = DWORD(-1);

//
// DirectSound3D Algorithms
//

// Default DirectSound3D algorithm {00000000-0000-0000-0000-000000000000}
  DS3DALG_DEFAULT: TGUID =
  	(D1:$00000000;D2:$0000;D3:$0000;D4:($00,$00,$00,$00,$00,$00,$00,$00));

// No virtualization {C241333F-1C1B-11d2-94F5-00C04FC28ACA}
  DS3DALG_NO_VIRTUALIZATION: TGUID =
  	(D1:$C241333F;D2:$1C1B;D3:$11D2;D4:($94,$F5,$00,$C0,$4F,$C2,$8A,$CA));

// High-quality HRTF algorithm {C2413340-1C1B-11d2-94F5-00C04FC28ACA}
  DS3DALG_HRTF_FULL: TGUID =
  	(D1:$C2413340;D2:$1C1B;D3:$11d2;D4:($94,$F5,$00,$C0,$4F,$C2,$8A,$CA));

// Lower-quality HRTF algorithm {C2413342-1C1B-11d2-94F5-00C04FC28ACA}
  DS3DALG_HRTF_LIGHT: TGUID =
  	(D1:$C2413342;D2:$1C1B;D3:$11d2;D4:($94,$F5,$00,$C0,$4F,$C2,$8A,$CA));

implementation

uses
  DXCommon;

function MAKE_DSHRESULT(code: DWORD) : HResult;
begin
  Result := HResult(1 shl 31) or HResult(_FACDS shl 16)
      or HResult(code);
end;

function DSSPEAKER_COMBINED(c, g: variant) : DWORD;
begin
  Result := byte(c.bVal) or (byte(g.bVal) shl 16)
end;

function DSSPEAKER_CONFIG(a: variant) : byte;
begin
  Result := byte(a.bVal);
end;

function DSSPEAKER_GEOMETRY(a: variant) : byte;
begin
  Result := byte(a.iVal shr 16 and $FF);
end;


function DSErrorString(Value: HResult) : string;
begin
  case Value of
    DS_OK: Result := 'The request completed successfully.';
    DSERR_ALLOCATED: Result := 'The request failed because resources, such as a priority level, were already in use by another caller.';
    DSERR_ALREADYINITIALIZED: Result := 'The object is already initialized.';
    DSERR_BADFORMAT: Result := 'The specified wave format is not supported.';
    DSERR_BUFFERLOST: Result := 'The buffer memory has been lost and must be restored.';
    DSERR_CONTROLUNAVAIL: Result := 'The control (volume, pan, and so forth) requested by the caller is not available.';
    DSERR_GENERIC: Result := 'An undetermined error occurred inside the DirectSound subsystem.';
    DSERR_INVALIDCALL: Result := 'This function is not valid for the current state of this object.';
    DSERR_INVALIDPARAM: Result := 'An invalid parameter was passed to the returning function.';
    DSERR_NOAGGREGATION: Result := 'The object does not support aggregation.';
    DSERR_NODRIVER: Result := 'No sound driver is available for use.';
    DSERR_NOINTERFACE: Result := 'The requested COM interface is not available.';
    DSERR_OTHERAPPHASPRIO: Result := 'Another application has a higher priority level, preventing this call from succeeding.';
    DSERR_OUTOFMEMORY: Result := 'The DirectSound subsystem could not allocate sufficient memory to complete the caller�s request.';
    DSERR_PRIOLEVELNEEDED: Result := 'The caller does not have the priority level required for the function to succeed.';
    DSERR_UNINITIALIZED: Result := 'The IDirectSound::Initialize method has not been called or has not been called successfully before other methods were called.';
    DSERR_UNSUPPORTED: Result := 'The function called is not supported at this time.';
    else Result := 'Unrecognized Error';
  end;
end;


initialization
begin
  if not IsNTandDelphiRunning then
  begin
    DSoundDLL := LoadLibrary('DSound.dll');
    DirectSoundCreate := GetProcAddress(DSoundDLL,'DirectSoundCreate');

    DirectSoundEnumerateW := GetProcAddress(DSoundDLL,'DirectSoundEnumerateW');
    DirectSoundEnumerateA := GetProcAddress(DSoundDLL,'DirectSoundEnumerateA');
  {$IFDEF UNICODE}
    DirectSoundEnumerate := DirectSoundEnumerateW;
  {$ELSE}
    DirectSoundEnumerate := DirectSoundEnumerateA;
  {$ENDIF}

    DirectSoundCaptureCreate :=
        GetProcAddress(DSoundDLL,'DirectSoundCaptureCreate');

    DirectSoundCaptureEnumerateW :=
        GetProcAddress(DSoundDLL,'DirectSoundCaptureEnumerateW');
    DirectSoundCaptureEnumerateA :=
        GetProcAddress(DSoundDLL,'DirectSoundCaptureEnumerateA');
  {$IFDEF UNICODE}
    DirectSoundCaptureEnumerate := DirectSoundCaptureEnumerateW;
  {$ELSE}
    DirectSoundCaptureEnumerate := DirectSoundCaptureEnumerateA;
  {$ENDIF}
  end;
end;

finalization
begin
  FreeLibrary(DSoundDLL);
end;

end.
