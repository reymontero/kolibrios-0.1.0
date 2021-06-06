;
;   Save Ramdisk to HD
;
;   Compile with FASM for Menuet
;

include 'macros.inc'

  use32
  org    0x0

  db     'MENUET01'             ; 8 byte id
  dd     0x01                   ; header version
  dd     START                  ; start of code
  dd     I_END                  ; size of image
  dd     I_END+1024             ; memory for app
  dd     I_END+512              ; esp
  dd     0x0 ; , 0x0            ; I_Param , I_Icon

state dd 0x0

START:                          ; start of execution

    mov  eax,40
    mov  ebx,101b
    int  0x40

red:
     call draw_window

still:
    mov  eax,23                 ; wait here for event
    mov  ebx,50
    int  0x40

    test eax,eax
    je   checkstate

    dec  eax                  ; redraw request ?
    je   red
    dec  eax
    dec  eax                  ; button in buffer ?
    je   button

checkstate:
    cmp  [state],1
    je   exit
    jmp  still


  button:                      ; button
    mov  eax,17                ; get id
    int  0x40

    dec  ah                    ; button id=1 ?
    je   exit

    mov  eax,51
    mov  ebx,1
    mov  ecx,thread
    mov  edx,I_END+1024
    int  0x40

    jmp  still


exit:
    or   eax,-1                    ; close this program
    int  0x40


thread:
    mov eax,18     ; save ramdisk to /hd/1/menuet.img
    mov ebx,6
    int 0x40

    mov  [state],1

    or   eax,-1
    int  0x40

;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************

draw_window:

    mov  eax,12                 ; function 12:tell os about windowdraw
    xor  ebx,ebx                ; 1, start of draw
    inc  ebx
    int  0x40
                                ; DRAW WINDOW
    xor  eax,eax                ; function 0 : define and draw window
    mov  ebx,200*65536+340      ; [x start] *65536 + [x size]
    mov  ecx,200*65536+72       ; [y start] *65536 + [y size]
    mov  edx,0x03dddddd         ; color of work area RRGGBB,8->color gl
    int  0x40
                                ; SAVE BUTTON
    mov  eax,8                  ; function 8 : define and draw button
    mov  ebx,10*65536+320       ; [x start] *65536 + [x size]
    mov  ecx,26*65536+37        ; [y start] *65536 + [y size]
    mov  edx,2                  ; button id
    mov  esi,0x00d07858         ; button color RRGGBB
    int  0x40
                                ; WINDOW LABEL
    mov  eax,4                  ; function 4 : write text to window
    mov  ebx,8*65536+8          ; [x start] *65536 + [y start]
    mov  ecx,0x10ffffff         ; font 1 & color ( 0xF0RRGGBB )
    mov  edx,labelt             ; pointer to text beginning
    mov  esi,labellen-labelt    ; text length
    int  0x40

    mov  ecx,0x10a04828
    mov  ebx,105*65536+35
    mov  edx,btntext
    mov  esi,btntextend-btntext
    int  0x40
    add  ebx,0x00010001
    mov  ecx,0x10dddddd
    int  0x40
    add  ebx,0xfffefffe

    mov  ecx,0x10a04828
    add  ebx,0xffdd000d
    mov  edx,btntxt1
    mov  esi,btntxt1end-btntxt1
    int  0x40
    add  ebx,0x00010001
    mov  ecx,0x10dddddd
    int  0x40

    mov  eax,12                 ; function 12:tell os about windowdraw
    mov  ebx,2                  ; 2, end of draw
    int  0x40

    ret


; DATA AREA

labelt:
     db   'RD2HD'
labellen:

btntext:
     db   'CLICK HERE TO SAVE'
btntextend:

btntxt1:
     db   'RAMDISK TO /HD/1/MENUET.IMG'
btntxt1end:

I_END:
