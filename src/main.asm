; Point d'entrée
org 100h
cpu 186

section .text
%include "include/constants.inc"

start:
    mov ax, 0x0012      ; VGA 640x480
    int 0x10

    call draw_ui
    call render_bricks
    call draw_paddle

game_loop:
    mov ah, 0x01        ; Touche pressée ?
    int 0x16
    jz delay_frame      ; Si rien, on attend un peu

    mov ah, 0x00        ; Lire touche
    int 0x16
    
    cmp al, 27          ; Echap
    je exit_game

    cmp al, 'a'         ; 'a'
    je move_left
    cmp ah, 0x4B        ; Flèche gauche
    je move_left

    cmp al, 'd'         ; 'd'
    je move_right
    cmp ah, 0x4D        ; Flèche droite
    je move_right

    jmp game_loop

move_left:
    call clear_paddle
    mov ax, [paddle_x]
    sub ax, PADDLE_SPEED
    cmp ax, 0
    jge update_paddle
    mov ax, 0           ; Limite gauche
    jmp update_paddle

move_right:
    call clear_paddle
    mov ax, [paddle_x]
    add ax, PADDLE_SPEED
    mov bx, SCREEN_WIDTH
    sub bx, PADDLE_WIDTH
    cmp ax, bx
    jle update_paddle
    mov ax, bx          ; Limite droite

update_paddle:
    mov [paddle_x], ax
    call draw_paddle
    jmp game_loop

delay_frame:
    mov cx, 0xFFFF      ; Pause
.wait_loop:
    loop .wait_loop
    jmp game_loop

exit_game:
    mov ax, 0x0003      ; Mode texte
    int 0x10

    mov ax, 0x4C00      ; Quitter
    int 0x21

%include "src/data.asm"
%include "src/render.asm"
