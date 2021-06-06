;
;   LAUNCHER - АВТОЗАПУСК ПРОГРАММ
;
;   Compile with flat assembler 1.50
;

  use32
  org    0x0
  db     'MENUET01'              ; 8 byte id
  dd     0x01                    ; header version
  dd     START                   ; start of code
  dd     I_END                   ; size of image
  dd     0x100000                ; memory for app
  dd     0x7fff0                 ; esp
  dd     0x0 , 0x0               ; I_Param , I_Icon
include 'macros.inc'

START:                          ; start of execution


    call make_table

    call draw_window

    mov  ecx,25

  newdelay2:

    mov  eax,5
    mov  ebx,4
    int  0x40

    call update_candy

    loop newdelay2


still:

    mov  eax,11                 ; wait here for event
    int  0x40

    cmp  eax,1                  ; redraw request ?
    je   red
    cmp  eax,2                  ; key in buffer ?
    je   key
    cmp  eax,3                  ; button in buffer ?
    je   button

    call launch_applications

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


applications  dd  file_list

files         dd  7         ; сколько программ будем запускать? (6)


file_list:

; имя файла
; параметры
; время ожидания

    db   'GRSCREEN        ' ; установим фон
    db   'BOOT            '
    dd   50 ; 60

    db   'SETUP           ' ; восстановим системные настройки
    db   'BOOT            '
    dd   30 ; 40

    db   'RB              ' ; подготовим контекстное меню рабочего стола
    db   'HI!             '
    dd   10 ; 40

    db   'SS              ' ; скринсейвер
    db   'SCREENSAVER     '
    dd   10 ; 40

    db   'ICONMNGR        ' ; расставим значки на рабочем столе
    db   'BOOT            '
    dd   40 ; 60

    db   'PANEL           ' ; запустим панель задач
    db   'BOOT            '
    dd   10

    db   'JPGBG           ' ; установка обоев
    db   '                '
    dd   10

    ; total: 50+30+10+10+40+10 = 150 (1,5 sec.)
    ;        60+40+40+40+60+10 = 250 (2,5 sec.)

star db  '*'

pos dd   35*65536+45


launch_applications:

    pusha

    mov  eax,4
    mov  ebx,[pos]
    mov  ecx,0x000000
    mov  edx,star
    mov  esi,1
    int  0x40

    add  [pos],10

    mov  eax,19
    mov  ebx,[applications]
    mov  ecx,ebx
    add  ecx,16
    int  0x40

    push ecx

    mov  ecx,[ecx+16]
    shr  ecx,2

  newdelay:

    mov  eax,5
    mov  ebx,4
    int  0x40

    call update_candy

    loop newdelay

    pop  ecx

    dec  [files]
    jne  more
    mov  eax,-1
    int  0x40
  more:

    add  [applications],32+4

    popa

    ret


update_candy:

    pusha

    sub  [cstate],2
    and  [cstate],63

    mov  ecx,[cstate]
    imul ecx,3
    mov  ebx,0x80000+32*3
    add  ebx,ecx
    mov  ecx,271*65536+1
    mov  edx,15*65536+105 ;83
    mov  edi,4
  newddd:
    mov  esi,10
  newdd:
    mov  eax,7
    int  0x40
    add  ebx,512*3
    add  edx,1
    dec  esi
    jnz  newdd

    popa

    ret



cstate  dd 0x0


make_table:

    pusha

    mov  edi,0x80000
    mov  eax,0xffffff

    mov  ecx,11
  newgg:
    push ecx
    mov  ecx,512
   newg:
    mov  [edi],eax
    add  edi,3
    loop newg
     sub  eax,0x0a0802
     pop  ecx
    loop newgg


    mov  edi,0x80000+64*3
    mov  eax,0x8899ff

    mov  ecx,10
  newgg2:
    push ecx
    mov  ecx,32
  newg2:
    mov  [edi],eax
    mov  [edi+64*3],eax
    mov  [edi+128*3],eax
    mov  [edi+192*3],eax
    mov  [edi+256*3],eax
    mov  [edi+256*3+64*3],eax
    mov  [edi+256*3+128*3],eax
    mov  [edi+256*3+192*3],eax

    add  edi,3
    loop newg2
    sub  eax,0x080808
    pop  ecx
    add  edi,3+224*3+256*3
    loop newgg2

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

    mov  ecx,eax
    and  ecx,0xffff
    shr  ecx,1
    sub  ecx,100
    shl  ecx,16

    shr  eax,17
    sub  eax,150
    shl  eax,16
    mov  ebx,eax

                                   ; DRAW WINDOW
    mov  eax,0                     ; function 0 : define and draw window
    mov  bx,300                    ; [x start] *65536 + [x size]
    mov  cx,125                    ; [y start] *65536 + [y size]
    mov  edx,0x03ffffff            ; color of work area RRGGBB,8->color gl
    mov  esi,0x805080d0            ; color of grab bar  RRGGBB,8->color gl
    mov  edi,0x005080d0            ; color of frames    RRGGBB
    int  0x40

                                   ; WINDOW LABEL
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov  ecx,0x10ddeeff            ; color of text RRGGBB
    mov  edx,labelt                ; pointer to text beginning
    mov  esi,labellen-labelt       ; text length
    int  0x40

                                   ; APPLICATION // PARAMETER
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,45*65536+30           ; [x start] *65536 + [y start]
    mov  ecx,0x000000            ; color of text RRGGBB
    mov  edx,text                  ; pointer to text beginning
    mov  esi,textlen-text          ; text length
    int  0x40


    mov  ebx,45*65536+45           ; draw info text with function 4
    mov  ecx,0x224466
    mov  edx,file_list
    mov  esi,32
    mov  edi,[files]
  newline:
    mov  eax,4
    int  0x40
    add  ebx,10
    add  edx,32+4
    dec  edi
    jnz  newline

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


; DATA AREA

if lang eq ru
  labelt:
       db   'АВТОЗАПУСК ПРОГРАММ'
  labellen:

  text:
       db   'ПРИЛОЖЕНИЕ      ПАРАМЕТРЫ'
  textlen:
else
  labelt:
       db   'LAUNCHER'
  labellen:

  text:
       db   'APPLICATION     PARAMETER'
  textlen:
end if

I_END:
