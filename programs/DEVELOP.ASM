;
;    DEVELOPER INFO - Compile with fasm
;    < russian edition by Ivan Poddubny >
;
;    ���������� ��� ������������� 0.3
;    �������஢��� FASM'��
;    ���� ����㡭�, ivan-yar@bk.ru
;

include 'macros.inc'

use32
         org    0x0
         db     'MENUET00'      ; 8 byte id
         dd     38              ; required os
         dd     START           ; program start
         dd     I_END           ; program image size
         dd     0x100000        ; required amount of memory
                                ; esp = 0x7fff0
         dd     0x00000000      ; reserved=no extended header

START:                          ; start of execution

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

    ;jmp  still

  key:                          ; key
    mov  eax,2                  ; just read it and ignore
    int  0x40

    jmp  still

  button:                       ; button
    mov  eax,17
    int  0x40

    or   eax,-1                 ; close this program
    int  0x40


;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************


draw_window:

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40
                                   ; DRAW WINDOW
    xor  eax,eax                   ; function 0 : define and draw window
    mov  ebx, 50*65536+385         ; [x start] *65536 + [x size]
    mov  ecx,100*65536+310         ; [y start] *65536 + [y size]
    mov  edx,0x03ffffff            ; color of work area RRGGBB
    mov  esi,0x8099bbff            ; color of grab bar  RRGGBB,8->color glide
    mov  edi,0x0099bbee            ; color of frames    RRGGBB
    int  0x40

                                   ; WINDOW LABEL
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov  ecx,0x10ffffff            ; color of text RRGGBB
    mov  edx,labelt                ; pointer to text beginning
    mov  esi,labellen-labelt       ; text length
    int  0x40

    mov  ebx,20*65536+30           ; draw info text with function 4
    xor  ecx,ecx
    mov  edx,text
    mov  esi,60
  newline:
    mov  eax,4
    int  0x40
    add  ebx,10
    add  edx,60
    cmp  [edx],byte 'x'
    jnz  newline

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


; DATA AREA

; +5 lines

text:
    db ' ��� �������� � ��������� EXAMPLE.ASM � �������             '
    db '                                                            '
    db ' 1) ��।������ 䠩� � TINYPAD� � ��࠭��              '
    db '    ��� �� ��� (������ "FILE", ������ ��� 䠩��          '
    db '    � ��⥬ ������ �� ������ "SAVE")                       '
    db ' 2) �⪮�������� 䠩� FASM��                              '
    db ' 3) �� ��室� �� ��⥬� �� ������ ��࠭��� ��ࠧ       '
    db '    ��᪥�� ��� ��࠭��� �ணࠬ�� � ��室������           '
    db '    �� ࠧ��� FAT32                                         '
    db '                                                            '
    db ' SYSFUNCS.TXT - ��⥬�� �㭪樨 ������                   '
    db ' SYSFUNCR.TXT - � ��, �� �� ���᪮� �몥                  '
    db '                                                            '
    db '                                                            '
    db ' ��� �������� � ��������������� ���� � �������              '
    db '                                                            '
    db ' ���砫� �㦭� � WINDOWS ��� ��㣮� �� �ᯠ������          '
    db ' ��娢 � ��室������ �� KERNEL.ZIP �� ��᪥��             '
    db ' 1) ��।������ ��� �� � ⥪�⮢�� ।����           '
    db ' 2) �⪮�������� KERNEL.ASM � KERNEL.MNT                  '
    db ' 3) �� ��室� �� ��⥬� �롥�� �㭪� 4 - RESTART KERNEL '
    db ' 4) ������ ����㧨���� ����� ��४������஢����� ��.      '
    db '    �� ��᫥���� ����� �� ����㧪� �㦭� �⢥���:        '
    db '    3 - USE PRELOADED IMAGE                                 '
    db '                                                            '
    db ' �� ⠪�� ����� ��४������஢��� �� � DOS, Linux        '
    db ' ��� Windows. �ᯮ���� FASM 1.40+                        '
    db 'x'

labelt:
    db   '���������� ��� �������������'
labellen:

I_END:
