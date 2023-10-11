assume cs:code, ds:data, ss:stack


stack segment
stack ends


data segment
	null		equ 0
	line_end	equ 0dH,0aH ;/r/n
	str_end		equ '$' ;end mark for (int 21h)-9
	
	ui_title: 	db 'Score Rater v1.0 ',line_end
				db '-----------------',line_end
				db "input 'q' to exit",line_end
				db '-----------------',line_end,str_end
	ui_score: 	db 'score: ', str_end
	ui_rate:	db 'rate: ', str_end
	ui_endl:	db line_end, str_end
	ui_err_oor:	db 'error: score out of range[0,100]', line_end, str_end ;error: out of range
	ui_err_ic:	db "error: invalid char or start with '.'", line_end, str_end ;error: invalid char
	
	max_score:	db 100
	A_ts:		db 90 ;ts - threshold
	B_ts:		db 75
	C_ts:		db 60
	min_score:	db 0
	
	buf_cap		equ 5
	input_buf:	db buf_cap, null
				db buf_cap dup(null)
	
data ends


code segment

;main
main proc
start:
	mov		ax, data
	mov		ds, ax
	
	call	print_title
	call	input
	
ed:	mov		ax,4c00H
	int		21H
main endp

;ui
ui	proc
;print ui text
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
	
sys_print_str:
	mov		ah, 9H
	int		21H
	ret

sys_print_char:
	push	dx
	call	print_endl
	pop		dx
	mov		ah, 2H
	int		21H
	ret
ui	endp

;input
input proc
i1:	call	print_score
i2:	lea		dx, input_buf
	mov		ah, 0aH
	int		21H

check_dot:
	mov		si, input_buf + 1
	xor		cx, cx
	mov		cl, [si]
	sub		cl, 1
	inc		si
	cd_loop_1:
		inc		si
		cmp		[si], '.'
		je		dot_operate
		loop	cd_loop_1

check_1:
	;no input check
	xor		ax, ax ;set 0
	mov		si, input_buf + 1
	mov		al, [si] ;buf_length
	cmp		al, 0
	je		i2
	
	call	print_endl
	
	;neg sign check
	mov		si, input_buf + 2
	mov		al, [si] ;first char
	cmp		al, '-'
	je		err_oor
	cmp		al, 'q'
	je		ed
	
	;invalid char check
	mov		si, input_buf + 1
	xor		cx, cx
	mov		cl, [si]
	c1_loop_1:
		inc		si
		cmp		[si],'0'
		jb		err_ic
		cmp		[si],'9'
		ja		err_ic
		loop	c1_loop_1
	
get_value:
	mov		si, input_buf + 1
	mov		cl, [si]
	xor		ax, ax
	mov		bl, 10
	mov		dl,	3 ;to ignore 4th number if exist
	gv_loop_1:
		inc		si
		mul		bl ;ax = al*bl = al*10
		mov		ah,	[si] ;
		sub		ah, 48
		add		al,	ah
		
		dec		dl
		cmp		dl, 0
		je		rate
		loop	gv_loop_1

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
	
input endp

dot_operate proc
	mov		si, input_buf + 1
	mov		al, [si]
	sub		al,	cl
	mov		[si], al 
	;buf_length = char amount before '.'
	;[BUG](kinda) therefore if buf_cap > 5(which is set to 5 now), scores (100,101) would be seem as 100
	jmp		check_1
dot_operate endp

response_handle proc
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
	call	sys_print_char
	call	print_endl
	jmp		continue	
	
err_oor:
	call	print_err_oof
	jmp		continue
err_ic:
	call	print_err_ic
	jmp		continue
response_handle endp

;rating end, start next turn
continue proc
	mov		di, input_buf + 1
	mov		[di], 0
	call	print_endl
	jmp		i1
continue endp

code ends
end start