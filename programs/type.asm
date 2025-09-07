	BITS 16
	%INCLUDE "mikedev.inc"
	ORG 32768

main_loop:
	mov ax, input
	mov bx, 255
	call os_input_string

	mov si, input
	mov di, exit_str
	call os_string_compare
	jc quit

	mov si, input
	mov di, clear_str
	call os_string_compare
	jc clear

	call os_print_newline

	jmp main_loop

clear:
	call os_clear_screen
	jmp main_loop

quit:
	ret


	input		times 255 db 0
	clear_str	db 'cls', 0
	exit_str	db 'exit', 0
