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

{$I gxglobal.cfg}
UNIT gxmdecod;

INTERFACE

{$I gxlocal.cfg}

PROCEDURE DecodeCRAM8(frmxd,frmyd:longint;data,img,col:pointer);
PROCEDURE DecodeCRAM16(frmxd,frmyd:longint;data,img:pointer);
PROCEDURE DecodeMRLE8(frmxd,frmyd:longint;data,img,col:pointer);
PROCEDURE DecodeCVID24(frmxd,frmyd:longint;data,img,codebook:pointer);
PROCEDURE DecodeDIB8(frmxd,frmyd:longint;data,img,col:pointer);
PROCEDURE DecodeDIB16(frmxd,frmyd:longint;data,img:pointer);
PROCEDURE DecodeDIB24(frmxd,frmyd:longint;data,img:pointer);
PROCEDURE DecodeDIB32(frmxd,frmyd:longint;data,img:pointer);
PROCEDURE DecodeDELTA7(frmxd,frmyd:longint;data,colortable,buf:pointer);
PROCEDURE DecodeLC12(frmxd,frmyd:longint;data,colortable,buf:pointer);
PROCEDURE DecodeBRUN15(frmxd,frmyd:longint;data,colortable,buf:pointer);
PROCEDURE DecodeCOPY16(frmxd,frmyd:longint;data,colortable,buf:pointer);

IMPLEMENTATION

USES gxbase,gxtype,graphix;

{============= MS Video 1 - 8bit CRAM =======================================}

{CONST matr4x4:array[0..15] of longint=(0,0,2,2,0,0,2,2,4,4,6,6,4,4,6,6);}
CONST matr4x4i:array[0..16] of longint=(0,6,6,4,4,6,6,4,4,2,2,0,0,2,2,0,0);

PROCEDURE DecodeCRAM8C8(frmxd,frmyd:longint;data:pointer;img:pimage;col:pointer);assembler;
VAR nextline,imgxdl,pd:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  ADD EAX,4   {!!! EAX=bytperpix*4}
  MOV nextline,EAX
  MOV EAX,[EDI+timage.pixeldata]
  MOV pd,EAX

  MOV EBX,0
  MOV ECX,frmyd
  DEC ECX

@CRAM8C8_loop1:
  XOR EDX,EDX
  MOV EAX,EBX
  DIV frmxd
  MOV EBX,EDX
  SHL EAX,2
  SUB ECX,EAX

  MOV EDI,EBX
{ SHL EDI,1 } {!!! EDI=EDI*bytperpix}
  MOV EAX,ECX
  MUL imgxdl
  ADD EDI,EAX
{  ADD EDI,imagedatastart
  ADD EDI,img }
  ADD EDI,pd

  LODSW
  MOVZX EAX,AX
  CMP AH,80h
  JB @CRAM8C8_colorexpand_4x4
  JA @CRAM8C8_next_cmp1

{ ----- 4x4 matrix einfaerbig ----- }

  AND EAX,000000FFh
  SHL EAX,2
  ADD EAX,col
  MOV EAX,[EAX]
  MOV AH,AL
  SHL EAX,8
  MOV AL,AH
  SHL EAX,8
  MOV AL,AH

  STOSD {!!! bytperpix*4}
  SUB EDI,nextline
  STOSD
  SUB EDI,nextline
  STOSD
  SUB EDI,nextline
  STOSD

  ADD EBX,4
  JMP @CRAM8C8_loop1
{ --------------------------------- }

@CRAM8C8_next_cmp1:
  CMP AH,84h
  JB @CRAM8C8_else1
  CMP AH,87h
  JA @CRAM8C8_else1
{ ----- skip 4x4 matrices --------- }
  AND EAX,03FFh
  SHL EAX,2
  ADD EBX,EAX
  JMP @CRAM8C8_loop1
{ --------------------------------- }

@CRAM8C8_else1:
{ ----- 4x(2x2) matrices ---------- }

  PUSH EBX
  PUSH ECX

  MOV EDX,EAX
  NOT EDX
  MOV EBX,col

  MOV ECX,16
@CRAM8C8_l1a:
  LEA EAX,matr4x4i
  MOV EAX,[EAX+ECX*4]
  SHR EDX,1
  ADC EAX,ESI
  MOVZX EAX,BYTE PTR [EAX]
  MOV EAX,[EBX+EAX*4]
  STOSB {!!! bytperpix}
  DEC ECX
  TEST CL,03h
  JNZ @CRAM8C8_l1a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @CRAM8C8_l1a

  POP ECX
  POP EBX
  ADD EBX,4
  ADD ESI,8
  JMP @CRAM8C8_loop1

{ --------------------------------- }
@CRAM8C8_colorexpand_4x4:
  OR EAX,EAX
  JZ @CRAM8C8_ende

  PUSH EBX
  PUSH ECX

  MOV EBX,EAX
  NOT EBX
  MOV EDX,col

  MOV ECX,16
@CRAM8C8_l1b:
  XOR EAX,EAX
  SHR EBX,1
  SETC AL
  MOV AL,[ESI+EAX]
  MOV EAX,[EDX+EAX*4]
  STOSB {!!! bytperpix }

  DEC ECX
  TEST CL,03h
  JNZ @CRAM8C8_l1b
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @CRAM8C8_l1b

  POP ECX
  POP EBX
  ADD ESI,2
  ADD EBX,4
  JMP @CRAM8C8_loop1
@CRAM8C8_ende:
END;

PROCEDURE DecodeCRAM8C16(frmxd,frmyd:longint;data:pointer;img:pimage;col:pointer);assembler;
VAR nextline,imgxdl,pd:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  ADD EAX,8   {!!! EAX=bytperpix*4}
  MOV nextline,EAX
  MOV EAX,[EDI+timage.pixeldata]
  MOV pd,EAX

  MOV EBX,0
  MOV ECX,frmyd
  DEC ECX

@CRAM8C16_loop1:
  XOR EDX,EDX
  MOV EAX,EBX
  DIV frmxd
  MOV EBX,EDX
  SHL EAX,2
  SUB ECX,EAX

  MOV EDI,EBX
  SHL EDI,1 {!!! EDI=EDI*bytperpix}
  MOV EAX,ECX
  MUL imgxdl
  ADD EDI,EAX
{  ADD EDI,imagedatastart
  ADD EDI,img }
  ADD EDI,pd

  LODSW
  MOVZX EAX,AX
  CMP AH,80h
  JB @CRAM8C16_colorexpand_4x4
  JA @CRAM8C16_next_cmp1

{ ----- 4x4 matrix einfaerbig ----- }

  AND EAX,000000FFh
  SHL EAX,2
  ADD EAX,col
  MOV EAX,[EAX]
  PUSH AX
  SHL EAX,16
  POP AX

  STOSD {!!! bytperpix*4}
  STOSD
  SUB EDI,nextline
  STOSD
  STOSD
  SUB EDI,nextline
  STOSD
  STOSD
  SUB EDI,nextline
  STOSD
  STOSD

  ADD EBX,4
  JMP @CRAM8C16_loop1
{ --------------------------------- }

@CRAM8C16_next_cmp1:
  CMP AH,84h
  JB @CRAM8C16_else1
  CMP AH,87h
  JA @CRAM8C16_else1
{ ----- skip 4x4 matrices --------- }
  AND EAX,03FFh
  SHL EAX,2
  ADD EBX,EAX
  JMP @CRAM8C16_loop1
{ --------------------------------- }

@CRAM8C16_else1:
{ ----- 4x(2x2) matrices ---------- }

  PUSH EBX
  PUSH ECX

  MOV EDX,EAX
  NOT EDX
  MOV EBX,col

  MOV ECX,16
@CRAM8C16_l1a:
  LEA EAX,matr4x4i
  MOV EAX,[EAX+ECX*4]
  SHR EDX,1
  ADC EAX,ESI
  MOVZX EAX,BYTE PTR [EAX]
  MOV EAX,[EBX+EAX*4]
  STOSW {!!! bytperpix}
  DEC ECX
  TEST CL,03h
  JNZ @CRAM8C16_l1a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @CRAM8C16_l1a

  POP ECX
  POP EBX
  ADD EBX,4
  ADD ESI,8
  JMP @CRAM8C16_loop1

{ --------------------------------- }
@CRAM8C16_colorexpand_4x4:
  OR EAX,EAX
  JZ @CRAM8C16_ende

  PUSH EBX
  PUSH ECX

  MOV EBX,EAX
  NOT EBX
  MOV EDX,col

  MOV ECX,16
@CRAM8C16_l1b:
  XOR EAX,EAX
  SHR EBX,1
  SETC AL
  MOV AL,[ESI+EAX]
  MOV EAX,[EDX+EAX*4]
  STOSW {!!! bytperpix }

  DEC ECX
  TEST CL,03h
  JNZ @CRAM8C16_l1b
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @CRAM8C16_l1b

  POP ECX
  POP EBX
  ADD ESI,2
  ADD EBX,4
  JMP @CRAM8C16_loop1
@CRAM8C16_ende:
END;

PROCEDURE DecodeCRAM8C24(frmxd,frmyd:longint;data:pointer;img:pimage;col:pointer);assembler;
VAR nextline,imgxdl,pd:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  ADD EAX,12   {!!! EAX=bytperpix*4}
  MOV nextline,EAX
  MOV EAX,[EDI+timage.pixeldata]
  MOV pd,EAX

  MOV EBX,0
  MOV ECX,frmyd
  DEC ECX

@CRAM8C24_loop1:
  XOR EDX,EDX
  MOV EAX,EBX
  DIV frmxd
  MOV EBX,EDX
  SHL EAX,2
  SUB ECX,EAX

  MOV EDI,EBX
  LEA EDI,[EDI+EDI*2] {!!! EDI=EDI*bytperpix}
  MOV EAX,ECX
  MUL imgxdl
  ADD EDI,EAX
{  ADD EDI,imagedatastart
  ADD EDI,img }
  ADD EDI,pd

  LODSW
  MOVZX EAX,AX
  CMP AH,80h
  JB @CRAM8C24_colorexpand_4x4
  JA @CRAM8C24_next_cmp1

{ ----- 4x4 matrix einfaerbig ----- }

  AND EAX,000000FFh
  SHL EAX,2
  ADD EAX,col
  MOV EAX,[EAX]

  SHL EAX,8
  MOV AL,AH
  ROR EAX,8

  STOSD {!!! bytperpix*4}
  MOV AL,AH
  ROR EAX,8
  STOSD
  MOV AL,AH
  ROR EAX,8
  STOSD
  MOV AL,AH
  ROR EAX,8
  SUB EDI,nextline
  STOSD
  MOV AL,AH
  ROR EAX,8
  STOSD
  MOV AL,AH
  ROR EAX,8
  STOSD
  MOV AL,AH
  ROR EAX,8
  SUB EDI,nextline
  STOSD
  MOV AL,AH
  ROR EAX,8
  STOSD
  MOV AL,AH
  ROR EAX,8
  STOSD
  MOV AL,AH
  ROR EAX,8
  SUB EDI,nextline
  STOSD
  MOV AL,AH
  ROR EAX,8
  STOSD
  MOV AL,AH
  ROR EAX,8
  STOSD

  ADD EBX,4
  JMP @CRAM8C24_loop1
{ --------------------------------- }

@CRAM8C24_next_cmp1:
  CMP AH,84h
  JB @CRAM8C24_else1
  CMP AH,87h
  JA @CRAM8C24_else1
{ ----- skip 4x4 matrices --------- }
  AND EAX,03FFh
  SHL EAX,2
  ADD EBX,EAX
  JMP @CRAM8C24_loop1
{ --------------------------------- }

@CRAM8C24_else1:
{ ----- 4x(2x2) matrices ---------- }

  PUSH EBX
  PUSH ECX

  MOV EDX,EAX
  NOT EDX
  MOV EBX,col

  MOV ECX,16
@CRAM8C24_l1a:
  LEA EAX,matr4x4i
  MOV EAX,[EAX+ECX*4]
  SHR EDX,1
  ADC EAX,ESI
  MOVZX EAX,BYTE PTR [EAX]
  MOV EAX,[EBX+EAX*4]
  STOSW {!!! bytperpix}
  SHR EAX,16
  STOSB
  DEC ECX
  TEST CL,03h
  JNZ @CRAM8C24_l1a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @CRAM8C24_l1a

  POP ECX
  POP EBX
  ADD EBX,4
  ADD ESI,8
  JMP @CRAM8C24_loop1

{ --------------------------------- }
@CRAM8C24_colorexpand_4x4:
  OR EAX,EAX
  JZ @CRAM8C24_ende

  PUSH EBX
  PUSH ECX

  MOV EBX,EAX
  NOT EBX
  MOV EDX,col

  MOV ECX,16
@CRAM8C24_l1b:
  XOR EAX,EAX
  SHR EBX,1
  SETC AL
  MOV AL,[ESI+EAX]
  MOV EAX,[EDX+EAX*4]
  STOSW {!!! bytperpix }
  SHR EAX,16
  STOSB

  DEC ECX
  TEST CL,03h
  JNZ @CRAM8C24_l1b
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @CRAM8C24_l1b

  POP ECX
  POP EBX
  ADD ESI,2
  ADD EBX,4
  JMP @CRAM8C24_loop1
@CRAM8C24_ende:
END;

PROCEDURE DecodeCRAM8C32(frmxd,frmyd:longint;data:pointer;img:pimage;col:pointer);assembler;
VAR nextline,imgxdl,pd:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  ADD EAX,16   {!!! EAX=bytperpix*4}
  MOV nextline,EAX
  MOV EAX,[EDI+timage.pixeldata]
  MOV pd,EAX

  MOV EBX,0
  MOV ECX,frmyd
  DEC ECX

@CRAM8C32_loop1:
  XOR EDX,EDX
  MOV EAX,EBX
  DIV frmxd
  MOV EBX,EDX
  SHL EAX,2
  SUB ECX,EAX

  MOV EDI,EBX
  SHL EDI,2 {!!! EDI=EDI*bytperpix}
  MOV EAX,ECX
  MUL imgxdl
  ADD EDI,EAX
{  ADD EDI,imagedatastart
  ADD EDI,img }
  ADD EDI,pd

  LODSW
  MOVZX EAX,AX
  CMP AH,80h
  JB @CRAM8C32_colorexpand_4x4
  JA @CRAM8C32_next_cmp1

{ ----- 4x4 matrix einfaerbig ----- }

  AND EAX,000000FFh
  SHL EAX,2
  ADD EAX,col
  MOV EAX,[EAX]

  STOSD {!!! bytperpix*4}
  STOSD
  STOSD
  STOSD
  SUB EDI,nextline
  STOSD
  STOSD
  STOSD
  STOSD
  SUB EDI,nextline
  STOSD
  STOSD
  STOSD
  STOSD
  SUB EDI,nextline
  STOSD
  STOSD
  STOSD
  STOSD

  ADD EBX,4
  JMP @CRAM8C32_loop1
{ --------------------------------- }

@CRAM8C32_next_cmp1:
  CMP AH,84h
  JB @CRAM8C32_else1
  CMP AH,87h
  JA @CRAM8C32_else1
{ ----- skip 4x4 matrices --------- }
  AND EAX,03FFh
  SHL EAX,2
  ADD EBX,EAX
  JMP @CRAM8C32_loop1
{ --------------------------------- }

@CRAM8C32_else1:
{ ----- 4x(2x2) matrices ---------- }

  PUSH EBX
  PUSH ECX

  MOV EDX,EAX
  NOT EDX
  MOV EBX,col

  MOV ECX,16
@CRAM8C32_l1a:
  LEA EAX,matr4x4i
  MOV EAX,[EAX+ECX*4]
  SHR EDX,1
  ADC EAX,ESI
  MOVZX EAX,BYTE PTR [EAX]
  MOV EAX,[EBX+EAX*4]
  STOSD {!!! bytperpix}
  DEC ECX
  TEST CL,03h
  JNZ @CRAM8C32_l1a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @CRAM8C32_l1a

  POP ECX
  POP EBX
  ADD EBX,4
  ADD ESI,8
  JMP @CRAM8C32_loop1

{ --------------------------------- }
@CRAM8C32_colorexpand_4x4:
  OR EAX,EAX
  JZ @CRAM8C32_ende

  PUSH EBX
  PUSH ECX

  MOV EBX,EAX
  NOT EBX
  MOV EDX,col

  MOV ECX,16
@CRAM8C32_l1b:
  XOR EAX,EAX
  SHR EBX,1
  SETC AL
  MOV AL,[ESI+EAX]
  MOV EAX,[EDX+EAX*4]
  STOSD {!!! bytperpix }

  DEC ECX
  TEST CL,03h
  JNZ @CRAM8C32_l1b
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @CRAM8C32_l1b

  POP ECX
  POP EBX
  ADD ESI,2
  ADD EBX,4
  JMP @CRAM8C32_loop1
@CRAM8C32_ende:
END;

PROCEDURE DecodeCRAM8(frmxd,frmyd:longint;data,img,col:pointer);
BEGIN
  CASE gxcurcol OF
    ig_col8:DecodeCRAM8C8(frmxd,frmyd,data,img,col);
    ig_col15:DecodeCRAM8C16(frmxd,frmyd,data,img,col);
    ig_col16:DecodeCRAM8C16(frmxd,frmyd,data,img,col);
    ig_col24:DecodeCRAM8C24(frmxd,frmyd,data,img,col);
    ig_col32:DecodeCRAM8C32(frmxd,frmyd,data,img,col);
  END;
END;

{============= MS Video 1 - 15bit CRAM ======================================}

PROCEDURE DecodeCRAM16C8(frmxd,frmyd:longint;data:pointer;img:pimage);assembler;
VAR nextline,imgxdl,pd:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  ADD EAX,4 {!!! bytperpx*4}
  MOV nextline,EAX
  MOV EAX,[EDI+timage.pixeldata]
  MOV pd,EAX

  MOV EBX,0
  MOV ECX,frmyd
  DEC ECX

@cram16C8_loop1:
  XOR EDX,EDX
  MOV EAX,EBX
  DIV frmxd
  MOV EBX,EDX
  SHL EAX,2
  SUB ECX,EAX

  MOV EDI,EBX
{  SHL EDI,0}  {!!! EDI=EDI*bytperpix}
  MOV EAX,ECX
  MUL imgxdl
  ADD EDI,EAX
{  ADD EDI,imagedatastart
  ADD EDI,img }
  ADD EDI,pd


  OR ECX,ECX
  JS @cram16C8_ende
  LODSW

  TEST AX,8000h
  JZ @cram16C8_else1

  CMP AH,84h
  JNE @fill
  MOVZX EAX,AL
  SHL EAX,2
  ADD EBX,EAX
  JMP @cram16C8_loop1
@fill:

{ ----- 4x4 matrix einfaerbig ----- }
  PUSH EBX
  PUSH ECX

  MOV ECX,16
@cram16C8_l0a:
  PUSH EAX

  SHL EAX,4
  SHL AX,2
  SHL EAX,3
  SHL AX,2
  SHR EAX,14
  STOSB

  POP EAX
  DEC ECX
  TEST CL,03h
  JNZ @cram16C8_l0a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16C8_l0a

  POP ECX
  POP EBX

  ADD EBX,4
  JMP @cram16C8_loop1
{ --------------------------------- }

@cram16C8_else1:
  MOV EDX,EAX
  LODSW
  TEST AX,8000h
  JZ @cram16C8_else2

{ ----- 4x(2x2) matrices ---------- }

  SUB ESI,2
  PUSH EBX
  PUSH ECX

  LEA EBX,matr4x4i
  NOT EDX

  MOV ECX,16
@cram16C8_l1a:
  XOR EAX,EAX
  SHR EDX,1
  ADC EAX,[EBX+ECX*4]
  MOV AX,[ESI+EAX*2]

  SHL EAX,4
  SHL AX,2
  SHL EAX,3
  SHL AX,2
  SHR EAX,14
  STOSB

  DEC ECX
  TEST CL,03h
  JNZ @cram16C8_l1a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16C8_l1a

  POP ECX
  POP EBX
  ADD EBX,4
  ADD ESI,16

  JMP @cram16C8_loop1
{ --------------------------------- }

@cram16C8_else2:
  PUSH EBX
  PUSH ECX

  NOT EDX
  SHL EAX,16
  LODSW
  MOV EBX,EAX

  MOV ECX,16
@cram16C8_l1b:
  SHR EDX,1
  MOV EAX,EBX
  JC @cram16C8_w2
  SHR EAX,16
@cram16C8_w2:

  SHL EAX,4
  SHL AX,2
  SHL EAX,3
  SHL AX,2
  SHR EAX,14
  STOSB

  DEC ECX
  TEST CL,03h
  JNZ @cram16C8_l1b
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16C8_l1b

  POP ECX
  POP EBX

  ADD EBX,4
  JMP @cram16C8_loop1
@cram16C8_ende:
END;

PROCEDURE DecodeCRAM16C15(frmxd,frmyd:longint;data:pointer;img:pimage);assembler;
VAR nextline,imgxdl,pd:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  ADD EAX,8 {!!! bytperpx*4}
  MOV nextline,EAX
  MOV EAX,[EDI+timage.pixeldata]
  MOV pd,EAX

  MOV EBX,0
  MOV ECX,frmyd
  DEC ECX

@cram16C15_loop1:
  XOR EDX,EDX
  MOV EAX,EBX
  DIV frmxd
  MOV EBX,EDX
  SHL EAX,2
  SUB ECX,EAX

  MOV EDI,EBX
  SHL EDI,1  {!!! EDI=EDI*bytperpix}
  MOV EAX,ECX
  MUL imgxdl
  ADD EDI,EAX
  ADD EDI,pd

  OR ECX,ECX
  JS @cram16C15_ende
  LODSW

  TEST AX,8000h
  JZ @cram16C15_else1

  CMP AH,84h
  JNE @fill
  MOVZX EAX,AL
  SHL EAX,2
  ADD EBX,EAX
  JMP @cram16C15_loop1
@fill:

{ ----- 4x4 matrix einfaerbig ----- }
  PUSH EBX
  PUSH ECX

  MOV ECX,16
@cram16C15_l0a:
  PUSH EAX

  AND AX,7FFFh
  STOSW

  POP EAX
  DEC ECX
  TEST CL,03h
  JNZ @cram16C15_l0a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16C15_l0a

  POP ECX
  POP EBX

  ADD EBX,4
  JMP @cram16C15_loop1
{ --------------------------------- }

@cram16C15_else1:
  MOV EDX,EAX
  LODSW
  TEST AX,8000h
  JZ @cram16C15_else2

{ ----- 4x(2x2) matrices ---------- }
  SUB ESI,2
  PUSH EBX
  PUSH ECX

  LEA EBX,matr4x4i
  NOT EDX

  MOV ECX,16
@cram16C15_l1a:
  XOR EAX,EAX
  SHR EDX,1
  ADC EAX,[EBX+ECX*4]
  MOV AX,[ESI+EAX*2]

  AND AX,7FFFh
  STOSW

  DEC ECX
  TEST CL,03h
  JNZ @cram16C15_l1a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16C15_l1a

  POP ECX
  POP EBX
  ADD EBX,4
  ADD ESI,16

  JMP @cram16C15_loop1
{ ---- 4x4 -------------------- }

@cram16C15_else2:

  NOT EDX
  SHL EAX,16
  LODSW

  PUSH EBX
  PUSH ECX

  MOV EBX,EAX

  MOV ECX,16
@cram16C15_l1b:
  SHR EDX,1
  MOV EAX,EBX
  JC @cram16C15_w2
  SHR EAX,16
@cram16C15_w2:

  AND AX,7FFFh
  STOSW

  DEC ECX
  TEST CL,03h
  JNZ @cram16C15_l1b
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16C15_l1b

  POP ECX
  POP EBX

  ADD EBX,4
  JMP @cram16C15_loop1
{ ---------------- }
@cram16C15_ende:
END;

PROCEDURE DecodeCRAM16C16(frmxd,frmyd:longint;data:pointer;img:pimage);assembler;
VAR nextline,imgxdl,pd:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  ADD EAX,8 {!!! bytperpx*4}
  MOV nextline,EAX
  MOV EAX,[EDI+timage.pixeldata]
  MOV pd,EAX

  MOV EBX,0
  MOV ECX,frmyd
  DEC ECX

@cram16C16_loop1:
  XOR EDX,EDX
  MOV EAX,EBX
  DIV frmxd
  MOV EBX,EDX
  SHL EAX,2
  SUB ECX,EAX

  MOV EDI,EBX
  SHL EDI,1  {!!! EDI=EDI*bytperpix}
  MOV EAX,ECX
  MUL imgxdl
  ADD EDI,EAX
{  ADD EDI,imagedatastart
  ADD EDI,img }
  ADD EDI,pd

  OR ECX,ECX
  JS @cram16C16_ende
  LODSW

  TEST AX,8000h
  JZ @cram16C16_else1

  CMP AH,84h
  JNE @fill
  MOVZX EAX,AL
  SHL EAX,2
  ADD EBX,EAX
  JMP @cram16C16_loop1
@fill:

{ ----- 4x4 matrix einfaerbig ----- }
  PUSH EBX
  PUSH ECX

  MOV ECX,16
@cram16C16_l0a:
  PUSH EAX

  SHL EAX,11
  SHR AX,1
  SHR EAX,10
  STOSW

  POP EAX
  DEC ECX
  TEST CL,03h
  JNZ @cram16C16_l0a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16C16_l0a

  POP ECX
  POP EBX

  ADD EBX,4
  JMP @cram16C16_loop1
{ --------------------------------- }

@cram16C16_else1:
  MOV EDX,EAX
  LODSW
  TEST AX,8000h
  JZ @cram16C16_else2

{ ----- 4x(2x2) matrices ---------- }

  SUB ESI,2
  PUSH EBX
  PUSH ECX

  LEA EBX,matr4x4i
  NOT EDX

  MOV ECX,16
@cram16C16_l1a:
  XOR EAX,EAX
  SHR EDX,1
  ADC EAX,[EBX+ECX*4]
  MOV AX,[ESI+EAX*2]

  SHL EAX,11
  SHR AX,1
  SHR EAX,10
  STOSW

  DEC ECX
  TEST CL,03h
  JNZ @cram16C16_l1a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16C16_l1a

  POP ECX
  POP EBX
  ADD EBX,4
  ADD ESI,16

  JMP @cram16C16_loop1
{ --------------------------------- }

@cram16C16_else2:
  PUSH EBX
  PUSH ECX

  NOT EDX
  SHL EAX,16
  LODSW
  MOV EBX,EAX

  MOV ECX,16
@cram16C16_l1b:
  SHR EDX,1
  MOV EAX,EBX
  JC @cram16C16_w2
  SHR EAX,16
@cram16C16_w2:

  SHL EAX,11
  SHR AX,1
  SHR EAX,10
  STOSW

  DEC ECX
  TEST CL,03h
  JNZ @cram16C16_l1b
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16C16_l1b

  POP ECX
  POP EBX

  ADD EBX,4
  JMP @cram16C16_loop1
@cram16C16_ende:
END;

PROCEDURE DecodeCRAM16C24(frmxd,frmyd:longint;data:pointer;img:pimage);assembler;
VAR nextline,imgxdl,pd:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  ADD EAX,12 {!!! bytperpx*4}
  MOV nextline,EAX
  MOV EAX,[EDI+timage.pixeldata]
  MOV pd,EAX

  MOV EBX,0
  MOV ECX,frmyd
  DEC ECX

@cram16C24_loop1:
  XOR EDX,EDX
  MOV EAX,EBX
  DIV frmxd
  MOV EBX,EDX
  SHL EAX,2
  SUB ECX,EAX

  MOV EDI,EBX
  LEA EDI,[EDI+EDI*2]  {!!! EDI=EDI*bytperpix}
  MOV EAX,ECX
  MUL imgxdl
  ADD EDI,EAX
{  ADD EDI,imagedatastart
  ADD EDI,img }
  ADD EDI,pd

  OR ECX,ECX
  JS @cram16C24_ende
  LODSW

  TEST AX,8000h
  JZ @cram16C24_else1

  CMP AH,84h
  JNE @fill
  MOVZX EAX,AL
  SHL EAX,2
  ADD EBX,EAX
  JMP @cram16C24_loop1
@fill:

{ ----- 4x4 matrix einfaerbig ----- }
  PUSH EBX
  PUSH ECX

  MOV ECX,16
@cram16C24_l0a:
  PUSH EAX

  ROR EAX,5
  SHL AX,3
  ROR EAX,8
  SHL AX,3
  ROL EAX,16
  STOSW
  SHL EAX,16
  STOSB

  POP EAX
  DEC ECX
  TEST CL,03h
  JNZ @cram16C24_l0a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16C24_l0a

  POP ECX
  POP EBX

  ADD EBX,4
  JMP @cram16C24_loop1
{ --------------------------------- }

@cram16C24_else1:
  MOV EDX,EAX
  LODSW
  TEST AX,8000h
  JZ @cram16C24_else2

{ ----- 4x(2x2) matrices ---------- }

  SUB ESI,2
  PUSH EBX
  PUSH ECX

  LEA EBX,matr4x4i
  NOT EDX

  MOV ECX,16
@cram16C24_l1a:
  XOR EAX,EAX
  SHR EDX,1
  ADC EAX,[EBX+ECX*4]
  MOV AX,[ESI+EAX*2]

  ROR EAX,5
  SHL AX,3
  ROR EAX,8
  SHL AX,3
  ROL EAX,16
  STOSW
  SHL EAX,16
  STOSB

  DEC ECX
  TEST CL,03h
  JNZ @cram16C24_l1a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16C24_l1a

  POP ECX
  POP EBX
  ADD EBX,4
  ADD ESI,16

  JMP @cram16C24_loop1
{ --------------------------------- }

@cram16C24_else2:
  PUSH EBX
  PUSH ECX

  NOT EDX
  SHL EAX,16
  LODSW
  MOV EBX,EAX

  MOV ECX,16
@cram16C24_l1b:
  SHR EDX,1
  MOV EAX,EBX
  JC @cram16C24_w2
  SHR EAX,16
@cram16C24_w2:

  ROR EAX,5
  SHL AX,3
  ROR EAX,8
  SHL AX,3
  ROL EAX,16
  STOSW
  SHL EAX,16
  STOSB

  DEC ECX
  TEST CL,03h
  JNZ @cram16C24_l1b
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16C24_l1b

  POP ECX
  POP EBX

  ADD EBX,4
  JMP @cram16C24_loop1
@cram16C24_ende:
END;

PROCEDURE DecodeCRAM16C32(frmxd,frmyd:longint;data:pointer;img:pimage);assembler;
VAR nextline,imgxdl,pd:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  ADD EAX,16 {!!! bytperpx*4}
  MOV nextline,EAX
  MOV EAX,[EDI+timage.pixeldata]
  MOV pd,EAX

  MOV EBX,0
  MOV ECX,frmyd
  DEC ECX

@cram16c32_loop1:
  XOR EDX,EDX
  MOV EAX,EBX
  DIV frmxd
  MOV EBX,EDX
  SHL EAX,2
  SUB ECX,EAX

  MOV EDI,EBX
  SHL EDI,2  {!!! EDI=EDI*bytperpix}
  MOV EAX,ECX
  MUL imgxdl
  ADD EDI,EAX
{  ADD EDI,imagedatastart
  ADD EDI,img }
  ADD EDI,pd

  OR ECX,ECX
  JS @cram16c32_ende
  LODSW

  TEST AX,8000h
  JZ @cram16c32_else1

  CMP AH,84h
  JNE @fill
  MOVZX EAX,AL
  SHL EAX,2
  ADD EBX,EAX
  JMP @cram16C32_loop1
@fill:

{ ----- 4x4 matrix einfaerbig ----- }
  PUSH EBX
  PUSH ECX

  MOV ECX,16
@cram16c32_l0a:
  PUSH EAX

  ROR EAX,5
  SHL AX,3
  ROR EAX,8
  SHL AX,3
  ROL EAX,16
  STOSD

  POP EAX
  DEC ECX
  TEST CL,03h
  JNZ @cram16c32_l0a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16c32_l0a

  POP ECX
  POP EBX

  ADD EBX,4
  JMP @cram16c32_loop1
{ --------------------------------- }

@cram16c32_else1:
  MOV EDX,EAX
  LODSW
  TEST AX,8000h
  JZ @cram16c32_else2

{ ----- 4x(2x2) matrices ---------- }

  SUB ESI,2
  PUSH EBX
  PUSH ECX

  LEA EBX,matr4x4i
  NOT EDX

  MOV ECX,16
@cram16c32_l1a:
  XOR EAX,EAX
  SHR EDX,1
  ADC EAX,[EBX+ECX*4]
  MOV AX,[ESI+EAX*2]

  ROR EAX,5
  SHL AX,3
  ROR EAX,8
  SHL AX,3
  ROL EAX,16
  STOSD

  DEC ECX
  TEST CL,03h
  JNZ @cram16c32_l1a
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16c32_l1a

  POP ECX
  POP EBX
  ADD EBX,4
  ADD ESI,16

  JMP @cram16c32_loop1
{ --------------------------------- }

@cram16c32_else2:
  PUSH EBX
  PUSH ECX

  NOT EDX
  SHL EAX,16
  LODSW
  MOV EBX,EAX

  MOV ECX,16
@cram16c32_l1b:
  SHR EDX,1
  MOV EAX,EBX
  JC @cram16c32_w2
  SHR EAX,16
@cram16c32_w2:

  ROR EAX,5
  SHL AX,3
  ROR EAX,8
  SHL AX,3
  ROL EAX,16
  STOSD

  DEC ECX
  TEST CL,03h
  JNZ @cram16c32_l1b
  SUB EDI,nextline
  OR ECX,ECX
  JNZ @cram16c32_l1b

  POP ECX
  POP EBX

  ADD EBX,4
  JMP @cram16c32_loop1
@cram16c32_ende:
END;

PROCEDURE DecodeCRAM16(frmxd,frmyd:longint;data,img:pointer);
BEGIN
  CASE gxcurcol OF
    ig_col8:DecodeCRAM16C8(frmxd,frmyd,data,img);
    ig_col15:DecodeCRAM16C15(frmxd,frmyd,data,img);
    ig_col16:DecodeCRAM16C16(frmxd,frmyd,data,img);
    ig_col24:DecodeCRAM16C24(frmxd,frmyd,data,img);
    ig_col32:DecodeCRAM16C32(frmxd,frmyd,data,img);
  END;
END;

{========================= MS RLE 8bit ======================================}

PROCEDURE DecodeMRLE8C8(frmxd,frmyd:longint;data,img,col:pointer);assembler;
VAR destofs,fillcode,copycode,imgxdl:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX

  MOV EAX,frmyd
  DEC EAX
  MUL imgxdl
{  ADD EAX,imagedatastart
  ADD EAX,img }
  ADD EAX,[EDI+timage.pixeldata]
  MOV destofs,EAX
  MOV EDI,EAX

  MOV EBX,col

@mrle8c8_loop1:
  LODSW
  OR AL,AL
  JNZ @mrle8c8_else1
  OR AH,AH
  JNZ @mrle8c8_w1

  MOV EDI,destofs
  SUB EDI,imgxdl
  MOV destofs,EDI
  JMP @mrle8c8_loop1

@mrle8c8_w1:
  CMP AH,1
  JE @mrle8c8_ende
  CMP AH,2
  JNE @mrle8c8_w2

  LODSB
  MOVZX EAX,AL
  ADD EDI,EAX
  LODSB
  MUL imgxdl
  SUB EDI,EAX
  SUB destofs,EAX

  JMP @mrle8c8_loop1

@mrle8c8_w2:
  MOVZX EDX,AH
@mrle8c8_copy32:
  LODSB
  MOVZX EAX,AL
  MOV EAX,[EBX+EAX*4]
  STOSB
  DEC EDX
  JNZ @mrle8c8_copy32
  INC ESI
  AND ESI,0FFFFFFFEh
  JMP @mrle8c8_loop1

@mrle8c8_else1:
  MOVZX ECX,AL
  MOVZX EAX,AH
  MOV EAX,[EBX+EAX*4]
  REP STOSB
  JMP @mrle8c8_loop1
@mrle8c8_ende:
END;

PROCEDURE DecodeMRLE8C16(frmxd,frmyd:longint;data,img,col:pointer);assembler;
VAR destofs,fillcode,copycode,imgxdl:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX

  MOV EAX,frmyd
  DEC EAX
  MUL imgxdl
{  ADD EAX,imagedatastart
  ADD EAX,img }
  ADD EAX,[EDI+timage.pixeldata]
  MOV destofs,EAX
  MOV EDI,EAX

  MOV EBX,col

@mrle8c16_loop1:
  LODSW
  OR AL,AL
  JNZ @mrle8c16_else1
  OR AH,AH
  JNZ @mrle8c16_w1

  MOV EDI,destofs
  SUB EDI,imgxdl
  MOV destofs,EDI
  JMP @mrle8c16_loop1

@mrle8c16_w1:
  CMP AH,1
  JE @mrle8c16_ende
  CMP AH,2
  JNE @mrle8c16_w2

  LODSB
  MOVZX EAX,AL
  LEA EDI,[EDI+EAX*2]
  LODSB
  MUL imgxdl
  SUB EDI,EAX
  SUB destofs,EAX

  JMP @mrle8c16_loop1

@mrle8c16_w2:
  MOVZX EDX,AH
@mrle8c16_copy32:
  LODSB
  MOVZX EAX,AL
  MOV EAX,[EBX+EAX*4]
  STOSW
  DEC EDX
  JNZ @mrle8c16_copy32
  INC ESI
  AND ESI,0FFFFFFFEh
  JMP @mrle8c16_loop1

@mrle8c16_else1:
  MOVZX ECX,AL
  MOVZX EAX,AH
  MOV EAX,[EBX+EAX*4]
  REP STOSW
  JMP @mrle8c16_loop1
@mrle8c16_ende:
END;

PROCEDURE DecodeMRLE8C24(frmxd,frmyd:longint;data,img,col:pointer);assembler;
VAR destofs,fillcode,copycode,imgxdl:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX

  MOV EAX,frmyd
  DEC EAX
  MUL imgxdl
{  ADD EAX,imagedatastart
  ADD EAX,img }
  ADD EAX,[EDI+timage.pixeldata]
  MOV destofs,EAX
  MOV EDI,EAX

  MOV EBX,col

@mrle8C24_loop1:
  LODSW
  OR AL,AL
  JNZ @mrle8C24_else1
  OR AH,AH
  JNZ @mrle8C24_w1

  MOV EDI,destofs
  SUB EDI,imgxdl
  MOV destofs,EDI
  JMP @mrle8C24_loop1

@mrle8C24_w1:
  CMP AH,1
  JE @mrle8C24_ende
  CMP AH,2
  JNE @mrle8C24_w2

  LODSB
  MOVZX EAX,AL
  LEA EAX,[EAX+EAX*2]
  ADD EDI,EAX
  LODSB
  MOVZX EAX,AL
  MUL imgxdl
  SUB EDI,EAX
  SUB destofs,EAX

  JMP @mrle8C24_loop1

@mrle8C24_w2:
  MOVZX EDX,AH
@mrle8C24_copy32:
  LODSB
  MOVZX EAX,AL
  MOV EAX,[EBX+EAX*4]
  STOSW
  SHR EAX,16
  STOSB
  DEC EDX
  JNZ @mrle8C24_copy32
  INC ESI
  AND ESI,0FFFFFFFEh
  JMP @mrle8C24_loop1

@mrle8C24_else1:
  MOVZX ECX,AL
  MOVZX EAX,AH
  MOV EAX,[EBX+EAX*4]
@mrle8c24_loopa:
  STOSW
  ROR EAX,16
  STOSB
  ROR EAX,16
  LOOP @mrle8c24_loopa
  JMP @mrle8C24_loop1
@mrle8C24_ende:
END;

PROCEDURE DecodeMRLE8C32(frmxd,frmyd:longint;data,img,col:pointer);assembler;
VAR destofs,fillcode,copycode,imgxdl:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX

  MOV EAX,frmyd
  DEC EAX
  MUL imgxdl
{  ADD EAX,imagedatastart
  ADD EAX,img }
  ADD EAX,[EDI+timage.pixeldata]
  MOV destofs,EAX
  MOV EDI,EAX

  MOV EBX,col

@mrle8c32_loop1:
  LODSW
  OR AL,AL
  JNZ @mrle8c32_else1
  OR AH,AH
  JNZ @mrle8c32_w1

  MOV EDI,destofs
  SUB EDI,imgxdl
  MOV destofs,EDI
  JMP @mrle8c32_loop1

@mrle8c32_w1:
  CMP AH,1
  JE @mrle8c32_ende
  CMP AH,2
  JNE @mrle8c32_w2

  LODSB
  MOVZX EAX,AL
  LEA EDI,[EDI+EAX*4]
  LODSB
  MUL imgxdl
  SUB EDI,EAX
  SUB destofs,EAX

  JMP @mrle8c32_loop1

@mrle8c32_w2:
  MOVZX EDX,AH
@mrle8c32_copy32:
  LODSB
  MOVZX EAX,AL
  MOV EAX,[EBX+EAX*4]
  STOSD
  DEC EDX
  JNZ @mrle8c32_copy32
  INC ESI
  AND ESI,0FFFFFFFEh
  JMP @mrle8c32_loop1

@mrle8c32_else1:
  MOVZX ECX,AL
  MOVZX EAX,AH
  MOV EAX,[EBX+EAX*4]
  REP STOSD
  JMP @mrle8c32_loop1
@mrle8c32_ende:
END;

PROCEDURE DecodeMRLE8(frmxd,frmyd:longint;data,img,col:pointer);
BEGIN
  CASE gxcurcol OF
    ig_col8:DecodeMRLE8C8(frmxd,frmyd,data,img,col);
    ig_col15:DecodeMRLE8C16(frmxd,frmyd,data,img,col);
    ig_col16:DecodeMRLE8C16(frmxd,frmyd,data,img,col);
    ig_col24:DecodeMRLE8C24(frmxd,frmyd,data,img,col);
    ig_col32:DecodeMRLE8C32(frmxd,frmyd,data,img,col);
  END;
END;

{=========================== Radius Cinepak 24bit ===========================}

FUNCTION colyuv(yuv:longint):longint;assembler;
ASM
  XOR BX,BX
  MOV BL,BYTE PTR [yuv]
  XOR DX,DX

  MOV AL,BYTE PTR [yuv+2]
  CBW
  SAL AX,1
  SUB DX,AX
  ADD AX,BX

  OR AH,AH
  JZ @cyuv_w1
  MOV AX,0
  JS @cyuv_w1
  MOV AX,255
@cyuv_w1:
  MOV CL,AL
  SHL ECX,16

  MOV AL,BYTE PTR [yuv+1]
  CBW
  SUB DX,AX
  SAL AX,1
  SAR DX,1
  ADD AX,BX

  OR AH,AH
  JZ @cyuv_w2
  MOV AX,0
  JS @cyuv_w2
  MOV AX,255
@cyuv_w2:
  MOV CL,AL

  ADD DX,BX

  OR DH,DH
  JZ @cyuv_w3
  MOV DX,0
  JS @cyuv_w3
  MOV DX,255
@cyuv_w3:
  MOV CH,DL

  PUSH ECX
  CALL rgbcolor
END;

PROCEDURE DecodeCVID24C8(frmxd,frmyd:longint;data,img,codebook:pointer);assembler;
VAR pd,imgxdl,bitmask,xpos,ypos,xinc,yinc,count,nextline,breite,hoehe,cbo,blockcount:longint;
    frametyp,blocktyp:word;
ASM
  MOV ypos,0

  MOV EDI,img
  MOV ESI,data

  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  MOV EAX,[EDI+timage.pixeldata]
  MOV pd,EAX

  MOV xinc,4 {bytperpix*4}

  MOV EAX,imgxdl
  SHL EAX,2
  MOV yinc,EAX

  MOV EAX,imgxdl
  SUB EAX,xinc
  MOV nextline,EAX

  MOV EAX,codebook
  MOV cbo,EAX

  LODSD  {00h-03h: gesamt groesse und frame typ}
  MOV BYTE PTR frametyp,AL
  LODSD  {04h-07h: ---}
  LODSW  {08h-09h: anzahl der bloecke}
  XCHG AL,AH
  MOVZX ECX,AX

{----- block decoder - bloecke ab 0Ah ---------------------------------------}

@cvid24c8_loop1:
  PUSH ECX
  PUSH ESI

  LODSD {00h-03h: gesamt groesse und type 10h,11h}
  XOR AL,AL
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV ECX,EAX

  LODSD {04h-07h: ---}
  XOR EAX,EAX
  LODSW {08h-09h: hoehe}
  XCHG AL,AH
  MOV hoehe,EAX
  MOV EBX,EAX
  LODSW   {0Ah-0Bh: breite}
  XCHG AL,AH
  MOV breite,EAX

  SHR EAX,2
  SHR EBX,2
  MUL EBX
  MOV blockcount,EAX

  MOV xpos,0
  MOV EAX,ypos
  MUL imgxdl
  MOV EDI,EAX
{  ADD EDI,imagedatastart
  ADD EDI,img }
  ADD EDI,pd
  MOV EAX,hoehe
  ADD ypos,EAX

{----- sub block decoder - sub bloecke ab 0Ch -------------------------------}
  SUB ECX,0Ch
@cvid24c8_loop2:
  LODSD {00h-03h: gesamt groesse und type 20h,21h,22h,23h,30h,31h,32h}
  MOV DL,AL
  XOR AL,AL
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  SUB ECX,EAX
  PUSH ECX

  CMP DL,21h
  JE @cvid24c8_type_21h
  CMP DL,23h
  JE @cvid24c8_type_23h

  CMP DL,31h
  JE @cvid24c8_type_31h
  CMP DL,30h
  JE @cvid24c8_type_30h

  CMP DL,20h
  JE @cvid24c8_type_20h
  CMP DL,22h
  JE @cvid24c8_type_22h

  CMP DL,32h
  JE @cvid24c8_type_32h

@cvid24c8_continue1:

  POP ECX
  OR ECX,ECX
  JNZ @cvid24c8_loop2

{----------------------------------------------------------------------------}

  POP ESI
  POP ECX

  MOV EAX,[ESI] {00h-03h: gesamt groesse und type 10h,11}
  XOR AL,AL
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  ADD ESI,EAX

  ADD cbo,1000h

  DEC ECX
  JNZ @cvid24c8_loop1

  JMP @cvid24c8_ende
{----------------------------------------------------------------------------}
{------------ block20 -------------------------------------------------------}
@cvid24c8_type_20h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c8_continue1
  PUSH EDI
  MOV EDI,codebook
@cvid24c8_t20h_loop1:
  PUSH ECX
  PUSH EDI
  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI+0000h],AL
  MOV [EDI+1000h],AL
  MOV [EDI+2000h],AL
  MOV [EDI+3000h],AL
  CALL colyuv
  MOV [EDI+0001h],AL
  MOV [EDI+1001h],AL
  MOV [EDI+2001h],AL
  MOV [EDI+3001h],AL
  CALL colyuv
  MOV [EDI+0002h],AL
  MOV [EDI+1002h],AL
  MOV [EDI+2002h],AL
  MOV [EDI+3002h],AL
  CALL colyuv
  MOV [EDI+0003h],AL
  MOV [EDI+1003h],AL
  MOV [EDI+2003h],AL
  MOV [EDI+3003h],AL
  POP EDI
  POP ECX
  ADD EDI,16
  SUB ECX,6
  JG @cvid24c8_t20h_loop1
  POP EDI
  JMP @cvid24c8_continue1
{------------ block21 -------------------------------------------------------}
@cvid24c8_type_21h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c8_continue1

  PUSH EDI
  MOV EDI,cbo
  MOV ECX,256
@cvid24c8_t21h_loop1:

  TEST CX,001Fh
  JNZ @cvid24c8_t21h_weiter1
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
@cvid24c8_t21h_weiter1:
  SHL bitmask,1
  JNC @cvid24c8_t21h_nocol

  PUSH ECX
  PUSH EDI

  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI],AL
  CALL colyuv
  MOV [EDI+1],AL
  CALL colyuv
  MOV [EDI+2],AL
  CALL colyuv
  MOV [EDI+3],AL

  CMP BYTE PTR frametyp,0
  JNE @cvid24c8_t21h_weiter2
  PUSH ESI
  MOV ESI,EDI
  ADD EDI,1000h
  MOVSD
  POP ESI
@cvid24c8_t21h_weiter2:

  POP EDI
  POP ECX
@cvid24c8_t21h_nocol:

  ADD EDI,16
  DEC ECX
  JG @cvid24c8_t21h_loop1
  POP EDI
  JMP @cvid24c8_continue1

{------------ block22 -------------------------------------------------------}
@cvid24c8_type_22h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c8_continue1
  PUSH EDI
  MOV EDI,codebook
  ADD EDI,4000h
@cvid24c8_t22h_loop1:
  PUSH ECX
  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI+0000h],EAX
  MOV [EDI+1000h],EAX
  MOV [EDI+2000h],EAX
  MOV [EDI+3000h],EAX
  CALL colyuv
  MOV [EDI+0004h],EAX
  MOV [EDI+1004h],EAX
  MOV [EDI+2004h],EAX
  MOV [EDI+3004h],EAX
  CALL colyuv
  MOV [EDI+0008h],EAX
  MOV [EDI+1008h],EAX
  MOV [EDI+2008h],EAX
  MOV [EDI+3008h],EAX
  CALL colyuv
  MOV [EDI+000Ch],EAX
  MOV [EDI+100Ch],EAX
  MOV [EDI+200Ch],EAX
  MOV [EDI+300Ch],EAX
  ADD EDI,16
  POP ECX
  SUB ECX,6
  JG @cvid24c8_t22h_loop1
  POP EDI
  JMP @cvid24c8_continue1
{------------ block23 -------------------------------------------------------}
@cvid24c8_type_23h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c8_continue1

  PUSH EDI
  MOV EDI,cbo
  ADD EDI,4000h
  MOV ECX,256
@cvid24c8_t23h_loop1:

  TEST ECX,001Fh
  JNZ @cvid24c8_t23h_weiter1
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
@cvid24c8_t23h_weiter1:

  SHL bitmask,1
  JNC @cvid24c8_t23h_nocol

  PUSH ECX
  PUSH EDI

  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI],EAX
  CALL colyuv
  MOV [EDI+4],EAX
  CALL colyuv
  MOV [EDI+8],EAX
  CALL colyuv
  MOV [EDI+12],EAX

  CMP BYTE PTR frametyp,0
  JNE @cvid24c8_t23h_weiter2
  PUSH ESI
  MOV ESI,EDI
  ADD EDI,1000h
  MOVSD
  MOVSD
  MOVSD
  MOVSD
  POP ESI
@cvid24c8_t23h_weiter2:

  POP EDI
  POP ECX
@cvid24c8_t23h_nocol:

  ADD EDI,16
  DEC ECX
  JG @cvid24c8_t23h_loop1
  POP EDI
  JMP @cvid24c8_continue1
{----------------------------------------------------------------------------}
{------------ block30 -------------------------------------------------------}
@cvid24c8_type_30h:
  MOV EAX,blockcount
  MOV count,EAX
@cvid24c8_t30h_loop1:
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX

  MOV ECX,32
  CMP ECX,count
  JLE @cvid24c8_t30h_loop2
  MOV ECX,count
@cvid24c8_t30h_loop2:
  SHL bitmask,1

  JNC @cvid24c8_t30h_block_2x2
  CALL DWORD PTR @cvid24c8_block4x4code
  LOOP @cvid24c8_t30h_loop2

  SUB count,32
  JG @cvid24c8_t30h_loop1
  JMP @cvid24c8_continue1

@cvid24c8_t30h_block_2x2:
  CALL DWORD PTR @cvid24c8_block2x2code
  LOOP @cvid24c8_t30h_loop2

  SUB count,32
  JG @cvid24c8_t30h_loop1
  JMP @cvid24c8_continue1
{------------ block31 -------------------------------------------------------}
@cvid24c8_type_31h:
  SUB EAX,4
  AND EAX,00FFFFFFh
  MOV count,EAX
  MOV ECX,0

@cvid24c8_t31h_loop1:

  OR ECX,ECX
  JNZ @cvid24c8_t31h_weiter1a
  CMP count,4
  JL @cvid24c8_continue1

  MOV ECX,32
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
  SUB count,4
@cvid24c8_t31h_weiter1a:

  DEC ECX
  SHL bitmask,1
  JC @cvid24c8_t31h_block

  MOV EAX,xpos
  ADD EAX,xinc
  CMP EAX,breite
  JL @cvid24c8_t31h_weiter3
  ADD EDI,yinc
  SUB EAX,breite
@cvid24c8_t31h_weiter3:
  MOV xpos,EAX
  JMP @cvid24c8_t31h_loop1

@cvid24c8_t31h_block:
  OR ECX,ECX
  JNZ @cvid24c8_t31h_weiter1b

  MOV ECX,32
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
  SUB count,4
@cvid24c8_t31h_weiter1b:

  DEC ECX
  SHL bitmask,1
  JNC @cvid24c8_t31h_block_2x2

  CALL @cvid24c8_block4x4code
  SUB count,4
  JMP @cvid24c8_t31h_loop1

@cvid24c8_t31h_block_2x2:
  CALL DWORD PTR @cvid24c8_block2x2code
  SUB count,1
  JMP @cvid24c8_t31h_loop1
{------------ block32 -------------------------------------------------------}
@cvid24c8_type_32h:
  MOV ECX,blockcount
@cvid24c8_t32h_loop1:
{===>  CALL block2x2code }
  CALL DWORD PTR @cvid24c8_block2x2code
  LOOP @cvid24c8_t32h_loop1
  JMP @cvid24c8_continue1

{---------- block 2x2 --------------------------------------------------- }
@cvid24c8_block2x2code:
  MOV EAX,xpos
  CMP EAX,breite
  JL @cvid24c8_block2x2_32_weiter1
  ADD EDI,yinc
  SUB EAX,breite
@cvid24c8_block2x2_32_weiter1:

  PUSH EDI
  ADD EDI,EAX
  ADD EAX,xinc
  MOV xpos,EAX

  MOVZX EBX,BYTE PTR [ESI]
  ADD ESI,1
  SHL EBX,4
  ADD EBX,cbo
  ADD EBX,4000h

  MOV AL,[EBX+4]
  MOV AH,AL
  SHL EAX,16
  MOV AL,[EBX]
  MOV AH,AL

  STOSD
  ADD EDI,nextline
  STOSD
  ADD EDI,nextline

  MOV AL,[EBX+12]
  MOV AH,AL
  SHL EAX,16
  MOV AL,[EBX+8]
  MOV AH,AL

  STOSD
  ADD EDI,nextline
  STOSD

  POP EDI
  RET

{---------- block 4x4 ------------------------------------------------------}
@cvid24c8_block4x4code:
  MOV EAX,xpos
  CMP EAX,breite
  JL @cvid24c8_block4x4_32_weiter1
  ADD EDI,yinc
  SUB EAX,breite
@cvid24c8_block4x4_32_weiter1:

  PUSH EDI
  ADD EDI,EAX
  ADD EAX,xinc
  MOV xpos,EAX
  LODSD
  PUSH ESI

  MOVZX ESI,AL
  MOVZX EDX,AH
  SHL ESI,4
  SHL EDX,4
  ADD ESI,cbo
  ADD EDX,cbo
  SHR EAX,16

  MOVSW
  XCHG EDX,ESI
  MOVSW
  XCHG EDX,ESI
  ADD EDI,nextline
  MOVSW
  XCHG EDX,ESI
  MOVSW

  MOVZX ESI,AL
  MOVZX EDX,AH
  SHL ESI,4
  SHL EDX,4
  ADD ESI,cbo
  ADD EDX,cbo

  ADD EDI,nextline
  MOVSW
  XCHG EDX,ESI
  MOVSW
  XCHG EDX,ESI
  ADD EDI,nextline
  MOVSW
  XCHG EDX,ESI
  MOVSW

  POP ESI
  POP EDI
  RET
@cvid24c8_ende:
END;

PROCEDURE DecodeCVID24C16(frmxd,frmyd:longint;data,img,codebook:pointer);assembler;
VAR pd,imgxdl,bitmask,xpos,ypos,xinc,yinc,count,nextline,breite,hoehe,cbo,blockcount:longint;
    frametyp,blocktyp:word;
ASM
  MOV ypos,0

  MOV EDI,img
  MOV ESI,data

  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  MOV EAX,[EDI+timage.pixeldata]
  MOV pd,EAX

  MOV xinc,8 {bytperpix*4}

  MOV EAX,imgxdl
  SHL EAX,2
  MOV yinc,EAX

  MOV EAX,imgxdl
  SUB EAX,xinc
  MOV nextline,EAX

  MOV EAX,codebook
  MOV cbo,EAX

  LODSD  {00h-03h: gesamt groesse und frame typ}
  MOV BYTE PTR frametyp,AL
  LODSD  {04h-07h: ---}
  LODSW  {08h-09h: anzahl der bloecke}
  XCHG AL,AH
  MOVZX ECX,AX

{----- block decoder - bloecke ab 0Ah ---------------------------------------}

@cvid24c16_loop1:
  PUSH ECX
  PUSH ESI

  LODSD {00h-03h: gesamt groesse und type 10h,11h}
  XOR AL,AL
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV ECX,EAX

  LODSD {04h-07h: ---}
  XOR EAX,EAX
  LODSW {08h-09h: hoehe}
  XCHG AL,AH
  MOV hoehe,EAX
  MOV EBX,EAX
  LODSW   {0Ah-0Bh: breite}
  XCHG AL,AH
  MOV breite,EAX

  SHR EAX,2
  SHR EBX,2
  MUL EBX
  MOV blockcount,EAX

  MOV EAX,breite
  SHL EAX,1   {EAX=EAX*bytperpix}
  MOV breite,EAX

  MOV xpos,0
  MOV EAX,ypos
  MUL imgxdl
  MOV EDI,EAX
{  ADD EDI,imagedatastart
  ADD EDI,img }
  ADD EDI,pd
  MOV EAX,hoehe
  ADD ypos,EAX

{----- sub block decoder - sub bloecke ab 0Ch -------------------------------}
  SUB ECX,0Ch
@cvid24c16_loop2:
  LODSD {00h-03h: gesamt groesse und type 20h,21h,22h,23h,30h,31h,32h}
  MOV DL,AL
  XOR AL,AL
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  SUB ECX,EAX
  PUSH ECX

  CMP DL,21h
  JE @cvid24c16_type_21h
  CMP DL,23h
  JE @cvid24c16_type_23h

  CMP DL,31h
  JE @cvid24c16_type_31h
  CMP DL,30h
  JE @cvid24c16_type_30h

  CMP DL,20h
  JE @cvid24c16_type_20h
  CMP DL,22h
  JE @cvid24c16_type_22h

  CMP DL,32h
  JE @cvid24c16_type_32h

@cvid24c16_continue1:

  POP ECX
  OR ECX,ECX
  JNZ @cvid24c16_loop2

{----------------------------------------------------------------------------}

  POP ESI
  POP ECX

  MOV EAX,[ESI] {00h-03h: gesamt groesse und type 10h,11}
  XOR AL,AL
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  ADD ESI,EAX

  ADD cbo,1000h

  DEC ECX
  JNZ @cvid24c16_loop1

  JMP @cvid24c16_ende
{----------------------------------------------------------------------------}
{------------ block20 -------------------------------------------------------}
@cvid24c16_type_20h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c16_continue1
  PUSH EDI
  MOV EDI,codebook
@cvid24c16_t20h_loop1:
  PUSH ECX
  PUSH EDI
  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI+0000h],AX
  MOV [EDI+1000h],AX
  MOV [EDI+2000h],AX
  MOV [EDI+3000h],AX
  CALL colyuv
  MOV [EDI+0002h],AX
  MOV [EDI+1002h],AX
  MOV [EDI+2002h],AX
  MOV [EDI+3002h],AX
  CALL colyuv
  MOV [EDI+0004h],AX
  MOV [EDI+1004h],AX
  MOV [EDI+2004h],AX
  MOV [EDI+3004h],AX
  CALL colyuv
  MOV [EDI+0006h],AX
  MOV [EDI+1006h],AX
  MOV [EDI+2006h],AX
  MOV [EDI+3006h],AX
  POP EDI
  POP ECX
  ADD EDI,16
  SUB ECX,6
  JG @cvid24c16_t20h_loop1
  POP EDI
  JMP @cvid24c16_continue1
{------------ block21 -------------------------------------------------------}
@cvid24c16_type_21h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c16_continue1

  PUSH EDI
  MOV EDI,cbo
  MOV ECX,256
@cvid24c16_t21h_loop1:

  TEST CX,001Fh
  JNZ @cvid24c16_t21h_weiter1
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
@cvid24c16_t21h_weiter1:
  SHL bitmask,1
  JNC @cvid24c16_t21h_nocol

  PUSH ECX
  PUSH EDI

  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI],AX
  CALL colyuv
  MOV [EDI+2],AX
  CALL colyuv
  MOV [EDI+4],AX
  CALL colyuv
  MOV [EDI+6],AX

  CMP BYTE PTR frametyp,0
  JNE @cvid24c16_t21h_weiter2
  PUSH ESI
  MOV ESI,EDI
  ADD EDI,1000h
  MOVSD
  MOVSD
  POP ESI
@cvid24c16_t21h_weiter2:

  POP EDI
  POP ECX
@cvid24c16_t21h_nocol:

  ADD EDI,16
  DEC ECX
  JG @cvid24c16_t21h_loop1
  POP EDI
  JMP @cvid24c16_continue1

{------------ block22 -------------------------------------------------------}
@cvid24c16_type_22h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c16_continue1
  PUSH EDI
  MOV EDI,codebook
  ADD EDI,4000h
@cvid24c16_t22h_loop1:
  PUSH ECX
  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI+0000h],EAX
  MOV [EDI+1000h],EAX
  MOV [EDI+2000h],EAX
  MOV [EDI+3000h],EAX
  CALL colyuv
  MOV [EDI+0004h],EAX
  MOV [EDI+1004h],EAX
  MOV [EDI+2004h],EAX
  MOV [EDI+3004h],EAX
  CALL colyuv
  MOV [EDI+0008h],EAX
  MOV [EDI+1008h],EAX
  MOV [EDI+2008h],EAX
  MOV [EDI+3008h],EAX
  CALL colyuv
  MOV [EDI+000Ch],EAX
  MOV [EDI+100Ch],EAX
  MOV [EDI+200Ch],EAX
  MOV [EDI+300Ch],EAX
  ADD EDI,16
  POP ECX
  SUB ECX,6
  JG @cvid24c16_t22h_loop1
  POP EDI
  JMP @cvid24c16_continue1
{------------ block23 -------------------------------------------------------}
@cvid24c16_type_23h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c16_continue1

  PUSH EDI
  MOV EDI,cbo
  ADD EDI,4000h
  MOV ECX,256
@cvid24c16_t23h_loop1:

  TEST ECX,001Fh
  JNZ @cvid24c16_t23h_weiter1
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
@cvid24c16_t23h_weiter1:

  SHL bitmask,1
  JNC @cvid24c16_t23h_nocol

  PUSH ECX
  PUSH EDI

  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI],EAX
  CALL colyuv
  MOV [EDI+4],EAX
  CALL colyuv
  MOV [EDI+8],EAX
  CALL colyuv
  MOV [EDI+12],EAX

  CMP BYTE PTR frametyp,0
  JNE @cvid24c16_t23h_weiter2
  PUSH ESI
  MOV ESI,EDI
  ADD EDI,1000h
  MOVSD
  MOVSD
  MOVSD
  MOVSD
  POP ESI
@cvid24c16_t23h_weiter2:

  POP EDI
  POP ECX
@cvid24c16_t23h_nocol:

  ADD EDI,16
  DEC ECX
  JG @cvid24c16_t23h_loop1
  POP EDI
  JMP @cvid24c16_continue1
{----------------------------------------------------------------------------}
{------------ block30 -------------------------------------------------------}
@cvid24c16_type_30h:
  MOV EAX,blockcount
  MOV count,EAX
@cvid24c16_t30h_loop1:
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX

  MOV ECX,32
  CMP ECX,count
  JLE @cvid24c16_t30h_loop2
  MOV ECX,count
@cvid24c16_t30h_loop2:
  SHL bitmask,1

  JNC @cvid24c16_t30h_block_2x2
  CALL DWORD PTR @cvid24c16_block4x4code
  LOOP @cvid24c16_t30h_loop2

  SUB count,32
  JG @cvid24c16_t30h_loop1
  JMP @cvid24c16_continue1

@cvid24c16_t30h_block_2x2:
  CALL DWORD PTR @cvid24c16_block2x2code
  LOOP @cvid24c16_t30h_loop2

  SUB count,32
  JG @cvid24c16_t30h_loop1
  JMP @cvid24c16_continue1
{------------ block31 -------------------------------------------------------}
@cvid24c16_type_31h:
  SUB EAX,4
  AND EAX,00FFFFFFh
  MOV count,EAX
  MOV ECX,0

@cvid24c16_t31h_loop1:

  OR ECX,ECX
  JNZ @cvid24c16_t31h_weiter1a
  CMP count,4
  JL @cvid24c16_continue1

  MOV ECX,32
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
  SUB count,4
@cvid24c16_t31h_weiter1a:

  DEC ECX
  SHL bitmask,1
  JC @cvid24c16_t31h_block

  MOV EAX,xpos
  ADD EAX,xinc
  CMP EAX,breite
  JL @cvid24c16_t31h_weiter3
  ADD EDI,yinc
  SUB EAX,breite
@cvid24c16_t31h_weiter3:
  MOV xpos,EAX
  JMP @cvid24c16_t31h_loop1

@cvid24c16_t31h_block:
  OR ECX,ECX
  JNZ @cvid24c16_t31h_weiter1b

  MOV ECX,32
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
  SUB count,4
@cvid24c16_t31h_weiter1b:

  DEC ECX
  SHL bitmask,1
  JNC @cvid24c16_t31h_block_2x2

  CALL @cvid24c16_block4x4code
  SUB count,4
  JMP @cvid24c16_t31h_loop1

@cvid24c16_t31h_block_2x2:
  CALL DWORD PTR @cvid24c16_block2x2code
  SUB count,1
  JMP @cvid24c16_t31h_loop1
{------------ block32 -------------------------------------------------------}
@cvid24c16_type_32h:
  MOV ECX,blockcount
@cvid24c16_t32h_loop1:
  CALL DWORD PTR @cvid24c16_block2x2code
  LOOP @cvid24c16_t32h_loop1
  JMP @cvid24c16_continue1

{---------- block 2x2 --------------------------------------------------- }
@cvid24c16_block2x2code:
  MOV EAX,xpos
  CMP EAX,breite
  JL @cvid24c16_block2x2_32_weiter1
  ADD EDI,yinc
  SUB EAX,breite
@cvid24c16_block2x2_32_weiter1:

  PUSH EDI
  ADD EDI,EAX
  ADD EAX,xinc
  MOV xpos,EAX

  MOVZX EBX,BYTE PTR [ESI]
  ADD ESI,1
  SHL EBX,4
  ADD EBX,cbo
  ADD EBX,4000h

  MOV AX,[EBX]
  SHL EAX,16
  MOV AX,[EBX+4]
  MOV EDX,EAX
  ROR EDX,16
  XCHG AX,DX

  STOSD
  XCHG EAX,EDX
  STOSD
  XCHG EAX,EDX
  ADD EDI,nextline
  STOSD
  XCHG EAX,EDX
  STOSD
  ADD EDI,nextline

  MOV AX,[EBX+8]
  SHL EAX,16
  MOV AX,[EBX+12]
  MOV EDX,EAX
  ROR EDX,16
  XCHG AX,DX

  STOSD
  XCHG EAX,EDX
  STOSD
  XCHG EAX,EDX
  ADD EDI,nextline
  STOSD
  XCHG EAX,EDX
  STOSD

  POP EDI
  RET

{---------- block 4x4 ------------------------------------------------------}
@cvid24c16_block4x4code:
  MOV EAX,xpos
  CMP EAX,breite
  JL @cvid24c16_block4x4_32_weiter1
  ADD EDI,yinc
  SUB EAX,breite
@cvid24c16_block4x4_32_weiter1:

  PUSH EDI
  ADD EDI,EAX
  ADD EAX,xinc
  MOV xpos,EAX
  LODSD
  PUSH ESI

  MOVZX ESI,AL
  MOVZX EDX,AH
  SHL ESI,4
  SHL EDX,4
  ADD ESI,cbo
  ADD EDX,cbo
  SHR EAX,16

  MOVSD
  XCHG EDX,ESI
  MOVSD
  XCHG EDX,ESI
  ADD EDI,nextline
  MOVSD
  XCHG EDX,ESI
  MOVSD

  MOVZX ESI,AL
  MOVZX EDX,AH
  SHL ESI,4
  SHL EDX,4
  ADD ESI,cbo
  ADD EDX,cbo

  ADD EDI,nextline
  MOVSD
  XCHG EDX,ESI
  MOVSD
  XCHG EDX,ESI
  ADD EDI,nextline
  MOVSD
  XCHG EDX,ESI
  MOVSD

  POP ESI
  POP EDI
  RET

@cvid24c16_ende:
END;

PROCEDURE DecodeCVID24C24(frmxd,frmyd:longint;data,img,codebook:pointer);assembler;
VAR pd,imgxdl,bitmask,xpos,ypos,xinc,yinc,count,nextline,breite,hoehe,cbo,blockcount:longint;
    frametyp,blocktyp:word;
ASM
  MOV ypos,0
  MOV EDI,img
  MOV ESI,data

  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  MOV EAX,[EDI+timage.pixeldata]
  MOV pd,EAX

  MOV xinc,12 {bytperpix*4}

  MOV EAX,imgxdl
  SHL EAX,2
  MOV yinc,EAX

  MOV EAX,imgxdl
  SUB EAX,xinc
  MOV nextline,EAX

  MOV EAX,codebook
  MOV cbo,EAX

  LODSD  {00h-03h: gesamt groesse und frame typ}
  MOV BYTE PTR frametyp,AL
  LODSD  {04h-07h: ---}
  LODSW  {08h-09h: anzahl der bloecke}
  XCHG AL,AH
  MOVZX ECX,AX

{----- block decoder - bloecke ab 0Ah ---------------------------------------}

@cvid24c24_loop1:
  PUSH ECX
  PUSH ESI

  LODSD {00h-03h: gesamt groesse und type 10h,11h}
  XOR AL,AL
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV ECX,EAX

  LODSD {04h-07h: ---}
  XOR EAX,EAX
  LODSW {08h-09h: hoehe}
  XCHG AL,AH
  MOV hoehe,EAX
  MOV EBX,EAX
  LODSW   {0Ah-0Bh: breite}
  XCHG AL,AH
  MOV breite,EAX

  SHR EAX,2
  SHR EBX,2
  MUL EBX
  MOV blockcount,EAX

  MOV EAX,breite
  LEA EAX,[EAX+EAX*2] {EAX=EAX*bytperpix}
  MOV breite,EAX

  MOV xpos,0
  MOV EAX,ypos
  MUL imgxdl
  MOV EDI,EAX
{  ADD EDI,imagedatastart
  ADD EDI,img }
  ADD EDI,pd
  MOV EAX,hoehe
  ADD ypos,EAX

{----- sub block decoder - sub bloecke ab 0Ch -------------------------------}
  SUB ECX,0Ch
@cvid24c24_loop2:
  LODSD {00h-03h: gesamt groesse und type 20h,21h,22h,23h,30h,31h,32h}
  MOV DL,AL
  XOR AL,AL
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  SUB ECX,EAX
  PUSH ECX

  CMP DL,21h
  JE @cvid24c24_type_21h
  CMP DL,23h
  JE @cvid24c24_type_23h

  CMP DL,31h
  JE @cvid24c24_type_31h
  CMP DL,30h
  JE @cvid24c24_type_30h

  CMP DL,20h
  JE @cvid24c24_type_20h
  CMP DL,22h
  JE @cvid24c24_type_22h

  CMP DL,32h
  JE @cvid24c24_type_32h

@cvid24c24_continue1:

  POP ECX
  OR ECX,ECX
  JNZ @cvid24c24_loop2

{----------------------------------------------------------------------------}

  POP ESI
  POP ECX

  MOV EAX,[ESI] {00h-03h: gesamt groesse und type 10h,11}
  XOR AL,AL
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  ADD ESI,EAX

  ADD cbo,1000h

  DEC ECX
  JNZ @cvid24c24_loop1

  JMP @cvid24c24_ende
{----------------------------------------------------------------------------}
{------------ block20 -------------------------------------------------------}
@cvid24c24_type_20h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c24_continue1
  PUSH EDI
  MOV EDI,codebook
@cvid24c24_t20h_loop1:
  PUSH ECX
  PUSH EDI
  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI+0000h],EAX
  MOV [EDI+1000h],EAX
  MOV [EDI+2000h],EAX
  MOV [EDI+3000h],EAX
  CALL colyuv
  MOV [EDI+0003h],EAX
  MOV [EDI+1003h],EAX
  MOV [EDI+2003h],EAX
  MOV [EDI+3003h],EAX
  CALL colyuv
  MOV [EDI+0006h],EAX
  MOV [EDI+1006h],EAX
  MOV [EDI+2006h],EAX
  MOV [EDI+3006h],EAX
  CALL colyuv
  MOV [EDI+0009h],EAX
  MOV [EDI+1009h],EAX
  MOV [EDI+2009h],EAX
  MOV [EDI+3009h],EAX
  POP EDI
  POP ECX
  ADD EDI,16
  SUB ECX,6
  JG @cvid24c24_t20h_loop1
  POP EDI
  JMP @cvid24c24_continue1
{------------ block21 -------------------------------------------------------}
@cvid24c24_type_21h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c24_continue1

  PUSH EDI
  MOV EDI,cbo
  MOV ECX,256
@cvid24c24_t21h_loop1:

  TEST CX,001Fh
  JNZ @cvid24c24_t21h_weiter1
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
@cvid24c24_t21h_weiter1:
  SHL bitmask,1
  JNC @cvid24c24_t21h_nocol

  PUSH ECX
  PUSH EDI

  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI],EAX
  CALL colyuv
  MOV [EDI+3],EAX
  CALL colyuv
  MOV [EDI+6],EAX
  CALL colyuv
  MOV [EDI+9],EAX

  CMP BYTE PTR frametyp,0
  JNE @cvid24c24_t21h_weiter2
  PUSH ESI
  MOV ESI,EDI
  ADD EDI,1000h
  MOVSD
  MOVSD
  MOVSD
  POP ESI
@cvid24c24_t21h_weiter2:

  POP EDI
  POP ECX
@cvid24c24_t21h_nocol:

  ADD EDI,16
  DEC ECX
  JG @cvid24c24_t21h_loop1
  POP EDI
  JMP @cvid24c24_continue1

{------------ block22 -------------------------------------------------------}
@cvid24c24_type_22h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c24_continue1
  PUSH EDI
  MOV EDI,codebook
  ADD EDI,4000h
@cvid24c24_t22h_loop1:
  PUSH ECX
  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI+0000h],EAX
  MOV [EDI+1000h],EAX
  MOV [EDI+2000h],EAX
  MOV [EDI+3000h],EAX
  CALL colyuv
  MOV [EDI+0004h],EAX
  MOV [EDI+1004h],EAX
  MOV [EDI+2004h],EAX
  MOV [EDI+3004h],EAX
  CALL colyuv
  MOV [EDI+0008h],EAX
  MOV [EDI+1008h],EAX
  MOV [EDI+2008h],EAX
  MOV [EDI+3008h],EAX
  CALL colyuv
  MOV [EDI+000Ch],EAX
  MOV [EDI+100Ch],EAX
  MOV [EDI+200Ch],EAX
  MOV [EDI+300Ch],EAX
  ADD EDI,16
  POP ECX
  SUB ECX,6
  JG @cvid24c24_t22h_loop1
  POP EDI
  JMP @cvid24c24_continue1
{------------ block23 -------------------------------------------------------}
@cvid24c24_type_23h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c24_continue1

  PUSH EDI
  MOV EDI,cbo
  ADD EDI,4000h
  MOV ECX,256
@cvid24c24_t23h_loop1:

  TEST ECX,001Fh
  JNZ @cvid24c24_t23h_weiter1
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
@cvid24c24_t23h_weiter1:

  SHL bitmask,1
  JNC @cvid24c24_t23h_nocol

  PUSH ECX
  PUSH EDI

  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI],EAX
  CALL colyuv
  MOV [EDI+4],EAX
  CALL colyuv
  MOV [EDI+8],EAX
  CALL colyuv
  MOV [EDI+12],EAX

  CMP BYTE PTR frametyp,0
  JNE @cvid24c24_t23h_weiter2
  PUSH ESI
  MOV ESI,EDI
  ADD EDI,1000h
  MOVSD
  MOVSD
  MOVSD
  MOVSD
  POP ESI
@cvid24c24_t23h_weiter2:

  POP EDI
  POP ECX
@cvid24c24_t23h_nocol:

  ADD EDI,16
  DEC ECX
  JG @cvid24c24_t23h_loop1
  POP EDI
  JMP @cvid24c24_continue1
{----------------------------------------------------------------------------}
{------------ block30 -------------------------------------------------------}
@cvid24c24_type_30h:
  MOV EAX,blockcount
  MOV count,EAX
@cvid24c24_t30h_loop1:
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX

  MOV ECX,32
  CMP ECX,count
  JLE @cvid24c24_t30h_loop2
  MOV ECX,count
@cvid24c24_t30h_loop2:
  SHL bitmask,1

  JNC @cvid24c24_t30h_block_2x2
  CALL DWORD PTR @cvid24c24_block4x4code
  LOOP @cvid24c24_t30h_loop2

  SUB count,32
  JG @cvid24c24_t30h_loop1
  JMP @cvid24c24_continue1

@cvid24c24_t30h_block_2x2:
  CALL DWORD PTR @cvid24c24_block2x2code
  LOOP @cvid24c24_t30h_loop2

  SUB count,32
  JG @cvid24c24_t30h_loop1
  JMP @cvid24c24_continue1
{------------ block31 -------------------------------------------------------}
@cvid24c24_type_31h:
  SUB EAX,4
  AND EAX,00FFFFFFh
  MOV count,EAX
  MOV ECX,0

@cvid24c24_t31h_loop1:

  OR ECX,ECX
  JNZ @cvid24c24_t31h_weiter1a
  CMP count,4
  JL @cvid24c24_continue1

  MOV ECX,32
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
  SUB count,4
@cvid24c24_t31h_weiter1a:

  DEC ECX
  SHL bitmask,1
  JC @cvid24c24_t31h_block

  MOV EAX,xpos
  ADD EAX,xinc
  CMP EAX,breite
  JL @cvid24c24_t31h_weiter3
  ADD EDI,yinc
  SUB EAX,breite
@cvid24c24_t31h_weiter3:
  MOV xpos,EAX
  JMP @cvid24c24_t31h_loop1

@cvid24c24_t31h_block:
  OR ECX,ECX
  JNZ @cvid24c24_t31h_weiter1b

  MOV ECX,32
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
  SUB count,4
@cvid24c24_t31h_weiter1b:

  DEC ECX
  SHL bitmask,1
  JNC @cvid24c24_t31h_block_2x2

  CALL @cvid24c24_block4x4code
  SUB count,4
  JMP @cvid24c24_t31h_loop1

@cvid24c24_t31h_block_2x2:
  CALL DWORD PTR @cvid24c24_block2x2code
  SUB count,1
  JMP @cvid24c24_t31h_loop1
{------------ block32 -------------------------------------------------------}
@cvid24c24_type_32h:
  MOV ECX,blockcount
@cvid24c24_t32h_loop1:
  CALL DWORD PTR @cvid24c24_block2x2code
  LOOP @cvid24c24_t32h_loop1
  JMP @cvid24c24_continue1

{---------- block 2x2 --------------------------------------------------- }
@cvid24c24_block2x2code:
  MOV EAX,xpos
  CMP EAX,breite
  JL @cvid24c24_block2x2_32_weiter1
  ADD EDI,yinc
  SUB EAX,breite
@cvid24c24_block2x2_32_weiter1:

  PUSH EDI
  ADD EDI,EAX
  ADD EAX,xinc
  MOV xpos,EAX

  MOVZX EBX,BYTE PTR [ESI]
  ADD ESI,1
  SHL EBX,4
  ADD EBX,cbo
  ADD EBX,4000h
  MOV EAX,[EBX]
  MOV EDX,[EBX+4]

  SHL EAX,8
  SHL EDX,8
  MOV AL,AH
  MOV DL,DH
  ROR EAX,8
  ROR EDX,8

  STOSD
  ROR EAX,8
  STOSW
  ROL EAX,8
  XCHG EAX,EDX
  STOSD
  ROR EAX,8
  STOSW
  ROL EAX,8
  XCHG EAX,EDX
  ADD EDI,nextline
  STOSD
  ROR EAX,8
  STOSW
  XCHG EAX,EDX
  STOSD
  ROR EAX,8
  STOSW
  ADD EDI,nextline

  MOV EAX,[EBX+8]
  MOV EDX,[EBX+12]

  SHL EAX,8
  SHL EDX,8
  MOV AL,AH
  MOV DL,DH
  ROR EAX,8
  ROR EDX,8

  STOSD
  ROR EAX,8
  STOSW
  ROL EAX,8
  XCHG EAX,EDX
  STOSD
  ROR EAX,8
  STOSW
  ROL EAX,8
  XCHG EAX,EDX
  ADD EDI,nextline
  STOSD
  ROR EAX,8
  STOSW
  XCHG EAX,EDX
  STOSD
  ROR EAX,8
  STOSW

  POP EDI
  RET

{---------- block 4x4 --- 32 ---------------------------------------------------}
@cvid24c24_block4x4code:
  MOV EAX,xpos
  CMP EAX,breite
  JL @cvid24c24_block4x4_32_weiter1
  ADD EDI,yinc
  SUB EAX,breite
@cvid24c24_block4x4_32_weiter1:

  PUSH EDI
  ADD EDI,EAX
  ADD EAX,xinc
  MOV xpos,EAX
  LODSD
  PUSH ESI

  MOVZX ESI,AL
  MOVZX EDX,AH
  SHL ESI,4
  SHL EDX,4
  ADD ESI,cbo
  ADD EDX,cbo
  SHR EAX,16

  MOVSD
  MOVSW
  XCHG EDX,ESI
  MOVSD
  MOVSW
  XCHG EDX,ESI
  ADD EDI,nextline
  MOVSD
  MOVSW
  XCHG EDX,ESI
  MOVSD
  MOVSW

  MOVZX ESI,AL
  MOVZX EDX,AH
  SHL ESI,4
  SHL EDX,4
  ADD ESI,cbo
  ADD EDX,cbo

  ADD EDI,nextline
  MOVSD
  MOVSW
  XCHG EDX,ESI
  MOVSD
  MOVSW
  XCHG EDX,ESI
  ADD EDI,nextline
  MOVSD
  MOVSW
  XCHG EDX,ESI
  MOVSD
  MOVSW

  POP ESI
  POP EDI
  RET

@cvid24c24_ende:
END;

PROCEDURE DecodeCVID24C32(frmxd,frmyd:longint;data,img,codebook:pointer);assembler;
VAR pd,imgxdl,bitmask,xpos,ypos,xinc,yinc,count,nextline,breite,hoehe,cbo,blockcount:longint;
    frametyp,blocktyp:word;
ASM
  MOV ypos,0
  MOV EDI,img
  MOV ESI,data

  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  MOV EAX,[EDI+timage.pixeldata]
  MOV pd,EAX

  MOV xinc,16 {bytperpix*4}

  MOV EAX,imgxdl
  SHL EAX,2
  MOV yinc,EAX

  MOV EAX,imgxdl
  SUB EAX,xinc
  MOV nextline,EAX

  MOV EAX,codebook
  MOV cbo,EAX

  LODSD  {00h-03h: gesamt groesse und frame typ}
  MOV BYTE PTR frametyp,AL
  LODSD  {04h-07h: ---}
  LODSW  {08h-09h: anzahl der bloecke}
  XCHG AL,AH
  MOVZX ECX,AX

{----- block decoder - bloecke ab 0Ah ---------------------------------------}

@cvid24c32_loop1:
  PUSH ECX
  PUSH ESI

  LODSD {00h-03h: gesamt groesse und type 10h,11h}
  XOR AL,AL
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV ECX,EAX

  LODSD {04h-07h: ---}
  XOR EAX,EAX
  LODSW {08h-09h: hoehe}
  XCHG AL,AH
  MOV hoehe,EAX
  MOV EBX,EAX
  LODSW   {0Ah-0Bh: breite}
  XCHG AL,AH
  MOV breite,EAX

  SHR EAX,2
  SHR EBX,2
  MUL EBX
  MOV blockcount,EAX

  MOV EAX,breite
  SHL EAX,2  {EAX=EAX*bytperpix}
  MOV breite,EAX

  MOV xpos,0
  MOV EAX,ypos
  MUL imgxdl
  MOV EDI,EAX
{  ADD EDI,imagedatastart
  ADD EDI,img }
  ADD EDI,pd
  MOV EAX,hoehe
  ADD ypos,EAX

{----- sub block decoder - sub bloecke ab 0Ch -------------------------------}
  SUB ECX,0Ch
@cvid24c32_loop2:
  LODSD {00h-03h: gesamt groesse und type 20h,21h,22h,23h,30h,31h,32h}
  MOV DL,AL
  XOR AL,AL
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  SUB ECX,EAX
  PUSH ECX

  CMP DL,21h
  JE @cvid24c32_type_21h
  CMP DL,23h
  JE @cvid24c32_type_23h

  CMP DL,31h
  JE @cvid24c32_type_31h
  CMP DL,30h
  JE @cvid24c32_type_30h

  CMP DL,20h
  JE @cvid24c32_type_20h
  CMP DL,22h
  JE @cvid24c32_type_22h

  CMP DL,32h
  JE @cvid24c32_type_32h

@cvid24c32_continue1:

  POP ECX
  OR ECX,ECX
  JNZ @cvid24c32_loop2

{----------------------------------------------------------------------------}

  POP ESI
  POP ECX

  MOV EAX,[ESI] {00h-03h: gesamt groesse und type 10h,11}
  XOR AL,AL
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  ADD ESI,EAX

  ADD cbo,1000h

  DEC ECX
  JNZ @cvid24c32_loop1

  JMP @cvid24c32_ende
{----------------------------------------------------------------------------}
{------------ block20 -------------------------------------------------------}
@cvid24c32_type_20h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c32_continue1
  PUSH EDI
  MOV EDI,codebook
@cvid24c32_t20h_loop1:
  PUSH ECX
  PUSH EDI
  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI+0000h],EAX
  MOV [EDI+1000h],EAX
  MOV [EDI+2000h],EAX
  MOV [EDI+3000h],EAX
  CALL colyuv
  MOV [EDI+0004h],EAX
  MOV [EDI+1004h],EAX
  MOV [EDI+2004h],EAX
  MOV [EDI+3004h],EAX
  CALL colyuv
  MOV [EDI+0008h],EAX
  MOV [EDI+1008h],EAX
  MOV [EDI+2008h],EAX
  MOV [EDI+3008h],EAX
  CALL colyuv
  MOV [EDI+000Ch],EAX
  MOV [EDI+100Ch],EAX
  MOV [EDI+200Ch],EAX
  MOV [EDI+300Ch],EAX
  POP EDI
  POP ECX
  ADD EDI,16
  SUB ECX,6
  JG @cvid24c32_t20h_loop1
  POP EDI
  JMP @cvid24c32_continue1
{------------ block21 -------------------------------------------------------}
@cvid24c32_type_21h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c32_continue1

  PUSH EDI
  MOV EDI,cbo
  MOV ECX,256
@cvid24c32_t21h_loop1:

  TEST CX,001Fh
  JNZ @cvid24c32_t21h_weiter1
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
@cvid24c32_t21h_weiter1:
  SHL bitmask,1
  JNC @cvid24c32_t21h_nocol

  PUSH ECX
  PUSH EDI

  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI],EAX
  CALL colyuv
  MOV [EDI+4],EAX
  CALL colyuv
  MOV [EDI+8],EAX
  CALL colyuv
  MOV [EDI+12],EAX

  CMP BYTE PTR frametyp,0
  JNE @cvid24c32_t21h_weiter2
  PUSH ESI
  MOV ESI,EDI
  ADD EDI,1000h
  MOVSD
  MOVSD
  MOVSD
  MOVSD
  POP ESI
@cvid24c32_t21h_weiter2:

  POP EDI
  POP ECX
@cvid24c32_t21h_nocol:

  ADD EDI,16
  DEC ECX
  JG @cvid24c32_t21h_loop1
  POP EDI
  JMP @cvid24c32_continue1

{------------ block22 -------------------------------------------------------}
@cvid24c32_type_22h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c32_continue1
  PUSH EDI
  MOV EDI,codebook
  ADD EDI,4000h
@cvid24c32_t22h_loop1:
  PUSH ECX
  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI+0000h],EAX
  MOV [EDI+1000h],EAX
  MOV [EDI+2000h],EAX
  MOV [EDI+3000h],EAX
  CALL colyuv
  MOV [EDI+0004h],EAX
  MOV [EDI+1004h],EAX
  MOV [EDI+2004h],EAX
  MOV [EDI+3004h],EAX
  CALL colyuv
  MOV [EDI+0008h],EAX
  MOV [EDI+1008h],EAX
  MOV [EDI+2008h],EAX
  MOV [EDI+3008h],EAX
  CALL colyuv
  MOV [EDI+000Ch],EAX
  MOV [EDI+100Ch],EAX
  MOV [EDI+200Ch],EAX
  MOV [EDI+300Ch],EAX
  ADD EDI,16
  POP ECX
  SUB ECX,6
  JG @cvid24c32_t22h_loop1
  POP EDI
  JMP @cvid24c32_continue1
{------------ block23 -------------------------------------------------------}
@cvid24c32_type_23h:
  MOV ECX,EAX
  SUB ECX,4
  JZ @cvid24c32_continue1

  PUSH EDI
  MOV EDI,cbo
  ADD EDI,4000h
  MOV ECX,256
@cvid24c32_t23h_loop1:

  TEST ECX,001Fh
  JNZ @cvid24c32_t23h_weiter1
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
@cvid24c32_t23h_weiter1:

  SHL bitmask,1
  JNC @cvid24c32_t23h_nocol

  PUSH ECX
  PUSH EDI

  LODSD
  MOV EBX,EAX
  LODSW
  SHL EAX,8

  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX
  ROR EBX,16
  MOV AL,BH
  PUSH EAX
  MOV AL,BL
  PUSH EAX

  CALL colyuv
  MOV [EDI],EAX
  CALL colyuv
  MOV [EDI+4],EAX
  CALL colyuv
  MOV [EDI+8],EAX
  CALL colyuv
  MOV [EDI+12],EAX

  CMP BYTE PTR frametyp,0
  JNE @cvid24c32_t23h_weiter2
  PUSH ESI
  MOV ESI,EDI
  ADD EDI,1000h
  MOVSD
  MOVSD
  MOVSD
  MOVSD
  POP ESI
@cvid24c32_t23h_weiter2:

  POP EDI
  POP ECX
@cvid24c32_t23h_nocol:

  ADD EDI,16
  DEC ECX
  JG @cvid24c32_t23h_loop1
  POP EDI
  JMP @cvid24c32_continue1
{----------------------------------------------------------------------------}
{------------ block30 -------------------------------------------------------}
@cvid24c32_type_30h:
  MOV EAX,blockcount
  MOV count,EAX
@cvid24c32_t30h_loop1:
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX

  MOV ECX,32
  CMP ECX,count
  JLE @cvid24c32_t30h_loop2
  MOV ECX,count
@cvid24c32_t30h_loop2:
  SHL bitmask,1

  JNC @cvid24c32_t30h_block_2x2
  CALL DWORD PTR @cvid24c32_block4x4code
  LOOP @cvid24c32_t30h_loop2

  SUB count,32
  JG @cvid24c32_t30h_loop1
  JMP @cvid24c32_continue1

@cvid24c32_t30h_block_2x2:
  CALL DWORD PTR @cvid24c32_block2x2code
  LOOP @cvid24c32_t30h_loop2

  SUB count,32
  JG @cvid24c32_t30h_loop1
  JMP @cvid24c32_continue1
{------------ block31 -------------------------------------------------------}
@cvid24c32_type_31h:
  SUB EAX,4
  AND EAX,00FFFFFFh
  MOV count,EAX
  MOV ECX,0

@cvid24c32_t31h_loop1:

  OR ECX,ECX
  JNZ @cvid24c32_t31h_weiter1a
  CMP count,4
  JL @cvid24c32_continue1

  MOV ECX,32
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
  SUB count,4
@cvid24c32_t31h_weiter1a:

  DEC ECX
  SHL bitmask,1
  JC @cvid24c32_t31h_block

  MOV EAX,xpos
  ADD EAX,xinc
  CMP EAX,breite
  JL @cvid24c32_t31h_weiter3
  ADD EDI,yinc
  SUB EAX,breite
@cvid24c32_t31h_weiter3:
  MOV xpos,EAX
  JMP @cvid24c32_t31h_loop1

@cvid24c32_t31h_block:
  OR ECX,ECX
  JNZ @cvid24c32_t31h_weiter1b

  MOV ECX,32
  LODSD
  XCHG AL,AH
  ROR EAX,16
  XCHG AL,AH
  MOV bitmask,EAX
  SUB count,4
@cvid24c32_t31h_weiter1b:

  DEC ECX
  SHL bitmask,1
  JNC @cvid24c32_t31h_block_2x2

  CALL @cvid24c32_block4x4code
  SUB count,4
  JMP @cvid24c32_t31h_loop1

@cvid24c32_t31h_block_2x2:
  CALL DWORD PTR @cvid24c32_block2x2code
  SUB count,1
  JMP @cvid24c32_t31h_loop1
{------------ block32 -------------------------------------------------------}
@cvid24c32_type_32h:
  MOV ECX,blockcount
@cvid24c32_t32h_loop1:
  CALL DWORD PTR @cvid24c32_block2x2code
  LOOP @cvid24c32_t32h_loop1
  JMP @cvid24c32_continue1

{---------- block 2x2 --------------------------------------------------- }
@cvid24c32_block2x2code:
  MOV EAX,xpos
  CMP EAX,breite
  JL @cvid24c32_block2x2_32_weiter1
  ADD EDI,yinc
  SUB EAX,breite
@cvid24c32_block2x2_32_weiter1:

  PUSH EDI
  ADD EDI,EAX
  ADD EAX,xinc
  MOV xpos,EAX

  MOVZX EBX,BYTE PTR [ESI]
  ADD ESI,1
  SHL EBX,4
  ADD EBX,cbo
  ADD EBX,4000h
  MOV EAX,[EBX]
  MOV EDX,[EBX+4]
  STOSD
  STOSD
  XCHG EAX,EDX
  STOSD
  STOSD
  XCHG EAX,EDX
  ADD EDI,nextline
  STOSD
  STOSD
  XCHG EAX,EDX
  STOSD
  STOSD
  ADD EDI,nextline
  MOV EAX,[EBX+8]
  MOV EDX,[EBX+12]
  STOSD
  STOSD
  XCHG EAX,EDX
  STOSD
  STOSD
  XCHG EAX,EDX
  ADD EDI,nextline
  STOSD
  STOSD
  XCHG EAX,EDX
  STOSD
  STOSD
  POP EDI
  RET

{---------- block 4x4 ------------------------------------------------------}
@cvid24c32_block4x4code:
  MOV EAX,xpos
  CMP EAX,breite
  JL @cvid24c32_block4x4_32_weiter1
  ADD EDI,yinc
  SUB EAX,breite
@cvid24c32_block4x4_32_weiter1:

  PUSH EDI
  ADD EDI,EAX
  ADD EAX,xinc
  MOV xpos,EAX
  LODSD
  PUSH ESI

  MOVZX ESI,AL
  MOVZX EDX,AH
  SHL ESI,4
  SHL EDX,4
  ADD ESI,cbo
  ADD EDX,cbo
  SHR EAX,16

  MOVSD
  MOVSD
  XCHG EDX,ESI
  MOVSD
  MOVSD
  XCHG EDX,ESI
  ADD EDI,nextline
  MOVSD
  MOVSD
  XCHG EDX,ESI
  MOVSD
  MOVSD

  MOVZX ESI,AL
  MOVZX EDX,AH
  SHL ESI,4
  SHL EDX,4
  ADD ESI,cbo
  ADD EDX,cbo

  ADD EDI,nextline
  MOVSD
  MOVSD
  XCHG EDX,ESI
  MOVSD
  MOVSD
  XCHG EDX,ESI
  ADD EDI,nextline
  MOVSD
  MOVSD
  XCHG EDX,ESI
  MOVSD
  MOVSD

  POP ESI
  POP EDI
  RET

@cvid24c32_ende:
END;

PROCEDURE DecodeCVID24(frmxd,frmyd:longint;data,img,codebook:pointer);
BEGIN
  CASE gxcurcol OF
     ig_col8:DecodeCVID24C8(frmxd,frmyd,data,img,codebook);
    ig_col15:DecodeCVID24C16(frmxd,frmyd,data,img,codebook);
    ig_col16:DecodeCVID24C16(frmxd,frmyd,data,img,codebook);
    ig_col24:DecodeCVID24C24(frmxd,frmyd,data,img,codebook);
    ig_col32:DecodeCVID24C32(frmxd,frmyd,data,img,codebook);
  END;
END;

{================================= Bitmap ===================================}

PROCEDURE DecodeDIB8(frmxd,frmyd:longint;data,img,col:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV EBX,col
  MOV ECX,frmyd
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  MUL ECX
  MOV EDI,[EDI+timage.pixeldata]
  ADD EDI,EAX
{  LEA EDI,[EDI+EAX+imagedatastart] }


@dib8_loop1:
  PUSH ECX
  SUB EDI,imgxdl
  PUSH EDI
  MOV ECX,frmxd

@dib8_loop2:
  PUSH ECX
  LODSB
  MOVZX EAX,AL
  MOV EAX,[EBX+EAX*4]

  MOV EDX,bytperpix
@dib8_loop3:
  STOSB
  SHR EAX,8
  DEC EDX
  JNZ @dib8_loop3

  POP ECX
  LOOP @dib8_loop2

  POP EDI
  POP ECX
  LOOP @dib8_loop1
END;

PROCEDURE DecodeDIB16(frmxd,frmyd:longint;data,img:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV ECX,frmyd
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  MUL ECX
{  LEA EDI,[EDI+EAX+imagedatastart] }
  MOV EDI,[EDI+timage.pixeldata]
  ADD EDI,EAX

@dib16_loop1:
  PUSH ECX
  SUB EDI,imgxdl
  PUSH EDI
  MOV ECX,frmxd

@dib16_loop2:
  PUSH ECX
  LODSW

  ROR EAX,5
  SHL AX,3
  ROR EAX,8
  SHL AX,3
  ROL EAX,16
  PUSH EAX
  CALL rgbcolor

  MOV EDX,bytperpix
@dib16_loop3:
  STOSB
  SHR EAX,8
  DEC EDX
  JNZ @dib16_loop3

  POP ECX
  LOOP @dib16_loop2

  POP EDI
  POP ECX
  LOOP @dib16_loop1
END;

PROCEDURE DecodeDIB24(frmxd,frmyd:longint;data,img:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV ECX,frmyd
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  MUL ECX
{  LEA EDI,[EDI+EAX+imagedatastart] }
  MOV EDI,[EDI+timage.pixeldata]
  ADD EDI,EAX

@dib24_loop1:
  PUSH ECX
  SUB EDI,imgxdl
  PUSH EDI
  MOV ECX,frmxd

@dib24_loop2:
  PUSH ECX
  LODSW
  SHL EAX,16
  LODSB
  ROR EAX,16
  PUSH EAX
  CALL rgbcolor

  MOV EDX,bytperpix
@dib24_loop3:
  STOSB
  SHR EAX,8
  DEC EDX
  JNZ @dib24_loop3

  POP ECX
  LOOP @dib24_loop2

  POP EDI
  POP ECX
  LOOP @dib24_loop1
END;

PROCEDURE DecodeDIB32(frmxd,frmyd:longint;data,img:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV ESI,data
  MOV EDI,img
  MOV ECX,frmyd
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
  MUL ECX
{  LEA EDI,[EDI+EAX+imagedatastart] }
  MOV EDI,[EDI+timage.pixeldata]
  ADD EDI,EAX

@dib32_loop1:
  PUSH ECX
  SUB EDI,imgxdl
  PUSH EDI
  MOV ECX,frmxd

@dib32_loop2:
  PUSH ECX
  LODSD
  PUSH EAX
  CALL rgbcolor

  MOV EDX,bytperpix
@dib32_loop3:
  STOSB
  SHR EAX,8
  DEC EDX
  JNZ @dib32_loop3

  POP ECX
  LOOP @dib32_loop2

  POP EDI
  POP ECX
  LOOP @dib32_loop1
END;

{============================ Apple Animation ===============================}

PROCEDURE DecodeAPPLANIM8(frmxd,frmyd:longint;data,img:pointer);
BEGIN
END;

PROCEDURE DecodeAPPLANIM16(frmxd,frmyd:longint;data,img:pointer);
BEGIN
END;

PROCEDURE DecodeAPPLANIM24(frmxd,frmyd:longint;data,img:pointer);
BEGIN
END;

{============================ DecodeDELTA7 ==================================}

PROCEDURE DecodeDELTA7L8(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EDI,buf
  MOV EDX,colortable
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

  LODSW
  MOVZX ECX,AX

@d7L8_loop1:
  PUSH EDI
  LODSW
  MOVZX EAX,AX
  TEST AX,0C000h
  JNZ @d7L8_skip
  OR AX,AX
  JZ @d7L8_zero2

  PUSH ECX
  MOV ECX,EAX

@d7L8_loop2:
  PUSH ECX
  LODSW
  MOVZX ECX,AH
  MOVZX EAX,AL
  ADD EDI,EAX

  OR CL,CL
  JZ @d7L8_weiter
  TEST CL,80h
  JZ @d7L8_copybytes

  NEG CL
  LODSW
  MOVZX EBX,AL
  MOV AL,[EDX+EBX*4]
  MOVZX EBX,AH
  MOV AH,[EDX+EBX*4]
  REP STOSW
  JMP @d7L8_weiter

@d7L8_copybytes:
  LODSW
  MOVZX EBX,AL
  MOV AL,[EDX+EBX*4]
  MOVZX EBX,AH
  MOV AH,[EDX+EBX*4]
  STOSW
  LOOP @d7L8_copybytes

@d7L8_weiter:
  POP ECX
  LOOP @d7L8_loop2
  POP ECX

@d7L8_zero2:
  POP EDI
  ADD EDI,imgxdl
  LOOP @d7L8_loop1
  JMP @d7L8_ende

@d7L8_skip:
  POP EDI
  NEG AX
  IMUL EAX,imgxdl
  ADD EDI,EAX
  JMP @d7L8_loop1
@d7L8_ende:
END;

PROCEDURE DecodeDELTA7L16(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EDI,buf
  MOV EDX,colortable
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

  LODSW
  MOVZX ECX,AX

@d7L16_loop1:
  PUSH EDI
  LODSW
  MOVZX EAX,AX
  TEST AX,0C000h
  JNZ @d7L16_skip
  OR AX,AX
  JZ @d7L16_zero2

  PUSH ECX
  MOV ECX,EAX

@d7L16_loop2:
  PUSH ECX
  LODSW
  MOVZX ECX,AH
  MOVZX EAX,AL
  LEA EDI,[EDI+EAX*2]

  OR CL,CL
  JZ @d7L16_weiter
  TEST CL,80h
  JZ @d7L16_copybytes

  NEG CL
  LODSW
  ROR EAX,8
  MOVZX EBX,AL
  MOV AX,[EDX+EBX*4]
  ROL EAX,16
  MOVZX EBX,AH
  MOV AX,[EDX+EBX*4]
  REP STOSD
  JMP @d7L16_weiter

@d7L16_copybytes:
  LODSW
  ROR EAX,8
  MOVZX EBX,AL
  MOV AX,[EDX+EBX*4]
  ROL EAX,16
  MOVZX EBX,AH
  MOV AX,[EDX+EBX*4]
  STOSD
  LOOP @d7L16_copybytes

@d7L16_weiter:
  POP ECX
  LOOP @d7L16_loop2
  POP ECX

@d7L16_zero2:
  POP EDI
  ADD EDI,imgxdl
  LOOP @d7L16_loop1
  JMP @d7L16_ende

@d7L16_skip:
  POP EDI
  NEG AX
  IMUL EAX,imgxdl
  ADD EDI,EAX
  JMP @d7L16_loop1
@d7L16_ende:
END;

PROCEDURE DecodeDELTA7L24(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EDI,buf
  MOV EDX,colortable
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

  LODSW
  MOVZX ECX,AX

@d7L24_loop1:
  PUSH EDI
  LODSW
  MOVZX EAX,AX
  TEST AX,0C000h
  JNZ @d7L24_skip
  OR AX,AX
  JZ @d7L24_zero2

  PUSH ECX
  MOV ECX,EAX

@d7L24_loop2:
  PUSH ECX
  LODSW
  MOVZX ECX,AH
  MOVZX EAX,AL
  LEA EDI,[EDI+EAX*2]
  ADD EDI,EAX

  OR CL,CL
  JZ @d7L24_weiter
  TEST CL,80h
  JZ @d7L24_copybytes

  NEG CL
  LODSW
  MOVZX EBX,AH
  MOV EBX,[EDX+EBX*4]
  MOVZX EAX,AL
  MOV EAX,[EDX+EAX*4]
  SHL EAX,8
  SHRD EAX,EBX,8
  SHR EBX,8
@d7L24_loop3:
  STOSD
  XCHG EAX,EBX
  STOSW
  XCHG EAX,EBX
  LOOP @d7L24_loop3
  JMP @d7L24_weiter

@d7L24_copybytes:
  LODSW
  MOVZX EBX,AH
  MOV EBX,[EDX+EBX*4]
  MOVZX EAX,AL
  MOV EAX,[EDX+EAX*4]
  SHL EAX,8
  SHRD EAX,EBX,8
  SHR EBX,8
  STOSD
  MOV EAX,EBX
  STOSW
  LOOP @d7L24_copybytes

@d7L24_weiter:
  POP ECX
  LOOP @d7L24_loop2
  POP ECX

@d7L24_zero2:
  POP EDI
  ADD EDI,imgxdl
  LOOP @d7L24_loop1
  JMP @d7L24_ende

@d7L24_skip:
  POP EDI
  NEG AX
  IMUL EAX,imgxdl
  ADD EDI,EAX
  JMP @d7L24_loop1
@d7L24_ende:
END;

PROCEDURE DecodeDELTA7L32(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EDI,buf
  MOV EDX,colortable
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

  LODSW
  MOVZX ECX,AX

@d7L32_loop1:
  PUSH EDI
  LODSW
  MOVZX EAX,AX
  TEST AX,0C000h
  JNZ @d7L32_skip
  OR AX,AX
  JZ @d7L32_zero2

  PUSH ECX
  MOV ECX,EAX

@d7L32_loop2:
  PUSH ECX
  LODSW
  MOVZX ECX,AH
  MOVZX EAX,AL
  LEA EDI,[EDI+EAX*4]

  OR CL,CL
  JZ @d7L32_weiter
  TEST CL,80h
  JZ @d7L32_copybytes

  NEG CL
  LODSW

  MOVZX EBX,AH
  MOV EBX,[EDX+EBX*4]
  MOVZX EAX,AL
  MOV EAX,[EDX+EAX*4]
@d7L32_loop3:
  STOSD
  XCHG EAX,EBX
  STOSD
  XCHG EAX,EBX
  LOOP @d7L32_loop3
  JMP @d7L32_weiter

@d7L32_copybytes:
  LODSW
  MOVZX EBX,AH
  MOV EBX,[EDX+EBX*4]
  MOVZX EAX,AL
  MOV EAX,[EDX+EAX*4]
  STOSD
  MOV EAX,EBX
  STOSD
  LOOP @d7L32_copybytes

@d7L32_weiter:
  POP ECX
  LOOP @d7L32_loop2
  POP ECX

@d7L32_zero2:
  POP EDI
  ADD EDI,imgxdl
  LOOP @d7L32_loop1
@d7L32_zero1:
  JMP @d7L32_ende

@d7L32_skip:
  POP EDI
  NEG AX
  IMUL EAX,imgxdl
  ADD EDI,EAX
  JMP @d7L32_loop1
@d7L32_ende:
END;

PROCEDURE DecodeDELTA7(frmxd,frmyd:longint;data,colortable,buf:pointer);
BEGIN
  CASE gxcurcol OF
    ig_col8:DecodeDELTA7L8(frmxd,frmyd,data,colortable,buf);
    ig_col15:DecodeDELTA7L16(frmxd,frmyd,data,colortable,buf);
    ig_col16:DecodeDELTA7L16(frmxd,frmyd,data,colortable,buf);
    ig_col24:DecodeDELTA7L24(frmxd,frmyd,data,colortable,buf);
    ig_col32:DecodeDELTA7L32(frmxd,frmyd,data,colortable,buf);
  END;
END;

{============================ DecodeLC12 ====================================}

PROCEDURE DecodeLC12L8(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EDI,buf
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

  LODSW
  CWDE
  MUL imgxdl
  ADD EDI,EAX

  LODSW
  OR AX,AX
  JZ @d12L8_zero1
  MOVZX ECX,AX

  MOV EDX,colortable

@d12L8_loop1:
  PUSH ECX
  PUSH EDI

  LODSB
  OR AL,AL
  JZ @d12L8_zero2

  MOVZX ECX,AX
  PUSH ECX
@d12L8_loop2:

  LODSW
  MOVZX EBX,AH
  MOVZX EAX,AL
  ADD EDI,EAX

  OR BL,BL
  JZ @d12L8_loop2

  PUSH ECX
  MOV ECX,EBX

  TEST CL,80h
  JZ @d12L8_copybytes

  NEG CL
  LODSB
  MOVZX EAX,AL
  MOV AL,DS:[EDX+EAX*4]
  REP STOSB
  JMP @d12L8_weiter

@d12L8_copybytes:
  LODSB
  MOVZX EAX,AL
  MOV AL,DS:[EDX+EAX*4]
  STOSB
  LOOP @d12L8_copybytes
@d12L8_weiter:
  POP ECX
  LOOP @d12L8_loop2
  POP ECX

@d12L8_zero2:
  POP EDI																														      
  ADD EDI,imgxdl
  POP ECX
  LOOP @d12L8_loop1
@d12L8_zero1:
END;

PROCEDURE DecodeLC12L16(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EDI,buf
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

  LODSW
  CWDE
  MUL imgxdl
  ADD EDI,EAX

  LODSW
  OR AX,AX
  JZ @d12L16_zero1
  MOVZX ECX,AX

  MOV EDX,colortable

@d12L16_loop1:
  PUSH ECX
  PUSH EDI

  LODSB
  OR AL,AL
  JZ @d12L16_zero2

  MOVZX ECX,AL
  PUSH ECX
@d12L16_loop2:

  LODSW
  MOVZX EBX,AH
  MOVZX EAX,AL
  LEA EDI,[EDI+EAX*2]

  OR BL,BL
  JZ @d12L16_loop2

  PUSH ECX
  MOV ECX,EBX

  TEST CL,80h
  JZ @d12L16_copybytes

  NEG CL
  LODSB
  MOVZX EAX,AL
  MOV AX,DS:[EDX+EAX*4]
  REP STOSW
  JMP @d12L16_weiter

@d12L16_copybytes:
  LODSB
  MOVZX EAX,AL
  MOV AX,DS:[EDX+EAX*4]
  STOSW
  LOOP @d12L16_copybytes

@d12L16_weiter:
  POP ECX
  LOOP @d12L16_loop2
  POP ECX

@d12L16_zero2:
  POP EDI
  ADD EDI,imgxdl
  POP ECX
  LOOP @d12L16_loop1
@d12L16_zero1:
END;

PROCEDURE DecodeLC12L24(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EDI,buf
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

  LODSW
  CWDE
  MUL imgxdl
  ADD EDI,EAX

  LODSW
  OR AX,AX
  JZ @d12L24_zero1
  MOVZX ECX,AX

  MOV EDX,colortable

@d12L24_loop1:
  PUSH ECX
  PUSH EDI

  LODSB
  OR AL,AL
  JZ @d12L24_zero2

  MOVZX ECX,AL
  PUSH ECX
@d12L24_loop2:

  LODSW
  MOVZX EBX,AH
  MOVZX EAX,AL
  LEA EDI,[EDI+EAX*2]
  ADD EDI,EAX

  OR BL,BL
  JZ @d12L24_loop2

  PUSH ECX
  MOV ECX,EBX

  TEST CL,80h
  JZ @d12L24_copybytes

  NEG CL
  LODSB
  MOVZX EAX,AL
  MOV EAX,DS:[EDX+EAX*4]
@d12L24_loop3:
  STOSW
  ROR EAX,16
  STOSB
  ROR EAX,16
  LOOP @d12L24_loop3
  JMP @d12L24_weiter

@d12L24_copybytes:
  LODSB
  MOVZX EAX,AL
  MOV EAX,DS:[EDX+EAX*4]
  STOSW
  SHR EAX,16
  STOSB
  LOOP @d12L24_copybytes

@d12L24_weiter:
  POP ECX
  LOOP @d12L24_loop2
  POP ECX

@d12L24_zero2:
  POP EDI
  ADD EDI,imgxdl
  POP ECX
  LOOP @d12L24_loop1
@d12L24_zero1:
END;

PROCEDURE DecodeLC12L32(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EDI,buf
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

  LODSW
  CWDE
  MUL imgxdl
  ADD EDI,EAX

  LODSW
  OR AX,AX
  JZ @d12L32_zero1
  MOVZX ECX,AX

  MOV EDX,colortable

@d12L32_loop1:
  PUSH ECX
  PUSH EDI

  LODSB
  OR AL,AL
  JZ @d12L32_zero2

  MOVZX ECX,AL
  PUSH ECX
@d12L32_loop2:

  LODSW
  MOVZX EBX,AH
  MOVZX EAX,AL
  LEA EDI,[EDI+EAX*4]

  OR BL,BL
  JZ @d12L32_loop2

  PUSH ECX
  MOV ECX,EBX

  TEST CL,80h
  JZ @d12L32_copybytes

  NEG CL
  LODSB
  MOVZX EAX,AL
  MOV EAX,DS:[EDX+EAX*4]
  REP STOSD
  JMP @d12L32_weiter

@d12L32_copybytes:
  LODSB
  MOVZX EAX,AL
  MOV EAX,DS:[EDX+EAX*4]
  STOSD
  LOOP @d12L32_copybytes

@d12L32_weiter:
  POP ECX
  LOOP @d12L32_loop2
  POP ECX

@d12L32_zero2:
  POP EDI
  ADD EDI,imgxdl
  POP ECX
  LOOP @d12L32_loop1
@d12L32_zero1:
END;

PROCEDURE DecodeLC12(frmxd,frmyd:longint;data,colortable,buf:pointer);
BEGIN
  CASE gxcurcol OF
    ig_col8:DecodeLC12L8(frmxd,frmyd,data,colortable,buf);
    ig_col15:DecodeLC12L16(frmxd,frmyd,data,colortable,buf);
    ig_col16:DecodeLC12L16(frmxd,frmyd,data,colortable,buf);
    ig_col24:DecodeLC12L24(frmxd,frmyd,data,colortable,buf);
    ig_col32:DecodeLC12L32(frmxd,frmyd,data,colortable,buf);
  END;
END;


{============================ DecodeBRUN15 ====================================}

PROCEDURE DecodeBRUN15L8(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EDI,buf
  MOV EDX,colortable
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

  MOV ECX,frmyd

@d15L8_loop1:
  PUSH ECX
  INC ESI
  MOV ECX,frmxd

@d15L8_loop2:

  LODSB
  OR AL,AL
  JZ @d15L8_weiter

  MOVZX EAX,AL
  TEST AL,80h
  JNZ @d15L8_copybytes
  SUB ECX,EAX
  PUSH ECX
  MOV ECX,EAX
  LODSB
  MOVZX EAX,AL
  MOV AL,[EDX+EAX*4]
  REP STOSB
  POP ECX
  JMP @d15L8_weiter

@d15L8_copybytes:
  NEG AL
  SUB ECX,EAX
  PUSH ECX
  MOV ECX,EAX
@d15L8_copy:
  LODSB
  MOVZX EAX,AL
  MOV AL,[EDX+EAX*4]
  STOSB
  LOOP @d15L8_copy
  POP ECX

@d15L8_weiter:
  OR ECX,ECX
  JNZ @d15L8_loop2

@d15L8_zero2:
  POP ECX
  LOOP @d15L8_loop1
END;

PROCEDURE DecodeBRUN15L16(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EDI,buf
  MOV EDX,colortable
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

  MOV ECX,frmyd

@d15L16_loop1:
  PUSH ECX
  INC ESI
  MOV ECX,frmxd

@d15L16_loop2:

  LODSB
  OR AL,AL
  JZ @d15L16_weiter

  MOVZX EAX,AL
  TEST AL,80h
  JNZ @d15L16_copybytes
  SUB ECX,EAX
  PUSH ECX
  MOV ECX,EAX
  LODSB
  MOVZX EAX,AL
  MOV AX,[EDX+EAX*4]
  REP STOSW
  POP ECX
  JMP @d15L16_weiter

@d15L16_copybytes:
  NEG AL
  SUB ECX,EAX
  PUSH ECX
  MOV ECX,EAX
@d15L16_copy:
  LODSB
  MOVZX EAX,AL
  MOV AX,[EDX+EAX*4]
  STOSW
  LOOP @d15L16_copy
  POP ECX

@d15L16_weiter:
  OR ECX,ECX
  JNZ @d15L16_loop2

@d15L16_zero2:
  POP ECX
  LOOP @d15L16_loop1
END;

PROCEDURE DecodeBRUN15L24(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EDI,buf
  MOV EDX,colortable
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

  MOV ECX,frmyd

@d15L24_loop1:
  PUSH ECX
  INC ESI
  MOV ECX,frmxd

@d15L24_loop2:

  LODSB
  OR AL,AL
  JZ @d15L24_weiter

  MOVZX EAX,AL
  TEST AL,80h
  JNZ @d15L24_copybytes
  SUB ECX,EAX
  PUSH ECX
  MOV ECX,EAX
  LODSB
  MOVZX EAX,AL
  MOV EAX,[EDX+EAX*4]
@d12L24_loop3:
  STOSW
  ROR EAX,16
  STOSB
  ROR EAX,16
  LOOP @d12L24_loop3
  POP ECX
  JMP @d15L24_weiter

@d15L24_copybytes:
  NEG AL
  SUB ECX,EAX
  PUSH ECX
  MOV ECX,EAX
@d15L24_copy:
  LODSB
  MOVZX EAX,AL
  MOV EAX,DS:[EDX+EAX*4]
  STOSW
  SHR EAX,16
  STOSB
  LOOP @d15L24_copy
  POP ECX

@d15L24_weiter:
  OR ECX,ECX
  JNZ @d15L24_loop2

@d15L24_zero2:
  POP ECX
  LOOP @d15L24_loop1
END;

PROCEDURE DecodeBRUN15L32(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EDI,buf
  MOV EDX,colortable
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

  MOV ECX,frmyd

@d15L32_loop1:
  PUSH ECX
  INC ESI
  MOV ECX,frmxd

@d15L32_loop2:

  LODSB
  OR AL,AL
  JZ @d15L32_weiter

  MOVZX EAX,AL
  TEST AL,80h
  JNZ @d15L32_copybytes
  SUB ECX,EAX
  PUSH ECX
  MOV ECX,EAX
  LODSB
  MOVZX EAX,AL
  MOV EAX,[EDX+EAX*4]
  REP STOSD
  POP ECX
  JMP @d15L32_weiter

@d15L32_copybytes:
  NEG AL
  SUB ECX,EAX
  PUSH ECX
  MOV ECX,EAX
@d15L32_copy:
  LODSB
  MOVZX EAX,AL
  MOV EAX,[EDX+EAX*4]
  STOSD
  LOOP @d15L32_copy
  POP ECX

@d15L32_weiter:
  OR ECX,ECX
  JNZ @d15L32_loop2

@d15L32_zero2:
  POP ECX
  LOOP @d15L32_loop1
END;

PROCEDURE DecodeBRUN15(frmxd,frmyd:longint;data,colortable,buf:pointer);
BEGIN
  CASE gxcurcol OF
    ig_col8:DecodeBRUN15L8(frmxd,frmyd,data,colortable,buf);
    ig_col15:DecodeBRUN15L16(frmxd,frmyd,data,colortable,buf);
    ig_col16:DecodeBRUN15L16(frmxd,frmyd,data,colortable,buf);
    ig_col24:DecodeBRUN15L24(frmxd,frmyd,data,colortable,buf);
    ig_col32:DecodeBRUN15L32(frmxd,frmyd,data,colortable,buf);
  END;
END;


{============================ DecodeCOPY16 ====================================}

PROCEDURE DecodeCOPY16L8(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EAX,frmyd
  MUL frmxd
  MOV ECX,EAX

  MOV EDI,buf
  MOV EDX,colortable
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

@d16L8_loop1:
  LODSB
  MOVZX EAX,AL
  MOV AL,[EDX+EAX*4]
  STOSB
  DEC ECX
  JNZ @d16L8_loop1
END;

PROCEDURE DecodeCOPY16L16(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EAX,frmyd
  MUL frmxd
  MOV ECX,EAX

  MOV EDI,buf
  MOV EDX,colortable
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]
@d16L16_loop1:
  LODSB
  MOVZX EAX,AL
  MOV AX,[EDX+EAX*4]
  STOSW
  DEC ECX
  JNZ @d16L16_loop1
END;

PROCEDURE DecodeCOPY16L24(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EAX,frmyd
  MUL frmxd
  MOV ECX,EAX

  MOV EDI,buf
  MOV EDX,colortable
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

@d16L24_loop1:
  LODSB
  MOVZX EAX,AL
  MOV EAX,[EDX+EAX*4]
  STOSW
  SHR EAX,16
  STOSB
  DEC ECX
  JNZ @d16L24_loop1
END;

PROCEDURE DecodeCOPY16L32(frmxd,frmyd:longint;data,colortable,buf:pointer);assembler;
VAR imgxdl:longint;
ASM
  MOV EAX,frmyd
  MUL frmxd
  MOV ECX,EAX

  MOV EDI,buf
  MOV EDX,colortable
  MOV ESI,data
  MOV EAX,[EDI+timage.bytesperline]
  MOV imgxdl,EAX
{  ADD EDI,imagedatastart }
  MOV EDI,[EDI+timage.pixeldata]

@d16L32_loop1:
  LODSB
  MOVZX EAX,AL
  MOV EAX,[EDX+EAX*4]
  STOSD
  DEC ECX
  JNZ @d16L32_loop1
END;

PROCEDURE DecodeCOPY16(frmxd,frmyd:longint;data,colortable,buf:pointer);
BEGIN
  CASE gxcurcol OF
    ig_col8:DecodeCOPY16L8(frmxd,frmyd,data,colortable,buf);
    ig_col15:DecodeCOPY16L16(frmxd,frmyd,data,colortable,buf);
    ig_col16:DecodeCOPY16L16(frmxd,frmyd,data,colortable,buf);
    ig_col24:DecodeCOPY16L24(frmxd,frmyd,data,colortable,buf);
    ig_col32:DecodeCOPY16L32(frmxd,frmyd,data,colortable,buf);
  END;
END;

{============================================================================}
END.


