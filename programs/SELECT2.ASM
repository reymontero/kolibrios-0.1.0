;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                    ;
;    PROGRAM SELECT                  ;
;                                    ;
;    Compile with fasm               ;
;                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


use32

               org   0x0

               db   'MENUET01'              ; 8 byte id
               dd   0x01                    ; version
               dd   START                   ; program start
               dd   I_END                   ; program image size
               dd   0x40000                 ; reguired amount of memor
               dd   0xfff0                  ; ESP
               dd   0,0                     ; param,icon

include 'macros.inc'

dat  db  'PANEL   DAT'

START:

    mov  eax,6
    mov  ebx,dat
    mov  ecx,0
    mov  edx,-1
    mov  esi,I_END
    int  0x40

    mov   edx,I_END
    add   edx,5*9+3
    movzx edx,byte [edx]
    sub  edx,48
    and  edx,1
    imul edx,20

    mov  eax,14                    ; get screen max x & max y
    int  0x40
    mov  ebx,eax
    shr  ebx,16
    inc  ebx
    mov  [x_max],ebx
    and  eax,65535
    sub  eax,41+16*22
    add  eax,edx
    mov  [y_start],eax
    mov  [y_size],16*16-1

    mov  [x_start],166
    mov  [x_size],140

;    call  get_transparent

    call  draw_window

still:

    mov  eax,10                    ; wait here for event
    int  0x40

    cmp  eax,1
    jz   red
    cmp  eax,2
    jz   key
    cmp  eax,3
    jz   button

    jmp  still

  red:
    call draw_window
    jmp  still

  key:
    mov  eax,2
    int  0x40
    jmp  still

  button:

    mov  eax,17
    int  0x40

    cmp  ah,1
    jnz  startapp

    mov  eax,0xffffffff   ; close this program
    int  0x40

  startapp:

    shr  eax,8
    and  eax,255
    sub  eax,11
    xor  edx,edx
    mov  ebx,11
    mul  ebx
    add  eax,apps

    mov  ebx,eax

    mov  eax,19
    mov  ecx,0
    int  0x40

    jmp  still



draw_transparent:

ret

    pusha

    mov  eax,7
    mov  ebx,0x10000
    mov  ecx,[x_size]
    shl  ecx,16
    add  ecx,[y_size]
    mov  edx,0
    int  0x40

    popa
    ret


get_transparent:

    pusha

    mov  eax,48                    ; get system colours
    mov  ebx,3
    mov  ecx,system_colours
    mov  edx,10*4
    int  0x40

    mov  eax,[x_start]
    add  eax,[x_size]
    mov  [x_end],eax
    mov  eax,[y_start]
    add  eax,[y_size]
    mov  [y_end],eax

    mov  eax,[x_start]
    mov  ebx,[y_start]

  dtpl1:

    push  eax
    push  ebx

    imul  ebx,[x_max]
    add   ebx,eax
    mov   eax,35
    int   0x40

    mov   ecx,eax
    and   ecx,0x00ff00
    cmp   ecx,0
    jne   cok
    mov   ecx,eax
    and   ecx,0x0000ff
    shl   ecx,8
    cmp   ecx,0
    jne   cok
    mov   ecx,eax
    and   ecx,0xff0000
    shr   ecx,8
    cmp   ecx,0
    jne   cok
  cok:
    mov   eax,ecx
    shr   eax,8

    mov   ebx,[esp+4]
    mov   ecx,[esp]
    sub   ebx,[x_start]
    sub   ecx,[y_start]
    imul  ecx,[x_size]
    imul  ebx,3
    imul  ecx,3
    add   ebx,ecx
    mov   [0x10000+ebx],eax

    pop   ebx
    pop   eax

    inc   eax
    cmp   eax,[x_end]
    jb    dtpl1
    mov   eax,[x_start]
    inc   ebx
    cmp   ebx,[y_end]
    jb    dtpl1

    popa

    ret



draw_window:

    pusha

    mov  eax,48                    ; get system colours
    mov  ebx,3
    mov  ecx,system_colours
    mov  edx,10*4
    int  0x40


    mov  eax,12                    ; tell os about redraw
    mov  ebx,1
    int  0x40

    mov  ecx,[y_start]
    shl  ecx,16
    add  ecx,[y_size]

    mov  eax,0                     ; define and draw window
    mov  ebx,[x_start]
    shl  ebx,16
    add  ebx,[x_size]
    mov  edx,[system_colours+24]
    mov  esi,edx
    mov  edi,edx
    int  0x40

     ; buttons

    mov  edx,text
    xor  edi,edi
    mov  ebx,15*65536+12
   newline2:
    cmp  [edx],byte ' '
    jz   noline2
    pusha
    mov  eax,8
    mov  ebx,0*65536+140
    mov  edx,11
    add  edx,edi
    shl  edi,4
    mov  ecx,edi
    shl  ecx,16
    add  ecx,15
    mov  esi,[system_colours+24]
    int  0x40
    popa
   noline2:
    add  ebx,16
    add  edx,32
    inc  edi
    cmp  [edx],byte 'x'
    jnz  newline2

;    call draw_transparent

    ; text

    mov  edx,text
    xor  edi,edi
    mov  ebx,15*65536+4
   newline:
    cmp  [edx],byte ' '
    jz   noline
    mov  eax,4
    mov  ecx,0xffffff
    mov  esi,32
    int  0x40
   noline:
    add  ebx,16
    add  edx,32
    inc  edi
    cmp  [edx],byte 'x'
    jnz  newline

    mov  eax,12                    ; tell os about redraw end
    mov  ebx,2
    int  0x40

    popa
    ret




; DATA AREA

x_start  dd 5
y_start  dd 220

x_size   dd 141
y_size   dd 200

x_end    dd 0
y_end    dd 0

x_max    dd 0

if lang eq ru
text:
    db 'àçîéêåÄñàü                      '
    db 'áÄÉêìáäÄ èêéñÖëëéêÄ             '
    db 'óÄëíéíÄ èêéñÖëëéêÄ              '
    db 'èÄåüíú                          '
    db 'SYSCALL TRACE                   '
    db 'èêéñÖëëõ                        '
    db 'íÖëí áÄôàíõ                     '
    db 'éíãÄÑäÄ                         '
    db 'HEXVIEW FOR HD                  '
    db 'ÄêïàÇÄíéê                       '
    db 'äéèàêéÇÄíú îÄâã                 '
    db 'çÄëíêéâäÄ ìëíêéâëíÇ             '
    db 'çÄëíêéâäÄ îéçÄ                  '
    db 'èêéëåéíê BMP îÄâãéÇ             '
    db 'çÄëíêéâäÄ ñÇÖíéÇ                '
    db 'çÄëíêéâäÄ èÄçÖãà                '
    db 'x'
else
text:
    db 'INFORMATION                     '
    db 'CPU LOAD HISTORY                '
    db 'CPU SPEED                       '
    db 'MEMORY USAGE                    '
    db 'SYSCALL TRACE                   '
    db 'CPU USAGE/APP                   '
    db 'TEST PROTECTION                 '
    db 'DEBUG BOARD                     '
    db 'HEXVIEW FOR HD                  '
    db 'LZP ARCHIVER                    '
    db 'FILE COPIER                     '
    db 'DEVICE SETUP                    '
    db 'BACKGROUND II                   '
    db 'MEVIEW                          '
    db 'DESKTOP COLOURS                 '
    db 'PANEL SETUP                     '
    db 'x'
end if

apps:
    db 'INFO       '
    db 'SYSMETER   '
    db 'CPUSPEED   '
    db 'MEMUSE     '
    db 'SYSTRACE   '
    db 'CPU        '
    db 'TEST       '
    db 'BOARD      '
    db 'HEXHD      '
    db 'MHC        '
    db 'COPY2      '
    db 'SETUP      '
    db 'PIC4       '
    db 'MV         '
    db 'DESKTOP    '
    db 'SPANEL     '


system_colours:


I_END:
