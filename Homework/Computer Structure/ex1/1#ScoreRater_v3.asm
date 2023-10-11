assume cs:code, ds:data, ss:stack


stack segment
stack ends


data segment
    
    ; һЩ�궨��
	null		equ 0
	cr			equ 0dH ;/r
	lf			equ 0aH ;/n
	str_end		equ '$' ;end mark for (int 21h)-9  
	
	; ����42��*��ascii��
	ui_title 	db 42, '----------------------------', 42, cr, lf
				db 42, '                            ', 42, cr, lf
				db 42, '      Score Rater v1.0      ', 42, cr, lf
				db 42, '                            ', 42, cr, lf
				db 42, '----------------------------', 42, cr, lf
				db cr, lf
				db "  - Input 'q' to exit",cr, lf
				db cr, lf
				db '==============================',cr, lf, str_end
				
				
	ui_score 	db ' score: ', str_end
	ui_rate		db '  rate: ', str_end
	ui_endl		db cr, lf, str_end
	ui_err_oor	db ' error: score out of range[0,100]', cr, lf, str_end ;error: out of range
	ui_err_ic	db " error: invalid char or start with '.'", cr, lf, str_end ;error: invalid char
	ui_del_line	db 8,8,8,8,8,8,8,'       ',str_end
	
	; ���������ص��ֽ�(Ϊʲô����Ҫ��db������equ?)
	max_score	db 100                  ; ��߷�100
	A_ts		db 90                   ;ts - threshold������ں���
	B_ts		db 75
	C_ts		db 60
	min_score	db 0                    ;��ͷ�0
	
	buf_cap		equ 6 
	
	; �ڶ������Ƕ�����6���ֽڣ����Ƕ���null����0
	input_buf	db buf_cap, null
				db buf_cap dup(null)
	
data ends


code segment
    
    
    
; �ܵ�ִ�в��裺
; 1. ����
; 2. ��ӡui_score
; 3. ��ӡscore
; 4. �Ӽ����ж����������浽input_buf��
; 5. �ж������������С�����������Ƿ�
; 6. �õ���Ҫ���������(string -> int)
; 7. �������ֺ������ı߽�ıȽ���ȷ���ɼ������    


;main
main proc
start:
	mov		ax, data
	mov		ds, ax
	
	call	clear_screen
	call	print_title
	
	
; ��ӡ����	
i1:	call	print_score

; �������
; ����Ķ�������dx�б���
; ���Լ���input_buf�ĵ�ַ���浽dx��
i2:	lea		dx, input_buf 
          
; �����������̾����õ������Դ��ϱ�ǩ



; AH = 0AH��DS��DX = �������׵�ַ��(DS:DX) = ����������ַ���
; ���ܣ�������������ַ�����DS��DXָ���������в��Իس�����
; dx�մ���input_buf�ĵ�ַ����������������
; ���ܹ���������ַ����浽input_buf��������ڴ�����
	mov		ah, 0aH
	int		21H

; ��ĳ��ִ���У�����֮�󣬷��֣�
; ds = 0710, input_buf = 0152
; ��ôʹ��(ds:input_buf)�����ʵ�������ַ��07252
; ����07252��07253���ǿ���
; ��07254��07255�ֱ���8��6���������������86��
; 07254��07259����ds�ж���� buf_cap dup(null)
; ��Ȼ07252��07253�����������buf_cap��null
check_dot:

; si = 0153��Ҳ����8֮ǰ���Ǹ�null
	lea		si, input_buf + 1           
	
; ��һ��cx��0�����������϶���0
; ��һ�������zf��pf��0�����1
	xor		cx, cx                
	
; ��8֮ǰ���Ǹ��ֽ���Ķ�����ֵ��cl
; ������˵��֮ǰ�������null������Ӧ����0
; ����������2����֪����Ϊɶ
; ֪���ˣ���Ϊ����ֽ��������ַ����ĳ���
; ���ò���̾���Ĺ�����ʵҲͦţb��	
	mov		cl, [si]
	
	
; ����㶮�ˣ�����ͺܼ��ˣ�����Ĵ���һλ���ͻ�����
	cmp		cl, 1 ;if only input 1 bit, skip this part
	jbe		check_1                                   
	
; ��λ����1
	sub		cl, 1
	
; ++si���״β����������ƶ�����һ����(8)
	inc		si
	cd_loop_1:
		inc		si
		cmp		byte ptr [si], '.'
		jne		cd_1
	dot_operate:
		lea		si, input_buf + 1
		mov		al, [si]
		sub		al,	cl
		mov		[si], al
		jmp		check_1
	cd_1:
		loop	cd_loop_1

check_1:
	;no input check
	xor		ax, ax ;set 0
	lea		si, input_buf + 1
	mov		al, [si] ;buf_length
	cmp		al, 0
	jne		cl_2
	call	del_line
	call	print_endl
	jmp		i1
	
cl_2:	
	call	print_endl
	
	;neg sign check
	lea		si, input_buf + 2
	mov		al, [si] ;first char
	cmp		al, '-'
	je		err_oor
	cmp		al, 'q'
	jne		c1_1
	call	clear_screen
	mov		ax,4c00H
	int		21H
	
	;invalid char check
c1_1:
	lea		si, input_buf + 1
	xor		cx, cx
	mov		cl, [si]
	c1_loop_1:
		inc		si
		cmp		byte ptr [si],'0'
		jb		err_ic
		cmp		byte ptr [si],'9'
		ja		err_ic
		loop	c1_loop_1
	
get_value:
	lea		si, input_buf + 1
	mov		cl, [si]
	xor		ax, ax
	mov		bl, 10
	mov		dl,	4 ;to ignore 4th number if exist
	gv_loop_1:
		inc		si
		mul		bl ;ax = al*bl = al*10
		jo		err_oor; ax > 2^8, overflow
		mov		ah,	[si] ;
		sub		ah, 48
		add		al,	ah
		
		dec		dl
		cmp		dl, 0
		je		rate
		loop	gv_loop_1

max_dot_check:
	cmp		ax, 100
	jne		rate
	lea		si, input_buf + 1
	mov		bl, [si]
	xor		bh, bh
	add		bx, 2
	add		si, bx
	cmp	byte ptr [si], '0'
	ja		err_oor

rate:
	lea		si, max_score
	cmp		al, [si] ;if score>100, error_out_of_range
	ja		err_oor 
	
	cmp		al,	[si+1]
	jae		A_process
	
	cmp		al,	[si+2]
	jae		B_process
	
	cmp		al,	[si+3]
	jae		C_process
	
	cmp		al,	[si+4]
	jae		D_process
	
ed:	call	clear_screen
	mov		ax,4c00H
	int		21H
main endp

response_handle proc
err_oor:
	call	print_err_oof
	jmp		continue
err_ic:
	call	print_err_ic
	jmp		continue

A_process:
	mov		dl, 'A'
	jmp		output_rate
B_process:
	mov		dl, 'B'
	jmp		output_rate
C_process:
	mov		dl, 'C'
	jmp		output_rate
D_process:
	mov		dl, 'D'
	jmp		output_rate

output_rate:
	push	dx
	call	print_rate
	pop		dx
	call	sys_print_char
	call	print_endl
	jmp		continue	
response_handle endp

;ui
ui	proc
clear_screen:   
	mov		ah, 6H
	mov		al, 0
	mov		bh, 7H
	mov		cx, 0
	mov		dx, 184fH
	int		10H
	
	mov		ah, 2H
	mov		bh, 0
	mov		dh, 0
	mov		dl, 0
	int		10H
	ret


; ��ӡui_title�������Ǹ����	
print_title:
	lea		dx, ui_title
	jmp		sys_print_str
	
	
print_score:
	lea		dx, ui_score
	jmp		sys_print_str
print_rate:
	lea		dx,	ui_rate
	jmp		sys_print_str
print_endl:
	lea		dx, ui_endl
	jmp		sys_print_str
print_err_oof:
	lea		dx, ui_err_oor
	jmp		sys_print_str
print_err_ic:
	lea		dx, ui_err_ic
	jmp		sys_print_str
del_line:
	lea		dx, ui_del_line
	jmp		sys_print_str
	

; AH = 09H��DS:DX = �ַ����׵�ַ���ַ�����'$'����
; ����dx���ľ���Ҫ��ӡ�Ķ���	
sys_print_str:
	mov		ah, 9H
	int		21H
	ret

sys_print_char:
	mov		ah, 2H
	int		21H
	ret
ui	endp

;rating end, start next turn
continue proc
	lea		di, input_buf + 1
	mov		byte ptr [di], 0
	call	print_endl
	jmp		i1
continue endp

code ends
end start