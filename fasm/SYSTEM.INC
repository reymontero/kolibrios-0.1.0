; flat assembler  version 1.10
; Copyright (c) 1999-2000, Tomasz Grysztar
; All rights reserved.
;
; MenuetOS system.inc by VT

CREATE_NEW           =   1
CREATE_ALWAYS        =   2
OPEN_EXISTING        =   3
OPEN_ALWAYS          =   4
TRUNCATE_EXISTING    =   5

GENERIC_READ         =   80000000h
GENERIC_WRITE        =   40000000h

STD_INPUT_HANDLE     =   0FFFFFFF6h
STD_OUTPUT_HANDLE    =   0FFFFFFF5h
STD_ERROR_HANDLE     =   0FFFFFFF4h

MEM_COMMIT           =   1000h
MEM_RESERVE          =   2000h
MEM_DECOMMIT         =   4000h
MEM_RELEASE          =   8000h
MEM_FREE             =   10000h
MEM_PRIVATE          =   20000h
MEM_MAPPED           =   40000h
MEM_RESET            =   80000h
MEM_TOP_DOWN         =   100000h

PAGE_NOACCESS          =   1
PAGE_READONLY          =   2
PAGE_READWRITE         =   4
PAGE_WRITECOPY         =   8
PAGE_EXECUTE           =   10h
PAGE_EXECUTE_READ      =   20h
PAGE_EXECUTE_READWRITE =   40h
PAGE_EXECUTE_WRITECOPY =   80h
PAGE_GUARD             =   100h
PAGE_NOCACHE           =   200h

file_info_open:  dd  0,0,0xffffff,0x20000,0xf0000
fullpath_open:   db  '/HD/1/EXAMPLE.ASM'
                     times 100 db 0

file_info_write: dd  1,0,0,0,0xf0000
fullpath_write:  db  '/HD/1/EXAMPLE'
                     times 100 db 0

file_info_start: dd  16,0,0,0,0xf0000
fullpath_start:  db  '/HD/1/EXAMPLE'
                     times 100 db 0

_ramdisk         db  '/RD/1/'
filepos          dd  0x0

init_memory:

    mov  [memory_start],0x100000
    mov  edi,[memory_start]
    mov  edi,0x380000
    mov  [additional_memory_end],edi
    mov  eax,edi
    shr  eax,3
    sub  edi,eax
    mov  [memory_end],edi
    mov  [additional_memory],edi
    ret

exit_program:

    cmp  [_mode],NORMAL_MODE
    je   still
    or   eax,-1
    int  0x40

make_timestamp:

    push ebx
    mov  eax,26
    mov  ebx,9
    int  0x40
    pop  ebx
    imul eax,10
    ret

get_environment_variable:
;        mov     ecx,[memory_end]
;        sub     ecx,edi
;        push    ecx    ; size
;        push    edi    ; buffer
;        push    esi    ; name
;        call    [GetEnvironmentVariable]
;        add     edi,eax
;        cmp     edi,[memory_end]
;        jae     out_of_memory
        mov      ecx,[memory_end]
        sub      ecx,edi
        cmp      ecx,7
        jb       out_of_memory
        cmp      dword [esi], "INCL"
        jne      .finish
        mov      esi,_ramdisk
        mov      ecx,6
        cld
        rep      movsb
  .finish:
        ret

open:

    pusha

    call make_fullpaths
    mov  [file_info_open+8],dword 1
    mov  eax,58
    mov  ebx,file_info_open
    int  0x40
    push eax
    mov  esi,fullpath_open
    call display_string
    mov  esi,lf
    call display_string
    pop  eax

    cmp  eax,0   ; found
    je   op1

    popa
    stc
    ret

op1:mov  [file_info_open+8],dword -1
    mov  eax,58
    mov  ebx,file_info_open
    int  0x40
    mov  [filesize],ebx

    popa
    clc
    ret

create:

    call  make_fullpaths
    ret

write:

    pusha

    ;  ebx file handle
    ;  ecx count of bytes to write
    ;  edx pointer to buffer

    mov   [file_info_write+8],ecx
    mov   [file_info_write+12],edx
    mov   [filesize],edx
    mov   esi,fullpath_write
    call  display_string
    mov   esi,lf
    call  display_string
    mov   eax,58
    mov   ebx,file_info_write
    int   0x40

    popa
    ret

make_fullpaths:

    pusha
    push  edx

    mov   esi,path              ; open
    mov   edi,fullpath_open
    cld
   newc1:
    movsb
    cmp  [esi],byte ' '
    jne  newc1
    mov  esi,[esp]
    mov  ecx,12
    cld
    rep  movsb
    mov  [edi],byte 0

    mov   esi,path              ; write
    mov   edi,fullpath_write
    cld
   newc2:
    movsb
    cmp  [esi],byte ' '
    jne  newc2
    mov  esi,[esp]
    mov  ecx,12
    cld
    rep  movsb
    mov  [edi],byte 0

    mov   esi,path              ; start
    mov   edi,fullpath_start
    cld
  newc3:
    movsb
    cmp  [esi],byte ' '
    jne  newc3
    mov  esi,[esp]
    mov  ecx,12
    cld
    rep  movsb
    mov  [edi],byte 0

    add  esp,4
    popa
    ret

read:

    pusha
    mov  edi,edx
    mov  esi,[filepos]
    add  esi,0x20000
    cld
    rep  movsb
    popa
    ret

close:

    ret

lseek:

        cmp  al,0
        jnz  ls0
        mov  [filepos],dword 0
      ls0:
        cmp  al,1
        jnz  ls1
      ls1:
        cmp  al,2
        jnz  ls2
        mov  eax,[filesize]
        mov  [filepos],eax
      ls2:
        mov  eax,[filepos]
        add  eax,edx
        mov  [filepos],eax
        ret


display_character:

        pusha

        cmp     [_mode],NORMAL_MODE
        jne     @f

        cmp     dl,13
        jz      dc2
        cmp     dl,0xa
        jnz     dc1
        mov     eax,0x00190000
        mov     ax,word [textxy]
        add     ax,0x00000009
        mov     [textxy],eax

dc2:    popa
        ret

dc1:    mov     eax,4
        mov     ebx,[textxy]
        mov     ecx,[text_color]
        mov     [dc],dl
        mov     edx,dc
        mov     esi,1
        int     0x40
        mov     eax,[textxy]
        add     eax,0x00060000
        mov     [textxy],eax

        popa
        ret

@@:
        mov     eax,63
        mov     ebx,1
        mov     cl,dl
        int     0x40

        popa
        ret



display_string:

        pusha

dpl0:   cmp     [esi],byte 0
        jz      found0
        mov     dl,[esi]
        call    display_character
        add     esi,1
        jmp     dpl0

found0: popa
        ret

display_number:

       push ebx
       mov ecx,1000000000
       xor edx,edx
       xor bl,bl
      display_loop:
       div ecx
       push edx
       cmp ecx,1
       je display_digit
       or bl,bl
       jnz display_digit
       or al,al
       jz digit_ok
       not bl
      display_digit:
       mov dl,al
       add dl,30h
       push ebx ecx
       call display_character
       pop ecx ebx
      digit_ok:
       mov eax,ecx
       xor edx,edx
       mov ecx,10
       div ecx
       mov ecx,eax
       pop eax
       or ecx,ecx
       jnz display_loop
       pop ebx
       ret

display_block:

     pusha
bll: mov     dl,[esi]
     call    display_character
     add     esi,1
     loop    bll
     popa
     ret

fatal_error:
 mov esi,error_prefix
 call display_string
 pop esi
 call display_string
 mov esi,error_suffix
 call display_string

 mov esi,err
 call display_string

 mov al,0FFh
 jmp exit_program

assembler_error:

 call flush_display_buffer
 mov ebx,[current_line]
find_error_home:
 test byte [ebx+7],80h
 jz error_home_ok
 mov ebx,[ebx+8]
 jmp find_error_home
error_home_ok:
 mov esi,[ebx]
 call display_string
 mov esi,line_number_start
 call display_string
 mov eax,[ebx+4]
 call display_number
 mov dl,']'
 call display_character

 cmp ebx,[current_line]
 je line_number_ok
 mov dl,20h
 call display_character
 mov esi,[current_line]
 mov esi,[esi]
 movzx ecx,byte [esi]
 inc esi
 call display_block
 mov esi,line_number_start
 call display_string
 mov esi,[current_line]
 mov eax,[esi+4]
 and eax,7FFFFFFFh
 call display_number
 mov dl,']'
 call display_character
line_number_ok:

 mov esi,err
 call display_string

 mov esi,line_data_start
 call display_string

 mov esi,ebx
 mov edx,[esi]
 call open
 mov al,2
 xor edx,edx
 call lseek
 mov edx,[esi+8]
 sub eax,edx
 push eax
 xor al,al
 call lseek
 mov ecx,[esp]
 mov edx,[memory_start]
 call read
 call close
 pop ecx
 mov esi,[memory_start]

get_line_data:
 mov al,[esi]
 cmp al,0Ah
 je display_line_data
 cmp al,0Dh
 je display_line_data
 cmp al,1Ah
 je display_line_data
 or al,al
 jz display_line_data
 inc esi
 loop get_line_data
display_line_data:
 mov ecx,esi
 mov esi,[memory_start]
 sub ecx,esi
 call display_block
 mov esi,cr_lf
 call display_string
 mov esi,error_prefix
 call display_string
 pop esi
 call display_string
 mov esi,error_suffix
 call display_string
 jmp exit_program

character db ?,0
bytes_count dd ?

textxy    dd 0x001900A0
dc        db 0x0
filesize  dd 0x0
opent     db 'sys_open',0
filepost  db 'sys_lseek',0
createt   db 'sys_create',0
writet    db 'sys_write - saved',0
readt     db 'sys_read',0
closet    db 'sys_close',0
err       db 13,10,13,10,'Error(s) found',0

error_prefix db 'error: ',0
error_suffix db '.'
cr_lf db 0Dh,0Ah,0
line_number_start db ' [',0
line_data_start db ':',0Dh,0Ah,0

macro dm string { db string,0 }



