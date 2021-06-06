; Hello, World! - Programm example for CMD shell
; Compile with FASM for Menuet
;
; You must run this program from CMD shell only
;

use32

   org 0x0

   db 'MENUET01'
   dd 0x01
   dd START
   dd I_END
   dd 0x100000
   dd 0x7fff0
   dd 0x0
   dd 0x0

include "CMDIPC.INC"       ; Подключить файл CMDIPC.INC

START:
 call initipc              ; инициализировать для работы с CMD

 mov eax,52                ; длина строки
 mov ebx,text1             ; указатель на строку
 call print                ; вывести строку

 call eol                  ; пропустить строку

 mov eax,68
 mov ebx,text2
 call print

 call eol
 call eol

 mov eax,26
 mov ebx,text3
 call print

again:
 call getkey               ; Ожидать нажатия клавиши и считать ее в key

 cmp byte [key],'Y'        ; Тут программа проверяет, нажата ли нужн. клавиша
 je goodday
 cmp byte [key],'y'
 je goodday
 cmp byte [key],'N'
 je goodmorning
 cmp byte [key],'n'
 je goodmorning

 jmp again                 ; Если нужн. клавиша не нажата, то считать клавишу
                           ; заново
goodday:                   ; Вывести приветствие Good Day, World!
 call eol

 mov eax,16
 mov ebx,text4
 call print

 call eol

 jmp endipc                ; Завершить программу

goodmorning:               ; Вывести приветствие Good Morning, World!
 call eol

 mov eax,20
 mov ebx,text5
 call print

 call eol

 jmp endipc                ; Заверщить программу

text1 db 'You deactivated CMD-window by running other program.'
text2 db 'Please, move your mouse pointer to CMD-window and press left button.'
text3 db 'Is it after 12 noon? [Y\N]?'

text4 db 'Good day, World!'
text5 db 'Good morning, World!'

I_END:
