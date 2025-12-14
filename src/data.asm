section .data

    brick_map:
        db 4, 1, 6, 2, 14, 14, 2, 6, 1, 4 
        db 4, 0, 6, 0, 14, 14, 0, 6, 0, 4
        db 4, 1, 6, 2, 14, 14, 2, 6, 1, 4
        db 0, 1, 6, 0, 0, 0, 0, 6, 1, 0
        db 4, 1, 6, 2, 14, 14, 2, 6, 1, 4

    paddle_x dw 280     ; (640 - 80) / 2 = 280

    msg_quit db 'ESC: Quitter', 0
    msg_quit_len equ $ - msg_quit
