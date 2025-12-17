.286
code segment public
    assume cs:code, ds:donnees, ss:pile

; =============================================================
; Declaration des symboles externes de LIBGFX
; =============================================================
extrn VideoVGA:proc
extrn VideoCMD:proc
extrn ClearScreen:proc
extrn PeekKey:proc
extrn sleep:proc
extrn fillRect:proc
extrn CharLine:proc

extrn userinput:byte
extrn col:byte
extrn Rx:word
extrn Ry:word
extrn Rw:word
extrn Rh:word
extrn tempo:word

; =============================================================
; Segment de PILE
; =============================================================
pile segment stack
    dw 100h dup(?)
pile ends

; =============================================================
; Segment de DONNEES
; =============================================================
donnees segment public
    ; ============ CONSTANTES ============
    SCREEN_WIDTH    equ 640
    SCREEN_HEIGHT   equ 480
    BRICK_WIDTH     equ 50
    BRICK_HEIGHT    equ 20
    BRICK_PADDING   equ 5
    BRICK_ROWS      equ 5
    BRICK_COLS      equ 10
    
    COLOR_BG        equ 0      ; Noir
    PADDLE_WIDTH    equ 80
    PADDLE_HEIGHT   equ 10
    PADDLE_Y        equ 450
    PADDLE_SPEED    equ 20
    PADDLE_COLOR    equ 9      ; Bleu clair
    TEXT_COLOR      equ 15     ; Blanc
    
    BALL_SIZE       equ 6
    BALL_COLOR      equ 14     ; Jaune
    
    ; ============ VARIABLES JEU ============
    brick_map       db 4, 1, 6, 2, 14, 14, 2, 6, 1, 4
                    db 4, 0, 6, 0, 14, 14, 0, 6, 0, 4
                    db 4, 1, 6, 2, 14, 14, 2, 6, 1, 4
                    db 0, 1, 6, 0, 0, 0, 0, 6, 1, 0
                    db 4, 1, 6, 2, 14, 14, 2, 6, 1, 4

    paddle_x        dw 280
    
    ball_x          dw 320
    ball_y          dw 400
    ball_vx         dw 4
    ball_vy         dw -4
    
    ; Variable locale pour calculs
    loc_x           dw 0
    loc_y           dw 0
    loc_w           dw 0
    loc_h           dw 0
    loc_col         db 0
    
    msg_quit        db "ESC: Quitter$" ; Termine par $ pour DOS si besoin, mais on utilise libgfx

donnees ends

; =============================================================
; Segment de CODE
; =============================================================

MAIN PROC
    ; Initialisation du segment de donnees
    mov ax, donnees
    mov ds, ax

    ; Initialisation Video via LIBGFX (VGA 640x480)
    call VideoVGA

    ; Initialisation jeu
    call draw_ui
    call render_bricks
    call draw_paddle
    call draw_ball

game_loop:
    mov tempo, 10 ; Vitesse du jeu
    call sleep
    
    call move_ball
    call PeekKey
    
    cmp userinput, 27          ; Echap
    je exit_game

    cmp userinput, 'q'         ; 'q' (gauche)
    je move_left
    cmp userinput, 'a'         ; 'a' (gauche azerty)
    je move_left
    
    cmp userinput, 'd'         ; 'd' (droite)
    je move_right

    jmp game_loop

move_left:
    call clear_paddle
    mov ax, paddle_x
    sub ax, PADDLE_SPEED
    cmp ax, 0
    jge update_paddle_l
    mov ax, 0           ; Limite gauche
update_paddle_l:
    jmp update_paddle_common

move_right:
    call clear_paddle
    mov ax, paddle_x
    add ax, PADDLE_SPEED
    mov bx, SCREEN_WIDTH
    sub bx, PADDLE_WIDTH
    cmp ax, bx
    jle update_paddle_r
    mov ax, bx          ; Limite droite
update_paddle_r:
    jmp update_paddle_common

update_paddle_common:
    mov paddle_x, ax
    call draw_paddle
    jmp game_loop

exit_game:
    call VideoCMD

    ; Quitter vers le DOS
    mov ah, 4Ch
    xor al, al
    int 21h
MAIN ENDP

; =============================================
;                PROCEDURES
; =============================================

check_screen_edges PROC
    pusha

    ; Predict next position
    mov ax, ball_x
    add ax, ball_vx
    cmp ax, 0
    jl bounce_x_edges
    mov bx, ax
    add bx, BALL_SIZE
    cmp bx, SCREEN_WIDTH
    jg bounce_x_edges

    mov ax, ball_y
    add ax, ball_vy
    cmp ax, 0
    jl bounce_y_edges
    mov bx, ax
    add bx, BALL_SIZE
    cmp bx, SCREEN_HEIGHT
    jg bounce_y_edges

    popa
    ret

bounce_x_edges:
    neg ball_vx
    popa
    ret

bounce_y_edges:
    neg ball_vy
    popa
    ret
check_screen_edges ENDP

check_paddle_collision PROC
    pusha

    ; Predict next position
    mov ax, ball_x
    add ax, ball_vx
    mov bx, ax
    mov ax, ball_y
    add ax, ball_vy
    mov cx, ax

    ; Check vertical overlap
    mov ax, cx
    add ax, BALL_SIZE
    cmp ax, PADDLE_Y
    jl skip_paddle
    mov ax, cx
    cmp ax, PADDLE_Y + PADDLE_HEIGHT
    jg skip_paddle

    ; Check horizontal overlap
    mov ax, bx
    add ax, BALL_SIZE
    cmp ax, paddle_x
    jl skip_paddle
    mov ax, bx
    cmp ax, paddle_x + PADDLE_WIDTH
    jg skip_paddle

    ; Collision → bounce vertically
    neg ball_vy

skip_paddle:
    popa
    ret
check_paddle_collision ENDP

; =============================================================
; Check collision with a single brick (specific coordinates)
; Inputs: loc_x = brick X, loc_y = brick Y
;         loc_w = brick width, loc_h = brick height
; =============================================================
check_brick_bounce PROC
    pusha

    ; Ball predicted rectangle
    mov ax, ball_x
    add ax, ball_vx
    mov bx, ax          ; ball left
    mov ax, bx
    add ax, BALL_SIZE
    mov dx, ax          ; ball right

    mov ax, ball_y
    add ax, ball_vy
    mov si, ax          ; ball top
    mov ax, si
    add ax, BALL_SIZE
    mov di, ax          ; ball bottom

    ; Brick rectangle
    mov ax, loc_x
    mov cx, ax          ; brick left
    mov ax, loc_w
    add cx, ax
    mov ax, loc_y
    mov bx, ax          ; brick top
    mov ax, loc_h
    add bx, ax
    mov bp, bx          ; brick bottom

    ; ---------------------------
    ; Check horizontal overlap
    ; ---------------------------
    ; Ball right < brick left?
    cmp dx, loc_x       ; dx = ball right
    jle cb_skip

    ; Ball left > brick right?
    mov ax, loc_x       ; load brick left
    add ax, loc_w       ; ax = brick right
    mov bx, ball_x      ; bx = ball left
    cmp bx, ax
    jge cb_skip

    ; ---------------------------
    ; Check vertical overlap
    ; ---------------------------
    ; Ball bottom < brick top?
    cmp si, loc_y       ; si = ball bottom
    jle cb_skip

    ; Ball top > brick bottom?
    mov ax, loc_y
    add ax, loc_h       ; ax = brick bottom
    mov bx, ball_y      ; bx = ball top
    cmp bx, ax
    jge cb_skip

    ; Collision detected → simple vertical bounce
    neg ball_vy
    ; Optionally destroy brick
    ; mov byte ptr [brick_color_address], 0

cb_skip:
    popa
    ret
check_brick_bounce ENDP


; =============================================================
; Loop through all bricks and check collision
; =============================================================
check_all_bricks PROC
    pusha

    xor di, di          ; row
check_rows:
    cmp di, BRICK_ROWS
    jge end_check_bricks

    xor si, si          ; column
check_cols:
    cmp si, BRICK_COLS
    jge next_row_cb

    ; Index = row * BRICK_COLS + col
    mov ax, di
    mov cx, BRICK_COLS
    mul cx
    add ax, si
    mov bx, offset brick_map
    add bx, ax
    mov al, [bx]        ; brick color
    cmp al, 0
    je next_col_cb      ; empty

    ; Calculate brick position
    mov ax, BRICK_WIDTH
    add ax, BRICK_PADDING
    mul si
    mov loc_x, ax

    mov ax, BRICK_HEIGHT
    add ax, BRICK_PADDING
    mul di
    mov loc_y, ax

    mov loc_w, BRICK_WIDTH
    mov loc_h, BRICK_HEIGHT

    ; Call collision check for this brick
    call check_brick_bounce

next_col_cb:
    inc si
    jmp check_cols

next_row_cb:
    inc di
    jmp check_rows

end_check_bricks:
    popa
    ret
check_all_bricks ENDP


move_ball PROC
    pusha

    ; Erase old ball
    call clear_ball

    ; Check collisions
    call check_screen_edges
    call check_paddle_collision
    call check_all_bricks

    ; Update position
    mov ax, ball_x
    add ax, ball_vx
    mov ball_x, ax
    mov ax, ball_y
    add ax, ball_vy
    mov ball_y, ax

    ; Draw new ball
    call draw_ball

    popa
    ret
move_ball ENDP

draw_ball PROC
    pusha
    mov ax, ball_x
    mov Rx, ax
    mov ax, ball_y
    mov Ry, ax
    mov ax, BALL_SIZE
    mov Rw, ax
    mov Rh, ax

    ; --- Check if ball is within brick area (0-550, 0-125) ---
    mov ax, ball_x
    cmp ax, 0
    jl not_in_bricks
    cmp ax, 550
    jg not_in_bricks

    mov ax, ball_y
    cmp ax, 0
    jl not_in_bricks
    cmp ax, 125
    jg not_in_bricks

    ; Ball is inside brick area
    mov al, 12      ; red
    jmp set_color

not_in_bricks:
    mov al, BALL_COLOR

set_color:
    mov col, al
    call fillRect
    popa
    ret
draw_ball ENDP

clear_ball PROC
    pusha
    mov ax, ball_x
    mov Rx, ax
    mov ax, ball_y
    mov Ry, ax
    mov ax, BALL_SIZE
    mov Rw, ax
    mov Rh, ax
    mov col, COLOR_BG
    call fillRect
    popa
    ret
clear_ball ENDP

render_bricks PROC
    pusha

    mov bx, offset brick_map
    xor di, di          ; ligne (di)

loop_rows:
    cmp di, BRICK_ROWS
    jge end_render

    xor si, si          ; colonne (si)

loop_cols:
    cmp si, BRICK_COLS
    jge next_row

    ; Index = ligne * cols + col
    mov ax, di
    mov cx, BRICK_COLS
    mul cx
    add ax, si

    ; Verif brique a l'adresse brick_map + index
    push bx
    mov bx, offset brick_map
    add bx, ax
    mov al, [bx]        ; AL = Couleur de la brique (0 = vide)
    pop bx

    cmp al, 0
    je next_col        ; Si 0 (vide), on passe

    ; Calcul Pos X -> loc_x
    push ax             ; Sauvegarde index
    mov ax, BRICK_WIDTH
    add ax, BRICK_PADDING
    mul si
    mov loc_x, ax
    pop ax

    ; Calcul Pos Y -> loc_y
    push ax             ; Sauvegarde index
    mov ax, BRICK_HEIGHT
    add ax, BRICK_PADDING
    mul di
    mov loc_y, ax 
    pop ax

    ; Recuperer la couleur
    push bx
    mov bx, offset brick_map
    add bx, ax
    mov al, [bx]
    mov loc_col, al
    pop bx

    ; Dessiner la brique
    call draw_fancy_brick

next_col:
    inc si
    jmp loop_cols

next_row:
    inc di
    jmp loop_rows

end_render:
    popa
    ret
render_bricks ENDP

draw_fancy_brick PROC
    ; Utilise loc_x, loc_y, loc_col
    pusha

    ; 1. Corps principal
    mov ax, loc_x
    mov Rx, ax
    mov ax, loc_y
    mov Ry, ax
    mov ax, BRICK_WIDTH
    mov Rw, ax
    mov ax, BRICK_HEIGHT
    mov Rh, ax
    mov al, loc_col
    mov col, al
    call fillRect

    ; 2. Bordure haute/gauche (Blanc 15)
    mov col, 15

    ; Ligne haut
    mov ax, BRICK_WIDTH
    mov Rw, ax
    mov Rh, 2
    call fillRect

    ; Ligne gauche
    mov ax, loc_x
    mov Rx, ax
    mov ax, loc_y
    mov Ry, ax
    mov Rw, 2
    mov ax, BRICK_HEIGHT
    mov Rh, ax
    call fillRect

    ; 3. Bordure bas/droite (Gris fonce 8)
    mov col, 8

    ; Ligne bas
    mov ax, loc_x
    mov Rx, ax
    mov ax, loc_y
    add ax, BRICK_HEIGHT
    sub ax, 2
    mov Ry, ax
    mov ax, BRICK_WIDTH
    mov Rw, ax
    mov Rh, 2
    call fillRect

    ; Ligne droite
    mov ax, loc_x
    add ax, BRICK_WIDTH
    sub ax, 2
    mov Rx, ax
    mov ax, loc_y
    mov Ry, ax
    mov Rw, 2
    mov ax, BRICK_HEIGHT
    mov Rh, ax
    call fillRect

    popa
    ret
draw_fancy_brick ENDP

draw_paddle PROC
    pusha
    mov ax, paddle_x
    mov Rx, ax
    mov Ry, PADDLE_Y
    mov al, PADDLE_COLOR
    mov col, al
    mov Rw, PADDLE_WIDTH
    mov Rh, PADDLE_HEIGHT
    call fillRect
    popa
    ret
draw_paddle ENDP

clear_paddle PROC
    pusha
    mov ax, paddle_x
    mov Rx, ax
    mov Ry, PADDLE_Y
    mov al, COLOR_BG
    mov col, al
    mov Rw, PADDLE_WIDTH
    mov Rh, PADDLE_HEIGHT
    call fillRect
    popa
    ret
clear_paddle ENDP

draw_ui PROC
    pusha
    ; Positionner le curseur en bas a gauche
    mov ah, 02h
    mov bh, 00h
    mov dh, 29      ; Ligne 29
    mov dl, 1       ; Colonne 1
    int 10h

    ; On utilise l'interruption DOS directe pour la string car CharLine de libgfx fait un saut de ligne
    mov dx, offset msg_quit
    mov ah, 09h
    int 21h

    popa
    ret
draw_ui ENDP

code ends
END MAIN
