;
;   EXAMPLE APPLICATION
;
;   Compile with FASM for Menuet
;

use32

               org    0x0

               db     'MENUET01'              ; 8 byte id
               dd     0x01                    ; header version
               dd     START                   ; start of code
               dd     I_END                   ; size of image
               dd     0x100000                ; memory for app
               dd     0x7fff0                 ; esp
               dd     0x0 , 0x0               ; I_Param , I_Icon

include 'macros.inc'

START:                          ; start of execution

    call draw_window            ; at first, draw the window

still:

    mov  eax,10                 ; wait here for event
    int  0x40

    cmp  eax,1                  ; redraw request ?
    je   red
    cmp  eax,2                  ; key in buffer ?
    je   key
    cmp  eax,3                  ; button in buffer ?
    je   button

    jmp  still

  red:                          ; redraw
    call draw_window
    jmp  still

  key:                          ; key
    mov  eax,2                  ; just read it and ignore
    int  0x40
    jmp  still

  button:                       ; button
    mov  eax,17                 ; get id
    int  0x40

    cmp  ah,1                   ; button id=1 ?
    jne  noclose
    mov  eax,-1                 ; close this program
    int  0x40
  noclose:

    jmp  still


;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************

draw_bar:

    pusha
    add  ebx,2
    add  ecx,2
    push edx
    push ebx
    push ecx

    sub  ebx,2*65536-2
    sub  ecx,2*65536-2
    mov  eax,13
    int  0x40

    mov  eax,38
    mov  ebx,[esp+4]
    mov  ecx,[esp+0]
    add  bx,[esp+6]
    mov  cx,[esp+2]
    sub  ebx,1*65536+1
    sub  ecx,1*65536+1
    mov  edx,0x000000
    int  0x40
    sub  ebx,1*65536-1
    sub  ecx,1*65536+1
    mov  edx,0x4080c0
    int  0x40

    mov  eax,38
    mov  ebx,[esp+4]
    mov  ecx,[esp+0]
    mov  bx,[esp+6]
    add  cx,[esp+2]
    sub  ebx,1*65536+1
    sub  ecx,1*65536+1
    mov  edx,0x000000
    int  0x40
    sub  ebx,1*65536+1
    sub  ecx,1*65536-1
    mov  edx,0x4080c0
    int  0x40

    mov  eax,38
    mov  bx,[esp+6]
    mov  cx,[esp+0]
    add  cx,[esp+2]
    sub  cx,2
    push bx
    push cx
    shl  ebx,16
    shl  ecx,16
    pop  cx
    pop  bx
    add  bx,[esp+4]
    sub  bx,2
    add  cx,0
    mov  edx,0xcccccc
    int  0x40

    mov  eax,38
    mov  bx,[esp+4]
    add  bx,[esp+6]
    sub  bx,2
    mov  cx,[esp+2]
    push bx
    push cx
    shl  ebx,16
    shl  ecx,16
    pop  cx
    pop  bx
    add  cx,[esp+0]
    sub  cx,2
    mov  edx,0xcccccc
    int  0x40


    add  esp,4*3
    popa
    ret


draw_window:

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40

                                   ; DRAW WINDOW
    mov  eax,0                     ; function 0 : define and draw window
    mov  ebx,100*65536+320         ; [x start] *65536 + [x size]
    mov  ecx,100*65536+220         ; [y start] *65536 + [y size]
    mov  edx,0x0299aaff            ; color of work area RRGGBB,8->color gl
    mov  esi,0x808899ff            ; color of grab bar  RRGGBB,8->color gl
    mov  edi,0x008899ff            ; color of frames    RRGGBB
    int  0x40

                                   ; WINDOW LABEL
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov  ecx,0x00ddeeff            ; color of text RRGGBB
    mov  edx,labelt                ; pointer to text beginning
    mov  esi,labellen-labelt       ; text length
    int  0x40

                                   ; CLOSE BUTTON
    mov  eax,8                     ; function 8 : define and draw button
    mov  ebx,(320-19)*65536+12     ; [x start] *65536 + [x size]
    mov  ecx,5*65536+12            ; [y start] *65536 + [y size]
    mov  edx,1                     ; button id
    mov  esi,0x6677cc              ; button color RRGGBB
    int  0x40

    mov  ebx,20*65536+280
    mov  ecx,60*65536+10*8+6
    mov  edx,0xffffff
    call draw_bar

    mov  ebx,118*65536+100
    mov  ecx,163*65536+12
    mov  edx,0xffffff
    call draw_bar
    add  ecx,10*2*65536
    call draw_bar


    mov  ebx,25*65536+35           ; draw info text with function 4
    mov  ecx,0x224466
    mov  edx,text
    mov  esi,40
  newline:
    mov  eax,4
    int  0x40
    add  ebx,10
    add  edx,40
    cmp  [edx],byte 'x'
    jne  newline


    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


; DATA AREA


text:
    db '/                                       '
    db '                                        '
    db '                                        '
    db '  FLOPPY                                '
    db '  RAMDISK                               '
    db '  HD                                    '
    db '  CD                                    '
    db '  DVD                                   '
    db '                                        '
    db '                                        '
    db '                                        '
    db '                                        '
    db '                                        '
    db ' FILENAME:                              '
    db '                                        '
    db ' DISPLAY TYPES: *.*                     '
    db '                                        '

    db 'x <- END MARKER, DONT DELETE            '


labelt:
     db   'BROWSE'
labellen:

I_END:
