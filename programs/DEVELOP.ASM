;
;    DEVELOPER INFO - Compile with fasm
;    < russian edition by Ivan Poddubny >
;
;    ИНФОРМАЦИЯ ДЛЯ РАЗРАБОТЧИКОВ 0.3
;    Компилировать FASM'ом
;    Иван Поддубный, ivan-yar@bk.ru
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
    db ' КАК ИЗМЕНИТЬ И ЗАПУСТИТЬ EXAMPLE.ASM В МЕНУЭТЕ             '
    db '                                                            '
    db ' 1) Отредактируйте файл в TINYPADе и сохраните              '
    db '    его на диск (нажмите "FILE", введите имя файла          '
    db '    и затем нажмите на кнопку "SAVE")                       '
    db ' 2) Откомпилируйте файл FASMом                              '
    db ' 3) При выходе из системы не забудьте сохранить образ       '
    db '    дискеты или сохранить программу с исходниками           '
    db '    на раздел FAT32                                         '
    db '                                                            '
    db ' SYSFUNCS.TXT - системные функции Менуэта                   '
    db ' SYSFUNCR.TXT - то же, но на русском языке                  '
    db '                                                            '
    db '                                                            '
    db ' КАК ИЗМЕНИТЬ И ОТКОМПИЛИРОВАТЬ ЯДРО В МЕНУЭТЕ              '
    db '                                                            '
    db ' Сначала нужно в WINDOWS или другой ОС распаковать          '
    db ' архив с исходниками ядра KERNEL.ZIP на дискету             '
    db ' 1) Отредактируйте код ядра в текстовом редакторе           '
    db ' 2) Откомпилируйте KERNEL.ASM в KERNEL.MNT                  '
    db ' 3) При выходе из системы выберите пункт 4 - RESTART KERNEL '
    db ' 4) Должно загрузиться новое перекомпилированное ядро.      '
    db '    На последний вопрос при загрузке нужно ответить:        '
    db '    3 - USE PRELOADED IMAGE                                 '
    db '                                                            '
    db ' Вы также можете перекомпилировать ядро в DOS, Linux        '
    db ' или Windows. Используйте FASM 1.40+                        '
    db 'x'

labelt:
    db   'ИНФОРМАЦИЯ ДЛЯ ПРОГРАММИСТОВ'
labellen:

I_END:
