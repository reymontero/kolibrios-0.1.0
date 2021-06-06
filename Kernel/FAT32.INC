;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                 ;;
;;  FAT32.INC                                                      ;;
;;                                                                 ;;
;;  FAT32 functions for MenuetOS                                   ;;
;;                                                                 ;;
;;  Copyright 2002 Paolo Minazzi, paolo.minazzi@inwind.it          ;;
;;                                                                 ;;
;;  See file COPYING for details                                   ;;
;;                                                                 ;;
;;  30.3.2004  Error parameters at function return - VT            ;;
;;  01.5.2002  Bugfix in device write - VT                         ;;
;;  20.5.2002  Hd status check - VT                                ;;
;;  29.6.2002  Improved fat32 verification - VT                    ;;
;;                                                                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   
   
   
;       CLUSTER[0]  CLUSTER[1]  CLUSTER[2] CLUSTER[3]
;
;###    ######## -->######## -->########   ########
;#2#--> #      # |  #      # |  #      #   #      #
;###    #      # |  #      # |  #      #   #      #
;       #      # |  #      # |  #      #   #      #
;       #      # |  #      # |  #      #   #      #
;       #      # |  #      # |  #      #   #      #          CLUSTER
;       #      # |  #      # |  #      #   #      #
;       #      # |  #      # |  #      #   #      #
;       #      # |  #      # |  #      #   #      #
;       ######## |  ######## |  ########   ########
;                |           |
;                |           ------------------
;                |                            |
;                --------------------         |
;                                   |         |
;      ########    ########    ########   ########
;      # xxxx #    # xxxx #    #   3  #   #   4  #
;      ########    ########    ########   ########          FAT
;
;       FAT[0]       FAT[1]      FAT[2]    FAT[3]
;
   
RESERVED_SECTOR:     dd 0x20
PARTITION_START:     dd 0x3f
FAT32_SIZE:          dd 0x1f3a
NUMBER_OF_FATS:      dd 0x2
SECTOR_PER_CLUSTER:  dd 0x8
ROOT_CLUSTER:        dd 2
buffer:              times 64 dd 0,0 ; resb 512
cluster:             dd 0
cluster1:            dd 0
valid_fat:           db 0
PARTITION_SIZE:      dd 0
PARTITION_END:       dd 0

;***********************
;*         Start       *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.1      *
;***********************
FILE_SIZE:           dd 0
ADR_FSINFO:          dd 0
change_mem           db 0
old_size_file:       dd 0
;***********************
;*         End         *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.1      *
;***********************
   
set_FAT32_variables:
   
    cli
    cmp [hd1_status],0
    je  set_fat32_l1
   
    sti
    call change_task
    jmp  set_FAT32_variables
   
  set_fat32_l1:
   
    mov [hd1_status],1  ; busy
    sti
   
   
    cmp dword [hdpos],0
    je problem_hd_or_partition_or_fat32_ret
   
    push eax
    push ebx
   
    xor eax,eax                        ;read MBR
    mov ebx,buffer
    call hd_read_new
   
    cmp dword [fat32part],0
    jnz hd_and_partition_ok
   
problem_hd_or_partition_or_fat32:
    pop ebx
    pop eax
problem_hd_or_partition_or_fat32_ret:
   
    mov [valid_fat],byte 0
    mov [hd1_status],0 ; free
   
    ret
   
hd_and_partition_ok:

    mov  ecx,[fat32part]
    mov  eax,0
    mov  ebx,buffer+0x1be+8  -16
  hdapl1:
    add  ebx,16
    add  eax,[ebx]
    loop hdapl1

;***********************
;*         Start       *
;* Mario79 edited code *
;*    partition fix    *
;*     change 1.4      *
;***********************
    cmp [part2_ld],3
    jge par_lb3_1
    jmp par_1_2_1
par_search_1:
    mov  ebx,buffer
    call hd_read_new
    mov  edx,[ebx+3]
    cmp  edx,'NTFS'
    je   par_ntfs_1
    add  eax,[ebx+32]
    jmp  par_all_1
par_ntfs_1:
    add  eax,[ebx+40]
    inc  eax
par_all_1:
    add  eax,63
    ret
par_lb3_1:
    mov ecx,2
part_lb31_1:
    call par_search_1
    inc ecx
    cmp ecx,[part2_ld]
    jl part_lb31_1
par_1_2_1:
    mov  [PARTITION_START],eax
    mov  ebx,[ebx+4]
    mov  [PARTITION_SIZE],ebx
    mov ebx,buffer
    call hd_read_new                       ;read boot sector of partition
    cmp [ebx+0x53],dword 'AT32'
    jnz  problem_hd_or_partition_or_fat32
    cmp [part2_ld],2
    jge par_lb3_2
    jmp par_1_2_2
par_lb3_2:
    mov  ecx,[ebx+32]
    mov  [PARTITION_SIZE],ecx
par_1_2_2:
;***********************
;*          End        *
;* Mario79 edited code *
;*    partition fix    *
;*     change 1.4      *
;***********************

    mov  [valid_fat],byte 1
    movzx eax,word [ebx+0xe]
    mov [RESERVED_SECTOR],eax
    mov eax,[ebx+0x24]
    mov [FAT32_SIZE],eax
    movzx eax,byte [ebx+0x10]
    mov [NUMBER_OF_FATS],eax
    movzx eax,byte [ebx+0xd]
    mov [SECTOR_PER_CLUSTER],eax
    mov eax,[ebx+44]
    mov [ROOT_CLUSTER],eax
    mov eax,[PARTITION_START]
    add eax,[PARTITION_SIZE]
    dec eax
    mov [PARTITION_END],eax
    pop ebx
    pop eax

    mov [hd1_status],0   ; free

    ret
   
set_FAT:
;--------------------------------
; set_FAT
;
; input :  EAX = #block
;          EDX = value to save
; output:  nothing
;--------------------------------
   push eax ;[esp+16]
   push ebx ;[esp+12]
   push ecx ;[esp+8]
   push edx ;[esp+4]
   push esi ;[esp]
   
   shl eax,2
   xor edx,edx
   mov ebx,512
   div ebx
   mov esi,edx
   
   add eax,[RESERVED_SECTOR]
   add eax,[PARTITION_START]
   mov ebx,buffer
   
   mov ecx,[NUMBER_OF_FATS]
   mov edx,[esp+4]
set_an_other_FAT:
   call hd_read_new
   
   cmp  [f_del],1
   je   fat_zero
   
   cmp  [buffer+esi],dword 0
   je   fat_zero
   mov  [8*0x100000],dword 0xffffff
   jmp  fat_nonzero
   
  fat_zero:
   
   mov [buffer+esi],edx
   call hd_write_new
   
  fat_nonzero:
   
   add eax,[FAT32_SIZE]
   loop set_an_other_FAT
   
   pop esi
   pop edx
   pop ecx
   pop ebx
   pop eax
   ret
   
   
get_FAT:
;--------------------------------
; get_FAT
;
; input :  EAX = #block
; output:  EAX = #block
;--------------------------------
   push ebx
   push edx
   
   shl eax,2
   xor edx,edx
   mov ebx,512
   div ebx
   
   add eax,[RESERVED_SECTOR]
   add eax,[PARTITION_START]
   mov ebx,buffer
   
   call hd_read_new
   
   mov eax,[buffer+edx]
   
   pop edx
   pop ebx
   ret
   
;find_pointer_in_FAT:
;--------------------------------
; For each item of FAT do
;   if (item read == EAX)
;     return #item
;     carry=0
;   else
;     carry=1;
;
; input :  EAX = #block
; output:  if CARRY=0 then EAX = #block
;          if CARRY=1 then EAX = distroyed
;--------------------------------
;  add eax,2
;  push eax
;  push ecx
;  push edx
   
;  mov ecx,[FAT32_SIZE]
;  shl ecx,9-2                 ; *512 for sector   /4 for dword
;  mov edx,2
   
;adr78:
;  mov eax,edx
;  call get_FAT
;  cmp eax,[esp+8]
;  je found_pointer
;  inc edx
;  loop adr78
   
;  pop edx
;  pop ecx
;  add esp,4
;  stc
;  ret
   
;found_pointer:
;  mov eax,edx
;  pop edx
;  pop ecx
;  add esp,4
;  clc
;  ret
   
analyze_directory:
;--------------------------------
; input  : EAX = first cluster of the directory
;          EBX = pointer to filename
; output : IF CARRY=0 EAX = sector where th file is found
;                     EBX = pointer in buffer
;                     [buffer .. buffer+511]
;                     ECX,EDX,EDI,EDI not changed
;          IF CARRY=1
;--------------------------------
   push ebx ;[esp+16]
   push ecx
   push edx
   push esi
   push edi
   
   
adr56:
   mov [cluster_tmp],eax
   
   mov ecx,[FAT32_SIZE]
   imul ecx,[NUMBER_OF_FATS]
   add ecx,[RESERVED_SECTOR]
   
   sub eax,2
   imul eax,[SECTOR_PER_CLUSTER]
   add eax,[PARTITION_START]
   add eax,ecx
   
   mov edx,[SECTOR_PER_CLUSTER]
   
new_sector_in_cluster:
   mov ebx,buffer
   call hd_read_new
   
   mov ecx,512/32
   
adr1_analyze:
   mov esi,[esp+16]
   mov edi,ebx
   cld
   push ecx
   mov ecx,11
   rep cmpsb
   pop ecx
   je found_file_analyze
   
   add ebx,32
   loop adr1_analyze
   
   inc eax
   dec edx
   jne new_sector_in_cluster
   
   mov eax,[cluster_tmp]
   call get_FAT
   mov [cluster_tmp],eax
   cmp eax,0x0f000000
   jb  adr56
   
   
   pop edi
   pop esi
   pop edx
   pop ecx
   add esp,4
   stc        ;file not found
   ret
   
found_file_analyze:
   pop edi
   pop esi
   pop edx
   pop ecx
   add esp,4
   clc        ;file found
   ret
   
cluster_tmp: dd 0 ; common variable used by
                  ; analyze_directory and analyze_directory_to_write
cluster_tmp2: dd 0
   
   
analyze_directory_to_write:
;--------------------------------
; input  : EAX = first cluster of the directory
; output : IF CARRY=0 EAX = sector where the file is found
;                     EBX = pointer in buffer
;                     [buffer .. buffer+511]
;                     ECX,EDX,EDI,EDI not changed
;          IF CARRY=1
;--------------------------------
   
   push ecx
   push edx
   push esi
   push edi
   
adr561:
   mov [cluster_tmp],eax
   mov [cluster_tmp2],eax
   
   mov ecx,[FAT32_SIZE]
   imul ecx,[NUMBER_OF_FATS]
   add ecx,[RESERVED_SECTOR]
   
   sub eax,2
   imul eax,[SECTOR_PER_CLUSTER]
   add eax,[PARTITION_START]
   add eax,ecx
   
   mov edx,[SECTOR_PER_CLUSTER]
   
new_sector_in_cluster1:
   mov ebx,buffer
   call hd_read_new
   
   mov ecx,512/32
   
adr1_analyze1:
   cmp byte [ebx],0x00
   je  found_file_analyze1
   cmp byte [ebx],0xe5
   je  found_file_analyze1
   
avanti:
   add ebx,32
   loop adr1_analyze1
   
   inc eax
   dec edx
   jne new_sector_in_cluster1
   
   mov eax,[cluster_tmp]
   call get_FAT
   mov [cluster_tmp],eax
   cmp eax,0x0f000000
   jb  adr561
   
   mov eax,2                       ;this block of code add a new cluster
   call get_free_FAT               ;for the directory because the directory
                                   ;is full
   
   mov edx,0x0fffffff
   call set_FAT
   
   mov edx,eax
   mov eax,[cluster_tmp2]
   call set_FAT
   
   mov ecx,512/4
   xor eax,eax
   mov edi,buffer
   cld
   rep stosd
   
   sub edx,2
   
   mov eax,[SECTOR_PER_CLUSTER]
   imul eax,edx
   add eax,[PARTITION_START]
   add eax,[RESERVED_SECTOR]
   mov ecx,[FAT32_SIZE]
   imul ecx,[NUMBER_OF_FATS]
   add eax,ecx
   mov ebx,buffer
   mov ecx,[SECTOR_PER_CLUSTER]
   
set_empty_directory:
   call hd_write_new
   inc eax
   loop set_empty_directory
   
   sub eax,[SECTOR_PER_CLUSTER]
   
found_file_analyze1:
   
   pop edi
   pop esi
   pop edx
   pop ecx
   clc        ;file found
   ret
   
get_data_cluster:
;--------------------------------
; input :  EAX = # block
;          EBX = pointer to buffer
;          ECX = # bytes to read in buffer
; output:  nothing
;--------------------------------
ORG_EAX equ [esp+20]
ORG_EBX equ [esp+16]
ORG_ECX equ [esp+12]
ORG_EDX equ [esp+8]
ORG_ESI equ [esp+4]
ORG_EDI equ [esp]
   
   push  eax ; ORG_EAX
   push  ebx ; ORG_EBX
   push  ecx ; ORG_ECX
   push  edx ; ORG_EDX
   push  esi ; ORG_ESI
   push  edi ; ORG_EDI
   
   mov   edi,ebx
   
   xor   edx,edx
   mov   eax,ecx
   mov   ebx,512
   div   ebx
   
   mov   ecx,[FAT32_SIZE]
   imul  ecx,[NUMBER_OF_FATS]
   add   ecx,[RESERVED_SECTOR]
   
   mov   ebx,ORG_EAX
   sub   ebx,2
   imul  ebx,[SECTOR_PER_CLUSTER]
   add   ebx,[PARTITION_START]
   add   ebx,ecx
   
   mov ecx,eax
   
   mov eax,ebx
   mov ebx,buffer
   jecxz not_whole
   
read:
   call hd_read_new
   
   mov esi,ebx
   cld
   push ecx
   mov ecx,512
   rep movsb
   pop ecx
   
   inc eax
   loop read
   
not_whole:
   call hd_read_new
   mov esi,ebx
   mov ecx,edx
   cld
   rep movsb
   
   pop edi
   pop esi
   pop edx
   pop ecx
   pop ebx
   pop eax
   ret
   
set_data_cluster:
;--------------------------------
; input :  EAX = # block
;          EBX = pointer to buffer
;          ECX = # bytes to write in buffer
; output:  nothing
;--------------------------------
   push eax ; ORG_EAX
   push ebx ; ORG_EBX
   push ecx ; ORG_ECX
   push edx ; ORG_EDX
   push esi ; ORG_ESI
   push edi ; ORG_EDI
   
   mov  esi,ebx
   
   xor  edx,edx
   mov  eax,ecx
   mov  ebx,512
   div  ebx
   
   mov  ecx,[FAT32_SIZE]
   imul ecx,[NUMBER_OF_FATS]
   add  ecx,[RESERVED_SECTOR]
   
   mov  ebx,ORG_EAX
   sub  ebx,2
   imul ebx,[SECTOR_PER_CLUSTER]
   add  ebx,[PARTITION_START]
   add  ebx,ecx
   
   mov  ecx,[SECTOR_PER_CLUSTER]    ; vt
   
   mov  eax,ebx
   mov  ebx,buffer
   
write:
   push ecx
   mov  edi,buffer
   mov  ecx,512
   cld
   rep  movsb
   call hd_write_new
   inc  eax
   pop  ecx
   loop write
   
   pop  edi
   pop  esi
   pop  edx
   pop  ecx
   pop  ebx
   pop  eax
   ret
   
get_free_FAT:
;------------------------------------------
; input  :  EAX = # cluster for start the searching
; output :  EAX = # first cluster found free
;-------------------------------------------
   push ebx
   push ecx
   push edx
   
   mov ecx,eax
   
   shl eax,2
   xor edx,edx
   mov ebx,512
   div ebx
   
   add eax,[RESERVED_SECTOR]
   add eax,[PARTITION_START]
   mov ebx,buffer
   call hd_read_new
   
check_new:
   
   cmp  dword [buffer+edx],0
   jne  no_found
   cmp  dword [buffer+edx+4],0
   jne  no_found
   jmp  found
  no_found:
   add  edx,4
   inc  ecx
   cmp  edx,512-4
   jb   check_new
   inc  ecx
   
   inc eax
   call hd_read_new
   xor edx,edx
   jmp check_new
   
found:
   mov eax,ecx
   pop edx
   pop ecx
   pop ebx
   ret
   
;EXPERIMENTAL !!!!!!!!!!!!!
get_cluster_of_a_path:
;---------------------------------------------------------
; input: EBX = pointer to a path string
;          (example: the path "/files/data/document" become
;                           "files......data.......document...0"
;         '.' = space char
;         '0' = char(0) (ASCII=0) !!! )
; output: if (CARRY=1) -> ERROR in the PATH
;         if (CARRY=0) -> EAX=cluster
;---------------------------------------------------------
    push ebx
    push edx
   
    mov eax,[ROOT_CLUSTER]
    mov edx,ebx
   
search_end_of_path:
    cmp byte [edx],0
    je found_end_of_path
   
    inc edx ; '/'
   
    mov ebx,edx
    call analyze_directory
    jc directory_not_found
   
    mov ax,[ebx+20]                     ;read the HIGH 16bit cluster field
    shl eax,16
    mov ax,[ebx+26]                     ;read the LOW 16bit cluster field
    add edx,11                            ;8+3 (name+extension)
    jmp search_end_of_path
   
found_end_of_path:
    pop edx
    pop ebx
    clc                                 ;no errors
    ret
   
directory_not_found:
    pop edx
    pop ebx
    stc                                 ;errors occour
    ret
   
bcd2bin:
;----------------------------------
; input  : AL=BCD number (eg. 0x11)
; output : AH=0
;          AL=decimal number (eg. 11)
;----------------------------------
                push cx
                mov cl,al
                shr cl,4
                mov ch,cl
                shl cl,3
                add cl,ch
                add cl,ch
                and al,0xf
                add al,cl
                mov ah,0
                pop cx
                ret
   
get_data_for_file:
;-----------------------------------------------------
; Get data from CMOS and pack day,month,year in AX
; DATE   bits  0..4   : day of month 0..31
;              5..8   : month of year 1..12
;              9..15  : count of years from 1980
;-----------------------------------------------------
                push dx
                xor dx,dx
                mov al,0x7   ;day
                out 0x70,al
                in al,0x71
                call bcd2bin
                or dx,ax
   
                mov al,0x8   ;month
                out 0x70,al
                in al,0x71
                call bcd2bin
                shl ax,5
                or dx,ax
   
                mov al,0x9   ;year
                out 0x70,al
                in al,0x71
                call bcd2bin
                add ax,20    ;because CMOS return only the
                ;two last digit (eg. 2000 -> 00 , 2001 -> 01) and we
                shl ax,9     ;need the difference with
                ;1980 (eg. 2001-1980)
                or dx,ax
                xchg ax,dx   ;the result must be in AX
                pop dx
                ret
   
;-----------------------------------------------------
; Get time from CMOS and pack hour,minute,second in AX
; TIME   bits  0..4   : second (the low bit is lost)
;              5..10  : minute 0..59
;              11..15 : hour 0..23
;-----------------------------------------------------
get_time_for_file:
                push dx
                xor dx,dx
                mov al,0x0   ;second
                out 0x70,al
                in al,0x71
                call bcd2bin
                shr ax,1
                or dx,ax
   
                mov al,0x2   ;minute
                out 0x70,al
                in al,0x71
                call bcd2bin
                shl ax,5
                or dx,ax
   
                mov al,0x4   ;hour
                out 0x70,al
                in al,0x71
                call bcd2bin
                shl ax,11
                or dx,ax
                xchg ax,dx   ;the result must be in AX
                pop dx
                ret
   
file_write:
;--------------------------------------------------------------------------
;   INPUT :user-reg  register-in-this  meaning      symbol-in-this-routine
;
;            EAX        EDI            system call to write    /
;            EBX        EAX   (PAR0)   pointer to file-name    PAR0
;            EDX        ECX   (PAR1)   pointer to buffer       PAR1
;            ECX        EBX   (PAR2)   file size               PAR2
;            ESI        EDX   (PAR3)   pointer to path         PAR3
;
;   OUTPUT : eax = 0 - ok
;            eax = 1 - error at write
;            eax = 2 - bad partition
;
;--------------------------------------------------------------------------
   
;***********************
;*         Start       *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.2      *
;***********************
    mov [FILE_SIZE],ebx
;***********************
;*         End         *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.2      *
;***********************
   
    cmp  [valid_fat],byte 1
    jz   fat_ok_for_writing
    mov  eax,2
    ret
fat_ok_for_writing:
   
   cli
   cmp  [hd1_status],0
   je   fatokl1
   
   sti
   call change_task
   jmp  fat_ok_for_writing
   
  fatokl1:
   
   mov  [hd1_status],1
   sti
   
   sub  esp,32
   call expand_filename
   
   pusha
   mov ecx,edx            ;try to delete the file first
   call file_delete
   popa
   
   pushad
   mov [0xfe10],dword 0
   
PAR0 equ [esp+28]        ;EAX
PAR1 equ [esp+24]        ;ECX
PAR2 equ [esp+16]        ;EBX
PAR3 equ [esp+20]        ;EDX
   
   
   mov ebx,PAR3
   call get_cluster_of_a_path
   jnc found_directory_for_writing
   
exit_writing_with_error:
   popa
   stc
   
   add  esp,32
   mov  [hd1_status],0
   mov  eax,1
   ret
   
found_directory_for_writing:
   call analyze_directory_to_write
   
found1:
   push eax
   mov eax,2
   call get_free_FAT
   mov [cluster],eax
   pop eax
   
   push ebx
   mov ebx,buffer
   call hd_read_new
   pop ebx
   
   mov esi,PAR0             ;file name
   mov edi,ebx
   mov ecx,11
   cld
   rep movsb
   
   mov ecx,PAR2
   mov [ebx+28],ecx         ;file size
   mov ecx,[cluster]
   mov [ebx+26],cx          ;16 bits low  of cluster
   shr ecx,16
   mov [ebx+20],cx          ;16 bits high of cluster
   mov byte [ebx+11],0x20   ;attrib
   push eax
   
   call get_time_for_file
   mov [ebx+22],ax
   
   call get_data_for_file
   mov [ebx+24],ax
   
   pop eax
   
   mov ebx,buffer           ;save the directory name,length,cluster
   call hd_write_new
   
   imul esi,[SECTOR_PER_CLUSTER],512
   
hd_new_block_write:
   
   mov  eax,[cluster]      ; eax = block
   mov  ebx,PAR1           ; ebx = buffer
   call set_data_cluster
   
   mov  ecx,esi            ; ecx = size to write in bytes
   cmp  ecx,PAR2
   jbe  adr3
   mov  ecx,PAR2
 adr3:
   
   add  PAR1,ecx
   sub  PAR2,ecx            ; sub wrote bytes in stack
   
   cmp  PAR2,dword 0
   je   file_saved_OK
   
   mov  eax,[cluster]
   inc  eax
   call get_free_FAT
   mov  [cluster1],eax      ; next free in FAT
   
   mov  eax,[cluster]
   mov  edx,[cluster1]
   call set_FAT
   
   mov  eax,[cluster1]
   mov  [cluster],eax
   
   jmp  hd_new_block_write     ; adr2
   
file_saved_OK:

   mov  eax,[cluster]
   mov  edx,0x0fffffff
   call set_FAT

   popad
   clc

   add  esp,32

;***********************
;*         Start       *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.3      *
;***********************
   call write_free_mem_hd   
   mov  [hd1_status],0
   ret

write_free_mem_hd:
   mov  eax,[PARTITION_START]
   mov  ebx,buffer
   call hd_read_new
   movzx  ecx,word [ebx+48]
   add  eax,ecx
   mov  [ADR_FSINFO],eax
   call hd_read_new
   mov  eax,[FILE_SIZE]
   call  calc_file_size_claster
   mov  [FILE_SIZE],eax
   cmp  [change_mem],1
   je change_mem_1
   cmp  [change_mem],2
   je change_mem_2
   jmp change_mem_3
change_mem_2:
   mov  eax,[old_size_file]
   call  calc_file_size_claster
   add  [buffer+488],eax
change_mem_1:
   mov  eax,[FILE_SIZE]
   sub  [buffer+488],eax
   mov  eax,[ADR_FSINFO]
   mov  ebx,buffer
   call hd_write_new
   call wait_for_hd_idle
change_mem_3:
   ret
calc_file_size_claster:
   mov  ebx,[SECTOR_PER_CLUSTER]
   call correct_calc
   mov  ebx,512
   call correct_calc
   ret
correct_calc:
   xor  edx,edx
   div  ebx
   cmp edx,0
   je not_correction
   inc eax
not_correction:
   ret
;***********************
;*          End        *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.3      *
;***********************
   
file_read:
;--------------------------------------------------------------------------
;   INPUT :  user-register register-in-this  meaning         symbol-in-this
;
;            EAX           EDI               system call to write   /
;            EBX           EAX   (PAR0)      pointer to file-name   PAR0
;            EDX           ECX   (PAR1)      pointer to buffer      PAR1
;            ECX           EBX   (PAR2)      file size              PAR2
;            ESI           EDX   (PAR3)      pointer to path        PAR3
;--------------------------------------------------------------------------
    cmp  [valid_fat],byte 1
    jz   fat_ok_for_reading
    ret
fat_ok_for_reading:
   
   pushad
   
PAR0 equ [esp+28]        ;EAX
PAR1 equ [esp+24]        ;ECX
PAR2 equ [esp+16]        ;EBX
PAR3 equ [esp+20]        ;EDX
   
   mov ebx,PAR3
   call get_cluster_of_a_path
   jc file_to_read_not_found
   
   mov ebx,PAR0
   call analyze_directory
   jc file_to_read_not_found
   
found1r:
   
   mov ax,[ebx+20]
   shl eax,16
   mov ax,[ebx+26]
   
   imul esi,[SECTOR_PER_CLUSTER],512
   
   mov ebx,PAR1
   mov ecx,esi
   cmp PAR2,esi
   jae adr3r
   mov ecx,PAR2
adr3r:
   
   call get_data_cluster
   
adr2r:
   add PAR1,ecx
   sub PAR2,ecx
   
   jz file_read_OK
   
   call get_FAT
   
   mov ebx,PAR1
   mov ecx,esi
   cmp PAR2,esi
   jae adr4r
   mov ecx,PAR2
adr4r:
   call get_data_cluster
   
   jmp adr2r
   
file_read_OK:
   popad
   clc
   ret
   
file_to_read_not_found:
   popad
   stc
   ret
   
f_del db 0x0
   
file_delete:
;--------------------------------------------------------------------------
;EXPERIMENTAL !!!!!
;      INPUT :  user-reg  register-in-this meaning           symbol-in-this
;               EAX       EDI              system call to delete   /
;               EBX       EAX     (PAR0)   pointer to file-name    PAR0
;               EDX       ECX     (PAR1)   pointer to path         PAR1
;--------------------------------------------------------------------------
   
    cmp  [valid_fat],byte 1
    jz   fat_ok_for_deleting
    ret
fat_ok_for_deleting:
   
   pushad
   
   mov [f_del],1           ; delete on
   mov [0xfe10],dword 0    ; clear cache
   
PAR0 equ [esp+28] ;EAX
PAR1 equ [esp+24] ;ECX
   
   mov ebx,PAR1
   call get_cluster_of_a_path
   jc file_to_delete_not_found
   
   mov ebx,PAR0
   call analyze_directory
   jc file_to_delete_not_found
   
found_delete:

   mov byte [ebx],0xe5

;***********************
;*        Start        *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.4      *
;***********************
   mov edx,[ebx+28]
   mov [old_size_file],edx
;***********************
;*          End        *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.4      *
;***********************

   mov edx,ebx
   mov ebx,buffer
   call hd_write_new

   mov ebx,edx

   mov ax,[ebx+20]
   shl eax,16
   mov ax,[ebx+26]
   xor edx,edx
   
clean_new_chain:
   mov ebx,eax
   
   call get_FAT
   mov ecx,eax
   
   mov eax,ebx
   call set_FAT
   
   mov eax,ecx
   cmp eax,0x0f000000
   jge delete_OK
   
   jmp clean_new_chain
   
delete_OK:
   popad
   clc
   mov [f_del],0
;***********************
;*        Start        *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.5      *
;***********************
   mov [change_mem],2
   ret

file_to_delete_not_found:

   popad
   mov  [f_del],0
   stc
   mov [change_mem],1
   ret
;***********************
;*          End        *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.5      *
;***********************
   
;**************************************************************************
hd_read_new:
   
; eax = block
; ebx = pointer to memory
   
    call  wait_for_hd_idle
   
    push  edi    ; [esp+12] +13 +14 +15
    push  eax    ; [esp+8]  +9 +10 +11
    push  ecx    ; [esp+4]  +5 +6 +7
    push  edx    ; [esp]    +1 +2 +3
   
    cli
   
    xor   eax,eax
    mov   edx,[hdbase]
    inc   edx
    out   dx,al
    inc   edx
    mov   al,1
    out   dx,al
    inc   edx
    mov   al,[esp+8]
    out   dx,al
    inc   edx
    mov   al,[esp+9]
    out   dx,al
    inc   edx
    mov   al,[esp+10]
    out   dx,al
    inc   edx
    mov   al,[esp+11]
    and   al,1+2+4+8
    add   al,byte [hdid]
    add   al,128+64+32
    out   dx,al
    inc   edx
    mov   al,20h
    out   dx,al
   
    sti
   
hdwait_read:
    in    al,dx
    and   al,128
    jnz    hdwait_read
   
    cli
   
    mov   edi,ebx
    mov   ecx,256
    mov   edx,[hdbase]
   
    cld
    rep insw
   
    sti
   
    pop edx
    pop ecx
    pop eax
    pop edi
    ret
;****************************************************************
hd_write_new:
; eax = block
; ebx = pointer to memory
   
    cmp  eax,[PARTITION_START]
    jb   danger
    cmp  eax,[PARTITION_END]
    ja   danger
   
    call  wait_for_hd_idle
   
    push  esi    ; [esp+12] +13 +14 +15
    push  eax    ; [esp+8]  +9  +10 +11
    push  ecx    ; [esp+4]  +5 +6 +7
    push  edx    ; [esp]    +1 +2 +3
   
    cli
   
    xor   eax,eax
    mov   edx,[hdbase] 
    inc   edx
    out   dx,al
    inc   edx
    mov   al,1 
    out   dx,al
    inc   edx
    mov   al,[esp+8] 
    out   dx,al
    inc   edx
    mov   al,[esp+9]
    out   dx,al
    inc   edx
    mov   al,[esp+10]
    out   dx,al
    inc   edx
    mov   al,[esp+11]
    and   al,1+2+4+8
    add   al,byte [hdid]
    add   al,128+64+32
    out   dx,al
    inc   edx
    mov   al,31h 
    out   dx,al
;**************************
;*          Start         *
;*  Mario79 edited code   *
;* correct save hard disk *
;**************************

    sti

hdwait_write:
    in    al,dx
    and   al,128
    jnz    hdwait_write

    cli

    mov   esi,ebx
    mov   ecx,256
    mov   edx,[hdbase]

    cld
    rep outsw
   
    sti

;**************************
;*          End           *
;*  Mario79 edited code   *
;* correct save hard disk *
;**************************

    pop edx
    pop ecx
    pop eax
    pop esi
danger:
    ret   
   
   
wait_for_hd_idle:
   
    push  eax
    push  edx
   
    mov   edx,[hdbase]
    add   edx,0x7
  wfhil1:
    in    al,dx
    test  al,128
    jnz   wfhil1
   
    pop   edx
    pop   eax
    ret
   
   
   
   
   
   
   
