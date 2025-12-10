; Point d'entrée
org 100h
cpu 186

section .text
%include "include/constants.inc"

start:
    mov ax, 0x0012      ; VGA 640x480
    int 0x10

game_loop:
    mov ah, 0x01        ; Touche pressée ?
    int 0x16
    jz .render

    mov ah, 0x00        ; Lire touche
    int 0x16
    
    cmp al, 27          ; Echap
    je exit_game

.render:
    call render_bricks
    
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
