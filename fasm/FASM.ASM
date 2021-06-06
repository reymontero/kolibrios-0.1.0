;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                 ;;
;;  flat assembler source                          ;;
;;  Copyright (c) 1999-2002, Tomasz Grysztar       ;;
;;  All rights reserved.                           ;;
;;                                                 ;;
;;  Menuet port by VT                              ;;
;;                                                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NORMAL_MODE    = 8
CONSOLE_MODE   = 32

;; Menuet header

use32

  org 0x0
  db 'MENUET01'  ; 8 byte id
  dd 0x01        ; header version
  dd START       ; program start
  dd program_end ; program image size
  dd 0x400000    ; reguired amount of memory
  dd 0xDFFF0     ; stack
  dd params,0x0  ; parameters,icon

include 'version.inc'

START:    ; Start of execution

   cmp     byte [params],0
   jz      noparams

   mov     ecx,37
   mov     al,' '
   mov     edi,infile
   push    ecx
   cld
   rep     stosb
   mov     ecx,[esp]
   mov     edi,outfile
   rep     stosb
   pop     ecx
   mov     edi,path
   rep     stosb

   mov     esi,params
   mov     edi,infile

   call    mov_param_str

   inc     esi
   mov     edi,outfile

   call    mov_param_str

   inc     esi
   mov     edi,path

   call    mov_param_str

   cmp     [esi], dword ',run'
   jne     @f
   mov     [_run_outfile],1
  @@:

   mov     [_mode],CONSOLE_MODE
   jmp     start

  noparams:

    call draw_window

still:

    mov  eax,10   ; Wait here for event
    int  0x40

    dec  eax   ; Redraw request
    jz   red
    dec  eax   ; Key in buffer
    jz   key
    dec  eax   ; Button in buffer
    jz   button

    jmp  still

red:    ; Redraw
    call draw_window
    jmp  still

key:    ; Key
    mov  eax,2   ; Read it and ignore
    int  0x40
    jmp  still

button:    ; Button in Window

    mov  eax,17
    int  0x40

    cmp  ah,2   ; Start compiling
    jnz  nostart
    jmp  start
   nostart:

    cmp  ah,3   ; Start compiled file
    jnz  norunout

    mov  edx,outfile
    call make_fullpaths
    mov  eax,58
    mov  ebx,file_info_start
    xor  ecx,ecx
    int  0x40
    jmp  still
   norunout:

    cmp  ah,11   ; Infile
    je  f1
    cmp  ah,12   ; Outfile
    je  f2
    cmp  ah,13   ; Path
    je  f3

    dec  ah   ; Close application
    jnz  still

    or   eax,-1
    int  0x40

draw_window:

    pusha

    mov  eax,12      ; Start of draw
    xor  ebx,ebx
    inc  ebx
    int  0x40

    xor  eax,eax     ; Draw Window
    mov  ebx,50*65536+285
    mov  ecx,50*65536+320
    mov  edx,0x02000000
    add  edx,[background]
    mov  esi,[borders]
    mov  edi,esi
    add  esi,0x80000000
    int  0x40

    mov  eax,8      ; Button: Close Fasm
    mov  ebx,(285-19)*65536+12
    mov  ecx,5*65536+12
    xor  edx,edx
    inc  edx
    mov  esi,[sbutton]
    int  0x40

       ; Button: Compile Application
    mov  ebx,28*65536+105
    mov  ecx,132*65536+13
    inc  edx
    int  0x40

       ; Button: Start Application
    mov  ebx,148*65536+105
    inc  edx
    int  0x40

       ; Button: Enter Infile
    mov  ebx,222*65536+28
    mov  ecx,84*65536+9
    mov  edx,11
    mov  esi,[sbutton]
    int  0x40

       ; Button: Enter Outfile
    mov  ecx,94*65536+9
    inc  edx
    int  0x40

       ; Button: Enter Path
    mov  ecx,104*65536+9
    inc  edx
    int  0x40

    mov  eax,4      ; Draw Window Label Text
    mov  ebx,15*65536+7
    mov  ecx,0x00ffffff
    mov  edx,labelt
    mov  esi,labellen-labelt
    int  0x40

    mov  esi,infile     ; Infile
    mov  edi,text+50*5+9
    mov  ecx,37
    cld
    rep  movsb

    mov  esi,outfile     ; Outfile
    mov  edi,text+50*6+9
    mov  ecx,37
    rep  movsb

    mov  esi,path     ; Path
    mov  edi,text+50*7+9
    mov  ecx,37
    rep  movsb

    mov  ebx,25*65536+35    ; Draw Window Text
    mov  ecx,[text_color]
    mov  edx,text
    mov  esi,40
   newline:
    mov  eax,4
    int  0x40
    add  ebx,10
    add  edx,50
    cmp  [edx],byte 'x'
    jnz  newline

    mov  eax,12      ; End of Draw
    mov  ebx,2
    int  0x40

    popa
    ret

; read string

f1: mov  [addr],infile
    mov  [ya],dword 85
    jmp  rk
f2: mov  [addr],outfile
    mov  [ya],dword 95
    jmp  rk
f3: mov  [addr],path
    mov  [ya],dword 105
rk: mov  edi,[addr]
    mov  eax,'_'
    mov  ecx,20
    cld
    rep  stosb

    call print_text

    mov  edi,[addr]
f11:mov  eax,10
    int  0x40
    cmp  eax,2
    jne  read_done
    mov  eax,2
    int  0x40
    shr  eax,8
    cmp  eax,13
    je  read_done
    cmp  eax,8
    jnz  nobs
    cmp  edi,[addr]
    jz  f11
    sub  edi,1
    mov  [edi],byte '_'
    call print_text
    jmp  f11
   nobs:
    cmp  eax,dword 31
    jbe  f11
    cmp  eax,dword 95
    jb  keyok
    sub  eax,32
   keyok:
    mov  [edi],al

    call print_text
    add  edi,1
    mov  esi,[addr]
    add  esi,20
    cmp  esi,edi
    jnz  f11

  read_done:

    mov  ecx,[addr]
    add  ecx,20
    sub  ecx,edi
    mov  eax,32
    cld
    rep  stosb
    call print_text

    jmp  still

print_text:

    mov  eax,13
    mov  ebx,(25+9*6)*65536+20*6
    mov  ecx,[ya]
    shl  ecx,16
    mov  cx,8
    mov  edx,[background]
    int  0x40

    mov  eax,4
    mov  ebx,(25+9*6)*65536
    add  ebx,[ya]
    mov  ecx,[text_color]
    mov  edx,[addr]
    mov  esi,37 ;20
    int  0x40

    ret


; DATA

labelt:  db  'FASM FOR MENUET'
labellen:

text:

    db 'flat assembler ',VERSION_STRING
    times text+50-$ db ' '

    db 'Copyright (c) 1999-2003, Tomasz Grysztar          '
    db 'All rights reserved.                              '
    db 'Menuet port by VT                                 '
    db '--------------------------------------------------'
    db 'infile:                           <<<             '
    db 'outfile:                          <<<             '
    db 'path:                             <<<             '
    db '--------------------------------------------------'
    db '                                                  '
    db '   START COMPILE        RUN OUTFILE               '
    db '                                                  '
    db '--------------------------------------------------'
    db 'x                                                 '

infile  db  'EXAMPLE.ASM                          ',0
outfile db  'EXAMPLE                              ',0
path    db  '/RD/1/                               ',0

lf db  13,10,0
addr dd  0x0
ya dd  0x0
zero db  0x0

text_color   dd 0xffffff
background   dd 0x2030a0
borders      dd 0x4466dd
sbutton      dd 0x6677cc

mov_param_str:
  @@:
   mov     al,[esi]
   cmp     al,','
   je      @f
   cmp     al,0
   je      @f
   mov     [edi],al
   inc     esi
   inc     edi
   jmp     @b
  @@:
ret


start:
   cmp   [_mode],NORMAL_MODE
   jne   @f
   mov   eax,13      ; clear work area
   mov   ebx,10*65536+260
   mov   ecx,0xA8*65536+90
   mov   edx,[background]
   int   0x40
   mov   [textxy],dword 0x001900A8
@@:
   mov   esi,_logo
   call  display_string

 ;
 ;   Fasm native code
 ;

 mov [input_file],infile
 mov [output_file],outfile

 call init_memory

 mov edi,characters
 mov ecx,100h
 xor al,al
      make_characters_table:
 stosb
 inc al
 loop make_characters_table
 mov esi,characters+'a'
 mov edi,characters+'A'
 mov ecx,26
 rep movsb
 mov edi,characters
 mov esi,symbol_characters+1
 movzx ecx,byte [esi-1]
 xor ebx,ebx
      convert_table:
 lodsb
 mov bl,al
 mov byte [edi+ebx],0
 loop convert_table

 call make_timestamp
 mov  [start_time],eax

 call preprocessor
 call parser
 call assembler
 call formatter

 movzx eax,[current_pass]
 inc eax
 call display_number
 mov esi,_passes_suffix
 call display_string
 call make_timestamp
 sub eax,[start_time]
 xor edx,edx
 mov ebx,100
 div ebx
 or eax,eax
 jz display_bytes_count
 xor edx,edx
 mov ebx,10
 div ebx
 push edx
 call display_number
 mov dl,'.'
 call display_character
 pop eax
 call display_number
 mov esi,_seconds_suffix
 call display_string
      display_bytes_count:
 mov eax,[written_size]
 call display_number
 mov esi,_bytes_suffix
 call display_string
 xor al,al

 cmp [_run_outfile],1
 jne @f
    mov  edx,outfile
    call make_fullpaths
    mov  eax,58
    mov  ebx,file_info_start
    xor  ecx,ecx
    int  0x40
@@:
 jmp exit_program

include 'system.inc'

include 'errors.inc'
include 'expressi.inc'
include 'preproce.inc'
include 'parser.inc'
include 'assemble.inc'
include 'formats.inc'
include 'x86.inc'

_copyright db 'Copyright (c) 1999-2002, Tomasz Grysztar',0

_logo db 'flat assembler  version ',VERSION_STRING,0Dh,0Ah,0

_passes_suffix db ' passes, ',0
_seconds_suffix db ' seconds, ',0
_bytes_suffix db ' bytes.',0Dh,0Ah,0

_include db 'INCLUDE',0

_counter db 4,'0000'

_mode         dd NORMAL_MODE
_run_outfile  dd 0

params:
db 0
rb 1000h

align 4

program_base dd ?

memory_start dd ?
memory_end dd ?
additional_memory dd ?
additional_memory_end dd ?
free_additional_memory dd ?
input_file dd ?
output_file dd ?
include_paths dd ?
source_start dd ?
code_start dd ?
code_size dd ?
real_code_size dd ?
start_time dd ?
written_size dd ?

current_line dd ?
macros_list dd ?
macro_constants dd ?
macro_line dd ?
macro_block dd ?
macro_block_line dd ?
macro_block_line_number dd ?
macro_embed_level dd ?
struc_name dd ?
fix_constants_count dd ?
equ_constants_count dd ?
anonymous_reverse dd ?
anonymous_forward dd ?
current_locals_prefix dd ?
labels_list dd ?
label_hash dd ?
org_origin dd ?
org_registers dd ?
org_start dd ?
org_symbol dd ?
undefined_data_start dd ?
undefined_data_end dd ?
counter dd ?
counter_limit dd ?
error_line dd ?
error dd ?
display_buffer dd ?
structures_buffer dd ?
number_start dd ?
current_offset dd ?
value dq ?
fp_value rd 8
symbol_identifier dd ?
address_symbol dd ?
format_flags dd ?
symbols_stream dd ?
number_of_relocations dd ?
number_of_sections dd ?
stub_size dd ?
stub_file dd ?
current_section dd ?
machine dw ?
subsystem dw ?
subsystem_version dd ?
image_base dd ?
resource_data dd ?
resource_size dd ?

  hash_tree		dd ?
  label_leaf		dd ?

macro_status db ?
parenthesis_stack db ?
output_format db ?
code_type db ?
current_pass dw ?
next_pass_needed db ?
reloc_labels db ?
times_working db ?
virtual_data db ?
fp_sign db ?
fp_format db ?
value_size db ?
forced_size db ?
value_undefined db ?
value_type db ?
address_size db ?
compare_type db ?
base_code db ?
extended_code db ?
postbyte_register db ?
segment_register db ?
operand_size db ?
imm_sized db ?
jump_type db ?
mmx_size db ?
mmx_prefix db ?
nextbyte db ?

characters rb 100h
converted rb 100h
buffer rb 4000h

program_end:

