;ɾȥDEVICE=C:\DOS71\EMM386.EXE NOEMS��Ȼ������dos
;���򱨴� emm386:unrecoverable privileged operation error #n9.press enter to reboot
%include	"init_gdt.inc"
org 0100h
jmp codeRealMode
[SECTION .gdt]
STACK:			  times 256 db 0
GDT_EMPTY:		  times 8 db 0
GDT_CODE_PROTECT: times 8 db 0
GDT_VIDEO:        times 8 db 0

GDT_LEN	          equ $-GDT_EMPTY
GDTR              dw GDT_LEN-1 ;����
                  dd 0         ;��ַ
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
	
	;��ʼ��GDTR
	xor eax,eax
	mov ax,cs
	shl eax,4
	add eax,GDT_EMPTY
	mov dword [GDTR+2],eax
	
	lgdt [GDTR]
	
	;�л�ģʽʱ����ص��ж�
	cli
	
	; �򿪵�ַ��A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al
	
	;����cr0���λ
	mov eax,cr0
	or eax,1
	mov cr0,eax
	
	;���뱣��ģʽ
	jmp dword SELECT_CODE:0
[SECTION .s32]; 32 λ�����. ��ʵģʽ����.
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