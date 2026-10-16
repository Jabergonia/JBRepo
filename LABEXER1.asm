%macro print 2
    mov eax, 4
    mov ebx, 1
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro

section .data
    clr         db 27, "[2J", 27, "[H"
    clr_len     equ $ - clr

    menu        db "----------------------------------", 10
                db "MENU", 10
                db "[A]dd", 10
                db "[S]ubtract", 10
                db "[M]ultiply", 10
                db "[D]ivide", 10
                db "----------------------------------", 10
                db "Enter your choice: "
    menu_len    equ $ - menu

    msg_first   db 10, "Enter first number: "
    msg_first_len equ $ - msg_first
    msg_second  db "Enter second number: "
    msg_second_len equ $ - msg_second

    msg_sum     db "The sum is "
    msg_sum_len equ $ - msg_sum
    msg_diff    db "The difference is "
    msg_diff_len equ $ - msg_diff
    msg_prod    db "The product is "
    msg_prod_len equ $ - msg_prod
    msg_quot    db "The quotient is "
    msg_quot_len equ $ - msg_quot
    msg_rem     db ", remainder is "
    msg_rem_len equ $ - msg_rem

    msg_zero    db "Error: cannot divide by zero", 10
    msg_zero_len equ $ - msg_zero
    msg_bad     db 10, "Invalid choice. Please pick A, S, M or D.", 10
    msg_bad_len equ $ - msg_bad

    msg_again   db 10, "Do you want to try again (Y/N) "
    msg_again_len equ $ - msg_again

    newline     db 10

section .bss
    buf     resb 16
    numbuf  resb 12
    num1    resd 1
    num2    resd 1
    quot    resd 1
    rem     resd 1

section .text
    global _start

_start:
main_menu:
    print clr, clr_len
    print menu, menu_len

    call read_char
    cmp al, 'A'
    je  do_add
    cmp al, 'S'
    je  do_sub
    cmp al, 'M'
    je  do_mul
    cmp al, 'D'
    je  do_div

    print msg_bad, msg_bad_len
    jmp ask_again

do_add:
    call get_numbers
    mov eax, [num1]
    add eax, [num2]
    push eax
    print msg_sum, msg_sum_len
    pop eax
    call print_number
    print newline, 1
    jmp ask_again

do_sub:
    call get_numbers
    mov eax, [num1]
    sub eax, [num2]
    push eax
    print msg_diff, msg_diff_len
    pop eax
    call print_number
    print newline, 1
    jmp ask_again

do_mul:
    call get_numbers
    mov eax, [num1]
    imul eax, [num2]
    push eax
    print msg_prod, msg_prod_len
    pop eax
    call print_number
    print newline, 1
    jmp ask_again

do_div:
    call get_numbers
    cmp dword [num2], 0
    je  div_zero
    mov eax, [num1]
    xor edx, edx
    div dword [num2]
    mov [quot], eax
    mov [rem], edx
    print msg_quot, msg_quot_len
    mov eax, [quot]
    call print_number
    print msg_rem, msg_rem_len
    mov eax, [rem]
    call print_number
    print newline, 1
    jmp ask_again

div_zero:
    print msg_zero, msg_zero_len

ask_again:
    print msg_again, msg_again_len
    call read_char
    cmp al, 'Y'
    je  main_menu

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80

get_numbers:
    print msg_first, msg_first_len
    call read_number
    mov [num1], eax
    print msg_second, msg_second_len
    call read_number
    mov [num2], eax
    ret

read_char:
    mov eax, 3
    mov ebx, 0
    mov ecx, buf
    mov edx, 16
    int 0x80
    test eax, eax
    jz  exit_program
    mov al, [buf]
    and al, 0xDF
    ret

read_number:
    mov eax, 3
    mov ebx, 0
    mov ecx, buf
    mov edx, 16
    int 0x80
    test eax, eax
    jz  exit_program
    xor eax, eax
    xor esi, esi
.next_digit:
    movzx ebx, byte [buf + esi]
    cmp bl, '0'
    jb  .done
    cmp bl, '9'
    ja  .done
    imul eax, 10
    sub bl, '0'
    add eax, ebx
    inc esi
    cmp esi, 2
    jb  .next_digit
.done:
    ret

print_number:
    xor esi, esi
    cmp eax, 0
    jge .convert
    neg eax
    mov esi, 1
.convert:
    mov edi, numbuf + 11
    mov ebx, 10
.divloop:
    xor edx, edx
    div ebx
    add dl, '0'
    dec edi
    mov [edi], dl
    test eax, eax
    jnz .divloop
    cmp esi, 1
    jne .show
    dec edi
    mov byte [edi], '-'
.show:
    mov ecx, edi
    mov edx, numbuf + 11
    sub edx, edi
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret