;
;   TIMER
;
;   Compile with flat assembler
;

use32

    org    0x0

    db     'MENUET01'       ; 8 byte id
    dd     0x01             ; header version
    dd     START            ; start of code
    dd     I_END            ; size of image
    dd     0x10000          ; memory for app
    dd     0x0fff0          ; esp
    dd     0x0 , 0x0        ; I_Param , I_Icon

include 'macros.inc'

START:                      ; start of execution

red:

    call draw_window

still:

    mov  eax,23                 ; wait here for event
    mov  ebx,50
    int  0x40

    cmp  eax,1                  ; redraw request ?
    je   red
    cmp  eax,2                  ; key in buffer ?
    je   key
    cmp  eax,3                  ; button in buffer ?
    je   button

    call draw_clock

    jmp  still

  key:                          ; key
    mov  eax,2                  ; just read it and ignore
    int  0x40
    jmp  still

  button:                       ; button
    mov  eax,17                 ; get id
    int  0x40

    dec  ah                     ; button id=1 ?
    jnz  still

    or   eax,-1                 ; close this program
    int  0x40


;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************

draw_clock:
    mov  eax,13
    mov  ebx,10*65536+55
    mov  ecx,30*65536+10
    mov  edx,0xffffff
    int  0x40

    mov  eax,26
    mov  ebx,9
    int  0x40

    xor  edx,edx
    mov  ebx,100
    div  ebx

  push eax

  xor  edx,edx
  mov  ebx,60
  div  ebx
  mov  ecx,eax

  push ecx
  push ecx

  xor  edx,edx
  mov  ebx,60
  div  ebx
  mov  ecx,eax

  mov  eax,47           ; HH
  mov  esi,0x10000000
  mov  ebx,0x00020000
  mov  edx,10*65536+30
  int  0x40

  pop  eax              ; MM
  imul ecx,ecx,60
  sub  eax,ecx
  mov  ecx,eax
  mov  eax,47
  add  edx,20*65536
  int  0x40

  pop  ecx
  pop  eax

  imul ecx,ecx,60
  sub  eax,ecx

  mov  ecx,eax          ; SS
  mov  eax,47
  add  edx,20*65536
  int  0x40

  ret

temp dd ?

draw_window:


    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40

                                   ; DRAW WINDOW
    mov  eax,0                     ; function 0 : define and draw window
    mov  ebx,100*65536+75          ; [x start] *65536 + [x size]
    mov  ecx,100*65536+50          ; [y start] *65536 + [y size]
    mov  edx,0x02ffffff            ; color of work area RRGGBB,8->color gl
    mov  esi,0x805080d0            ; color of grab bar  RRGGBB,8->color gl
    mov  edi,0x005080d0            ; color of frames    RRGGBB
    int  0x40

                                   ; WINDOW LABEL
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov  ecx,0x10ddeeff            ; font 1 & color ( 0xF0RRGGBB )
    mov  edx,labelt                ; pointer to text beginning
    mov  esi,labellen-labelt       ; text length
    int  0x40

                                   ; CLOSE BUTTON
    mov  eax,8                     ; function 8 : define and draw button
    mov  ebx,(75-19)*65536+12      ; [x start] *65536 + [x size]
    mov  ecx,5*65536+12            ; [y start] *65536 + [y size]
    mov  edx,1                     ; button id
    mov  esi,0x6688dd              ; button color RRGGBB
    int  0x40

    call draw_clock

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


; DATA AREA


labelt:
     db   'TIMER'
labellen:

I_END:
