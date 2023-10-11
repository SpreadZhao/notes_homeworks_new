assume cs:code, ds:data, ss:stack

stack segment
stack ends

data segment
	;qt put value here(float32 lv, int32 {sign}, float32 rv)
	sign	db '0', 15 dup(0)
	lstr	db '001101',0dh,0ah,'$', 7 dup (0)
	zero	db '000000',0dh,0ah,'$', 7 dup (0)
	
	
	l_input db 6,0,6 dup(0)
	r_input	db 6,0,6 dup(0)
	
	
    mid_product_rstr db '00000000001011',0dh,0ah,'$', 15 dup(0)
	line	db '---------------',0dh,0ah,'$'
	ui_result db 0dh,0ah,'result: ','$'
	ui_i_l	db '[1] ','$'
	ui_i_r  db '[2] ','$'
	ui_error db 'invalid input. 5-bit binary expected',0dh,0ah,'$'
	ui_nextl db 0dh,0ah,'$'
	
	
	o_buf	db '00000000',0dh,0ah,'$'
	
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
	
	input_l:
		lea		dx, ui_i_l
		mov		ah, 9
		int		21H
		
		lea		dx, l_input
		mov		ah, 0aH
		int		21H
		
		mov		cx, 5
		lea		si, l_input[2]
		check_loop_l:
			cmp byte ptr [si], 'q'
			jne		cll2
			lea		dx, ui_nextl
			mov		ah, 9
			int		21H
			jmp		end_
		cll2:
			cmp byte ptr [si], '0'
			je		cll1
			cmp byte ptr [si], '1'
			je		cll1
			lea		dx, ui_error
			mov		ah, 9
			int		21H
			inc		si
			jmp		input_l
		cll1:
			inc		si
		loop	check_loop_l
	
	lea		dx, ui_nextl
	mov		ah, 9
	int		21H
	input_r:
		lea		dx, ui_i_r
		mov		ah, 9
		int		21H
		
		lea		dx, r_input
		mov		ah, 0aH
		int		21H
		
		mov		cx, 5
		lea		si, r_input[2]
		check_loop_r:
			cmp byte ptr [si], 'q'
			jne		clr2
			lea		dx, ui_nextl
			mov		ah, 9
			int		21H
			jmp		end_
		clr2:
			cmp byte ptr [si], '0'
			je		clr1
			cmp byte ptr [si], '1'
			je		clr1
			lea		dx, ui_error
			mov		ah, 9
			int		21H
			inc		si
			jmp		input_r
		clr1:
			inc		si
		loop	check_loop_r
		
	lea		dx, ui_nextl
	mov		ah, 9
	int		21H
	lea		dx, ui_nextl
	mov		ah, 9
	int		21H
	place_lr:
		mov		al, r_input[2]
		mov		ah, l_input[2]
		xor		al, ah
		xor		ah, ah
		mov		[sign], al
		
		mov		cx, 4
		lea		si, l_input[2]
		lea		di, lstr[2]
		move_loop_l:
			mov		al, [si]
			mov		[di], al
			inc		si
			inc		di
		loop move_loop_l
		
		mov		cx, 4
		lea		si, r_input[3]
		lea		di, mid_product_rstr[10]
		move_loop_r:
			mov		al, [si]
			mov		[di], al
			inc		si
			inc		di
		loop move_loop_r
			
		
	;input
	
	lea		si, mid_product_rstr[5]

	main_loop:	
		dec		si
		mov		dx, si
		mov		ah, 9
		int		21H
		cmp		si, offset mid_product_rstr
		jne		ml1
		jmp		output
		ml1:
		mov		cx, si ;cx = si
		
		cmp byte ptr [si+9], '1'
		jne		print_0
		print_l:
			lea		dx, lstr
			mov		ah, 9
			int		21H
			
			lea		si, lstr[5]
			jmp		end_print
		print_0:
			lea		dx, zero
			mov		ah, 9
			int		21H
		end_print:
			mov		bx, dx
			lea		dx, line
			mov		ah, 9
			int		21H
			mov		dx, bx
			
		add_:
			cmp		dx, offset zero
			je		print_result
			
			mov		di, cx
			add		di, 5
			xor		ax, ax
			xor		bx, bx
			add_loop:
				mov		bl, [si]
				add		bl, [di]
				sub		bl, 60h
				add		bl, al
				xor		al, al
				
				cmp		bl, 2
				jb		place_sum
					mov		al, 1
					sub		bl, 2
				
				place_sum:
					add		bl, 30h
					mov		[di], bl
				
				dec		di
				dec		si
			cmp		di, cx
			jne		add_loop
				
		print_result:
			mov		dx, cx
			mov		ah, 9
			int		21H
			
	mov		si, cx	
	jmp		main_loop		
			
	output:
		lea		dx, ui_result
		mov		ah, 9
		int		21h
	
		lea		si, mid_product_rstr[2]
		lea		di, o_buf
		move:
			mov		al, [si]
			mov		[di], al
			inc		si
			inc		di
			cmp		di, offset o_buf[7]
			jbe		move
		
		cmp	byte ptr sign, 1
		jne positive
			mov		dl, '-'
			jmp		o1
		positive:
			mov		dl, '+'
		o1:
		mov		ah, 2
		int		21H
			
		lea		dx, o_buf
		mov		ah, 9
		int		21H
end_:	
	mov		ax, 4c00H
	int		21H
	
code ends 
end start

        