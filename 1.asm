%define _boot_debug_
%ifdef _boot_debug_
	org 0100h
%else
	org 07c00h
%endif
mov ax,cs
mov es,ax
call showStr
jmp $ ;����ѭ�� $��ǰ�е�ַ
showStr:
mov ax,showMsg
mov bp,ax; es:bpΪҪ��ʾ�ַ�����ַ
mov cx,16; �ַ�������
mov ax,1301h; 
;��Teletype ģʽ����ʾ�ַ��� ��ڲ�����AH��13H BH��ҳ�� BL������(��AL=00H ��01H) CX����ʾ�ַ������� (DH��DL)������(�С���) ES:BP����ʾ�ַ����ĵ�ַ AL�� ��ʾ�����ʽ 0���ַ�����ֻ����ʾ�ַ�������ʾ������ BL �С���ʾ�󣬹��λ �ò��� 1���ַ�����ֻ����ʾ�ַ�������ʾ������ BL �С���ʾ�󣬹��λ �øı� 2���ַ����к���ʾ�ַ�����ʾ���ԡ���ʾ�󣬹��λ�ò��� 3���ַ����к���ʾ�ַ�����ʾ���ԡ���ʾ�󣬹��λ�øı�
mov bx,000ch;������ɫ
mov dx,0;��0�У�0��
int 10h
ret
showMsg: db "hello world"
times 510-($-$$) db 0;$$��ε�ַ
dw 0xaa55