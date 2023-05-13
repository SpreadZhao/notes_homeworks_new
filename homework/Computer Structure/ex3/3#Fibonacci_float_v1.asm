assume cs:code, ds:data, ss:stack

stack segment
stack ends

data segment
	
    n		dq -0.0 	;N, must has '.'
	i		dq -0.0001		;I, must has '.'
	m 		dw 0		;M
	
	result	dq 0
	result_bcd dt 0
	result_str db 23 dup('$')
	
	precision	dw 10000
	line_used	dw 0

	nextl	db 0dh,0ah,' $'
	m_input db 0dh,0ah,' M: $'
	error_nui	db 'Error: not unsigned int',0dh,0ah,'$'
	error_of	db 'Error: input int > 65535',0dh,0ah,'$'
	nan		db 'NAN...',0dh,0ah,'$'
	del_line	db 8,8,8,8,'    ','$'
	trash	dq 0
	
	buf_cap		equ 6 ;input buf capcity
	;for (int 21)- 10
	input_buf	db buf_cap, 0
				db buf_cap dup(0)
	div_n	dw 10
	

data ends

code segment
start:
    mov		ax, data
    mov		ds, ax
	
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
		
	input:
		mov	word ptr [line_used],0
	
		lea		dx, m_input
		mov		ah, 9h
		int		21h
		
		lea		dx, input_buf
		mov		ah, 10
		int		21H
	
		
		check_valid_input:
			xor		ch, ch
			mov		cl, input_buf[1]
			cmp		cx, 0
			jne		cvi1
			lea		dx, del_line
			mov		ah, 9h
			int		21h
			jmp		input
			
			cvi1:
			lea		si, input_buf[2]
			check_valid_char:
				cmp		byte ptr [si],'q'
				jne		cvc3
				jmp		end_
				
				cvc3:
				cmp		byte ptr [si],'0'
				jae		cvc1
				lea		dx, nextl
				mov		ah, 9h
				int		21h
				lea		dx, error_nui
				mov		ah, 9h
				int		21h
				jmp		input
				cvc1:
				cmp		byte ptr [si],'9'
				jbe		cvc2
				lea		dx, nextl
				mov		ah, 9h
				int		21h
				lea		dx, error_nui
				mov		ah, 9h
				int		21h
				jmp		input
				cvc2:
				inc		si
			loop	check_valid_char
			
	get_value:
		xor		ch, ch
		mov		cl, input_buf[1]
		lea		si, input_buf[1]
		xor		ax, ax
		xor		bx, bx
		gv_loop_1:
			inc		si
			mul word ptr [div_n] ;dx:ax = ax*10
			jo		err_oor ;ax > 2^16, overflow
			mov		bl,	[si]
			sub		bl, 48 ;ascii(48) = '0'
			add		ax,	bx
			jc		err_oor ;ax > 2^16, overflow
			loop	gv_loop_1
		
		jmp		place_m
		err_oor:
			lea		dx, nextl
			mov		ah, 9h
			int		21h
			lea		dx, error_of
			mov		ah, 9h
			int		21h
			jmp		input
		
	place_m:
		mov		m, ax
		
	lea		dx, nextl
	mov		ah, 9h
	int		21h
	;
	;TODO input M
	;
	
	
	fld		n
	fld		i
	mov		cx, m
	mov		bx, 1
	
	fild	precision
	fld		i
	fmul	st, st(1)
	fxch	st(1)
	
	fld		n
	fmul	st, st(1)
	fxch	st(1)
	
	fstp	trash

turn:
cmp		cx, 0
ja		t1
lea		dx, nextl
mov		ah, 9h
int		21h
jmp		input
t1:
	push	cx
	check_mode:
		cmp		bx, 2
		ja		calculate
			fbstp	result_bcd
			push	bx
			jmp		to_string
	
	calculate:
		push	bx
		add_:
			fxch	st(1)
			fadd	st(0), st(1)
			fst		result
		
	return_borrow:

		fild	precision
		fmul	st, st(1)
		fbstp	result_bcd
		
	to_string:
		
		ts1:
		lea		di, result_bcd[8]
		lea		si, result_bcd[1]
		
		check_NAN:
		mov		al, [di] 
		cmp		al, 0ffh
		jne		go_left_ts
		lea		dx, nan
		mov		ah, 9h
		int		21h
		jmp		input
		
		go_left_ts:
			cmp byte ptr [di], 0
			jne		ts2
			cmp		di, si
			je		ts2
			dec		di
			jmp		go_left_ts
			
		ts2:
		mov		dx, 0004h ;should print dot or 0, times
		lea		si, result_bcd
		mov		bx, 0
		
		mov		cx, 0 ;record how many char pushed
		push_space:
			mov		ax, ' '
			push	ax
			inc		cx
		
		proc_bcd_bit:
		mov		al, [si]
		mov		ah, al
		;first bcd bit
		and		ah, 0fh
		cmp		ah, 0
			jne		ts3
			;bcd bit is 0
			cmp		dh, 0
				je		ts4
				;should_be_print 0
				mov		bx, '0'
				push	bx
				inc		cx
				jmp		ts4
		
		ts3:
		add		ah, '0'
		xor		bh, bh
		mov		bl, ah
		or		dh, 01h
		push	bx
		inc		cx
		ts4:
		dec		dl
		
		;second bcd bit
		xor		ah, ah
		and		al, 0f0h
		mov		bl, 10h
		div		bl
		
		cmp		al, 0
		jne		ts5
			;bcd bit is 0
			cmp		dh, 0
			je		ts6
				cmp		si, offset result_bcd[1]
				je		abcd
				cmp		si, di
				je		ts6
				abcd:
					;should_be_print 0
					mov		bx, '0'
					push	bx
					inc		cx
					jmp		ts6
		
		ts5:
		add		al, '0'
		xor		bh, bh
		mov		bl, al
		or		dh, 01h
		push	bx
		inc		cx
		ts6:
		dec		dl
		
		
		cmp		dl, 0
		jne		ts7
			;dl == 0
			cmp		dh, 0
			je		ts10
				;dh != 0, push dot
				mov		bx, '.'
				push	bx
				inc		cx
				
		ts10:
		or		dh, 01h
		
		ts7:
		cmp		si, di
		je		ts8
		inc		si
		jmp		proc_bcd_bit
		
		ts8:
		lea		di, result_bcd[1]
		cmp		si, di
		ja		ts9
		mov		ax, '0'
		push	ax
		inc		cx
		
		ts9:
		cmp byte ptr result_bcd[9],80h
		jne		check_line
		mov		ax, '-'
		push	ax
		inc		cx
		
	check_line:
		mov		bx, line_used
		add		bx, cx
		cmp		bx, 78
		jb		place_char
	
	change_line:
		lea		dx, nextl
		mov		ah, 9h
		int		21h
		
		mov		bx, cx
	
	place_char:
		mov		line_used, bx
		lea		di, result_str
		loop_pc:
			pop		ax
			mov		[di], al
			inc		di
		loop	loop_pc
		
	print_result:
		lea		dx, result_str
		mov		ah, 9h
		int		21h
	
	recover_result_str:
		lea		si, result_str
		rrs1:
			cmp	byte ptr [si], '$'
			je		pop_bx_cx
			mov	byte ptr [si], '$'
			inc		si
		jmp		rrs1
			
	pop_bx_cx:
	pop		bx
	inc		bx
	pop		cx
	dec		cx
	jmp		turn

end_:	
	lea		dx, nextl
	mov		ah, 9h
	int		21h
	mov		ax, 4c00H
	int		21H
	
code ends 
end start

        