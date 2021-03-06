;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                   ;
;    MENUBAR for MenuetOS  - Compile with fasm      ;
;                                                   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

use32
  org  0x0
  db   'MENUET01'   ; 8 byte id
  dd   0x01         ; required OS version
  dd   START        ; program start
  dd   I_END        ; program image size
  dd   0x80000      ; reguired amount of memory
  dd   0x80000      ; esp
  dd   0x0,0x0      ; param, icon
include 'macros.inc'

width           dd  305
buttons         dd    1  ;  0 no frames  ; 1 frames
soften_up       dd    1  ;  0 no         ; 1 yes
soften_down     dd    0  ;  0 no         ; 1 yes
minimize_left   dd    1
minimize_right  dd    1
icons_position  dd   95
menu_enable     dd    1
setup_enable    dd    0
graph_text      dd    1
soften_middle   dd    1  ;  0 no         ; 1 yes
icons           dd    1  ;  0 defaults   ; 1 activate

dat  db  'PANEL   DAT'


START:
    mov  eax,6
    mov  ebx,dat
    mov  ecx,0
    mov  edx,-1
    mov  esi,I_END
    int  0x40

    mov  eax,40
    mov  ebx,0101b
    int  0x40

    mov  edi,width
    mov  esi,I_END
    mov  eax,0
  new_number:
    cmp  [esi],byte ';'
    je   number_ready
    imul eax,10
    movzx ebx,byte [esi]
    sub  ebx,48
    add  eax,ebx
    inc  esi
    jmp  new_number
  number_ready:
    mov  [edi],eax
    mov  eax,0
    add  edi,4
    inc  esi
    cmp  [esi],byte 'x'
    jne  new_number


    call set_variables


start_after_minimize:

    call draw_window
    call draw_info
    call draw_running_applications

    mov  eax,5
    mov  ebx,30
    int  0x40

still:

    call draw_info
    call draw_running_applications

    mov  eax,23
    mov  ebx,20
    int  0x40

    cmp  eax,1          ; redraw ?
    jz   red
    cmp  eax,3          ; button ?
    jz   button

    jmp  still

  red:                   ; redraw window
    call draw_window
    call draw_info
    jmp  still

  button:                ; button
    mov  eax,17
    int  0x40

    cmp  ah,50
    jb   no_activate
    cmp  ah,70
    jg   no_activate

    movzx ecx,byte ah
    sub  ecx,52
    shl  ecx,2

    mov  eax,18
    mov  ebx,3
    mov  ecx,[app_list+ecx]
    int  0x40

    jmp  still
  no_activate:


    cmp  ah,101          ; minimize to left
    jne  no_left
    mov  eax,51
    mov  ebx,1
    mov  ecx,left_button
    mov  edx,0x6fff0
    int  0x40
    mov  eax,5
    mov  ebx,10
    int  0x40
    mov  eax,-1
    int  0x40
  no_left:

    cmp  ah,102          ; minimize to right
    jne  no_right
    mov  eax,51
    mov  ebx,1
    mov  ecx,right_button
    mov  edx,0x6fff0
    int  0x40
    mov  eax,5
    mov  ebx,10
    int  0x40
    mov  eax,-1
    int  0x40
  no_right:

    cmp  ah,byte 1       ; start/terminate menu
    jnz  noselect
    call menu_handler
    jmp  still
  noselect:

    cmp  ah,byte 2             ; start system setup
    jnz  noclock
    mov  eax,19
    mov  ebx,file_sys
    int  0x40
    jmp  still
  noclock:

    cmp  ah,byte 11            ; start file 1
    jnz  nob1
    mov  eax,19
    mov  ebx,file1
    int  0x40
    jmp  still
  nob1:

    cmp  ah,byte 12            ; start file 2
    jnz  nob2
    mov  eax,19
    mov  ebx,file2
    int  0x40
    jmp  still
  nob2:

    cmp  ah,byte 13            ; start file 3
    jnz  nob3
    mov  eax,19
    mov  ebx,file3
    int  0x40
    jmp  still
  nob3:

    cmp  ah,14                 ; start file 4
    jne  noid14
    mov  eax,19
    mov  ebx,file4
    mov  ecx,file4_par
    int  0x40
    jmp  still
  noid14:

    cmp  ah,15                 ; start file 5
    jne  noid15
    mov  eax,19
    mov  ebx,file5
    int  0x40
    jmp  still
  noid15:

    jmp  still


;app_list  dd  1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20
;      dd  21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,30
;      dd  31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50

draw_running_applications:

    pusha

    cmp  [icons],1
    jne  dr_ret

    call calculate_applications

    cmp  edi,[running_applications]
    jne  noret
    popa
    ret
  noret:

;    cmp  edi,[running_applications]
;    jge  no_application_decrease
    call draw_window
;  no_application_decrease:

    mov  [running_applications],edi

    mov  edi,0
    mov  ecx,2

  newpr:

    mov  eax,9
    mov  ebx,0x70000
    int  0x40

    push eax
    push ecx

    cmp  eax,ecx
    jb   norpl2

    cmp  [0x70000+11],dword 'CON '
    je   norpl
;    cmp  [0x70000+10],dword 'SELE'
;    je   norpl
    cmp  [0x70000+11],dword 'ENU '
    je   norpl
    cmp  [0x70000+12],dword 'NEL '
    je   norpl
    cmp  [0x70000+12],dword '    '
    je   norpl


    mov  eax,4
    mov  ebx,edi
    inc  ebx
    shl  ebx,16
    imul ebx,6*13
    add  ebx,10*65536+7
    mov  ecx,[wcolor]
    add  ecx,0x303030
    mov  edx,0x70000+10
    mov  esi,11
    int  0x40

  norpl2:

    inc  edi

  norpl:

    pop  ecx
    pop  eax

    inc  ecx

    cmp  edi,[max_applications]
    jb   newpr

  nompr:

  dr_ret:

    popa

    ret


calculate_applications:

    mov  edi,app_list
    mov  ecx,20
    mov  eax,0xff
    cld
    rep  stosd

    mov  edi,0
    mov  ecx,2

  cnewpr:

    mov  eax,9
    mov  ebx,0x70000
    int  0x40

    cmp  [0x70000+11],dword 'CON '
    je   cnorpl
;    cmp  [0x70000+10],dword 'SELE'
;    je   cnorpl
    cmp  [0x70000+11],dword 'ENU '
    je   cnorpl
    cmp  [0x70000+12],dword 'NEL '
    je   cnorpl
    cmp  [0x70000+12],dword '    '
    je   cnorpl

    mov  [app_list+edi*4],ecx

    inc  edi

  cnorpl:
    inc  ecx

    cmp  eax,ecx
    jge  cnewpr

    ret


draw_application_buttons:

    pusha

    cmp [icons],1
    jne da_ret

    mov  eax,14
    int  0x40

    shr  eax,16

    cmp  eax,639
    jne  now1
    mov  [max_applications],6
  now1:
    cmp  eax,799
    jne  now2
    mov  [max_applications],8
  now2:

    mov  edi,1

  nb:

    mov  eax,8
    mov  ebx,edi
    shl  ebx,16
    imul ebx,6*13
    add  ebx,5*65536+13*6-1
    mov  ecx,1*65536+17
    mov  edx,edi
    add  edx,51
    cmp  [buttons],1
    je   bufr
    add  edx,0x40000000
  bufr:
    mov  esi,[wcolor]
    int  0x40

    inc  edi
    cmp  edi,[max_applications]
    jbe  nb

  da_ret:

    popa

    ret


menu_handler:
    mov  eax,19
    mov  ebx,filename
    xor  ecx,ecx
    int  0x40
;    int  0x40
ret

draw_small_right:

    pusha

    mov  eax,12
    mov  ebx,1
    int  0x40

    mov  eax,14
    int  0x40

    mov  ebx,eax
    sub  ebx,9*65536
    mov  bx,9
    mov  ecx,eax
    mov  edx,[b_size_y]
    sub  ecx,edx
    shl  ecx,16
    mov  cx,dx

    mov  eax,0
    mov  edx,[wcolor]
    mov  esi,edx
    mov  edi,edx
    int  0x40

    mov  eax,8
    mov  ebx,0*65536+9
    mov  ecx,0*65536
    mov  cx,[b_size_y]
    mov  edx,1
    mov  esi,[wcolor]
    int  0x40

    mov  eax,4
    mov  ebx,2*65536+16
    cmp  [graph_text],1
    jne  nos3
    mov  ebx,2*65536+7
  nos3:
    mov  ecx,[wcolor]
    add  ecx,0x303030
    mov  edx,hidetext
    mov  esi,1
    int  0x40

    mov  eax,12
    mov  ebx,2
    int  0x40

    popa

    ret



draw_small_left:

    pusha

    mov  eax,12
    mov  ebx,1
    int  0x40

    mov  eax,14
    int  0x40

    mov  ebx,0*65536+9
    mov  ecx,eax
    mov  edx,[b_size_y]
    sub  ecx,edx
    shl  ecx,16
    mov  cx,dx

    mov  eax,0
    mov  edx,[wcolor]
    mov  esi,edx
    mov  edi,edx
    int  0x40

    cmp  [graph_text],1
    je   nos4

    mov  eax,8
    mov  ebx,0*65536+9
    mov  ecx,0*65536+18-6
    mov  edx,2
    mov  esi,[wcolor]
    int  0x40

    mov  eax,4
    mov  ebx,2*65536+4
    mov  ecx,[wcolor]
    add  ecx,0x303030
    mov  edx,hidetext+2
    mov  esi,1
    int  0x40

  nos4:

    mov  eax,8
    mov  ebx,0*65536+9
    mov  ecx,13*65536+25
    cmp  [graph_text],1
    jne  nos6
    mov  ecx,0*65536
    mov  cx,word [b_size_y]
  nos6:
    mov  edx,1
    mov  esi,[wcolor]
    int  0x40

    mov  eax,4
    mov  ebx,3*65536+22
    cmp  [graph_text],1
    jne  nos7
    mov  ebx,3*65536+7
  nos7:
    mov  ecx,[wcolor]
    add  ecx,0x303030
    mov  edx,hidetext+1
    mov  esi,1
    int  0x40

    mov  eax,12
    mov  ebx,2
    int  0x40

    popa
    ret


right_button:

    mov  [small_draw],dword draw_small_right

    mov  eax,5
    mov  ebx,20
;    int  0x40

    call draw_small_right

    mov  eax,5
    mov  ebx,30
    int  0x40

    jmp  small_wait


left_button:

    mov  [small_draw],dword draw_small_left

    mov  eax,5
    mov  ebx,20
;    int  0x40

    call draw_small_left

    mov  eax,5
    mov  ebx,30
    int  0x40

  small_wait:

    mov  eax,10
    int  0x40

    cmp  eax,1
    jne  no_win
    call [small_draw]
    jmp  small_wait
  no_win:

    cmp  eax,2
    jne  no_key
    mov  eax,2
    int  0x40
    jmp  small_wait
  no_key:

    mov  eax,17
    int  0x40

    cmp  ah,1
    jne  no_full
    mov  eax,51
    mov  ebx,1
    mov  ecx,start_after_minimize
    mov  edx,0x7fff0
    int  0x40
    mov  eax,5
    mov  ebx,20
    int  0x40
    mov  eax,-1
    int  0x40
  no_full:

    call menu_handler

    jmp  small_wait



set_variables:

     pusha

     mov  [b_size_y],dword 38
     cmp  [graph_text],1
     jne  noy2
     mov  [b_size_y],dword 18
   noy2:

     mov  [button_frames],0x0
     cmp  [buttons],0
     jne  no_frames
     mov  [button_frames],0x40000000
   no_frames:


     mov  eax,48           ; 3d button look
     mov  ebx,1
     mov  ecx,1
     int  0x40

     mov  eax,0x40404040   ; dividers for processes
     mov  edi,pros
     mov  ecx,10
     cld
     rep  stosd

     popa
     ret



draw_flag:

    pusha

    cmp  [graph_text],0
    jne  no_flags

    mov  edx,ebx

    mov  ebx,[maxx]
    and  eax,1
    imul eax,17
    sub  ebx,eax
    sub  ebx,28
    shl  ebx,16
    mov  bx,24

    mov  ecx,[bte]

    dec  edx
    shl  edx,1
    add  edx,flag_text
    mov  esi,2
    mov  eax,4
    int  0x40

  no_flags:

    popa
    ret






; ***************************************************
; ********* WINDOW DEFINITIONS AND DRAW *************
; ***************************************************


draw_window:

    pusha

    mov  [running_applications],-1
    mov  [checks],-1

    mov  eax,12                    ; tell os about redraw
    mov  ebx,1
    int  0x40

    mov  eax,48
    mov  ebx,3
    mov  ecx,I_END
    mov  edx,10*4
    int  0x40

    mov  eax,[I_END+4*6]
    mov  [wcolor],eax

    mov  eax,14                    ; get screen max x & max y
    int  0x40

    cmp  [width],0
    je   no_def_width
    and  eax,0xffff
    mov  ebx,[width]
    shl  ebx,16
    add  eax,ebx
  no_def_width:

    mov  ebx,eax
    mov  [screenxy],ebx
    shr  ebx,16
    sub  ax,38
    shl  eax,16
    mov  ecx,eax
    add  ecx,0*65536+38
    cmp  [graph_text],1
    jne  no_text_1
    mov  cx,18
    add  ecx,20*65536
  no_text_1:
    mov  eax,0                     ; DEFINE AND DRAW WINDOW
    mov  edx,[wcolor]
    mov  esi,[wcolor]
    mov  edi,[wcolor]
    int  0x40

    movzx ebx,word [screenxy+2]
    mov  ecx,0*65536+0
    mov  edx,[wcolor]
    add  edx,0x161616
  newline:
    sub  edx,0x040404
    mov  eax,38
    cmp  [soften_up],1
    jne  no_su
    int  0x40
  no_su:

    pusha
    cmp  [soften_down],1
    jne  no_sd
    sub  edx,0x141414
    mov  edi,[b_size_y]
    shl  edi,16
    add  edi,[b_size_y]
    add  ecx,edi
    sub  ecx,3*65536+3
    int  0x40
  no_sd:
    popa

    add  ecx,1*65536+1
    cmp  cx,5
    jb   newline

    cmp   [soften_middle],1
    jne   no_sm

    movzx ebx,word [screenxy+2]
    mov   ecx,5*65536+5
    mov   esi,stripe
    mov   edx,[wcolor]
  newline3:
    add  edx,[esi]
    add  esi,4

    mov  eax,38
    int  0x40
    add  ecx,1*65536+1
    cmp  cx,15
    jb   newline3

  no_sm:

    cmp  [minimize_left],1
    jne  no_mleft
    mov  eax,8                               ; ABS LEFT
    mov  ebx,0 *65536+9
    mov  ecx,1 *65536
    add  ecx,[b_size_y]
    dec  ecx
    mov  edx,101
    add  edx,[button_frames]
    mov  esi,[wcolor]
    int  0x40
    mov  eax,4                               ; HIDE TEXT
    mov  ebx,2*65536+17
    cmp  [graph_text],1
    jne  no_y1
    mov  bx,7
  no_y1:
    mov  ecx,[wcolor]
    add  ecx,0x303030
    mov  edx,hidetext
    mov  esi,1
    int  0x40
  no_mleft:

    movzx eax,word [screenxy+2]
    mov  [maxx],eax

    cmp  [minimize_right],1
    jne  no_mright
    mov  eax,[maxx]
    sub  eax,77
    shl  eax,16
    mov  ebx,eax
    add  ebx,67
    mov  eax,8                               ; ABS RIGHT
    mov  ecx,1 *65536
    add  ecx,[b_size_y]
    dec  ecx
    add  ebx,68*65536
    mov  bx,9
    mov  edx,102
    add  edx,[button_frames]
    mov  esi,[wcolor]
    int  0x40
    mov  edx,hidetext+1
    mov  eax,4
    mov  ebx,[maxx]
    sub  ebx,6
    shl  ebx,16
    mov  bx,17
    cmp  [graph_text],1
    jne  no_y2
    mov  bx,7
  no_y2:
    mov  ecx,[wcolor]
    add  ecx,0x303030
    mov  esi,1
    int  0x40
  no_mright:

    call draw_menuet_icon

    call draw_program_icons

    mov  [ptime],0
    call draw_info

    call draw_application_buttons

    mov  eax,12
    mov  ebx,2
    int  0x40

    popa
    ret



draw_menuet_icon:

    pusha

    cmp  [menu_enable],1
    jne  no_menu


    mov  eax,8                               ; M BUTTON
    mov  ebx,10 *65536+44
    cmp  [minimize_left],0
    jne  no_m_s
    sub  ebx,10*65536
  no_m_s:
    mov  ecx,1  *65536
    add  ecx,[b_size_y]
    dec  ecx
    mov  edx,1
    add  edx,[button_frames]
    mov  esi,[wcolor]
    int  0x40

    cmp  [graph_text],1
    jne  no_mtext

    mov  eax,4
    mov  bx,7
    add  ebx,8*65536
    mov  ecx,0x10ffffff
    mov  edx,m_text
    mov  esi,4
    int  0x40

    popa
    ret

  no_mtext:



    mov  eax,[wcolor]
    mov  [m_icon+4],eax

    mov  eax,6                               ; load file
    mov  ebx,m_bmp
    mov  ecx,0
    mov  edx,200000
    mov  esi,image
    mov  edi,0
    int  0x40

    mov  eax,40
    mov  ebx,0
    mov  edi,image+53

   new_m_pix:

;    movzx ecx,byte [edi]
;    shr  ecx,5

    mov    cl,[edi]
    cmp    cl,10
    jb     nopix
    mov    cl,[edi+1]
    cmp    cl,10
    jb     nopix
    mov    cl,[edi+2]
    cmp    cl,10
    jb     nopix

    pusha
    cmp  [minimize_left],0
    jne  no_m_s2
    sub  ebx,10
  no_m_s2:
;    mov  edx,[ecx*4+m_icon]
    mov  edx,[edi+1]

    mov  ecx,eax
    mov  eax,1
    add  ebx,12
    int  0x40
    popa

   nopix:

    add  edi,3
    add  ebx,1
    cmp  ebx,40
    jnz  new_m_pix

    mov  ebx,0
    dec  eax
    jnz  new_m_pix

  no_menu:

    popa
    ret


draw_program_icons:

    pusha

    cmp  [icons],0
    jne  dp_ret

    mov  edi,1
    push edi

  new_icon_file:

    pusha
    mov  edx,[esp+32]
    add  edx,10
    push edx
    mov  esi,[wcolor]
    mov  ecx,1*65536
    add  ecx,[b_size_y]
    dec  ecx
    mov  eax,edi
    dec  eax
    imul eax,40
    mov  ebx,eax
    add  ebx,[icons_position]
    shl  ebx,16
    mov  bx,39
    pop  edx
    add  edx,[button_frames]
    mov  eax,8
    int  0x40
    popa

    mov  ecx,[esp]
    add  ecx,48
    mov  [iconf+6],cl

    mov  eax,6                      ; load file
    mov  ebx,iconf
    mov  ecx,0
    mov  edx,200000
    mov  esi,image
    int  0x40

    mov  eax,0
    mov  ebx,32
    mov  edi,image+51+32*33*3

   np2:                             ; new pixel of file

    mov  edx,[edi]
    and  edx,0xffffff

    cmp  eax,3                      ; Y draw limits
    jb   nopix2
    cmp  eax,36
    jg   nopix2
    cmp  ebx,38                     ; X draw limits
    jg   nopix2
    cmp  ebx,2
    jb   nopix2

    cmp  edx,0
    jz   nopix2

    cmp  [graph_text],1
    jne  no_icon_text

    pusha

    mov  ebx,[esp+32]
    dec  ebx
    imul ebx,40
    add  ebx,8
    add  ebx,[icons_position]
    shl  ebx,16
    mov  bx,7

    mov  eax,4
    mov  ecx,0xffffff
    mov  edx,[esp+32]
    dec  edx
    imul edx,4
    add  edx,mi_text
    mov  esi,4
    int  0x40

    popa

    jmp  nopix2

  no_icon_text:

    mov  esi,[esp]
    pusha
    push edx
    mov  ecx,eax
    add  ecx,2
    mov  eax,esi
    dec  eax
    imul eax,40
    add  ebx,eax
    add  ebx,3
    add  ebx,[icons_position]
    pop  edx
    mov  eax,1
    int  0x40
    popa

  nopix2:

    sub  edi,3
    dec  ebx
    jnz  np2

    mov  ebx,32
    add  eax,1
    cmp  eax,32
    jnz  np2

    add  dword [esp],1
    mov  edi,[esp]
    cmp  dword [esp],4
    jbe  new_icon_file
    add  esp,4

    mov  eax,4
    mov  ebx,40
    imul ebx,3
    add  ebx,[icons_position]
    add  ebx,10
    shl  ebx,16
    mov  bx,23
    mov  ecx,[wcolor]
    mov  edx,gpl
    mov  esi,3
    int  0x40

  dp_ret:

    popa
    ret



draw_info:    ; draw cpu usage, time, date

    pusha

    cmp  [setup_enable],1
    jne  no_setup

    cmp  [minimize_right],0
    jne  no_m_r
    add  [maxx],10

   no_m_r:

    mov  eax,3
    int  0x40
    cmp  eax,[ptime]
    jz   _ret
    mov  [ptime],eax

    call draw_cpu_usage

    mov  eax,[maxx]   ; blink sec
    sub  eax,33
    shl  eax,16
    mov  ebx,eax
    add  ebx,9
    mov  eax,3
    int  0x40
    cmp  [graph_text],1
    jne  no_y4
    sub  bx,2
  no_y4:
    mov  ecx,eax
    shr  ecx,16
    and  ecx,1
    mov  edx,[bte]
    sub  edx,[wcolor]
    imul ecx,edx
    add  ecx,[wcolor]
    mov  edx,sec
    mov  eax,4
    mov  esi,1
    int  0x40


    mov  eax,26          ; check for change in time or country
    mov  ebx,5
    int  0x40
    mov  edx,eax
    mov  eax,26
    mov  ebx,2
    mov  ecx,9
    int  0x40
    add  edx,eax
    mov  eax,3
    int  0x40
    and  eax,0xffff
    add  edx,eax
    cmp  edx,[checks]
    je   _ret
    mov  [checks],edx


    mov  ebx,[maxx]
    sub  ebx,74
    shl  ebx,16
    add  ebx,64

    mov  eax,8               ; time/date button
    mov  ecx,1 *65536
    add  ecx,[b_size_y]
    dec  ecx
    mov  edx,2+0x80000000
    mov  esi,[wcolor]
    int  0x40
    pusha
    mov  eax,13
    add  ebx,10*65536-16
    add  ecx,5*65536-8
    mov  edx,[wcolor]
    int  0x40
    popa
    and  edx,0xffff
    add  edx,[button_frames]
    int  0x40


    ; flags

    mov  eax,26
    mov  ebx,5
    int  0x40
    mov  ebx,eax

    mov  eax,1
    call draw_flag

    mov  eax,26
    mov  ebx,2
    mov  ecx,9
    int  0x40
    mov  ebx,eax

    mov  eax,2
    call draw_flag

    mov  eax,3                  ; get time
    int  0x40

    movzx ebx,al
    shr   eax,8
    movzx ecx,al
    shr   eax,8
    movzx edx,al

    ; ebx ecx edx h m s

    push ebx
    push ecx

    mov  eax,[maxx]
    sub  eax,32
    shl  eax,16
    mov  ebx,eax
    add  ebx,9

    mov  ecx,[bte]

    cmp  [graph_text],1
    jne  no_y3
    sub  bx,2
    mov  ecx,0xffffff
  no_y3:


    mov  edx,[esp]             ; __:_X
    and  edx,15
    mov  eax,4
    add  ebx,10*65536
    add  edx,text
    mov  esi,1
    int  0x40

    pop  edx                    ; __:X_
    shr  edx,4
    and  edx,15
    mov  eax,4
    sub  ebx,6*65536
    add  edx,text
    mov  esi,1
    int  0x40

    mov  edx,[esp]             ; _X:__
    and  edx,15
    mov  eax,4
    sub  ebx,11*65536
    add  edx,text
    mov  esi,1
    int  0x40

    pop  edx                    ; X_:__
    shr  edx,4
    and  edx,15
    mov  eax,4
    sub  ebx,6*65536
    add  edx,text
    mov  esi,1
    int  0x40

    call draw_cpu_usage

  _ret:

    cmp  [minimize_right],0
    jne  no_m_r2
    sub  [maxx],10
   no_m_r2:

   no_setup:

    popa
    ret



draw_cpu_usage:

    pusha

    mov  [ysi],30
    cmp  [graph_text],1
    jne  @f
    mov  [ysi],10
  @@:


    mov  eax,18    ; TSC / SEC
    mov  ebx,5
    int  0x40
    shr  eax,20
    push eax
    mov  eax,18    ; IDLE / SEC
    mov  ebx,4
    int  0x40
    shr  eax,20
    xor  edx,edx
    imul eax,[ysi]

    cdq  ;xor  edx,edx
    pop  ebx
    add  ebx,1
    div  ebx
    push eax

    mov  eax,13
    mov  ebx,[maxx]
    sub  ebx,65
    shl  ebx,16
    mov  bx,8
    push ebx
    mov  eax,13
    mov  ecx,5*65536
    add  cx,word [ysi]
    inc  cx
    mov  edx,[wcolor]
    sub  edx,0x303030
    int  0x40
    pop  ebx
    pop  eax

    push ebx
    add  eax,1
    mov  ecx,5*65536
    mov  cx,ax
    pop  ebx
    mov  eax,13
    mov  edx,[wcolor]
    add  edx,0x00101010
    int  0x40

    popa

    ret




; DATA

stripe:

    dd  -0x020202
    dd  -0x020202
    dd  -0x020202
    dd  -0x020202
    dd  -0x020202

    dd   0x020202
    dd   0x020202
    dd   0x020202
    dd   0x020202
    dd   0x020202

m_icon:
    dd  0x0
    dd  0x808080
    dd  0x000000
    dd  0x000000
    dd  0xffffff

if lang eq ru
  m_text:  db   '????'
else
  m_text   db   'MENU'
end if

mi_text: db   'WAVETETRBGRDGPL '

flag_text db 'ENFIGE',0x90,0x93,'FR'


button_frames  dd  0x0

checks    dd -1
hidetext  db 0x11,0x10,0x1e
iconf     db  'MBAR_IX BMP'
m_bmp     db  'MENUET  BMP'

file_sys  db  'SETUP      '
filename  db  'MENU       '
file1     db  'SB         '
file2     db  'TETRIS     '
file3     db  'PIC4       '
file4     db  'TINYPAD    '
file4_par db  'COPYING.TXT',0
file5     db  'MFASM      '
gpl       db  'GPL'


running_applications  dd  0x100
max_applications      dd  11

b_size_y:  dd  0x0
ysi  dd  0
small_draw dd 0x0

ptime   dd 0x0
maxx    dd 0x0
text    db '0123456789'
bte     dd 0xccddee

wcolor  dd 0x506070

sec     db ': '
pros    db '                                                  '
        db '                                                  '

screenxy    dd  0x0
stcount     dd  0x0


I_END:
system_colours rd 10
app_list rd 50
tictable:
  rd 256
image:
