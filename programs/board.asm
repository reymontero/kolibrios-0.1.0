;
;   DEBUG BOARD for APPLICATIONS and KERNEL DEVELOPMENT
;
;   See f63
;
;   Compile with FASM for Menuet
;

   use32
   org    0x0
   db     'MENUET01'              ; 8 byte id
   dd     0x01                    ; header version
   dd     START                   ; start of code
   dd     I_END                   ; size of image
   dd     0x1000                  ; memory for app (4 Kb)
   dd     0x1000                  ; esp
   dd     0x0 , 0x0               ; I_Param , I_Icon
include 'macros.inc'

MAXSTRINGS = 12

xpos  dd 0x0
ypos  dd 11

START:                          ; start of execution

     mov  ecx,1024
    flush:
     mov  eax,63
     mov  ebx,2
     int  0x40
     loop flush

     mov  [tmp],'x'

     mov  eax,14
     int  0x40
     and  eax,0xffff0000
     sub  eax,400 shl 16
     add  eax,400
     mov  [xstart],eax

     call draw_window

still:

    mov  eax,23                 ; wait here for event
    mov  ebx,1
    int  0x40

    cmp  eax,1                  ; redraw request ?
    je   red
    cmp  eax,2                  ; key in buffer ?
    je   key
    cmp  eax,3                  ; button in buffer ?
    je   button

    mov  eax,63
    mov  ebx,2
    int  0x40

    cmp  ebx,1
    jne  still

  new_data:

    cmp  al,13
    jne  no13
    mov  [xpos],0
    jmp  new_check
   no13:
    cmp  al,10
    jne  no10
    inc  [ypos]
    cmp  [ypos],MAXSTRINGS
    jbe  noypos
    mov  [ypos],MAXSTRINGS
    mov  esi,text+80
    mov  edi,text
    mov  ecx,80*(MAXSTRINGS+1)
    cld
    rep  movsb
  noypos:
    jmp  new_check
  no10:

    mov  esi,[ypos]
    imul esi,80
    add  esi,[xpos]
    mov  [text+esi],al
    inc  [xpos]
    cmp  [xpos],80
    jb   xposok
    mov  [xpos],79
  xposok:

  new_check:

    mov  eax,63
    mov  ebx,2
    int  0x40

    cmp  ebx,1
    je   new_data

    call draw_window

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


draw_window:

    mov  eax,48
    mov  ebx,3
    mov  ecx,sc
    mov  edx,sizeof.system_colors
    int  0x40

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40

                                   ; DRAW WINDOW
    mov  eax,0                     ; function 0 : define and draw window
;   mov  ebx,50*65536+400          ; [x start] *65536 + [x size]
    mov  ebx,[xstart]
    mov  ecx,170                   ; [y start] *65536 + [y size]
    mov  edx,[sc.work]             ; color of work area RRGGBB,8->color gl
    or   edx,0x02000000
    mov  esi,[sc.grab]             ; color of grab bar  RRGGBB,8->color gl
    or   esi,0x80000000
    mov  edi,[sc.frame]            ; color of frames    RRGGBB
    int  0x40

                                   ; WINDOW LABEL
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov  ecx,[sc.grab_text]        ; color of text RRGGBB
    or   ecx,0x10000000
    mov  edx,header                ; pointer to text beginning
    mov  esi,_header_len           ; text length
    int  0x40
                                   ; CLOSE BUTTON
    mov  eax,8                     ; function 8 : define and draw button
    mov  ebx,(400-19)*65536+12     ; [x start] *65536 + [x size]
    mov  ecx,5*65536+12            ; [y start] *65536 + [y size]
    mov  edx,1                     ; button id
    mov  esi,[sc.grab_button]      ; button color RRGGBB
    int  0x40

    mov  ebx,15*65536+33           ; draw info text with function 4
    mov  ecx,[sc.work_text]
    mov  edx,text
    mov  esi,80
  newline:
    mov  eax,4
    int  0x40
    add  ebx,10
    add  edx,80
    cmp  [edx],byte 'x'
    jne  newline

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


; DATA AREA


;text:
;    times 80*14 db 32
;    db 'x';  <- END MARKER, DONT DELETE


header:
     db   'GENERAL DEBUG & MESSAGE BOARD'
_header_len = $ - header

I_END:
     text rb 80*14
     tmp  db ?
     xstart dd ?
     sc   system_colors