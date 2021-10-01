; **************************************************************************** 
; * LICENSE:                                                                 *
; *                                                                          *
; *   GMThreads is free software; you can redistribute it and/or             *
; *   modify it under the terms of the GNU Lesser General Public             *
; *   License as published by the Free Software Foundation; either           *
; *   version 2.1 of the License, or (at your option) any later version.     *
; *                                                                          *
; *   GMThreads is distributed in the hope that it will be useful,           *
; *   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
; *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU      *
; *   Lesser General Public License for more details.                        *
; *                                                                          *
; *   You should have received a copy of the GNU Lesser General Public       *
; *   License along with GMThreads; if not, write to the Free Software       *
; *   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA          *
; *   02110-1301 USA                                                         *
; ****************************************************************************
; * main.asm                                                                 *
; *                                                                          * 
; * Copyright 2009 (C) Snake (http://sgames.ovh.org/)                        *
; ****************************************************************************

.386
.model flat, stdcall

include windows.inc
include kernel32.inc
include user32.inc
includelib kernel32.lib
includelib user32.lib

GM_SIGNATURE_ADDRESS           equ 00500000h
GM_SIGNATURE_GM80              equ 0E982754Fh
GM_SIGNATURE_GM70              equ 00589A24h
GM_SIGNATURE_GM61              equ 0E8005386h

GM70_UTILITY_CODEOBJECTCOMPILE equ 00545C2Ch
GM70_UTILITY_CREATECODEOBJECT  equ 00545B50h
GM70_UTILITY_CREATEINSTANCE    equ 004ACC54h
GM70_UTILITY_EXECUTECODEOBJECT equ 0052CB6Ch
GM70_UTILITY_DESTROYOBJECT     equ 004041D4h
GM70_ADDRESS_INSTANCECLASS     equ 004AC1BCh
GM70_ADDRESS_CODECLASS         equ 00545858h

GM61_UTILITY_CODEOBJECTCOMPILE equ 004F6E1Ch
GM61_UTILITY_CREATECODEOBJECT  equ 004F6D58h
GM61_UTILITY_CREATEINSTANCE    equ 004A1688h
GM61_UTILITY_EXECUTECODEOBJECT equ 004D7614h
GM61_UTILITY_DESTROYOBJECT     equ 00404184h
GM61_ADDRESS_INSTANCECLASS     equ 004A0C10h
GM61_ADDRESS_CODECLASS         equ 004F6C58h

.data
; Initialized to GM8 addresses
GM_UTILITY_CODEOBJECTCOMPILE   dd 00543B38h
GM_UTILITY_CREATECODEOBJECT    dd 00543A5Ch
GM_UTILITY_CREATEINSTANCE      dd 004AB45Ch
GM_UTILITY_EXECUTECODEOBJECT   dd 00528CECh
GM_UTILITY_DESTROYOBJECT       dd 00404A30h
GM_ADDRESS_INSTANCECLASS       dd 004AA8C4h
GM_ADDRESS_CODECLASS           dd 00543754h

.code
; ======================================================================================
; = String constants                                                                   =
; ======================================================================================

strError                       db "GMThreads error", 0
strIncompatibleVersion         db "Error: Trying to use GMThreads with Instant Play or Game Maker version different than 6.1, 7.0 or 8.0.", 0
strCannotCompile               db "Error: Unable to compile specified GML code for a thread.", 0

; ======================================================================================
; = Utilities                                                                          =
; ======================================================================================

ErrorMessage proc aMessage: DWORD
  push    MB_SYSTEMMODAL or MB_ICONERROR    ; Options
  push    offset strError                   ; Caption
  push    aMessage                          ; Message
  push    0                                 ; Handle
  call    [MessageBoxA]

  ret
ErrorMessage endp

; ======================================================================================
; = Thread function                                                                    =
; ======================================================================================

GMLThread proc aCodeObject: DWORD
  local   result[6]: DWORD

  ; ZeroMemory( result, 24 )
  lea     edi, result
  mov     ecx, 6
  
  cld
  xor     eax, eax
  rep stosd
  
  push    0
  push    0
  push    0
  push    0
  push    0
  xor     ecx, ecx
  mov     dl, 1
  mov     eax, dword ptr ds:[GM_ADDRESS_INSTANCECLASS]
  mov     eax, dword ptr ds:[eax]
  call    [GM_UTILITY_CREATEINSTANCE]
  mov     esi, eax
  
  lea     eax, result
  push    eax
  mov     ecx, ebx
  mov     edx, esi
  mov     eax, esi
  call    [GM_UTILITY_EXECUTECODEOBJECT]
  
  xor     al, 1
  push    eax
  
  mov     eax, esi
  call    [GM_UTILITY_DESTROYOBJECT]
  mov     eax, ebx
  call    [GM_UTILITY_DESTROYOBJECT]
  
  pop     eax
  ret
GMLThread endp

; ======================================================================================
; = DLL functions                                                                      =
; ======================================================================================

ThreadCreate proc aCode: DWORD, aSuspend: QWORD
  push    0
  mov     ecx, aCode
  mov     dl, 1
  mov     eax, dword ptr ds:[GM_ADDRESS_CODECLASS]
  mov     eax, dword ptr ds:[eax]
  call    [GM_UTILITY_CREATECODEOBJECT]

  mov     ebx, eax
  call    [GM_UTILITY_CODEOBJECTCOMPILE]
  
  test    al, al
  jnz     CompilationSuccess
    push    offset strCannotCompile
    call    [ErrorMessage]
    
    fldz
    ret
  
CompilationSuccess:

  ; if ( aSuspend ) eax = CREATE_SUSPENDED; else eax = 0;
  sub     esp, 4

  fld     aSuspend
  fistp   dword ptr ss:[esp]
  pop     eax
  neg     eax
  sbb     eax, eax
  and     eax, CREATE_SUSPENDED

  push    0         ; lpThreadId
  push    eax       ; dwCreationFlags
  push    ebx       ; lpParameter; pass code object to the thread
  push    GMLThread ; lpStartAddress
  push    0         ; dwStackSize
  push    0         ; lpThreadAttributes
  call    [CreateThread]
  
  mov     dword ptr ds:[aSuspend], eax
  fild    dword ptr ds:[aSuspend]
  ret
ThreadCreate endp

ThreadTerminate proc aHandle: QWORD
  push    1
  sub     esp, 4h

  fld     aHandle
  fistp   dword ptr ss:[esp]
  call    [TerminateThread]

  mov     dword ptr ds:[aHandle], eax
  fild    dword ptr ds:[aHandle]
  ret
ThreadTerminate endp

ThreadSuspend proc aHandle: QWORD
  sub     esp, 4

  fld     aHandle
  fistp   dword ptr ds:[esp]
  call    [SuspendThread]
  
  fldz
  ret
ThreadSuspend endp

ThreadResume proc aHandle: QWORD
  sub     esp, 4

  fld     aHandle
  fistp   dword ptr ds:[esp]
  call    [ResumeThread]
  
  fldz
  ret
ThreadResume endp

ThreadSetPriority proc aHandle: QWORD, aPriority: QWORD
  sub     esp, 8h
  
  fld     aPriority
  fistp   dword ptr ss:[esp + 4h]
  fld     aHandle
  fistp   dword ptr ss:[esp]
  call    [SetThreadPriority]
  
  fldz
  ret
ThreadSetPriority endp

ThreadSetAffinity proc aHandle: QWORD, aAffinity: QWORD
  sub     esp, 8h
  
  fld     aAffinity
  fistp   dword ptr ss:[esp + 4h]
  fld     aHandle
  fistp   dword ptr ss:[esp]
  call    [SetThreadAffinityMask]

  mov     dword ptr ds:[aHandle], eax
  fild    dword ptr ds:[aHandle]
  ret
ThreadSetAffinity endp

ThreadSetProcessor proc aHandle: QWORD, aProcessor: QWORD
  sub    esp, 8h

  fld     aProcessor
  fistp   dword ptr ss:[esp + 4h]
  fld     aHandle
  fistp   dword ptr ss:[esp]
  call    [SetThreadIdealProcessor]

  mov     dword ptr ds:[aHandle], eax
  fild    dword ptr ds:[aHandle]
  ret
ThreadSetProcessor endp

ThreadGetPriority proc aHandle: QWORD
  sub     esp, 4h

  fld     aHandle
  fistp   dword ptr ss:[esp]
  call    [GetThreadPriority]
  
  mov     dword ptr ds:[aHandle], eax
  fild    dword ptr ds:[aHandle]
  ret
ThreadGetPriority endp

ThreadGetError proc aHandle: QWORD
  push    0                   ; lpExitCode buffer
  push    esp                 ; lpExitCode parameter
  sub     esp, 4h             ; Handle parameter

  fld     aHandle
  fistp   dword ptr ss:[esp]  ; Handle
  call    [GetExitCodeThread]
  test    al, al
  jnz     Success
    mov     dword ptr ds:[esp], -1

Success:  
  fild    dword ptr ds:[esp]
  ret
ThreadGetError endp

GetProcessorCount proc
  local   systemInfo: SYSTEM_INFO
  
  lea     eax, systemInfo
  push    eax
  call    [GetSystemInfo]
  
  fild    systemInfo.dwNumberOfProcessors
  ret
GetProcessorCount endp

ThreadClose proc aHandle: QWORD
  sub     esp, 4h

  fld     aHandle
  fistp   dword ptr ss:[esp]
  call    [CloseHandle]

  mov     dword ptr ds:[aHandle], eax
  fild    dword ptr ds:[aHandle]
  ret
ThreadClose endp

ThreadWait proc aHandle: QWORD, aTimeout: QWORD
  sub     esp, 8h

  fld     aTimeout
  fistp   dword ptr ds:[esp + 4h]
  fld     aHandle
  fistp   dword ptr ds:[esp]
  call    [WaitForSingleObject]
  
  mov     dword ptr ds:[aHandle], eax
  fild    dword ptr ds:[aHandle]
  ret
ThreadWait endp

; ======================================================================================
; = Entrypoint                                                                         =
; ======================================================================================

DllEntryPoint proc aModule:DWORD, aReason: DWORD, aReserved: DWORD
  cmp     aReason, DLL_PROCESS_ATTACH
  jne     Return
    push    aModule
    call    [DisableThreadLibraryCalls]

    ; Correct addresses to suitable GM version
    mov     eax, dword ptr ds:[GM_SIGNATURE_ADDRESS]
    cmp     eax, GM_SIGNATURE_GM80
    jne     Version61
      ; Exit - addresses already set to GM8
      jmp     Return

  Version61:
    ; Get base pointer to the beginning of address variables
    mov     ebx, offset GM_UTILITY_CODEOBJECTCOMPILE

    cmp     eax, GM_SIGNATURE_GM61
    jne     Version70
      mov     dword ptr ds:[ebx],       GM61_UTILITY_CODEOBJECTCOMPILE
      mov     dword ptr ds:[ebx + 04h], GM61_UTILITY_CREATECODEOBJECT
      mov     dword ptr ds:[ebx + 08h], GM61_UTILITY_CREATEINSTANCE
      mov     dword ptr ds:[ebx + 0Ch], GM61_UTILITY_EXECUTECODEOBJECT
      mov     dword ptr ds:[ebx + 10h], GM61_UTILITY_DESTROYOBJECT
      mov     dword ptr ds:[ebx + 14h], GM61_ADDRESS_INSTANCECLASS
      mov     dword ptr ds:[ebx + 18h], GM61_ADDRESS_CODECLASS
      jmp     Return

  Version70:
    cmp     eax, GM_SIGNATURE_GM70
    jne     VersionError
      mov     dword ptr ds:[ebx],       GM70_UTILITY_CODEOBJECTCOMPILE
      mov     dword ptr ds:[ebx + 04h], GM70_UTILITY_CREATECODEOBJECT
      mov     dword ptr ds:[ebx + 08h], GM70_UTILITY_CREATEINSTANCE
      mov     dword ptr ds:[ebx + 0Ch], GM70_UTILITY_EXECUTECODEOBJECT
      mov     dword ptr ds:[ebx + 10h], GM70_UTILITY_DESTROYOBJECT
      mov     dword ptr ds:[ebx + 14h], GM70_ADDRESS_INSTANCECLASS
      mov     dword ptr ds:[ebx + 18h], GM70_ADDRESS_CODECLASS
      jmp     Return

  VersionError:
    push    offset strIncompatibleVersion
    call    [ErrorMessage]

    xor     eax, eax
    ret

Return:
  mov     eax, 1
  ret
DllEntryPoint endp

end DllEntryPoint
