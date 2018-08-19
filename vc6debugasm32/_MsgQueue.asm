;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
QUEUE_SIZE	equ	100		;��Ϣ���еĳ���
MSG_QUEUE_ITEM	struct			;�����е�����Ϣ�ĸ�ʽ����
  dwMessageId	dd	?		;��Ϣ���
  szSender	db	12 dup (?)	;������
  szContent	db	256 dup (?)	;��������
MSG_QUEUE_ITEM	ends
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

		.data?

stCS		CRITICAL_SECTION <?>
stMsgQueue	MSG_QUEUE_ITEM QUEUE_SIZE dup (<?>)
dwMsgCount	dd	?		;�����е�ǰ��Ϣ����

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

		.data

dwSequence	dd	1	;��Ϣ��ţ���1��ʼ
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; �ڶ����м���һ����Ϣ
; -- ��������Ѿ����ˣ�����������ǰ��һ��λ�ã��൱���������Ϣ������
;    Ȼ���ڶ���β���ճ���λ�ü�������Ϣ
; -- �������δ�������ڶ��е�����������Ϣ
; -- ��Ϣ��Ŵ�1��ʼ������������֤�����и���Ϣ�ı����������
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; ��ڣ�_lpszSender = ָ�������ַ�����ָ��
;	_lpszContent = ָ��������������ַ�����ָ��
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.code
_InsertMsgQueue	proc	_lpszSender,_lpszContent
	pushad
	
	invoke	EnterCriticalSection,addr stCS
	.if	dwMsgCount>=QUEUE_SIZE
		mov	esi,offset stMsgQueue+sizeof MSG_QUEUE_ITEM
		mov	edi,offset stMsgQueue
		mov	ecx,QUEUE_SIZE-1
		cld
		rep	movsw
	.else
		inc	dwMsgCount	
	.endif
	
	lea	esi,stMsgQueue
	
	mov	eax,dwMsgCount
	dec	eax
	mov	ecx,sizeof MSG_QUEUE_ITEM
	mul	ecx
	add	esi,eax
	assume  esi:ptr MSG_QUEUE_ITEM
	push	dwSequence
	pop	[esi].dwMessageId
	invoke	lstrcpy,addr [esi].szSender,_lpszSender
	invoke	lstrcpy,addr [esi].szContent,_lpszContent
	
	inc	dwSequence
	popad
	invoke	LeaveCriticalSection,addr stCS
	assume	esi:nothing
	ret
_InsertMsgQueue endp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; �Ӷ��л�ȡָ����ŵ���Ϣ
; -- ���ָ����ŵ���Ϣ�Ѿ����������Ϣ���У��򷵻ر����С��һ����Ϣ
;    ���������ٶȹ����Ŀͻ��˷���Ϣ���ٶȱȲ�����Ϣ��������ٶȣ����м�
;    ����Ϣ���ڱ����ԣ��������Ա�֤������·����Ӱ�������·
; -- ��������е�������Ϣ�ı�Ŷ���ָ�����С����ζ����Щ��Ϣ��ǰ������ȡ����
;    ��ô�������κ���Ϣ
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; ��ڣ�_dwMessageId = ��Ҫ��ȡ����Ϣ���
;	_lpszSender = ���ڷ�����Ϣ�з������ַ����Ļ�����ָ��
;	_lpszSender = ���ڷ�����Ϣ�����������ַ����Ļ�����ָ��
; ���أ�eax = 0������Ϊ�գ����߶�����û��С�ڵ���ָ����ŵ���Ϣ��
;	eax <> 0���Ѿ���ȡ��һ����Ϣ����ȡ����Ϣ��ŷ��ص�eax�У�
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_GetMsgFromQueue proc	uses ebx esi edi _dwMessageId,_lpszSender,_lpszContent
	mov eax,_dwMessageId
	.if eax>=dwSequence
		mov eax,0
		ret
	.endif
	
	invoke	EnterCriticalSection,addr stCS
	lea esi,stMsgQueue
	assume esi:ptr MSG_QUEUE_ITEM
	mov ebx,1
	.while TRUE		
		mov edi,[esi].dwMessageId
		.if edi==_dwMessageId
			invoke	lstrcpy,_lpszSender,addr [esi].szSender
			invoke	lstrcpy,_lpszContent,addr [esi].szContent
			inc	edi
			.break
		.endif
		add esi,sizeof MSG_QUEUE_ITEM
		inc ebx
		.if ebx>dwMsgCount
			xor edi,edi
			.break	
		.endif
	.endw
	invoke	LeaveCriticalSection,addr stCS
	assume	esi:nothing
	mov	eax,edi
	ret
_GetMsgFromQueue endp