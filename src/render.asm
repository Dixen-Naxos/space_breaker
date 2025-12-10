render_bricks:
    pusha

    mov bx, brick_map
    xor di, di          ; ligne

.loop_rows:
    cmp di, BRICK_ROWS
    jge .end_render

    xor si, si          ; colonne

.loop_cols:
    cmp si, BRICK_COLS
    jge .next_row

    ; Index = ligne * cols + col
    mov ax, di
    mov cx, BRICK_COLS
    mul cx
    add ax, si
    
    ; Verif brique
    push bx
    mov bx, brick_map
    add bx, ax
    mov al, [bx]        ; AL = Couleur de la brique (0 = vide)
    pop bx

    cmp al, 0
    je .next_col        ; Si 0 (vide), on passe

    ; Pos X
    mov bx, ax          ; Sauvegarder la couleur dans BL (via AX -> BX) temporairement
    mov bl, al          ; BL = couleur

    mov ax, BRICK_WIDTH
    add ax, BRICK_PADDING
    mul si
    mov cx, ax          ; CX = X

    ; Pos Y
    mov ax, BRICK_HEIGHT
    add ax, BRICK_PADDING
    mul di
    mov dx, ax          ; DX = Y (AX a été écrasé, mais DX ok)

    ; Dessiner (avec effet d'ombre/bordure)
    push cx
    push dx
    
    mov al, bl          ; Récupérer la couleur
    call draw_fancy_brick

    pop dx
    pop cx

.next_col:
    inc si
    jmp .loop_cols

.next_row:
    inc di
    jmp .loop_rows

.end_render:
    popa
    ret

; Dessine une brique avec un effet de relief simple
; Entrées : CX=X, DX=Y, AL=Couleur principale
draw_fancy_brick:
    pusha

    mov [var_rect_x], cx
    mov [var_rect_y], dx
    mov [var_rect_color], al

    ; 1. Corps principal
    mov word [var_w], BRICK_WIDTH
    mov word [var_h], BRICK_HEIGHT
    call draw_rect_filled

    ; 2. Bordure haute/gauche (plus claire -> blanc/brillant)
    ; Pour simplifier en 16 couleurs, on utilise blanc (15) ou gris clair (7)
    mov al, 15          ; Blanc
    mov [var_rect_color], al
    
    ; Ligne haut
    mov word [var_w], BRICK_WIDTH
    mov word [var_h], 2
    call draw_rect_filled
    
    ; Ligne gauche
    mov cx, [var_rect_x]
    mov dx, [var_rect_y]
    mov word [var_w], 2
    mov word [var_h], BRICK_HEIGHT
    call draw_rect_filled

    ; 3. Bordure bas/droite (plus sombre -> noir/gris foncé)
    ; On dessine en bas et à droite
    mov al, 8           ; Gris foncé
    mov [var_rect_color], al

    ; Ligne bas
    mov cx, [var_rect_x]
    mov dx, [var_rect_y]
    add dx, BRICK_HEIGHT
    sub dx, 2           ; Remonter de 2 pixels
    mov word [var_w], BRICK_WIDTH
    mov word [var_h], 2
    call draw_rect_filled

    ; Ligne droite
    mov cx, [var_rect_x]
    add cx, BRICK_WIDTH
    sub cx, 2           ; Reculer de 2 pixels
    mov dx, [var_rect_y]
    mov word [var_w], 2
    mov word [var_h], BRICK_HEIGHT
    call draw_rect_filled

    popa
    ret

; Dessine un rectangle plein générique
; Utilise var_rect_x, var_rect_y, var_rect_color, var_w, var_h
draw_rect_filled:
    pusha
    
    xor bx, bx          ; y counter

.loop_y:
    cmp bx, [var_h]
    jge .end
    
    xor si, si          ; x counter

.loop_x:
    cmp si, [var_w]
    jge .next_line
    
    mov ah, 0x0C
    mov al, [var_rect_color]
    mov bh, 0
    
    mov cx, [var_rect_x]
    add cx, si
    
    mov dx, [var_rect_y]
    add dx, bx
    
    int 0x10
    
    inc si
    jmp .loop_x

.next_line:
    inc bx
    jmp .loop_y

.end:
    popa
    ret

section .bss
    var_rect_x resw 1
    var_rect_y resw 1
    var_rect_color resb 1
    var_w resw 1
    var_h resw 1
