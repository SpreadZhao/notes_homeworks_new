assume cs:code, ds:data, ss:stack


stack segment
stack ends


data segment
    
    ; 一些宏定义
	null		equ 0
	cr			equ 0dH ;/r
	lf			equ 0aH ;/n
	str_end		equ '$' ;end mark for (int 21h)-9  
	
	; 这里42是*的ascii码
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
	
	; 定义分数相关的字节(为什么分数要用db而不是equ?)
	max_score	db 100                  ; 最高分100
	A_ts		db 90                   ;ts - threshold，即入口函数
	B_ts		db 75
	C_ts		db 60
	min_score	db 0                    ;最低分0
	
	buf_cap		equ 6 
	
	; 第二条，是定义了6个字节，他们都是null，即0
	input_buf	db buf_cap, null
				db buf_cap dup(null)
	
data ends


code segment
    
    
    
; 总的执行步骤：
; 1. 清屏
; 2. 打印ui_score
; 3. 打印score
; 4. 从键盘中读数，并保存到input_buf中
; 5. 判断输入的数字是小数，负数，非法
; 6. 得到我要输入的数字(string -> int)
; 7. 根据数字和评级的边界的比较来确定成绩并输出    


;main
main proc
start:
	mov		ax, data
	mov		ds, ax
	
	call	clear_screen
	call	print_title
	
	
; 打印分数	
i1:	call	print_score

; 获得输入
; 输入的东西放在dx中保存
; 所以加载input_buf的地址保存到dx中
i2:	lea		dx, input_buf 
          
; 以上两个过程经常用到，所以打上标签



; AH = 0AH，DS：DX = 缓冲区首地址，(DS:DX) = 缓冲区最大字符数
; 功能：读键盘输入的字符串到DS：DX指定缓冲区中并以回车结束
; dx刚存了input_buf的地址，那我这样操作，
; 就能够将输入的字符保存到input_buf所代表的内存中了
	mov		ah, 0aH
	int		21H

; 在某次执行中，输入之后，发现：
; ds = 0710, input_buf = 0152
; 那么使用(ds:input_buf)算出真实的物理地址：07252
; 发现07252和07253都是空字
; 而07254和07255分别是8和6，正好是我输入的86分
; 07254到07259是在ds中定义的 buf_cap dup(null)
; 显然07252和07253就是它上面的buf_cap和null
check_dot:

; si = 0153，也就是8之前的那个null
	lea		si, input_buf + 1           
	
; 第一次cx是0，那异或操作肯定是0
; 第一次运算后，zf和pf从0变成了1
	xor		cx, cx                
	
; 把8之前的那个字节里的东西赋值给cl
; 按理来说，之前定义的是null，本来应该是0
; 但这里变成了2，不知道是为啥
; 知道了，因为这个字节是输入字符串的长度
; 不得不感叹汇编的功能其实也挺牛b的	
	mov		cl, [si]
	
	
; 上面搞懂了，这里就很简单了，输入的大于一位，就会跳过
	cmp		cl, 1 ;if only input 1 bit, skip this part
	jbe		check_1                                   
	
; 把位数减1
	sub		cl, 1
	
; ++si，首次操作，就是移动到第一个数(8)
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


; 打印ui_title，就是那个框框	
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
	

; AH = 09H，DS:DX = 字符串首地址，字符串以'$'结束
; 所以dx里存的就是要打印的东西	
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