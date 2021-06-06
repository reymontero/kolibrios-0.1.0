;
;    ICON APPLICATION
;
;    Compile with FASM for Menuet
;

   use32
   org     0x0
   db      'MENUET01'              ; 8 byte id
   dd      0x01                    ; required os
   dd      START                   ; program start
   dd      I_END                   ; program image size
   dd      0x4000                  ; required amount of memory
   dd      0x4000                  ; stack pointer
   dd      I_PARAM


include 'macros.inc'
purge mov

; params 4 xpos 4 ypos 11 iconfile 11 startfile 8 label
;          +0     +4      +8          +19         +30

struc icon_params
 {
  .xpos       dd  ?
  .ypos       dd  ?
  .iconfile   rb  11
  .startfile  rb  11
  .label      rb  8
 }
struct icon_params

START:                          ; start of execution

;    mov  esp,16300

    cmp  [I_PARAM],byte 0
    jne  @f
    or   eax,-1
    int  0x40
  @@:

    call init_all_vars

    mov  eax,40                 ; get also event background change
    mov  ebx,010101b
    int  0x40

    call draw_window


still:

    mov  eax,23                 ; wait here for event with timeout
    mov  ebx,50
    int  0x40

    cmp  eax,1                  ; redraw request ?
    jz   red
    cmp  eax,3                  ; button in buffer ?
    jz   button
    cmp  eax,5                  ; background redraw ?
    jz   check

    mov  [dbl_check],byte 0

    jmp  still


  check:
    call check_icon
    jmp  still

  red:                          ; redraw
    call draw_window
    jmp  still

  button:                       ; button
    mov  eax,17                 ; get id
    int  0x40

    cmp  [dbl_check],byte 0
    jz   .nodbl

    mov  eax,19
    mov  ebx,start_file
    xor  ecx,ecx
    int  0x40

  .nodbl:
    mov  [dbl_check],byte 1

    jmp  still


check_icon:

     pusha

     call get_bgr_info
     call draw_icon

     popa
     ret


init_all_vars:
    mov  eax,[params.xpos]
    sub  eax,0x01010101
    mov  [xpos],eax
    mov  eax,[params.ypos]
    sub  eax,0x01010101
    mov  [ypos],eax

    mov  esi,params.iconfile
    mov  edi,fname
    mov  ecx,11
    cld
    rep  movsb

    mov  esi,params.startfile
    mov  edi,start_file
    mov  ecx,11
    rep  movsb

    mov  esi,params.label
    mov  edi,labelt
    mov  ecx,8
    rep  movsb

    mov  eax,14
    int  0x40
    add  eax,0x00010001
    mov  [scrxy],eax

    call text_length

    mov  eax,6
    mov  ebx,fname
    mov  ecx,0
    mov  edx,-1
    mov  esi,data_from_file
    int  0x40

    call get_bgr_info

    ret


get_bgr_info:
    mov  eax,39
    mov  ebx,4
    int  0x40
    mov  [bgrdrawtype],eax

    mov  eax,39     ; get background size
    mov  ebx,1
    int  0x40
    mov  [bgrxy],eax

    mov  ebx,eax
    shr  eax,16
    and  ebx,0xffff
    mov  [bgrx],eax
    mov  [bgry],ebx
ret
    ; for y = 32 to 0
    ;   for x = 0 to 32
    ;     if (pix[y][x]==0) then
    ;        pix[y][x]=background(x,y);



;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************


draw_window:

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40

                                   ; DRAW WINDOW
    mov  eax,0                     ; function 0 : define and draw window
    mov  ebx,[xpos-2]
    mov  ecx,[ypos-2]
    add  ebx,[yw]                  ; [x start] *65536 + [x size]
    add  ecx,51                    ; [y start] *65536 + [y size]
    mov  edx,0x01000000            ; color of work area RRGGBB,8->color gl
    int  0x40

    mov  eax,8    ; button
    mov  ebx,51
    mov  ecx,50
    mov  edx,1 or 0x40000000
    int  0x40

    call draw_icon

    mov  eax,12
    mov  ebx,2
    int  0x40

    ret


draw_picture:

    pusha

    mov  ebx,[yw]  ; y
    mov  ecx,0     ; x
    mov  esi,data_from_file+54+32*3*33-3
    mov  [pixpos],0

  newb:

    push ebx
    push ecx

    cmp  ebx,10
    jb   yesbpix
    cmp  ebx,42
    jge  yesbpix
    cmp  ecx,32
    jg   yesbpix

    push esi

    mov  esi,data_from_file+54+32*3*33-3
    sub  esi,[pixpos]

    add  [pixpos],3
    mov  eax,[esi]
    and  eax,0xffffff

    pop  esi

    test eax,eax
    jnz  nobpix

  yesbpix:

  stretch:
    cmp   [bgrdrawtype],dword 2
    jne   nostretch

    mov   eax,[ypos]
    add   eax,ecx
    imul  eax,[bgry]
    cdq
    movzx ebx,word [scrxy]
    div   ebx
    imul  eax,[bgrx]
    push  eax

    mov   eax,[xpos]
    add   eax,[esp+8]
    imul  eax,[bgrx]
    cdq
    movzx ebx,word [scrxy+2]
    div   ebx
    add   eax,[esp]
    add   esp,4

    jmp   notiled

  nostretch:

    cmp   [bgrdrawtype],dword 1
    jne   notiled

    mov   eax,[ypos]
    add   eax,ecx
    cdq
    movzx ebx,word [bgrxy]
    div   ebx
    mov   eax,edx
    imul  eax,[bgrx]
    push  eax

    mov   eax,[xpos]
    movzx ebx,word [bgrxy+2]
    cdq
    div   ebx
    mov   eax,edx
    add   eax,[esp]
    add   esp,4

  notiled:

    lea  ecx,[eax+eax*2]

    mov  eax,39
    mov  ebx,2

    int  0x40

  nobpix:

    pop  ecx
    pop  ebx

    mov  edx,eax
    mov  eax,1
    int  0x40

    dec  ebx
    cmp  ebx,-1
    jnz  newb
    mov  ebx,[yw]

    inc  ecx

    mov  eax,[ya]
    add  [pixpos],eax

    cmp  [top],1
    jne  notop
    cmp  ecx,38
    je   toponly

  notop:

    cmp  ecx,52
    jnz  newb

  toponly:

    popa

    ret



draw_icon:

    call draw_picture
    call draw_text

    ret



text_length:

    pusha

    mov   eax,labelt
  news:
    cmp   [eax],byte 33
    jb    founde
    inc   eax
    cmp   eax,labelt+11
    jb    news

   founde:

    sub   eax,labelt
    mov   [tl],eax

    popa

    ret



draw_text:

    pusha

    mov   eax,[tl]
    lea   eax,[eax+eax*2]  ; eax *= char_width/2
    shl   eax,16

    mov   ebx,27*65536+42
    sub   ebx,eax

    mov   eax,4
    mov   ecx,0                ; black shade of text
    mov   edx,labelt
    mov   esi,[tl]
    add   ebx,1*65536+1
    int   0x40
;   mov   eax,4                ; white text
    sub   ebx,1*65536+1
    mov   ecx,0xffffff
    int   0x40

    popa

    ret



; DATA AREA

tl          dd    2
yw          dd   51
ya          dd    0

dbl_check   db    0

xpos        dd   15
ypos        dd  185

start_file  db  'SETUP      '
fname       db  'HD      BMP'
labelt:
            db  'SETUP      '
labellen:

bgrxy       dd  0x0
scrxy       dd  0x0
bgrdrawtype dd  0x0

pixpos      dd  0
iconstate   dd  0

csum        dd  0x0
dtype       dd  0x0

top       dd 0

I_PARAM:

I_END:

params icon_params
bgrx dd ?
bgry dd ?
data_from_file:
  rb 54 ;header
 raw_data:
  rb 32*32
