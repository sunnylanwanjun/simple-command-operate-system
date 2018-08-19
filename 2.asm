;删去DEVICE=C:\DOS71\EMM386.EXE NOEMS，然后重启dos
;否则报错 emm386:unrecoverable privileged operation error #n9.press enter to reboot
%include	"init_gdt.inc"
org 0100h
jmp codeRealMode
[SECTION .gdt]
STACK:			  times 256 db 0
GDT_EMPTY:		  times 8 db 0
GDT_CODE_PROTECT: times 8 db 0
GDT_VIDEO:        times 8 db 0

GDT_LEN	          equ $-GDT_EMPTY
GDTR              dw GDT_LEN-1 ;界限
                  dd 0         ;基址
SELECT_CODE 	  equ GDT_CODE_PROTECT-GDT_EMPTY
SELECT_VIDEO      equ GDT_VIDEO-GDT_EMPTY

BASE_CODE_PROTECT dd 0

[SECTION .s16]
[BITS	16]
codeRealMode:
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov ax,[STACK]
	mov sp,ax
	
	xor eax,eax
	mov ax,cs
	shl eax,4
	add eax,codeProtectMode
	mov dword [BASE_CODE_PROTECT],eax
	init_gdt GDT_CODE_PROTECT,dword [BASE_CODE_PROTECT],CODE_PROTECT_EDGE,DA_32|DA_C
	
	init_gdt GDT_VIDEO,0B8000h,0ffffh,DA_DRW
	
	;初始化GDTR
	xor eax,eax
	mov ax,cs
	shl eax,4
	add eax,GDT_EMPTY
	mov dword [GDTR+2],eax
	
	lgdt [GDTR]
	
	;切换模式时必须关掉中断
	cli
	
	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al
	
	;设置cr0最低位
	mov eax,cr0
	or eax,1
	mov cr0,eax
	
	;进入保护模式
	jmp dword SELECT_CODE:0
[SECTION .s32]; 32 位代码段. 由实模式跳入.
[BITS	32]
codeProtectMode:
	
	mov ax,SELECT_VIDEO
	mov gs,ax
	mov edi,(80*10+0)*2
	mov ah,0ch
	mov al,'P'
	mov [gs:edi],ax
	
	jmp	$
CODE_PROTECT_EDGE equ $ - codeProtectMode - 1