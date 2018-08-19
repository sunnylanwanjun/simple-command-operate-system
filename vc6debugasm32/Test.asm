.386
.model flat,stdcall
option casemap:none
;预定义

;头文件
include		windows.inc   	;常量定义
include		kernel32.inc  	;GetModuleHandle ExitProcess 的定义
includelib	kernel32.lib	
include		user32.inc	;EndDialog DialogBoxParam 的定义
includelib	user32.lib
include		InitConsole.asm
include		_CmdLine.asm
		.data?
szBuffer1	db	4096 dup (?)
szOutput	db	4096 dup (?)
LABEL_DESC_CODE32 dd ?
		.const
szFormat1	db	'exe name:%s',0dh,0ah
		db	'arg num:%d',0dh,0ah,0
szFormat2	db	'arg[%d]:%s',0dh,0ah,0
szFormat3   db  'res=%x',0dh,0ah,0
;代码
.code
_Main 	proc	uses ebx esi
	LOCAL	argNum
	invoke	GetModuleFileName,0,addr szBuffer1,sizeof szBuffer1
	invoke	_argc
	mov	argNum,eax
	invoke	wsprintf,addr szOutput,addr szFormat1,addr szBuffer1,argNum
	invoke	_WriteConsole,addr szOutput,0
	
	xor	esi,esi
	.while	esi<argNum
		invoke	_argv,esi,addr szBuffer1,sizeof szBuffer1
		invoke	wsprintf,addr szOutput,addr szFormat2,esi,addr szBuffer1	
		invoke	_WriteConsole,addr szOutput,0
		inc 	esi
	.endw
	
	ret
_Main endp

_DEBUG_ASM  proc
	mov eax,0aabbccddh
	;mov dword ptr [LABEL_DESC_CODE32],eax
	;mov	word ptr [LABEL_DESC_CODE32+2], ax
	shr	eax, 16
	mov	byte ptr [LABEL_DESC_CODE32 + 4], al
	;mov	byte ptr [LABEL_DESC_CODE32 + 7], ah

	invoke	wsprintf,addr szOutput,addr szFormat3,LABEL_DESC_CODE32
	invoke	_WriteConsole,addr szOutput,0
	ret
_DEBUG_ASM  endp

start:
	invoke	_InitConsole
	;invoke	_Main
	invoke  _DEBUG_ASM
	invoke	_ReadConsole
	invoke	ExitProcess,NULL
end start
