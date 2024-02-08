assume cs:code, ds:data, ss:stack

stack segment
stack ends


data segment
	null		equ 0
	cr			equ 0dH ;/r
	lf			equ 0aH ;/n
	str_end		equ '$' ;end mark for (int 21h)-9
	
	arr		dw 1, 14, 514, 65535, 0, 555, 1024, 718, 3393, 9057
			db str_end
	len		db 10
	div_n	dw 10
	
	ui_title db 218, '-------------------------------------', 191, cr, lf
			 db 179, '                                     ', 179, cr, lf
			 db 179, '  10 Unsigned int_16 Quik Sort v1.0  ', 179, cr, lf
			 db 179, '                                     ', 179, cr, lf
			 db 192, '-------------------------------------', 217, cr, lf
			 db cr, lf
			 db "  - Input 'q' to exit              ", cr, lf
			 db "  - Input 'f' to fill remaining slots", cr, lf
			 db "    with built-in numbers", cr, lf
			 db cr, lf
			 db '  - Support int between [0,65535]  ', cr, lf
			 db cr, lf
			 db '=======================================', cr, lf, str_end
	ui_notice db 'Input numbers:', cr, lf, cr, lf, str_end
	ui_input db '[',null,'] ', str_end
	ui_aod	 db ' - (0)    ascending', cr, lf
			 db ' - (else) descending', cr, lf
			 db 'order: ', str_end
	ui_line	 db '=======================================', cr, lf, str_end
	ui_endl	 db cr, lf, str_end
	ui_err_oor	db 'Error: out of range[0,65535]', cr, lf, str_end ;error: out of range
	ui_err_ic	db 'Error: invalid char', cr, lf, str_end ;error: invalid char
	ui_del_line	db 8,8,8,8,'    ',str_end
	
	buf_cap		equ 6
	input_buf	db buf_cap, null
				db buf_cap dup(null)
	aod		 db null
data ends


code segment

;main
main proc
start:
	mov		ax, data
	mov		ds, ax
	
	call	clear_screen
	call	print_title
start_:		
	call	print_notice
	call	input
m_sort:
	mov		bl, 0
	mov		bh, [len]
	sub		bh, 1	
	add		bh, bh
	call	qsort
	
	call	print_endl
	call	print_aod
	
	mov		ah, 1
	int		21h
	mov		[aod], al
	
	call	print_endl
	call	print_endl
	
	call	output
	
	call	print_endl
	call	print_line
	jmp		start_
	
	;call	print_title
	;call	input
	
ed0:	
	mov		ax, 4c00H
	int		21H
main endp

ui proc
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
	
print_title:
	lea		dx, ui_title
	jmp		sys_print_str
print_notice:
	lea		dx, ui_notice
	jmp		sys_print_str
print_input:
	lea		dx,	ui_input
	jmp		sys_print_str
print_aod:
	lea		dx,	ui_aod
	jmp		sys_print_str
print_line:
	lea		dx, ui_line
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
	
sys_print_str:
	mov		ah, 9H
	int		21H
	ret
ui endp

input proc
	mov		cx, 10
	mov		bl, 47
i_loop:
	push	cx
	inc		bl
	push	bx
	mov		[ui_input+1], bl
	call	print_input
	
i1:	lea		dx, input_buf
	mov		ah, 0aH
	int		21H
	
check_1:
	;no input check
	xor		ax, ax ;set 0
	lea		si, input_buf + 1
	mov		al, [si] ;buf_length
	cmp		al, 0
	jne		c1_2
	call	del_line
	jmp		continue

c1_2:
	call	print_endl
	
	;neg sign check
	mov		al, [input_buf + 2] ;first char
	cmp		al, '-'
	je		err_oor
	cmp		al, 'f'
	jne		c1_2_1
	pop		bx
	pop		cx
	jmp		m_sort
c1_2_1:
	cmp		al, 'q'
	jne		c1_1
	
	call	clear_screen
	mov		ax,4c00H
	int		21H
	
relay:
	jmp	i_loop
	
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
	xor		dx, dx
	xor		bx, bx
	gv_loop_1:
		inc		si
		mul word ptr [div_n] ;dx:ax = ax*10
		jo		err_oor ;ax > 2^16, overflow
		mov		bl,	[si]
		sub		bl, 48
		add		ax,	bx
		jc		err_oor ;ax > 2^16, overflow
		loop	gv_loop_1
	
place_value:
	pop		bx
	pop		cx
	mov		di, cx
	dec		di
	add		di, di
	mov		arr[di], ax
	loop	relay
i_ret:	
	ret
input endp

err_oor:
	call	print_err_oof
	jmp		continue
err_ic:
	call	print_err_ic
	jmp		continue
continue proc
	call	print_endl
	pop		bx
	dec		bx
	pop		cx
	jmp		i_loop
continue endp

qsort proc
	cmp		bl, bh
	jb		q_start
	ret
q_start:
	xor		ah, ah
	mov		al, bl
	mov		si, ax ;si = initial left index = bl
	mov		al, bh
	mov		di, ax ;di = initial right index = bh
	
	mov		dx, arr[si] ;dx stores first num

check_end_1:	
	cmp		si, di
	jb		l1
	
	mov	word ptr arr[si], dx
	
	mov 	ax, si
	jmp		next
	
l1:
	cmp		dx, arr[di]
	ja		swap_1
	sub		di, 2
	jmp		check_end_1
	
check_end_2:	
	cmp		si, di
	jb		l2
	mov	word ptr arr[di], dx
	mov		ax, di
	jmp		next
	
l2:
	cmp		arr[si], dx
	ja		swap_2
	add		si, 2
	jmp		check_end_2
	
next:
	push	bx
	mov		ax, si
	sub		ax, 2
	jns		n1
	mov		ax, 0
n1:	mov		bh, al
	call	qsort
	
	pop		bx
	mov		ax, si
	add		ax, 2
	cmp		ax, 18 ;[TODO] 18 only works when len == 10
	jbe		n2
	mov		ax, 18
n2:	mov		bl, al
	call	qsort
	
	ret	
qsort endp

swap proc
swap_1:
	mov		ax, arr[di]
	mov		arr[si], ax
	add		si, 2
	jmp		check_end_2
swap_2:
	mov		ax, arr[si]
	mov		arr[di], ax
	sub		di, 2
	jmp		check_end_1
swap endp

output proc
	mov		cl, [len]
	xor		ch, ch
	lea		si, arr
	cmp		[aod], '0'
	je		o1
	add		si, 18 ;[TODO] only works when len == 10
o1:
	mov		bx, 0
	o_loop:
		push	cx
		mov		ax, [si]
		o_l_loop1:
			xor		dx, dx
			div	word ptr [div_n]
			add		dx, '0'
			push	dx
			inc		bx
			xor		dx, dx
			cmp		ax, 0
			jne		o_l_loop1
		
		mov		cx, bx
		xor		bx, bx
		o_l_loop2:
			pop		dx
			mov		ah, 2H
			int		21H
			loop	o_l_loop2	
			
		pop		cx
		add		si, 2
		cmp		[aod], '0'
		je		o2
		sub		si, 4
o2:
		cmp		cx, 1
		je		o
		mov		dl, ' '
		int		21H
o:		loop	o_loop
	ret
output endp

code ends
end start