%define _boot_debug_
%ifdef _boot_debug_
	org 0100h
%else
	org 07c00h
%endif
mov ax,cs
mov es,ax
call showStr
jmp $ ;无限循环 $表当前行地址
showStr:
mov ax,showMsg
mov bp,ax; es:bp为要显示字符串地址
mov cx,16; 字符串长度
mov ax,1301h; 
;在Teletype 模式下显示字符串 入口参数：AH＝13H BH＝页码 BL＝属性(若AL=00H 或01H) CX＝显示字符串长度 (DH、DL)＝坐标(行、列) ES:BP＝显示字符串的地址 AL＝ 显示输出方式 0—字符串中只含显示字符，其显示属性在 BL 中。显示后，光标位 置不变 1—字符串中只含显示字符，其显示属性在 BL 中。显示后，光标位 置改变 2—字符串中含显示字符和显示属性。显示后，光标位置不变 3—字符串中含显示字符和显示属性。显示后，光标位置改变
mov bx,000ch;设置颜色
mov dx,0;第0行，0列
int 10h
ret
showMsg: db "hello world"
times 510-($-$$) db 0;$$表段地址
dw 0xaa55