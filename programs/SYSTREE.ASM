;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                              ;
;   SYSTEM TREE BROWSER                        ;
;                                              ;
;   Authors:                                   ;
;    Ville         - original SYSTREE          ;
;    M. Lisovin    - double-click buttons      ;
;                    warning windows           ;
;                    deleting files            ;
;    Ivan Poddubny - open text/asm/bmp files   ;
;                    bugfixes                  ;
;                    colors, beep              ;
;                                              ;
;   Compile with FASM for MenuetOS             ;
;                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 84 Kb memory!

;******************************************************************************
  use32
  org    0x0
  db     'MENUET01'   ; 8 byte id
  dd     0x01         ; header version
  dd     START        ; program start
  dd     I_END        ; program image size
  dd     0x15000      ; memory
  dd     0x15000      ; stack
  dd     0x0,0x0      ; param,icon
include  'macros.inc'
;******************************************************************************

START:                          ; start of execution

    call read_directory
red:
    call draw_window            ; at first, draw the window

still:

    mov  eax,10                 ; wait here for event
    int  0x40

    dec  eax                    ; redraw request ?
    jz   red
    dec  eax                    ; key in buffer ?
    jz   key
    dec  eax                    ; button in buffer ?
    jz   button

  key:                          ; key
    mov  eax,2
    int  0x40
    cmp  ah,184
    je   pgup
    cmp  ah,183
    je   pgdn
    cmp  ah,178
    je   curup
    cmp  ah,177
    je   curdn
    cmp  ah,52
    je   view1
    cmp  ah,53
    je   view1
    cmp  ah,57
    je   delete
    cmp  ah,182
    je   delete
    cmp  ah,13
    jne  still
    mov  ah,[butid]
    jmp  noreadhd3
  curup:
    cmp  [butid],21
    jbe  curup1
    dec  [butid]
    inc  [drawid]
    call drawbuttons
    dec  [drawid]
    jmp  still
  curup1:
    mov  [butid],36
    jmp  pgup
  curdn:
    cmp  [butid],36
    jae  curdn1
    inc  [butid]
    inc  [drawid]
    call drawbuttons
    dec  [drawid]
    jmp  still
  curdn1:
    mov  [butid],21
    jmp  pgdn

  button:                       ; button
    mov  eax,17
    int  0x40

    cmp  ah,21
    jl   noclose1
    cmp  ah,36
    jg   noclose1
    cmp  ah,[butid]
    je   dblclick
    mov  [butid],ah
    inc  [drawid]
    call drawbuttons
    dec  [drawid]
  dblclick:

    mov  eax,23
    mov  ebx,40
    int  0x40
    cmp  eax,3
    jne  still

    mov  eax,17
    int  0x40
    cmp  al,1
    je   still
    cmp  ah,[butid]
    jne  still
  noclose1:

    cmp  ah,41                  ; button id=12 -> directory
    jb   noreadhd

    shr  eax,8
    sub  eax,41
    imul eax,12

    cmp  eax,[loclen]
    jge  still

    mov  [loclen],eax
    mov  [readblock],1
    call read_directory
    mov  [butid],21
    call drawbuttons

    jmp  still

  noreadhd:

    cmp  ah,13                  ; button id=13 ?
    jnz  noreadhd2
  pgup:
    mov  eax,[readblock]
    cmp  eax,1
    jz   nozer1
    dec  eax
    mov  [readblock],eax
    call read_directory
    inc  [drawid]
    call drawbuttons
    dec  [drawid]
   nozer1:
    jmp  still

  noreadhd2:

    cmp  ah,14                  ; button id=14 ?
    jnz  reread
   pgdn:
    mov  eax,[readblock]
    inc  eax
    mov  [readblock],eax
    call read_directory
    inc  [drawid]
    call drawbuttons
    dec  [drawid]
  nozer2:
    jmp  still

  reread:
    cmp  ah,2
    jne  view
    call read_directory
    call drawbuttons
    jmp  still
  view:
    cmp  ah,4
    je   delete
    cmp  ah,3
    jne  noreadhd3
  view1:
    mov  ah,[butid]
    mov  [temp],56
    jmp  yeseditor1

  noreadhd3:
    cmp  ah,21
    jge  yesnewdir
    jmp  nonewdir
  yesnewdir:

    pusha
    mov  al,ah
    and  eax,255
    add  eax,-21
    imul eax,62
    mov  esi,eax
    add  esi,fileinfo+7

    cmp  [esi-2],dword ' FOL'
    jz   folok

    cmp  [esi+12],dword '.TXT'          ; show txt, asm and inc files
    je   yeseditor
    cmp  [esi+12],dword '.ASM'
    je   yeseditor
    cmp  [esi+12],dword '.INC'
    je   yeseditor
    cmp  [esi+12],dword '.BMP'
    je   yesbmpview
    jmp  noeditor

  yesbmpview:
    mov  [temp],0
    jmp  yescommon
  yeseditor:
    mov  [temp],56
  yescommon:
    popa
  yeseditor1:

    call getparam

    mov  ebx,bmpview
    cmp  [temp],56
    jne  @f
    mov  ebx,editor
@@:
    mov  eax,19
;    mov  ebx,editor
    mov  ecx,param
    int  0x40

    jmp  still

temp dd ?

  noeditor:
                                ; start application

    popa
    pusha

    call getparam
    mov  eax,58
    mov  ebx,fileinfo_start
    int  0x40

    popa
    jmp  still


  folok:         ; user clicked on the folder

    popa

    mov  al,ah
    and  eax,255
    add  eax,-21
    imul eax,32    ; ((button_id&255)-21)*32?
    mov  esi,eax
    mov  edi,[loclen]
    inc  edi
    add  esi,data_area+1024
    cmp  [esi],word '..'     ; if '..'
    jnz  chdir1
    mov  eax,[loclen]
    add  eax,-12
    mov  [loclen],eax
    mov  [readblock],dword 1
    jmp  readhd
  chdir1:
    cmp  [esi],byte '.'     ; if '.'
    jnz  chdir2
    jmp  still
  chdir2:

    add  edi,location
    mov  ecx,11
    cld
    rep  movsb

    add  [loclen],12
    mov  [readblock],dword 1

  readhd:

    call read_directory
    mov  [butid],21
    call drawbuttons

    jmp  still

  nonewdir:

    dec  ah
    jne  still

    or   eax,-1
    int  0x40

;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************


draw_window:
    mov  eax,48
    mov  ebx,3
    mov  ecx,sc
    mov  edx,sizeof.system_colors
    int  0x40

    mov  eax,[sc.work_button]
    mov  [b_color],eax

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40

                                   ; DRAW WINDOW
    xor  eax,eax                   ; function 0 : define and draw window
    mov  ebx,140*65536+480         ; [x start] *65536 + [x size]
    mov  ecx,160*65536+280         ; [y start] *65536 + [y size]
    mov  edx,[sc.work]             ; color of work area RRGGBB
    or   edx,0x03000000
    int  0x40

                                   ; WINDOW LABEL
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov  ecx,[sc.grab_text]        ; color of text RRGGBB
    or   ecx,0x10000000
    mov  edx,labelt                ; pointer to text beginning
    mov  esi,labellen-labelt       ; text length
    int  0x40

    mov  eax,8
    mov  ebx,20*65536+50
    mov  ecx,37*65536+12
    mov  edx,2
    mov  esi,[b_color]
    int  0x40
  nextbut:
    add  ebx,51*65536
    inc  edx
    int  0x40
    cmp  edx,4
    jb   nextbut
    ; UP
    mov  ebx,359*65536+50          ; [x start] *65536 + [x size]
    mov  edx,13                    ; button id
    int  0x40
    ; DOWN

    mov  ebx,410*65536+50          ; [x start] *65536 + [x size]
    mov  edx,14                    ; button id
    int  0x40
    mov  ebx,25*65536+40           ; draw info text with function 4
    mov  ecx,[sc.work_button_text]
    mov  edx,buttonstring
    mov  esi,[buttonstringlen]
    mov  eax,4
    int  0x40

    call drawbuttons

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret

;*****************
;*  Draw buttons *
;*****************

drawbuttons:

    pusha

    mov  ebx,150*65536+310
    mov  ecx,50*65536+12
    mov  edx,21            ;ID кнопок с 21 по 36
 newb:
    cmp  dl,[butid]
    jne  nodrawcur
 drawcur:
    mov  esi,[b_color] ;0x6677cc
    jmp  drawbut
 nodrawcur:
    mov  esi,[b_color] ;0x112288
    add  esi,-0x282828
 drawbut:
    mov  eax,8
    int  0x40
    cmp  [drawid],1
    je   drawtxt

    pusha
    add  ebx,-130*65536
    mov  bx,120
    add  edx,20
    mov  esi,[b_color] ;0x3344aa
    int  0x40
    popa

 drawtxt:
    pusha
    add  edx,-21
    mov  esi,edx
    imul edx,12
    cmp  edx,[loclen]
    jg   no_dir_text
    mov  eax,4
    add  ebx,-125*65536
    shr  ecx,16
    mov  bx,cx
    add  bx,3
    shl  esi,2+16
    add  ebx,esi
    mov  ecx,0xffffff
    add  edx,root
    cmp  edx,root
    jne  no_yellow
    mov  ecx,0xffff00
  no_yellow:
    mov  esi,11
    int  0x40
  no_dir_text:
    popa

    pusha
    add  edx,-21
    mov  eax,edx
    imul eax,62
    add  eax,fileinfo
    mov  ebx,155*65536
    shr  ecx,16
    mov  bx,cx
    add  ebx,5*65536+3
    mov  ecx,0xffffff
    cmp  [eax+5],dword ' DEL'
    jne  @f
    mov  ecx,[b_color] ;0x99aaee
    jmp  end_color
  @@:
    cmp  [eax+5],dword ' FOL'  ; folder
    jne  @f
    mov  ecx,0xffff00
    jmp  end_color
  @@:
    cmp  [eax+19],dword '.ASM' ; asm file
    je   yesasm
    cmp  [eax+19],dword '.INC' ; inc asm file
    jne  noasm
  yesasm:
    mov  ecx,0x88ffff
    jmp  end_color
  noasm:
    cmp  [eax+19],dword '.BMP' ; bmp file
    jne  @f
    mov  ecx,0xee77ee
    jmp  end_color
  @@:
    cmp  [eax+19],dword '.   ' ; menuet application
    jne @f
    mov  ecx,0x55dd55
  @@:
  end_color:
    mov  edx,eax
    mov  esi,57
    mov  eax,4
    int  0x40
    popa

    add  ecx,(13*65536)
    inc  edx
    cmp  edx,37
    jnz  newb

    popa

    ret



read_directory:

    mov  edi,0x14000 ;0x20000
    xor  eax,eax
    mov  ecx,512
    cld
    rep  stosb

    mov  esi,location
    mov  edi,filedir
    mov  ecx,12*16
    cld
    rep  movsb

    mov  eax,[loclen]
    mov  [filedir+eax],byte 0

    mov  eax,[readblock]
    dec  eax
    mov  [fileinfoblock+4],eax
    mov  eax,58
    mov  ebx,fileinfoblock
    int  0x40

    test eax,eax
    jne  hd_read_error

    mov  [dirlen],ebx
    mov  esi,0x14000 ;0x20000
    mov  edi,data_area+1024
    mov  ecx,512
    cld
    rep  movsb

    mov  ebx,1024

    ; command succesful

    mov  esi,data_area+1024
    mov  edi,fileinfo+11
    mov  edx,16

  newlineb:

    pusha               ; clear
    mov  al,32
    mov  ecx,58
    sub  edi,11
    cld
    rep  stosb
    popa

    mov  cl,[esi]       ; end of entries ?
    cmp  cl,6
    jnz  noib0

    mov  [edi-5],dword 'EOE '
    add  esi,32
    add  edi,62
    jmp  inf

  noib0:

    mov  cl,[esi+0]
    cmp  cl,0xe5
    je   yesdelfil

    mov  cl,[esi+11]    ; long fat32 name ?
    cmp  cl,0xf
    jnz  noib1

    mov  [edi-5],dword 'F32 '
    add  esi,32
    add  edi,62
    jmp  inf

  noib1:

    mov  eax,'DAT '     ; data or .. ?

    mov  cl,[esi+0]     ; deleted file
    cmp  cl,0xe5
    je   yesdelfil
    cmp  cl,0x0
    je   yesdelfil
    jmp  nodelfil
   yesdelfil:
    mov  eax,'DEL '
    jmp  ffile
  nodelfil:

    mov  cl,[esi+11]    ; folder
    and  cl,0x10
    jz   ffile
    mov  eax,'FOL '
    mov  [edi-5],eax
;    mov  [edi+45],byte '-'
    jmp  nosize

  ffile:

    mov  [edi-5],eax

    pusha               ; size
    mov  eax,[esi+28]
    mov  esi,edi
    add  esi,37
    mov  ebx,10
    mov  ecx,8
  newnum:
    xor  edx,edx
    div  ebx
    add  dl,48
    mov  [esi],dl
    test eax,eax
    jz   zernum
    dec  esi
    loop newnum
  zernum:
    popa
  nosize:

    pusha                    ; date
    mov  [edi+17],dword '.  .'

    movzx eax,word [esi+24]
    shr  eax,9         ; year
    add  eax,1980
    mov  ecx,4
  newdel1:
    dec  ecx
    xor  edx,edx
    mov  ebx,10
    div  ebx
    add  edx,48
    mov  [edi+ecx+21],dl
    test ecx,ecx
    jnz  newdel1

    movzx eax,word [esi+24]
    shr  eax,5    ; month
    and  eax,0x0f
    mov  ecx,2
  newdel2:
    dec  ecx
    xor  edx,edx
    mov  ebx,10
    div  ebx
    add  edx,48
    mov  [edi+ecx+18],dl
    test ecx,ecx
    jnz  newdel2

    movzx eax,word [esi+24]
    and  eax,0x1f ; day
    mov  ecx,2
  newdel3:
    dec  ecx
    xor  edx,edx
    mov  ebx,10
    div  ebx
    add  edx,48
    mov  [edi+ecx+15],dl
    test ecx,ecx
    jnz  newdel3

    popa


    pusha                    ; number
    mov  ecx,17
    sub  ecx,edx
    mov  eax,[readblock]
    dec  eax
    shl  eax,4
    add  eax,ecx
    xor  edx,edx
    mov  ebx,10
    div  ebx
    add  dl,48
    mov  [edi-8],dl          ;0001
    xor  edx,edx
    div  ebx
    add  dl,48
    mov  [edi-9],dl          ;0010
    xor  edx,edx
    div  ebx
    add  al,48
    add  dl,48
    mov  [edi-10],dl         ;0100
    mov  [edi-11],al         ;1000
    mov  [edi-7],byte '.'
    popa

    mov  ecx,8          ; first 8
    cld
    rep  movsb
    mov  [edi],byte '.'
    inc  edi
    mov  ecx,3          ; last 3
    cld
    rep  movsb

    add  esi,(32-11)
    add  edi,(60-12+2)

  inf:

    dec  edx
    test edx,edx
    jnz  newlineb

    ret  ; read directory


hd_read_error:

    mov  [winpar],byte 8
    mov  [winpar+3],byte 12
    mov  [winstat],word 1
    cmp  eax,1
    jnz  la1
    mov  [winpar+1],word 82
  la1:
    cmp  eax,2
    jnz  la2
    mov  [winpar+1],word 164
  la2:
    cmp  eax,3
    jnz  la3
    mov  [winpar+1],word 205
  la3:
    cmp  eax,4
    jnz  la4
    mov  [winpar+1],word 123
  la4:
    cmp  eax,5
    jnz  la5
    mov  [winpar+1],word 246
    dec  dword [readblock]
    add  [loclen],dword 12

  la5:
    cmp  eax,6
    jnz  la6
    mov  [winpar+1],word 287
  la6:

    sub  [loclen],dword 12
    jmp  thread


; GET_PARAM {
; path to file in MeOS format
; (e.g. "/HD/1/MENUETOS/DOC/FASM.TXT")
  getparam:
    ;(1) clear parameters string
    mov edi,param
    mov ecx,50
    mov al,0
    rep stosb

    ;(2) write path prefix - "/RD/1/" or "/HD/1/"
    mov edi,param
    mov esi,rdpathbeg
    cmp [location+1],dword 'HARD'
    jne @f
    mov esi,hdpathbeg
   @@:
    mov ecx,6
    cld
    rep movsb

    ;(3) write location ( "MENUETOS/DOC/" )
    mov esi,location+25
    mov ecx,[loclen]
    sub ecx,24
    cmp ecx,0
    jle exitloc

  begloc:
    cmp byte [esi],' '
    jnz @f
    inc esi
    dec ecx
    jz exitloc
    jmp begloc
  @@:
    movsb
    dec ecx
    jnz begloc
  exitloc:

    ;(4) get file name
    xor  eax,eax
    mov  al,[butid]
    sub  eax,21
    imul eax,32
    add  eax,data_area+1024
    mov  esi,eax

    ;(5) write file name ( "FASM" )
    mov ecx,8
  begfn:
    cmp byte [esi],' '
    jnz @f
    inc esi
    dec ecx
    jz  endfn
    jmp begfn
  @@:
    movsb
    dec ecx
    jnz begfn
  endfn:

    ;(6) write extension, ( ".TXT" )
    mov al,'.'
    stosb
    mov ecx,3
    rep movsb

    ret
; GET_PARAM }

  delete:

  movzx  eax,[butid]
    add  eax,-21
    imul eax,32
    add  eax,data_area+1024
    mov  ecx,11
    mov  esi,eax
    mov  edi,param
    rep  movsb

    cmp  [eax],byte 0xe5
    je   still
    cmp  [eax],byte '.'
    je   still
    mov  edi,notdelete
  cont:
    cld
    mov  esi,param
    mov  ecx,8
    repe cmpsb
    je   still
    add  edi,ecx
    cmp  edi,notdelete+48
    jb   cont

    mov  [winpar],byte 0
    cmp  [location+1],dword 'RAMD'
    jne  hddelete
    mov  [winpar+1],dword 0
    jmp  thread
hddelete:
    cmp  [location+1],dword 'HARD'
    jne  still
    xor  al,al
    mov  edi,param
    mov  ecx,11
    rep  stosb
    mov  [winpar+1],word 41
    mov  [winpar+3],byte 12
    mov  [winstat],1
thread:
;   mov  eax,5
;   mov  ebx,20
;   int  0x40
    mov  eax,51
    mov  ebx,1
    mov  ecx,alert
    mov  edx,0x15000 ;0xff000
    int  0x40
    cmp  ah,0xff
    je   still
 closewait:
    mov  eax,23
    mov  ebx,20
    int  0x40
    cmp  eax,1
    jne  closewait1
    call draw_window
 closewait1:
    bt   [winstat],1
    jnc  closewait
    btr  [winstat],1
    call read_directory
    call drawbuttons
    jmp  still

;******************************************************************************

  alert:             ; <<< START OF ALERT WINDOW PROCESS!
    ; { beep {
    mov  eax,55
    mov  ebx,eax
    mov  esi,beep
    int  0x40
    ; } beep }
    call aldraw_window

    alstill:

    mov  eax,10                 ; wait here for event
    int  0x40

    cmp  eax,1                  ; redraw request ?
    je   alred
    cmp  eax,2                  ; key in buffer ?
    je   alkey
    cmp  eax,3                  ; button in buffer ?
    je   albutton

    jmp  alstill

  alred:                          ; redraw
    call aldraw_window
    jmp  alstill

  alkey:                        ; key
   ; mov  eax,2                 ; just read it and ignore
    int  0x40
    bt   [winstat],0
    jnc  alkey1
    cmp  ah,13
    je   alclose
    jmp  alstill
  alkey1:
    cmp  ah,27
    je   alclose
    cmp  ah,121
    je   rdd
    cmp  ah,110
    je   alclose
    cmp  ah,89
    je   rdd
    cmp  ah,78
    je   alclose
    jmp  alstill

  albutton:                     ; button
    mov  eax,17                 ; get id
    int  0x40

    cmp  ah,2                    ; button id=2 ?
    je   alclose
    cmp  ah,1
    jne  alnoclose
  rdd:
    mov  ebx,param
    mov  eax,32
    int  0x40

 alclose:
    bts  [winstat],1
    or   eax,-1
    int  0x40                 ; close this program
 alnoclose:
    jmp  alstill


aldraw_window:


    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40

                                   ; DRAW WINDOW
    xor  eax,eax                   ; function 0 : define and draw window
    mov  ebx,100*65536+260         ; [x start] *65536 + [x size]
    mov  ecx,100*65536+120         ; [y start] *65536 + [y size]
    mov  edx,0x02ffffff            ; color of work area RRGGBB,8->color gl
    mov  esi,0x80d54455            ; color of grab bar  RRGGBB,8->color gl
    mov  edi,0x00d54455            ; color of frames    RRGGBB
    int  0x40

    mov  eax,8                     ; function 8 : define and draw button
    mov  ecx,70*65536+20           ; [y start] *65536 + [y size]
    mov  edx,2                     ; button id
    mov  esi,0xd0c0b0
    bt   [winstat],0
    jc   butok
    mov  ebx,150*65536+50
    int  0x40
    sub  ebx,6553600
    dec  edx
    int  0x40
    jmp  aldrawtext
  butok:
    mov  ebx,100*65536+50
    int  0x40
  aldrawtext:
                                   ; WINDOW LABEL
    mov    eax,4                     ; function 4 : write text to window
    mov    ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov    ecx,0x10ffffff            ; color of text RRGGBB
    movzx  edx,byte [winpar]
    add    edx,allabelt
    mov    esi,8                     ; text length
    int    0x40
    mov    ebx,8*65536+35           ; draw info text with function 4
    mov    ecx,0x224466
    movzx  edx,word [winpar+1]
    add    edx,altext
    mov    esi,41
    int    0x40
    mov    ebx,95*65536+50
    movzx  edx,byte [winpar+3]
    add    edx,param
    mov    esi,11
    int    0x40
    mov    ebx,67*65536+76
    mov    ecx,0xffffff
    mov    esi,20
    bt     [winstat],0
    jc     ok
    mov    edx,albuttext
    int    0x40
    jmp    closewin
  ok:
    mov    edx,albuttext+18
    int    0x40

  closewin:
    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


;******************************************************************************

; DATA AREA

winpar: db 0,0,0,0
winstat dw 0
notdelete:  db 'HARDDISKRAMDISK FIRST   SECOND  THIRD   FOURTH  '
altext:
    db '      DO YOU REALLY WANT TO DELETE       '      ;0
    db '    THE OS DON"T SUPPORT HDD DELETING    '      ;41
    db 'NO HD BASE AND/OR FAT32 PARTITION DEFINED'      ;82
    db '    INVALID PARTITION AND/OR HD BASE     '      ;123
    db '      THIS FS DOESNT SUPPORTS YET        '      ;205
    db '               UNKNOWN FS                '      ;246
    db '              END OF FILE                '      ;287
    db '             FILE NOT FOUND              '      ;328
albuttext: db 'Yes              No        Ok       '
allabelt:
     db   'DELETINGWARNING '

buttonstring: db 'Re-read View(F3) Del(F8)                                 '
              db  0x18,'(PgUp) ',0x19,'(PgDn)'

buttonstringlen dd 72
drawid    db   0
butid     db   21
dirlen    dd   0x1
b_color   dd   0x6677cc
editor    db   'TINYPAD    '
bmpview   db   'MV         ' ;'BMPVIEW    '

beep:
db 0x90,0x30,0

fileinfo_start:
dd 16
dd 0
dd 0
dd 0
dd 0x10000

param     db 0
times 50 db 0

text      db   '/                       '
loclen    dd  0
readblock dd  1
labelt    db   'SYSTEM TREE'
labellen:

hdpathbeg db '/HD/1/'
rdpathbeg db '/RD/1/'

root      db   'ROOTDIR     '

location:

       db    '/           /           /           /           '
       db    '/           /           /           /           '
       db    '/           /           /           /           '
       db    '/           /           /           /           '
       db    '/           /           /           /           '
       db    '/           /           /           /           '
       db    '/           /           /           /           '
       db    '/           /           /           /           '


fileinfoblock:

   dd 0x0       ; read
   dd 0x0       ; first block
   dd 0x1       ; number of blocks to read
   dd 0x14000   ; ret
   dd 0x4000    ; work

I_END:
filedir:
rb 12*20

procinfo process_information
sc system_colors

fileinfo:
rb 16*62

data_area:
