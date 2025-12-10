section .data

    ; 1-15 = couleur brique (VGA), 0 = vide
    brick_map:
        db 4, 1, 6, 2, 14, 14, 2, 6, 1, 4  ; Rouge, Bleu, Orange, Vert, Jaune...
        db 4, 0, 6, 0, 14, 14, 0, 6, 0, 4
        db 4, 1, 6, 2, 14, 14, 2, 6, 1, 4
        db 0, 1, 6, 0, 0, 0, 0, 6, 1, 0
        db 4, 1, 6, 2, 14, 14, 2, 6, 1, 4
