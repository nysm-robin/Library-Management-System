; Library Management System TP079583

%define MAX_ENTRIES  80
%define NAME_LEN     80

section .data
menu	db  10,"--- Library System ---",10
        db  "1. Add Book",10
        db  "2. Delete Book",10
        db  "3. Add Member",10
        db  "4. Delete Member",10
        db  "5. View Data",10
        db  "6. Exit",10
        db  "Choose: "
menuLen	equ $-menu

msgAdd	db  10,"Enter name: "
msgAddLen	equ $-msgAdd

msgDel	db  10,"Enter number to delete: "
msgDelLen	equ $-msgDel

msgView	db  10,"1. Books  2. Members: "
msgViewLen      equ $-msgView

msgBooks	db  10,"-- Books --",10
msgBooksLen     equ $-msgBooks

msgMembers	db  10,"-- Members --",10
msgMembersLen	equ $-msgMembers

msgFull	db  10,"Storage full!",10
msgFullLen	equ $-msgFull

msgEmpty	db  10,"Nothing to delete!",10
msgEmptyLen     equ $-msgEmpty

msgTotalBook    db  10,"Total books: "
msgTotalBookLen equ $-msgTotalBook

msgTotalMember  db  10,"Total members: "
msgTotalMemberLen equ $-msgTotalMember

newline	db  10
colon	db  ": "

section .bss
input           resb 81
digitBuf        resb 8
books           resb MAX_ENTRIES * NAME_LEN
bookCount       resb 1
members         resb MAX_ENTRIES * NAME_LEN
memberCount     resb 1

section .text
global _start

%macro sys_print 2
 mov rax, 1
 mov rdi, 1
 mov rsi, %1
 mov rdx, %2
 syscall
%endmacro

%macro sys_read 0
 mov rax, 0
 mov rdi, 0
 mov rsi, input
 mov rdx, 82
 syscall
%endmacro


strip_newline:
 push rcx
 xor  rcx, rcx
.sn_loop:
 cmp  rcx, 82
 jge  .sn_done
 cmp  byte [input + rcx], 10
 je   .sn_found
 inc  rcx
 jmp  .sn_loop
.sn_found:
 mov  byte [input + rcx], 0
.sn_done:
 pop  rcx
 ret


parse_number:
 xor rax, rax
 xor rcx, rcx
.pn_loop:
 movzx rbx, byte [input + rcx]
 cmp   bl, '0'
 jl    .pn_done
 cmp   bl, '9'
 jg    .pn_done
 sub   bl, '0'
 imul  rax, rax, 10
 add   rax, rbx
 inc   rcx
 jmp   .pn_loop
.pn_done:
 ret

print_number:
 push rbx
 push rcx
 push rdx
 push rsi
 push rdi

 cmp  rax, 0
 jne  .pnum_nonzero
 mov  byte [digitBuf], '0'
 mov  rax, 1
 mov  rdi, 1
 lea  rsi, [digitBuf]
 mov  rdx, 1
 syscall
 jmp  .pnum_done

.pnum_nonzero:
 lea  rsi, [digitBuf + 7]
 mov  byte [rsi], 0
 dec  rsi
 mov  rbx, 10
 xor  rcx, rcx

.pnum_div:
 cmp  rax, 0
 je   .pnum_print
 xor  rdx, rdx
 div  rbx
 add  dl, '0'
 mov  [rsi], dl
 dec  rsi
 inc  rcx
 jmp  .pnum_div

.pnum_print:
 inc  rsi
 mov  rax, 1
 mov  rdi, 1
 mov  rdx, rcx
 syscall

.pnum_done:
 pop  rdi
 pop  rsi
 pop  rdx
 pop  rcx
 pop  rbx
 ret

name_len:
 xor rdx, rdx
.nl_loop:
 cmp  rdx, NAME_LEN
 jge  .nl_done
 cmp  byte [rsi + rdx], 0
 je   .nl_done
 inc  rdx
 jmp  .nl_loop
.nl_done:
 ret


zero_slot:
 push rcx
 push rdi
 mov  rcx, NAME_LEN
.zs_loop:
 mov  byte [rdi], 0
 inc  rdi
 dec  rcx
 jnz  .zs_loop
 pop  rdi
 pop  rcx
 ret

copy_input_to_slot:
 push rsi
 push rcx
 push rdi
 call zero_slot
 xor  rcx, rcx
.ci_loop:
 cmp  rcx, NAME_LEN
 jge  .ci_done
 mov  al, [input + rcx]
 cmp  al, 0
 je   .ci_done
 mov  [rdi + rcx], al
 inc  rcx
 jmp  .ci_loop
.ci_done:
 pop  rdi
 pop  rcx
 pop  rsi
 ret


shift_entries:
 push rax
 push rbx
 push rcx
 push rdx
 push rsi
 push rdi

.se_loop:
 cmp  rbx, rcx
 jge  .se_zero_last

 mov  rax, rbx
 inc  rax
 imul rax, NAME_LEN
 lea  rsi, [r8 + rax]

 mov  rax, rbx
 imul rax, NAME_LEN
 lea  rdi, [r8 + rax]

 push rcx
 mov  rcx, NAME_LEN

.se_copy:
 mov  al, [rsi]
 mov  [rdi], al
 inc  rsi
 inc  rdi
 dec  rcx
 jnz  .se_copy
 pop  rcx

 inc  rbx
 jmp  .se_loop

.se_zero_last:
 mov  rax, rcx
 imul rax, NAME_LEN
 lea  rdi, [r8 + rax]
 call zero_slot

 pop  rdi
 pop  rsi
 pop  rdx
 pop  rcx
 pop  rbx
 pop  rax
 ret

_start:
mov byte [bookCount],   0
mov byte [memberCount], 0

menu_loop:
sys_print menu, menuLen
sys_read

mov al, [input]
cmp al, '1'
je  add_book
cmp al, '2'
je  del_book
cmp al, '3'
je  add_member
cmp al, '4'
je  del_member
cmp al, '5'
je  view_data
cmp al, '6'
je  exit_prog
jmp menu_loop

add_book:
movzx rax, byte [bookCount]
cmp   rax, MAX_ENTRIES
jge   add_book_full

sys_print msgAdd, msgAddLen
sys_read
call  strip_newline

movzx rax, byte [bookCount]
imul  rax, NAME_LEN
lea   rdi, [books + rax]
call  copy_input_to_slot

inc   byte [bookCount]
jmp   menu_loop

add_book_full:
sys_print msgFull, msgFullLen
jmp menu_loop

del_book:
movzx rax, byte [bookCount]
cmp   rax, 0
je    del_book_empty

sys_print msgDel, msgDelLen
sys_read
call  parse_number

movzx rcx, byte [bookCount]
dec   rcx
cmp   rax, rcx
jg    menu_loop

mov   rbx, rax
lea   r8,  [books]
call  shift_entries

dec   byte [bookCount]
jmp   menu_loop

del_book_empty:
sys_print msgEmpty, msgEmptyLen
jmp menu_loop


add_member:
movzx rax, byte [memberCount]
cmp   rax, MAX_ENTRIES
jge   add_member_full

sys_print msgAdd, msgAddLen
sys_read
call  strip_newline

movzx rax, byte [memberCount]
imul  rax, NAME_LEN
lea   rdi, [members + rax]
call  copy_input_to_slot

inc   byte [memberCount]
jmp   menu_loop

add_member_full:
sys_print msgFull, msgFullLen
jmp menu_loop

del_member:
movzx rax, byte [memberCount]
cmp   rax, 0
je    del_member_empty

sys_print msgDel, msgDelLen
sys_read
call  parse_number

movzx rcx, byte [memberCount]
dec   rcx
cmp   rax, rcx
jg    menu_loop

mov   rbx, rax
lea   r8,  [members]
call  shift_entries

dec   byte [memberCount]
jmp   menu_loop

del_member_empty:
sys_print msgEmpty, msgEmptyLen
jmp menu_loop

view_data:
sys_print msgView, msgViewLen
sys_read

cmp byte [input], '1'
je  view_books
cmp byte [input], '2'
je  view_members
jmp menu_loop

view_books:
sys_print msgBooks, msgBooksLen
mov r12, 0

vb_loop:
movzx r13, byte [bookCount]
cmp   r12, r13
je    vb_stats

mov  rax, r12
call print_number
sys_print colon, 2

mov  rax, r12
imul rax, NAME_LEN
lea  rsi, [books + rax]
call name_len
mov  rax, 1
mov  rdi, 1
syscall
sys_print newline, 1

inc  r12
jmp  vb_loop

vb_stats:
sys_print msgTotalBook, msgTotalBookLen
movzx rax, byte [bookCount]
call  print_number
sys_print newline, 1
jmp   menu_loop

view_members:
sys_print msgMembers, msgMembersLen
mov r12, 0

vm_loop:
movzx r13, byte [memberCount]
cmp   r12, r13
je    vm_stats

mov  rax, r12
call print_number
sys_print colon, 2

mov  rax, r12
imul rax, NAME_LEN
lea  rsi, [members + rax]
call name_len
mov  rax, 1
mov  rdi, 1
syscall
sys_print newline, 1

inc  r12
jmp  vm_loop

vm_stats:
sys_print msgTotalMember, msgTotalMemberLen
movzx rax, byte [memberCount]
call  print_number
sys_print newline, 1
jmp   menu_loop

exit_prog:
mov rax, 60
xor rdi, rdi
syscall
