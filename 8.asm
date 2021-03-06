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
GDT_PAGE_DIR:	  times 8 db 0
GDT_PAGE_TBL:	  times 8 db 0

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
SELECT_PAGE_DIR           equ GDT_PAGE_DIR-GDT_EMPTY
SELECT_PAGE_TBL			  equ GDT_PAGE_TBL-GDT_EMPTY

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
_szPMMessage:			db	"In Protect Mode now. ^-^", 0ah, 0	; 进入保护模式后显示此字符串
_szMemChkTitle:			db	"BaseAddrL BaseAddrH LengthLow LengthHigh   Type", 0Ah, 0	; 进入保护模式后显示此字符串
_szRAMSize				db	"RAM size:", 0
_szReturn				db	0Ah, 0
; 变量
_wSPValueInRealMode		dw	0
_dwMCRNumber:			dd	0					; Memory Check Result
_dwDispPos:				dd	(80 * 6 + 0) * 2	; 屏幕第 6 行, 第 0 列。
_dwMemSize:				dd	0
_MemChkBuf:				times	256	db	0

; 保护模式下使用这些符号
szPMMessage		    	equ	_szPMMessage	- DATA
szMemChkTitle	    	equ	_szMemChkTitle	- DATA
szRAMSize		    	equ	_szRAMSize	    - DATA
szReturn		    	equ	_szReturn	    - DATA
dwDispPos		    	equ	_dwDispPos	    - DATA
dwMemSize		    	equ	_dwMemSize	    - DATA
dwMCRNumber		    	equ	_dwMCRNumber	- DATA
dwBaseAddrLow		    equ	0
dwBaseAddrHigh		    equ	4
dwLengthLow	    	    equ	8
dwLengthHigh		    equ	12
dwType		    	    equ	16
MemChkBuf		    	equ	_MemChkBuf	    - DATA
DATA_EDGE		    	equ	 $ - DATA - 1
AddressRangeMemory 		equ 1 ;留给操作系统使用的内存
AddressRangeReserved    equ 2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 页目录首地址 由于需要预留低12位作为属性用，所以必须是地址必须是4KB的整数倍
PAGE_DIR_ADDR equ 200000h ;20=10+10=>1024*1024=>1M=>2*1M=2M
; 页表首地址
PAGE_TBL_ADDR equ 201000h ;2M+4KB
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
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;获取内存信息
	mov di,_MemChkBuf
	xor ebx,ebx
.loop_mem:
	mov eax,0e820h
	mov ecx,20
	mov edx,534d4150h
	int 15h
	jc .loop_mem_err
	inc dword [_dwMCRNumber]
	cmp ebx,0
	je .loop_mem_end
	add di,20
	jmp .loop_mem
.loop_mem_err:
	mov dword [_dwMCRNumber],0
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;返回实模式描述符初始化
.loop_mem_end:
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
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;页相关
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;初始化页目录描述符表
	init_gdt GDT_PAGE_DIR,PAGE_DIR_ADDR,4095,DA_DRW
	;初始化页表描述符表 界限base+1024*4K-1，可是这要怎么传值呢，传1024
	;不是，传1023也不是
	;在低层可能是这么作的,假设curLimit为当前界限，Limit为最终界面，G为粒度
	;for(int curLimit=0;curLimit<=Limit;curLimit++){
	;	int realLimit=curLimit*G;
	;}
	;所以最终界限粒度没有关系，只需考虑粒度为1的情况就可以了
	init_gdt GDT_PAGE_TBL,PAGE_TBL_ADDR,3,DA_DRW|DA_LIMIT_4K	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;页结束
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
	;初始化视频段
	mov ax,SELECT_VIDEO
	mov gs,ax
	mov edi,(80*10+0)*2
	mov ah,0ch
	
	push szPMMessage
	call func_dispStr
	add esp,4
	
	push	szMemChkTitle
	call	func_dispStr
	add	esp, 4
	
	call func_dispMem
	call func_paging
	
	jmp	SELECT_CODE_REAL:0
	
;function千万不能放在32位代码外面，否则是不能调用的
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;打印内存信息
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
func_dispMem:
	push ecx
	push eax
	push ebx
	mov ecx,[dwMCRNumber]
	mov ebx,MemChkBuf
	
.loop_dispMem:
    	
	push dword [ebx+dwBaseAddrLow]
	call func_dispDWORD
	add esp,4
	push 2
	call func_blank
	add esp,4
	
	push dword [ebx+dwBaseAddrHigh]
	call func_dispDWORD
	add esp,4
	push 2
	call func_blank
	add esp,4
	
	push dword [ebx+dwLengthLow]
	call func_dispDWORD
	add esp,4
	push 2
	call func_blank
	add esp,4
	
	push dword [ebx+dwLengthHigh]
	call func_dispDWORD
	add esp,4
	push 2
	call func_blank
	add esp,4
	
	push dword [ebx+dwType]
	call func_dispDWORD
	add esp,4
	call func_rn
	
	;暂时不考虑两系统可用内存间存在不可用内存的情况
	cmp dword [ebx+dwType],AddressRangeMemory
	jne .loop_dispMem_next
	mov eax,[ebx+dwBaseAddrLow]
	add eax,[ebx+dwLengthLow]
	cmp eax,dword [dwMemSize]
	jb .loop_dispMem_next
	mov dword [dwMemSize],eax
.loop_dispMem_next:
	add ebx,20
	loop .loop_dispMem

	;打印内存总数
	push szRAMSize
	call func_dispStr
	add esp,4
	push dword [dwMemSize]
	call func_dispDWORD
	add esp,4
	
	pop ebx
	pop eax
	pop ecx
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;启动分页机制
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
func_paging:
	cld
	
	;初始化页目录
	xor eax,eax
	mov ax,SELECT_PAGE_DIR
	mov es,ax
	xor edi,edi
	
	;计算页目录条目
	;一个页大小为4KB，一个页有1024条页表项，一个页占4KB内存
	;所以一个页表共需4KB*1024+4KB内存=4.003MB,约等于4MB
	;4*1024*1024共需2+10+10=22位，400000h
	xor edx,edx
	mov eax,dword [dwMemSize]
	mov ebx,400000h
	div ebx
	
	;call func_rn
	;push eax
	;call func_dispDWORD
	;add esp,4
	;jmp $
	
	push eax
	mov ecx,eax
	mov eax,PAGE_TBL_ADDR|PG_P|PG_USU|PG_RWW
.loop_dir:
	stosd
	add eax,4096;页表是连续存放的
	loop .loop_dir
	
	;初始化页表
	xor eax,eax
	mov ax,SELECT_PAGE_TBL	
	mov es,ax
	xor edi,edi
	
	xor edx,edx
	pop eax
	mov ebx,1024
	mul ebx
	mov ecx,eax
	
	;call func_rn
	;push ecx
	;call func_dispDWORD
	;add esp,4
	;jmp $
	
	xor eax,eax
	mov eax,PG_P|PG_USU|PG_RWW
.loop_tbl:
	stosd
	add eax,4096
	loop .loop_tbl
	
	;设置页目录地址
	mov eax,PAGE_DIR_ADDR
	mov cr3,eax
	;开启分页机制
	mov eax,cr0
	or eax,80000000h
	mov cr0,eax
	jmp short .3
.3:
	nop
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;打印字符串,参数为首地址
;打印的视频地址为 gs:edi
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
func_dispStr:
	push ebp
	mov ebp,esp
	mov esi,[ebp+8]
.loop_dispStr:
	lodsb
	cmp al,0ah
	jz .dispStr_rn
	jmp .dispStr_next
.dispStr_rn:
	call func_rn
	jmp .loop_dispStr
.dispStr_next:
	test al,al
	jz .dispStr_end
	mov ah,0ch
	mov [gs:edi],ax
	add edi,2
	jmp .loop_dispStr
.dispStr_end:
	pop ebp
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;打印一个32位数字,参数为要打印的数字
;打印的视频地址为 gs:edi
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
func_dispDWORD:
	push ebp
	push ebx
	push ecx
	push eax
	mov ebp,esp
	mov ebx,[ebp+20]
	
	mov ecx,8
.loop_byte:
	xor eax,eax
	shld eax,ebx,4
	shl ebx,4
	;打印
	and al,0fh
	cmp al,9
	ja .letter
	add al,'0'
	jmp .next
.letter:
	add al,55
.next:
	mov ah,0ch
	mov [gs:edi],ax
	add edi,2
	loop .loop_byte
	
	pop eax
	pop ecx
	pop ebx
	pop ebp
ret
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;打印空格,参数为空格的个数
;视频位置为 gs:edi
;;;;;;;;;;;;;;;;;;;;;;;;;;;
func_blank:
	push ebp
	push eax
	push ecx
	mov ebp,esp
	mov ecx,[ebp+16]
	
.loop_blank:	
	mov al,0
	mov [gs:edi],al
	add edi,2
	loop .loop_blank
	
	pop ecx
	pop eax
	pop ebp
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
	
	;关闭分页机制并重置实模式标志位
	;回到实模式时，一定要关闭分页机制，否则会崩溃
	mov eax,cr0
	and eax,7ffffffeh
	mov cr0,eax
	
	;重置实模式标志位
	;mov	eax, cr0
	;and	al, 11111110b
	;mov	cr0, eax
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