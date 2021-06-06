;
; END
;

include "macros.inc"

meos_app_start
code

    mov   eax,40
    mov   ebx,0101b
    int   0x40

    call  draw_window

still:

    mov  eax,10                 ; wait here for event
    int  0x40

    cmp  eax,1
    jz   red
    cmp  eax,3
    jz   button

    jmp  still

  red:
    call draw_window
    jmp  still

  button:
    mov  eax,17
    int  0x40

    cmp  ah,1
    jne  close

  boot:
    mov  eax,18    ; system boot
    mov  ebx,1
    int  0x40

  close:
    or   eax,-1    ; close this program
    int  0x40


draw_window:

    pusha

    mov  eax,48
    mov  ebx,3
    mov  ecx,sc
    mov  edx,sizeof.system_colors
    int  0x40

    mov  eax,12                    ; tell os about redraw start
    mov  ebx,1
    int  0x40

    mov  eax,14                    ; get screen max x & max y
    int  0x40

    shr  eax,17
    sub  eax,78
    shl  eax,16
    mov  ebx,eax
    add  ebx,150

    mov  eax,0                     ; define and draw window
    mov  ecx,200*65536+65
    mov  edx,[sc.work_button]
    mov  esi,[sc.work_button]
    mov  edi,0xffffff
    int  0x40

    mov  eax,8
    mov  ebx,15*65536+55           ; button start x & size
    mov  ecx,40*65536+12           ; button start y & size
    mov  edx,1                     ; button number
    mov  esi,[sc.work_button]      ; button color
    int  0x40

    mov  ebx,80*65536+55           ; button start x & size
    inc  edx
    int  0x40


    mov  eax,4                     ; 0x00000004 = write text
    mov  ebx,15*65536+19
    mov  ecx,[sc.work_button_text] ; 8b window nro - RR GG BB color
    mov  edx,label1                ; pointer to text beginning
    mov  esi,label1_len            ; text length
    int  0x40

    mov  ebx,14*65536+43
    mov  edx,label2                ; pointer to text beginning
    mov  esi,label2_len            ; text length
    int  0x40

    mov  eax,12                    ; tell os about redraw end
    mov  ebx,2
    int  0x40

    popa

    ret



data

if lang eq ru

  label1:
      db   '     Çõ ìÇÖêÖçõ?'
  label1_len = $ - label1

  label2:
      db   '    ÑÄ        çÖí'
  label2_len = $ - label2

else

  label1:
      db   '     EXIT MENUET     '
  label1_len = $ - label1

  label2:
      db   '    OK       CANCEL   '
  label2_len = $ - label2

end if


udata
  sc  system_colors


meos_app_end
