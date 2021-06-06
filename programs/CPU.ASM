;
;   PROCESS MANAGEMENT
;
;   VTurjanmaa
;   additions by M.Lisovin lisovin@26.ru
;   Compile with FASM for Menuet
;

  use32
  org    0x0

  db     'MENUET01'              ; 8 byte id
  dd     0x01                    ; header version
  dd     START                   ; start of code
  dd     I_END                   ; size of image
  dd     0x8000                 ; memory for app
  dd     0x8000                 ; esp
  dd     0x0 , 0x0               ; I_Param , I_Icon

include 'macros.inc'

START:                          ; start of execution

     mov  [addr],dword start_application
     mov  [ya],dword 382
red:
     call draw_window

still:

    mov  eax,23                 ; wait here for event
    mov  ebx,100
    int  0x40

    cmp  eax,1                  ; redraw request ?
    je   red
    cmp  eax,2                  ; key in buffer ?
    je   key
    cmp  eax,3                  ; button in buffer ?
    je   button

    call draw_process

    jmp  still

  key:                          ; key
    mov  eax,2                  ; just read it and ignore
    int  0x40
    cmp  ah,184
    je   pgdn
    cmp  ah,183
    je   pgup
    cmp  ah,27
    je   close
    jmp  still

  button:                       ; button
    mov  eax,17                 ; get id
    int  0x40


    shr  eax,8

    cmp  eax,10
    jb   noterm
    cmp  eax,50
    jg   noterm
    sub  eax,11
    mov  ebx,4
    mul  ebx
    add  eax,tasklist
    mov  ecx,dword [eax]
    mov  eax,18
    mov  ebx,2
    int  0x40
    jmp  still
  noterm:

    cmp  eax,51
    jne  noadd
  pgdn:
    cmp  [list_start],0
    je   still
    pop  [list_start]
    jmp  still
  noadd:

    cmp  eax,52
    jne  nosub
  pgup:
    mov  eax,[list_start]
    push eax
    add  eax,[list_add]
    mov  [list_start],eax
    and  [list_start],127
    jmp  still
  nosub:

    cmp  eax,53
    je   read_string

    cmp  eax,54
    jne  nostart
    mov  eax,58
    mov  ebx,file_start
    int  0x40
  nostart:
    cmp  eax,55
    jne  noreboot
    mov  eax,18
    mov  ebx,1
    int  0x40
  noreboot:

    cmp  eax,1                   ; button id=1 ?
    jne  noclose
  close:
    mov  eax,-1                 ; close this program
    int  0x40
  noclose:

    jmp  still



pos  equ 10*65536+45

list_start  dd 0

draw_process:
    pusha
  newprocess1:
    xor  eax,eax      ;cleaning tasklist
    mov  edi,tasklist
    mov  ecx,32
    cld
    rep  stosd

    mov  [listpos],0
    xor  edi,edi
    mov  [holes],0

  newprocess:
    inc  edi
    cmp  edi,32
    ja   nodrawbar

    mov  eax,13
    mov  ebx,pos
    mov  edx,ebx
    and  ebx,0xffff0000
    add  ebx,10*65536+500
    and  edx,0xffff
    mov  ecx,edi
    imul ecx,10
    add  ecx,edx
    shl  ecx,16
    add  ecx,9
    mov  edx,0xeeeeee
    int  0x40

  nodrawbar:
    mov  eax,9
    mov  ebx,I_END
    mov  ecx,edi
    add  ecx,[list_start]
    int  0x40

    cmp  ecx,eax
    jg   no_process1

    cmp  [I_END+22],dword 0 ; memory start
    jne  no_holes
    cmp  [I_END+50],word 9  ; slot state
    jne  no_holes
    inc  [holes]
    jmp  no_process
  no_holes:
    cmp  edi,[list_start]
    jb   newprocess
    je   corr_ls

    inc  [listpos]               ;start of drawing

    mov  eax,[listpos]
    dec  eax
    mov  ebx,4
    mul  ebx
    add  eax,tasklist
    mov  dword [eax],edi

    mov  eax,18
    mov  ebx,5
    int  0x40

    xor  edx,edx
    mov  ebx,100
    div  ebx

    mov  ebx,[I_END+0]

    xchg eax,ebx

    xor  edx,edx
    or   ebx,1
    div  ebx
    cmp  eax,0
    ja   noblack
    mov  [tcolor],0
    jmp  nored
  noblack:
    cmp  eax,80
    ja   nogreen
    mov  [tcolor],0x00107a30
    jmp  nored
  nogreen:
    mov  [tcolor],0x00ac0000
  nored:
    push eax

    mov  eax,4                 ; name of the process
    mov  ebx,[listpos]
;    imul ebx,10
    lea  ebx,[ebx+ebx*4]  ; ebx*=10!
    shl  ebx,1
    add  ebx,40*65536+pos
    mov  ecx,[tcolor]
    mov  edx,I_END+10
    mov  esi,11
    int  0x40

    mov  eax,47                ; list position
    mov  ebx,2*65536+1*256
    mov  ecx,edi
    ;add  ecx,[list_start]
    mov  edx,[listpos]
    imul edx,10
    add  edx,10*65536+pos
    mov  esi,[tcolor]
    int  0x40

                               ; display PID
    mov  ebx,8*65536+1*256
    mov  ecx,[I_END+30]
    add  edx,110*65536
    int  0x40
                               ; display cpu usage
    mov  ecx,[I_END+0]
    add  edx,10*6*65536
    int  0x40

    pop  ecx
                                ; display cpu usage %
    mov  ebx,3*65536+0*256
    add  edx,10*6*65536
    int  0x40
                                ; display memory start
    mov  ebx,8*65536+1*256
    mov  ecx,[I_END+22]
    add  edx,5*6*65536
    int  0x40
                                ; display memory usage
    mov  ecx,[I_END+26]
    inc  ecx
    add  edx,10*6*65536
    int  0x40
                                ; display window stack
    mov  ecx,[I_END+4]
    add  edx,10*6*65536
    int  0x40
                                ; display window xy size
    mov  ecx,[I_END+42]
    shl  ecx,16
    add  ecx,[I_END+46]
    add  edx,10*6*65536
    int  0x40

  no_process:
    cmp  [listpos],32
    jb   newprocess
  no_process1:
    cmp  edi,32
    jb   newprocess

    sub  edi,[list_start]
    mov  [list_add],edi
    popa

    ret

  corr_ls:
    mov  eax,edi
    sub  eax,[holes]
    xor  edx,edx
    mov  ebx,32
    div  ebx
    cmp  edx,0
    je   newprocess
    cmp  edx,16
    jb   corr_b
    mov  eax,32
    sub  eax,edx
    add  [list_start],eax
    jmp  newprocess
  corr_b:
    sub  [list_start],edx
    jmp  newprocess1

file_start: dd 16
            dd 0,0,0,0x10000

start_application: db '/RD/1/LAUNCHER',0
                   times 60 db 32
addr     dd  0x0
ya       dd  0x0

read_string:

    mov  edi,[addr]
    xor  eax,eax
    mov  ecx,40
    cld
    rep  stosb

    call print_text

    mov  edi,[addr]

  f11:
     mov  eax,23
     mov  ebx,100
    int  0x40
    call draw_process
    cmp  eax,0
    je   f11
    cmp  eax,2
    jne  read_done
    mov  eax,2
    int  0x40
    shr  eax,8
    cmp  eax,13
    je   read_done
    cmp  eax,8
    jnz  nobsl
    cmp  edi,[addr]
    jz   f11
    dec  edi
    mov  [edi],byte 32
    call print_text
    jmp  f11
  nobsl:
    cmp  al,95
    jbe  cok
    sub  al,32
  cok:
    mov  [edi],al

    call print_text

    inc  edi
    mov  esi,[addr]
    add  esi,30
    cmp  esi,edi
    jnz  f11

  read_done:

    mov  [edi],byte 0

    call print_text

    jmp  still


print_text:

    pusha

    mov  eax,13
    mov  ebx,264*65536+31*6
    mov  ecx,[ya]
    shl  ecx,16
    mov  cx,12
    sub  ecx,2*65536
    mov  edx,0xeeeeee
    int  0x40

    mov  eax,4
    mov  edx,[addr]
    mov  ebx,265*65536
    add  ebx,[ya]
    xor  ecx,ecx
    mov  esi,30
    int  0x40

    popa
    ret



;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************


draw_window:


    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40

    mov  eax,14
    int  0x40

    mov  ebx,eax
    mov  ecx,eax

    shr  ebx,16
    and  ebx,0xffff
    and  ecx,0xffff

    shr  ebx,1
    shr  ecx,1

    sub  ebx,300
    sub  ecx,200

    shl  ebx,16
    shl  ecx,16
                                   ; DRAW WINDOW
    xor  eax,eax                   ; function 0 : define and draw window
    mov  bx,600                    ; [x start] *65536 + [x size]
    mov  cx,400                    ; [y start] *65536 + [y size]
    mov  edx,0x03ffffff            ; color of work area RRGGBB,8->color gl
    mov  esi,0x805080d0            ; color of grab bar  RRGGBB,8->color gl
    mov  edi,0x005080d0            ; color of frames    RRGGBB
    int  0x40

                                   ; WINDOW LABEL
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov  ecx,0x10ffffff            ; font 1 & color ( 0xF0RRGGBB )
    mov  edx,labelt                ; pointer to text beginning
    mov  esi,labellen-labelt       ; text length
    int  0x40

    mov  ebx,22*65536+35           ; draw info text with function 4
    xor  ecx,ecx
    mov  edx,text
    mov  esi,100
    mov  eax,4
    int  0x40

    mov  eax,8                      ; terminate buttons
    mov  ebx,530*65536+55
    mov  ecx,55*65536+8
    mov  edx,11
    mov  esi,0xaabbcc
   newb:
    int  0x40
    add  ecx,10*65536
    inc  edx
    cmp  edx,11+32
    jb   newb
                                    ; previous
    mov  ebx,30*65536+96
    mov  ecx,380*65536+10
    mov  edx,51
    int  0x40
                                    ; next
    mov  ebx,130*65536+96
    inc  edx
    int  0x40
                                    ; text enter
    mov  ebx,237*65536+20
    inc  edx
    int  0x40
                                    ; start application
    mov  ebx,456*65536+63
    inc  edx
    int  0x40

    add  ebx,70*65536               ; reboot button
    inc  edx
    int  0x40


    mov  eax,4
    mov  ebx,30*65536+382
    xor  ecx,ecx
    mov  edx,tbts
    mov  esi,tbte-tbts
    int  0x40

    call draw_process

    call print_text

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


; DATA AREA
holes     dd 0
list_add  dd 0
listpos   dd 0
tcolor    dd 0x000000
tasklist: times 32 dd 0

text:
  db '     NAME           PID     CPU-USAGE  %   '
  db 'MEMORY START/USAGE  W-STACK   W-SIZE      TERMINATE'

tbts: db  '    PREV PAGE       NEXT PAGE       >  '
      db  '                                    RUN'
      db  '       REBOOT'
tbte:

labelt:
     db   'Processes - Ctrl/Alt/Del'
labellen:

I_END:
