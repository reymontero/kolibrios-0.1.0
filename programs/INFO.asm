;;
;;    INFO  - Compile with FASM
;;

use32

                 org    0x0

                 db     'MENUET00'              ; 8 byte id
                 dd     38                      ; required os
                 dd     START                   ; program start
                 dd     I_END                   ; program image size
                 dd     0x100000                ; reguired amount of memory
                 dd     0x00000000              ; reserved=no extended header


START:


    mov  eax,12                    ; tell os about redraw
    mov  ebx,1
    int  0x40

    mov  eax,0                     ; define and draw window
    mov  ebx,420*65536+215
    mov  ecx,40*65536+290
    mov  edx,0x031111aa
    mov  esi,0x80335599            ; 8 -> color glide
    mov  edi,0x0099bbee
    int  0x40

    ; info text

    mov  eax,26
    mov  ebx,5
    int  0x40

    mov  [syslang],eax

    cmp  eax,1
    jnz  no_eng
    mov  edx,text_eng

    call infoeng

  no_eng:

    cmp  eax,2
    jnz  no_fin
    mov  edx,text_fin

    call infoeng

  no_fin:

    cmp  eax,3
    jnz  no_ger
    mov  edx,text_ger

    call infoeng

  no_ger:

    cmp  eax,4
    jnz  no_rus
    mov  edx,text_rus

    call inforus

  no_rus:


    xor  edi,edi
    mov  ebx,12*65536+45
  newline:
    mov  eax,4
    mov  ecx,0xffffff
    mov  esi,32
    int  0x40
    add  ebx,8
    add  edx,32
    inc  edi
    cmp  edi,30
    jnz  newline

    mov  eax,12                    ; tell os about redraw end
    mov  ebx,2
    int  0x40

still:

    mov  eax,26
    mov  ebx,5
    int  0x40

    mov  edx,[syslang]
    cmp  eax,edx
    jz   oklang

    jmp  START

  oklang:


    mov  eax,23                 ; wait here for event
    mov  ebx,100
    int  0x40

    cmp  eax,1
    jz   red
    cmp  eax,2
    jz   key
    cmp  eax,3
    jz   button

    jmp  still

  red:
    jmp  START

  key:

    mov  eax,2
    int  0x40

    jmp  still

  button:

    mov  eax,0xffffffff ; close this program
    int  0x40

    ; end of program



infoeng:

    pusha

    mov  eax,dword 0x00000004      ; 0x00000004 = write text
    mov  ebx,8*65536+8
    mov  ecx,dword 0x00ffffff      ; 8b window nro - RR GG BB color
    mov  edx,labelt                ; pointer to text beginning
    mov  esi,labellen-labelt       ; text length
    int  0x40

    popa

    ret


inforus:

    pusha

    mov  eax,dword 0x00000004      ; 0x00000004 = write text
    mov  ebx,8*65536+8
    mov  ecx,dword 0x00ffffff      ; 8b window nro - RR GG BB color
    mov  edx,labelr                ; pointer to text beginning
    mov  esi,labellenr-labelr      ; text length
    int  0x40

    popa

    ret


syslang dd 0x0

text_eng:

    db '         Menuet Beta            '
    db 'Copyright(c)2001 Ville Turjanmaa'
    db '                                '
    db ' Menuet is distributed under GPL'
    db 'see file \COPYING for details.  '
    db '                                '
    db 'eMail is welcome to             '
    db '                                '
    db '  villemt@silmu.jyu.fi          '
    db '                                '
    db 'for mailing me about develop-   '
    db 'ment or .. you name it.         '
    db '                                '
    db ' The diskette can be modified   '
    db 'in Wind*ws or Linux.            '
    db '                                '
    db ' Sources to all applications    '
    db 'and kernel are included to the  '
    db 'diskette. Compile with          '
    db 'FASM 1.30 and above.            '
    db '                                '
    db ' Menuet is fully written in     '
    db '32 bit assembly.                '
    db '                                '
    db 'Sources:                        '
    db '-www.menuetos.org               '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '

text_fin:

    db '         Menuet Beta            '
    db 'Copyright(c)2001 Ville Turjanmaa'
    db '                                '
    db ' Menuet k',193,'ytt',194,'j',193,'rjestelm',193,193,' voit '
    db 'jakaa ja k',193,'ytt',193,193,' vapaasti kunhan'
    db 'GPL ehdot tayttyvat, /COPYING.  '
    db 'S',193,'hk',194,'posti on tervetullutta     '
    db '                                '
    db '  villemt@silmu.jyu.fi          '
    db '                                '
    db 'osotteeseen. Voit lahett',193,193,'      '
    db 'postia asiasta kuin asiasta..   '
    db '                                '
    db ' Levykett',193,' voit muokata henkil',194,'-'
    db 'kohtaiseen k',193,'ytt',194,194,'n mm. Linuxin '
    db 'ja Windowsin avulla.            '
    db '                                '
    db ' L',193,'hdekoodit kaikkiin ohjelmiin '
    db 'sek',193,' k',193,'ytt',194,'j',193,'rjestelm',193,193,'n        '
    db 'ovat levyll',193,'. K',193,'yt',193,' k',193,193,'nt',193,'j',193,'n'
    db 193,'  '
    db 'Fasm 1.30+                      '
    db '                                '
    db ' Menuet on t',193,'ysin kirjoitettu   '
    db '32 bit konekielell',193,'.            '
    db '                                '
    db 'L',193,'hteet:                        '
    db '-www.menuetos.org               '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '


text_ger:

    db '         Menuet Beta            '
    db 'Copyright(c)2001 Ville Turjanmaa'
    db '                                '
    db ' Menuet ist GPL-ware, das heisst'
    db 'man kann es frei verteilen,     '
    db 'solange die Copyright nicht     '
    db 'verфndert wird.                 '
    db '                                '
    db 'eMail willkommen an             '
    db '  villemt@silmu.jyu.fi          '
    db '                                '
    db 'zum mailen ьber Entwicklung     '
    db ' oder ьber was auch immer ..    '
    db '                                '
    db ' Die Diskette kann unter Wind*ws'
    db 'oder Linux verфndert werden wenn'
    db 'man den Kernel nicht verschiebt,'
    db 'seine Position ist fix.         '
    db '                                '
    db ' Sources zu allen Applikationen '
    db 'und zum Kernel sind auf der Disk'
    db 'und zu kompilieren mit          '
    db 'nasm 0.98+ und fasm.            '
    db '                                '
    db ' Menuet ist ganz in             '
    db '32 bit assembler geschrieben.   '
    db '                                '
    db 'Sources:                        '
    db '-www.menuetos.org               '
    db '                                '
    db '                                '
    db '                                '




text_rus:

    db '  Операционная система KOLIBRI  '
    db '  РУССКАЯ ВЕРСИЯ - MENUET OS    '
    db '                                '
    db 'Copyright(c)2001 Ville Turjanmaa'
    db 'Menuet распространяется под     '
    db 'лицензией GPL. См. COPYING.TXT  '
    db '                                '
    db 'Свои отзывы и предложения       '
    db 'присылайте по адресу            '
    db 'villemt@silmu.jyu.fi            '
    db ' - Ville Turjanmaa (автор ОС)   '
    db 'ivan-yar@bk.ru                  '
    db ' - Иван Поддубный (этот дистриб)'
    db 'mario79@bk.ru - Mario79 (то же) '
    db 'Вы можете изменять содержимое   '
    db 'дискеты в Windows или Linux.    '
    db '                                '
    db 'Вы можете скачать исходники с   '
    db 'www.mario79.narod.ru/menuet.htm '
    db 'www.meosfiles.narod.ru          '
    db 'Компилируйте их с помощью       '
    db 'FASM 1.52.                      '
    db '                                '
    db 'Menuet полностью написан на     '
    db '32-битном ассемблере.           '
    db '                                '
    db 'Официальный сайт:               '
    db 'http://www.menuetos.org         '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '
    db '                                '


labelt:
    db   'MENUET INFO'
labellen:

labelr:
    db   140,128+5,128+13,144+3,144+13,144+2
labellenr:

I_END:
