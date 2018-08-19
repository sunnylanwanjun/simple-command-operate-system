%include	"init_gdt.inc"
org 0100h
jmp codeRealMode_Entry
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;gdt
GDT_EMPTY:		  times 8 db 0
GDT_NORMAL:		  times 8 db 0
GDT_CODE_PROTECT: times 8 db 0 ;保护模式描述符
GDT_CODE_REAL:	  times 8 db 0 ;实模式描述符
GDT_VIDEO:        times 8 db 0
GDT_DATA:		  times 8 db 0
GDT_STACK:		  times 8 db 0
GDT_STACK3:		  times 8 db 0
GDT_TEST:		  times 8 db 0
GDT_LDTR:		  times 8 db 0
GDT_CODE_GATE:	  times 8 db 0
GDT_GATE:		  times 8 db 0
GDT_CODE_RING3:   times 8 db 0
GDT_TSS:		  times 8 db 0

GDT_LEN	          equ $-GDT_EMPTY
GDTR              dw GDT_LEN-1 ;界限
                  dd 0         ;基址
				  
;选择子
SELECT_NORMAL			  equ GDT_NORMAL-GDT_EMPTY
SELECT_CODE_PROTECT 	  equ GDT_CODE_PROTECT-GDT_EMPTY
SELECT_CODE_REAL 	  	  equ GDT_CODE_REAL-GDT_EMPTY
SELECT_VIDEO      		  equ GDT_VIDEO-GDT_EMPTY
SELECT_DATA				  equ GDT_DATA-GDT_EMPTY
SELECT_STACK			  equ GDT_STACK-GDT_EMPTY
SELECT_STACK3			  equ (GDT_STACK3-GDT_EMPTY)|SA_RPL3
SELECT_TEST				  equ GDT_TEST-GDT_EMPTY
SELECT_LDTR				  equ GDT_LDTR-GDT_EMPTY
SELECT_CODE_GATE		  equ GDT_CODE_GATE-GDT_EMPTY
SELECT_TSS				  equ GDT_TSS-GDT_EMPTY
;门RPL<=门DPL,实际上是MAX(RPL,CPL)<=DPL
;对于RPL的解释
;有一个国度，办所有的事都需要通过卡才能进行，不能等级的人拥有不同颜色的卡
;绿卡权力最大，啥事都能干，黄卡权力最小，只能干一点事，有一天一个拥有很
;大权力的人想去某机构办点事，于是需要把这张绿卡委托给这个机构，这个机构
;拿着这张绿卡把委托人的事办完后，又偷偷的去干了其它一些私事，原本这个机构
;只有黄卡的，现在终于有机会让它干其它事了，这是不安全的，所以需要有一个
;替代卡，临时把卡变长黄色的，这样这个机构就不能用这张绿卡干坏事了，而这个
;临时卡就是RPL,所以说RPL对于低特权级的程序来说并没起什么作用，所以会有
;MAX(CPL,RPL)<=DPL,就是说从两者当中选个权力最低的，拿去当临时卡，所以如果
;你权力低，就算拿个牛B的临时绿卡也没用，系统会自动的把RPL切换回CPL。
;所以正确的做法是，选择子中的RPL应该要据对应的描述符的特权级来设置值。
;这是最安全的做法
SELECT_GATE				  equ (GDT_GATE-GDT_EMPTY)|SA_RPL3 
SELECT_CODE_RING3         equ (GDT_CODE_RING3-GDT_EMPTY)|SA_RPL3

;段基址
BASE_CODE_PROTECT dd 0
BASE_CODE_REAL_BACK dd 0
BASE_DATA dd 0
BASE_STACK dd 0
BASE_STACK3 dd 0
BASE_TEST dd 0
BASE_LDTR dd 0
BASE_CODE_GATE dd 0
BASE_GATE dd 0
BASE_CODE_RING3 dd 0
BASE_TSS dd 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TSS
TSS: times 100 db 0
     dw 0 ;? 调试陷阱标志
	 dw $-TSS+2;-1+3=2 其实就是TSS的长度
	 db 0ffh
TSS_EDGE equ $-TSS-1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 全局堆栈段
STACK: times 512 db 0
STACK_EDGE	equ	$ - STACK - 1
STACK3: times 512 db 0
STACK_EDGE3	equ	$ - STACK3 - 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 数据段
DATA:
; 字符串
PMMessage:		db	"In Protect Mode now. ^-^", 0	; 进入保护模式后显示此字符串
OffsetPMMessage		equ	PMMessage - DATA
StrTest:		db	"ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
OffsetStrTest		equ	StrTest - DATA
DATA_EDGE			equ	$ - DATA - 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;实模式 入口
[BITS 16]
codeRealMode_Entry:
	mov ax,cs
	mov word [codeRealModel_Handler_cs+3],ax
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov sp,[STACK]
	
	;返回实模式描述符初始化
	xor eax,eax
	mov ax,cs
	shl eax,4
	add eax,codeRealMode_Back
	mov dword [BASE_CODE_REAL_BACK],eax
	;!!!!!!!! 一定要注意边界不能是CODE_REAL_BACK_EDGE，而必须为
	;0ffffh,还有不能为DA_32，否则都不能跳转成功
	init_gdt GDT_CODE_REAL,dword [BASE_CODE_REAL_BACK],0ffffh,DA_C
	;保护模式描述符初始化
	xor eax,eax
	mov ax,cs
	shl eax,4
	add eax,codeProtectMode
	mov dword [BASE_CODE_PROTECT],eax
	init_gdt GDT_CODE_PROTECT,dword [BASE_CODE_PROTECT],CODE_PROTECT_EDGE,DA_C|DA_32
	;视频描述符初始化
	init_gdt GDT_VIDEO,0B8000h,0ffffh,DA_DRW|DA_DPL3
	;默认描述符初始化 在回到实模式时使用
	init_gdt GDT_NORMAL,0,0ffffh,DA_DRW
	;数据段描述符初始化
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,DATA
	mov dword [BASE_DATA],eax
	init_gdt GDT_DATA,dword [BASE_DATA],DATA_EDGE,DA_DRW
	;堆栈段描述符
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,STACK
	mov dword [BASE_STACK],eax
	;己访问位的解释
	;A位由处理器负责置位，这个功能是给操作系统使用的，用于虚拟内存管理。	;A位由操作系统复位，操作系统可以根据A位被置位的次数统计段的使用频率，在内存紧张时淘汰那些较少使用的段。
	;数据没有32位和16位之分，所以GDT_DATA和GDT_TEST都没有加了DA_32
	;但堆栈有，因为push和pop指令如果是16位的，那么就只能对16位寄存器
	;进行操作,如果是32位的，那么就能对32位的寄存器进行操作
	init_gdt GDT_STACK,dword [BASE_STACK],STACK_EDGE,DA_DRWA|DA_32
	
	;测试段描述符
	init_gdt GDT_TEST,0500000h,0ffffh,DA_DRW
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;ring3相关
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;初始化ring3堆栈
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,STACK3
	mov dword [BASE_STACK3],eax
	init_gdt GDT_STACK3,dword [BASE_STACK3],STACK_EDGE3,DA_DRWA|DA_32|DA_DPL3
	
	;初始化RING3代码
	xor eax,eax
	mov ax,cs
	shl eax,4
	add eax,codeRing3
	mov dword [BASE_CODE_RING3],eax
	init_gdt GDT_CODE_RING3,dword [BASE_CODE_RING3],CODE_RING3_EDGE,DA_C|DA_32|DA_DPL3
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;ring3结束
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;LDT开始
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;LDT寄存器
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,LDT_BEGIN
	mov dword [BASE_LDTR],eax
	init_gdt GDT_LDTR,dword [BASE_LDTR],LDT_EDGE,DA_LDT
	
	;初始化LDT测试代dcg
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,codeLDT
	mov dword [BASE_LDT_CODE],eax
	init_gdt LDT_CODE_PROTECT,dword [BASE_LDT_CODE],CODE_LDT_EDGE,DA_C|DA_32
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;LDT结束
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;门相关
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;初始化门描述符
	;初始化偏移值
	xor eax,eax
	mov word [GDT_GATE],ax
	mov word [GDT_GATE+6],ax
	;初始化选择子
	xor eax,eax
	mov ax,SELECT_CODE_GATE
	mov word [GDT_GATE+2],ax
	;初始化属性
	xor eax,eax
	mov byte [GDT_GATE+4],al
	;加了门以后，可以实现非一致代码向低权级向高权级转移
	mov ax,DA_386CGate|DA_32|DA_DPL3
	mov byte [GDT_GATE+5],al
	
	;初始化门测试代码
	xor eax,eax
	mov ax,cs
	shl eax,4
	add eax,codeGate ;目标代码特权级与调用代码的相同
	mov dword [BASE_CODE_GATE],eax
	init_gdt GDT_CODE_GATE,dword [BASE_CODE_GATE],CODE_GATE_EDGE,DA_C|DA_32
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;结束门
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;TSS相关
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;TSS寄存器
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,TSS
	mov dword [BASE_TSS],eax
	init_gdt GDT_TSS,dword [BASE_TSS],TSS_EDGE,DA_386TSS
	
	;初始化TSS
	xor eax,eax
	mov eax,STACK_EDGE
	mov dword [TSS+4],eax
	xor eax,eax
	mov ax,SELECT_STACK
	mov dword [TSS+8],eax
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;TSS结束
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
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
	;此时并没有因为cr0改为保护模式，cs被修改，因为存在高速缓冲存储器，所以寻址不会混乱
	;进入保护模式，dword加不加都无所谓，用了dword表示段间寻址，
	;这里很明显在64kb的范围内，这一点书上说的不对
	jmp SELECT_CODE_PROTECT:0 ;
	;可见32位指令前面会多个值为66的字节,32位跳转指令的值无法理解
	;其它的都比较直观
	;jmp dword 0abcdh:1234h 66ea34120000cd
	;jmp word 0abcdh:1234h ea3412cdab
	;jmp 0abcdh:1234h ea3412cdab
	;jmp 0:codeRealModel_Handler ea09070000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;保护模式入口
;16位模式下，代码段属性值必须为DA_C，且界限必须为0ffffh
;32位模式下，代码段属性值必须包含DA_32，但可以再包含其它，所以是不固定的，界限也任意
;实模式只能运行在16位，保护模式任意
;在下面的几段代码中
;codeProtectMode 因为此时cr0已经置位，所以处在保护模式下的，假如设为[BITS 16]位，则所以代码段属性必为DA_C，假如代码段设为[BITS 32]位,则代码段属性应为DA_32|DA_C
;codeRealMode_Back 此时仍然处于保护模式，规则与codeProtectMode 相同
;codeRealModel_Handler 由于cr0已经复位，所以处于实模式下，此时只能是16位模式了
;必须使用BITS 32，因为dos的com文件默认是16位的,不使用BITS 32进行显示的指定
;会编译出错误的代码，进入保护模式后，必须使用32位的指令,否则指令不能被正常执行
[BITS 32] 
codeProtectMode:
	
	;初始化栈
	mov ax,SELECT_STACK
	mov ss,ax
	mov esp,STACK_EDGE
	;初始化源数据段
	mov ax,SELECT_DATA
	mov ds,ax
	mov esi,OffsetPMMessage
	;初始化目标数据段
	mov ax,SELECT_TEST
	mov es,ax
	;初始化视频段
	mov ax,SELECT_VIDEO
	mov gs,ax
	mov edi,(80*10+0)*2
	mov ah,0ch
	
	cld
.1:
	lodsb
	test al,al
	jz .2
	mov [gs:edi],ax
	add edi,2
	jmp .1
	
.2:
	call func_rn ;换行打印
	;call SELECT_CODE_GATE:0 ;不采用调用门
	;call SELECT_GATE:0 ;采用调用门
	;现在由高权级转向低权级，由于没有从低权级转向高权级的代码
	
	mov ax,SELECT_TSS
	ltr ax
	;所以现在只能模拟调用栈,然后才可以返回到低权级中
	push SELECT_STACK3;ss
	push STACK_EDGE3  ;esp
	push SELECT_CODE_RING3;cs
	push 0;eip
	retf
	
	mov ax,SELECT_LDTR
	lldt ax
	jmp SELECT_LDT_CODE_PROTECT:0 ;LDT跳转
	
	mov ah,0ch	
	xor esi,esi
	mov ecx,8
	call func_read
	
	call func_rn ;换行打印
	
	push edi
	mov edi,OffsetStrTest ;DATA
	mov ah,0ch
	xor esi,esi ;TEST
	mov ecx,8
	call func_write
	
	pop edi
	mov ah,0ch	
	xor esi,esi
	mov ecx,8
	call func_read
	jmp	SELECT_CODE_REAL:0
	
;function千万不能放在32位代码外面，否则是不能调用的

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;打印es:esi中的数据,打印次数为ecx
;打印的视频地址为 gs:edi
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
func_read:
.loop_read:
	mov al,[es:esi]
	mov dl,al
	shr al,4
	push ecx
	mov ecx,2
	
.loop_byte:
	;打印
	and al,0fh
	cmp al,9
	ja .letter
	add al,'0'
	jmp .next
.letter:
	add al,55
.next:
	mov [gs:edi],ax
	add edi,2
	
	;打印低位字节
	mov al,dl
	loop .loop_byte
	
	pop ecx
	inc esi
	;打印一个空格
	call func_blank
	loop .loop_read
ret	

;;;;;;;;;;;;;;;;;;;;;;;
;从ds:edi中读取数据
;把数据写入es:esi中
;写数据的个数由ecx指定
;;;;;;;;;;;;;;;;;;;;;;;
func_write:
.loop_write:
	mov al,[ds:edi]
	mov byte [es:esi],al
	inc esi
	inc edi
	loop .loop_write
ret

;;;;;;;;;;;;;;;;;;;;;;;
;将打印位置换行
;视频位置为 gs:edi
;;;;;;;;;;;;;;;;;;;;;;;
func_rn:
	push eax
	push ebx
	mov eax,edi
	mov bl,160
	div bl
	and eax,0ffh;清除余数
	inc eax
	mul bl
	mov edi,eax
	pop ebx
	pop eax
ret

;;;;;;;;;;;;;;;;;;;;;;;;
;打印空格
;视频位置为 gs:edi
;;;;;;;;;;;;;;;;;;;;;;;;
func_blank:
	push eax
	mov al,0
	mov [gs:edi],al
	add edi,2
	pop eax
ret

CODE_PROTECT_EDGE equ $ - codeProtectMode - 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;回到实模式 在还没有重置实模式时，仍然可以用32位的代码，但只要一跳转到实模式
;就必须用16位模式，可能这就是书上说的，不能由32位直接回到实模式的原因吧
[BITS 16] 
codeRealMode_Back:
	;在保护模式时，使用过什么寄存器，在返回实模式前，一定要归位，
	;因为实模式下寄存器的属性和界面都是固定值，如果不归位，会造成
	;返回实模式失败
	;这里只是把段寄存器的属性和界限重设为16位模式下的样子
	;但ss和cs的值仍然是不正确的，在jmp后，cs才会是正确的值
	;而ss则在codeRealModel_Handler中进行设置
	mov ax,SELECT_NORMAL
	mov	gs, ax
	mov ds, ax
	mov ss, ax
	mov es, ax
	
	;重置实模式标志位
	mov	eax, cr0
	and	al, 11111110b
	mov	cr0, eax
codeRealModel_Handler_cs:
	jmp 0:codeRealModel_Handler
	
CODE_REAL_BACK_EDGE equ $-codeRealMode_Back-1
[BITS 16] 
codeRealModel_Handler:
	mov ax,cs
	mov ds,ax
	mov ss,ax
	mov sp,[STACK]
	
	in	al, 92h		; ┓
	and	al, 11111101b	; ┣ 关闭 A20 地址线
	out	92h, al		; ┛
	
	sti			; 开中断
	
	mov ax,4c00h
	int 21h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;局部任务
LDT_BEGIN:
LDT_CODE_PROTECT: times 8 db 0
;LDT的选择子，必须将TL置位，才能标识该选择子是LDT的选择子
SELECT_LDT_CODE_PROTECT equ (LDT_CODE_PROTECT-LDT_BEGIN)|SA_TIL
LDT_EDGE equ $-LDT_BEGIN-1
BASE_LDT_CODE dd 0
[BITS 32]
codeLDT:
	mov ah,0ch
	mov al,'L'
	mov [gs:edi],ax
	add edi,2
	jmp	SELECT_CODE_REAL:0
CODE_LDT_EDGE equ $-codeLDT-1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;门调用
[BITS 32]
codeGate:
	mov ah,0ch
	mov al,'G'
	mov [gs:edi],ax
	add edi,2
	
	;为了从低特权级进入调用门后能顺序返回dos，这里不使用retf
	jmp	SELECT_CODE_REAL:0
	
	;retf ;不能用ret,因为ret表短返回，只恢复eip，retf表长返回，恢复eip，cs
CODE_GATE_EDGE equ $-codeGate-1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ring3代码
;从高特权级向低特权级转移，使用模拟栈和retf即可
;从低特权级向高特权级转移，需要使用门，才能转移，此时需要有TSS存储门调用代码的
;ss和esp，然后将当前的ss和esp存入新栈中，并把参数进行拷贝，参数的个数由门描述符
;中的param count指定
[BITS 32]
codeRing3:
	mov ah,0ch
	mov al,'3'
	mov [gs:edi],ax
	add edi,2
	;ring3 到ring0
	call SELECT_GATE:0
	jmp $
CODE_RING3_EDGE equ $-codeRing3-1