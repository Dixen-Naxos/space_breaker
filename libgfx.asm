;****************************************
;   TJO libgfx  (c) 2021
; =======================================
; Librairie de dessin
;
;  v 1.0  T. JOUBERT     Nov 2014
;  v 2.0  T. JOUBERT  11 Nov 2020
;  v 2.1  T. JOUBERT  28 Nov 2021
;  v 2.2  T. JOUBERT  04 Dec 2021
;  v 2.3  T. JOUBERT  27 Dec 2021
;  v 2.4  T. JOUBERT  08 Nov 2025
;****************************************;

;==== exported functions ====
public Video13h   
public VideoVGA      
public VideoCMD
public ClearScreen
public CharLine     ; DX>>
public WaitKey      ; >>userinput
public PeekKey      ; >>userinput
public PaintPxl     ; pX, pY, col>>
public ReadPxl      ; >> rdcol
public BigPixl      ; pX, pY, col>>
public sleep        ; tempo>>
public FillShape    ; CX, DX>>
public Horizontal   ; CX, DX, col, BX>>
public Vertical     ; CX, DX, col, BX>>
public Rectangle    ; Rx, Ry, Rw, Rh, col>>
public fillRect     ; Rx, Ry, Rw, Rh, col>>
public drawIcon     ; iX, iY, BX>>
public drawIconBig  ; iX, iY, BX>>
;==== exported variables ====
public userinput ; <<kbhit
public col       ; >>PaintPxl
public rdcol     ; 
public pX
public pY
public Rx        ; >>Rectangle, etc.
public Ry
public Rw
public Rh
public iX        ; >>drawIcon
public iY
public tempo     ; >>sleep
;=============================

donnees segment public        ; *************Segment de donnees
; sortie sub ReadKey, PeekKey ===============
userinput DB 0   ; hit key
; parametres sub paintPxl====================
pX        DW 0    ; X pixel
pY        DW 0    ; Y pixel
col       DB 0   ; color pixel
; sortie sub readPxl====================
rdcol     DB 0   ; pixel color
; parametres sub Sleep=======================
tempo     DW 0   ; duration 
; parametres sub drawIcon====================
iX        DW 0   ; X icon origin
iY        DW 0   ; Y icon origin

; variable sub GotoGFX, GotoCMD -------------
BaseVMode DB 0   ; memo mode video
; variables sub drawIcon---------------------
maxX      DW 0   ; internal max-X
nbPix     DW 0   ; internal Pixl cnter
totPix    DW 0   ; internal Pixel Total
; variables sub fillShape--------------------
fCX       DW 0   ; memo X fill
; ===========================================

; parametres sub drawRect & fillRect=========
Rx        DW 0      ; X origin
Ry        DW 0      ; Y origin
Rw        DW 0      ; Width
Rh        DW 0      ; Height
colR      DB 0      ; color
; ============================================

donnees ends

code    segment public        ; *****************Segment de code
assume  cs:code,ds:donnees

;------------Sub GotoGFX-----------
; out: mode CMD dans BaseVMode
Video13h:
    mov AH, 0Fh
    int 10h
    and AL, 0BFh
    mov BaseVMode, AL
    mov AL, 13h
    mov AH, 0
    int 10h
    ret
;------------Sub GotoVGA-----------
; out: mode CMD dans BaseVMode
VideoVGA:
    mov AH, 0Fh
    int 10h
    and AL, 0BFh
    mov BaseVMode, AL
    mov Ax, 4F02h
    mov BX, 101h
    int 10h
    ret
;------------Sub GotoCMD-----------
VideoCMD:
    mov AL, BaseVMode
    mov AH, 0
    int 10h
    ret
;------------Sub ClearScreen-----------
ClearScreen:
    mov AH, 0Fh
    int 10h
    and AL, 0BFh
    mov AH, 0h
    int 10h
    ret
;------------Sub Charline    -----------
; in: DX pointe sur la chaine
CharLine:
    mov AH, 9
    int 21h
    mov DL, 10
    mov AH, 2
    int 21h
    ret
;------------Attente Clavier-----------
WaitKey:
    mov AH,07h
    int 21H
    mov userinput, AL
    ret
;---------- Lecture Clavier -----------
; >> userinput
PeekKey:
    mov AH, 06h
    mov DL, 0FFh 
    int 21h
    mov userinput, AL
    ret
;------------Sub PaintPxl-------------
PaintPxl:
    mov AH, 0Ch
    mov CX, pX      ; nouveau
    mov DX, pY
    mov AL, col
    int 10h
    ret
;------------Sub ReadPxl-------------
ReadPxl:
    mov AH, 0Dh
    mov CX, pX      ; nouveau
    mov DX, pY
    int 10h
    mov rdcol, AL
    ret
;------------sleep routine -------------
; << tempo
Sleep:
    mov AX, tempo       ; multiplier
axloop:
    mov BX, 0FFFh
bxloop:
    dec BX
    cmp BX, 0
    jne bxloop ; ==-> inner loop
    dec AX
    cmp AX, 0
    jne axloop ; ==-> outer loop
    ret
;------------Sub BigPixl-------------
; in: CX, DX, AL
BigPixl:
    mov AH, 0Ch
    mov CX, pX
    mov DX, pY
    mov AL, col
    int 10h     ; pixel 1
    inc DX      ; pixel 2
    int 10h
    inc CX      ; pixel 3
    int 10h
    dec DX      ; pixel 4
    int 10h
    ret
;------------Sub fillShape -------------
FillShape:
    mov fCX, CX     ; memo start
    mov pY, DX
fillline:
    inc DX          ; next line 
    mov AH, 0Dh     ; read pixel
    int 10h
    cmp AL, 0       ; black ?
    jne done        ; first pixel in line is non black
before:
    mov col, 31
    dec CX          ; go left
    mov AH, 0Dh     ; read pixel
    int 10h
    cmp AL, 0       ; black
    je before
horiz:
    inc CX
    mov AH, 0Dh     ; read pixel
    int 10h
    cmp AL, 0       ; non black
    jne nextline
    inc col
    cmp col, 104
    jnz fillpxl
    mov col,32
fillpxl:
    mov AL, col
    mov AH, 0Ch
    int 10h
    jmp horiz       ; fill current line
nextline:
    mov CX, fCX     ; rewind CX
    jmp fillline
done:
    mov CX, pX
    mov DX, pY
    ret
;---------------- ligne horizontale -----------
; << CX, DX, BX, col
horizontal:
    mov AH, 0Ch
    mov AL, col
loopH:
    int 10h
    inc CX
    dec BX
    CMP BX, 0
    jne loopH
    RET
;---------------- ligne verticale -----------
; << CX, DX, BX, col
vertical:
    mov AH, 0Ch
    mov AL, col
loopV:
    int 10h
    inc DX
    dec BX
    CMP BX, 0
    jne loopV
    RET
;---------------- Rectangle ----------------
; << Rx, Ry, Rw, Rh
Rectangle:
    mov AL, col
    mov CX, Rx
    mov DX, Ry
    mov BX, Rw
    call horizontal
    mov CX, Rx
    mov DX, Ry
    mov BX, Rh
    call vertical
    mov CX, Rx
    add CX, Rw
    mov DX, Ry
    mov BX, Rh
    call vertical
    mov CX, Rx
    mov DX, Ry
    add DX, Rh
    mov BX, Rw
    call horizontal
    RET
;----------------- Rectangle plein ------------
; << Rx, Ry, Rw, Rh, color
fillRect:
    mov AH, 0Ch
    mov AL, col
    mov DX, Ry
    add DX, Rh
bclVertic:
    mov CX, Rx
    add CX, Rw
bclHoriz:
    int 10h
    dec CX
    cmp CX, Rx
    jge bclHoriz
    dec DX
    cmp DX, Ry
    jge bclVertic
    RET
; ------------------- draw icon ------------------
; << iX, iY, BX
drawIcon:
    mov AX, iX      ; prepare limite en X
    add AX, [BX]    ; ajoute nbcol
    mov maxX, AX    ; memorise dans maxX
    inc BX          ; BX saute un Word
    inc BX
    mov AX, [BX]    ; nb total pixels
    mov totPix, AX  ; memorise dans totPix
    inc BX          ; BX saute un Word
    inc BX
    mov AX, 0
    mov nbPix, AX   ; compteur pixels
    mov CX, iX      ; position init
    mov DX, iY
dessin:
    mov AL, byte ptr[BX] ; couleur pixel
    mov AH, 0CH      ; BIOS dessin
    int 10h          ; dessin

    inc BX           ; pixel suivant
    inc CX
    cmp CX, maxX     ; fin de ligne ?
    jl sameline
    mov CX, iX       ; CR
    inc DX           ; LF
sameline:
    inc nbPix
    mov AX, nbPix
    cmp AX, totPix   ; dernier pixel ?
    jnz dessin
    ret
; ------------------- draw icon ------------------
; << iX, iY, BX
drawIconBig:
    mov AX, iX      ; prepare limite en X
    add AX, [BX]    ; ajoute nbcol x 2
    add AX, [BX]
    mov maxX, AX    ; memorise dans maxX
    inc BX          ; BX saute un Word
    inc BX
    mov AX, [BX]    ; nb total pixels
    mov totPix, AX  ; memorise dans totPix
    inc BX          ; BX saute un Word
    inc BX
    mov AX, 0
    mov nbPix, AX   ; compteur pixels
    mov CX, iX      ; position init
    mov DX, iY
dessbig:
    mov AL, byte ptr[BX] ; couleur pixel
    mov AH, 0CH      ; BIOS dessin
    int 10h     ; pixel 1
    inc DX      ; pixel 2
    int 10h
    inc CX      ; pixel 3
    int 10h
    dec DX      ; pixel 4
    int 10h

    inc BX           ; pixel suivant
    inc CX
    cmp CX, maxX     ; fin de ligne ?
    jl samelibig
    mov CX, iX       ; CR
    inc DX           ; LF x 2
    inc DX          
samelibig:
    inc nbPix
    mov AX, nbPix
    cmp AX, totPix   ; dernier pixel ?
    jnz dessbig
    ret
;------------------------------------------
code    ends                   ; Fin du segment de code
end
