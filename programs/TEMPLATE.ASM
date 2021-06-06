; <--- description --->
; compiler:     FASM 1.50
; name:         Basic window example for MenuetOS
; version:      1.00
; last update:  10/01/2004
; written by:   Ivan Poddubny
; e-mail:       ivan-yar@bk.ru


; <--- include all MeOS stuff --->
include "macros.inc"


; <--- start of MenuetOS application --->
meos_app_start


; <--- start of code --->
code
    call    draw_window            ; at first create and draw the window

  wait_event:                      ; main cycle
    mov     eax,10
    int     0x40

    cmp     eax,1                  ;   if event == 1
    je      redraw                 ;     jump to redraw handler
    cmp     eax,2                  ;   else if event == 2
    je      key                    ;     jump to key handler
    cmp     eax,3                  ;   else if event == 3
    je      button                 ;     jump to button handler

    jmp     wait_event             ;   else return to the start of main cycle


  redraw:                          ; redraw event handler
    call    draw_window
    jmp     wait_event


  key:                             ; key event handler
    mov     eax,2                  ;   get key code
    int     0x40

    jmp     wait_event

  button:                          ; button event handler
    mov     eax,17                 ;   get button identifier
    int     0x40

    cmp     ah,1
    jne     wait_event             ;   return if button id != 1

    or      eax,-1                 ;   exit application
    int     0x40


  draw_window:
    mov     eax,12                 ; start drawing
    mov     ebx,1
    int     0x40

    mov     eax,0                  ; create and draw the window
    mov     ebx,100*65536+300      ;   (window_cx)*65536+(window_sx)
    mov     ecx,100*65536+200      ;   (window_cy)*65536+(window_sy)
    mov     edx,0x03000000         ;   work area color & window type 3
    mov     esi,0                  ;   grab color (not used)
    mov     edi,0                  ;   frame color (not used)
    int     0x40

    mov     eax,4                  ; window header
    mov     ebx,8*65536+8          ;   coordinates
    mov     ecx,0x10ffffff         ;   color & font N1
    mov     edx,header             ;   address of text
    mov     esi,header_len         ;   length of text
    int     0x40

    mov     eax,12                 ; finish drawing
    mov     ebx,2
    int     0x40

  ret



; <--- initialised data --->
data
  header:
    db      "EXAMPLE APPLICATION"  ; window header
  header_len = $ - header



; <--- uninitialised data --->
udata


meos_app_end
; <--- end of MenuetOS application --->