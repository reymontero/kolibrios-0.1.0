;******************************************************************************
;   MAIN MENU by lisovin@26.ru
;   Some parts of code rewritten by Ivan Poddubny <ivan-yar@bk.ru>
;
;   Compile with FASM for Menuet
;******************************************************************************
  include "MACROS.INC"

  BTN_HEIGHT  = 22
  TXT_Y       = (BTN_HEIGHT)/2-5

  use32
  org    0x0
  db     'MENUET01'              ; 8 byte id
  dd     0x01                    ; header version
  dd     START                   ; start of code
  dd     I_END                   ; size of image
  dd     0x200000                ; memory for app
  dd     0x200000                ; esp
  dd     0x0 , 0x0               ; I_Param , I_Icon
;******************************************************************************
;include "DEBUG.INC"
START:                           ; start of execution

     mov  eax, 48                ; load system colors
     mov  ebx, 3
     mov  ecx, sc
     mov  edx, sizeof.system_colors
     int  0x40

     mov  eax, 58                ; load MENU.DAT
     mov  ebx, fileinfo
     int  0x40
     test eax, eax               ; error ?
     jnz  close
     test ebx, ebx               ; length = 0 ?
     jz   close
     mov  ecx, ebx
     mov  edi, mem_end
  newsearch:
     mov  al, '#'
     cld
     repne scasb
     test ecx, ecx               ; if not found
     jz   close
     call get_number
     test ebx, ebx
     jnz  .number
     cmp  al, '#'
     je   search_end
   .number:
     shl  ebx, 4
     add  ebx, workarea          ; pointer to process table
     mov  [ebx], edi
     inc  [processes]
     jmp  newsearch
  search_end:
     mov  [end_pointer], edi
     mov  ebx, [processes]
     dec  ebx
     shl  ebx, 4
     add  ebx, workarea
  newprocess:
     xor  edx, edx
     mov  ecx, edi
     sub  ecx, [ebx]
     mov  al, 10
  newsearch1:
     std
     repne scasb
     test ecx, ecx
     je   endprocess
     cmp  [edi], byte 13
     jne  newsearch1
     inc  edx
     jmp  newsearch1
  endprocess:
     mov  esi, ebx
     add  esi, 4
     dec  edx
     mov  [esi], dl
     cmp  ebx, workarea
     jbe  search_end1
     sub  ebx, 16
     jmp  newprocess
  search_end1:
     mov  eax, 14
     int  0x40
     sub  ax, 20
     mov  [workarea + y_end],   ax
     mov  [workarea + x_start], 5
     mov  al, [workarea + rows]
     mov  [workarea + cur_sel],  al     ; clear selection
     mov  [workarea + prev_sel], al

     mov  [buffer], 0
  thread:
     mov  eax, [buffer]          ; identifier
     shl  eax, 4
     add  eax, workarea
     mov  edi, eax

     mov  eax, 40                ; set event mask
     mov  ebx, 100111b
     int  0x40

     call draw_window

still:
    mov  eax, 23                 ; wait here for event
    mov  ebx, 5
    int  0x40

    test [close_now], 1          ; is close flag set?
    jnz  close

    cmp  eax, 1                  ; redraw request ?
    je   red
    cmp  eax, 2                  ; key pressed ?
    je   key
    cmp  eax, 3                  ; button in buffer ?
    je   button
    cmp  eax, 6                  ; mouse event ?
    je   mouse

    cmp  edi, workarea
    je   still                   ; if main process-ignored

  movzx  ebx, [edi + parent]     ; parent id
    shl  ebx, 4
    add  ebx, workarea           ; ebx = base of parent info
    call backconvert             ; get my id in al
    cmp  al, [ebx + child]      ; if I'm not child of my parent, I shall die :)
    jne  close

    jmp  still


  red:                           ; redraw
    call draw_window
    jmp  still


  key:
;   mov  eax, 2
    int  0x40

    mov  al,  [edi + rows]       ; number of buttons

    cmp  ah,  178                ; KEY_UP
    jne  .noup

    mov  ah,  [edi+cur_sel]
    mov  [edi+prev_sel], ah
    dec  byte [edi+cur_sel]
    jnz  redrawbut
    mov  [edi+cur_sel], al
    jmp  redrawbut


  .noup:
    cmp  ah, 177                 ; KEY_DOWN
    jne  .nodn

    mov  ah, [edi + cur_sel]
    mov  [edi + prev_sel], ah
    inc  [edi + cur_sel]
    cmp  [edi + cur_sel], al
    jna  redrawbut
    mov  [edi + cur_sel], 1
    jmp  redrawbut

  .nodn:
    cmp  ah, 13                  ; ENTER
    jne  .noenter
    mov  ah, [edi + cur_sel]
    jmp  button1

  .noenter:
    cmp  ah, 27                  ; ESC
    jne  still
    jmp  close



  button:                        ; BUTTON HANDLER
    mov  eax, 17                 ; get id
    int  0x40

  button1:
    mov  esi, edi
    push edi
    mov  edi, [edi + pointer]

    ; look for the next line <ah> times; <ah> = button_id
    push eax
  .next_string:
    call searchstartstring
    dec  ah
    jnz  .next_string
    pop  eax

    mov  ecx, 40
    mov  al, '/'
    cld
  repne  scasb
    test ecx, ecx            ; if '/' not found
    je   searchexit

    cmp  [edi], byte '@'     ; check for submenu
    je   runthread

    dec  edi
    push edi                 ; pointer to start of filename
    call searchstartstring   ; search for next string
    sub  edi, 2              ; to last byte of string

    mov  ecx, edi
    pop  esi
    sub  ecx, esi
    inc  ecx                 ; length of filename
    mov  edi, fileinfo_start.name
    rep  movsb               ; copy string
    mov  byte [edi], 0       ; store terminator

    mov  eax, 58             ; start program
    mov  ebx, fileinfo_start
    int  0x40

    or   [close_now], 1      ; set close flag

    pop  edi
    mov  [mousemask], 0
    jmp  close

  searchexit:
    pop  edi
    jmp  still


  runthread:
    inc  edi

    push eax
    call get_number           ; get number of this process
    pop  eax

    test ebx, ebx             ; returned zero - main menu or not number
    jz   searchexit

    mov  al, bl

    mov  ebx, [processes]
    dec  bl
    cmp  al, bl
    ja   searchexit           ; such process doesnt exist
    cmp  al, [esi + child]
    je   searchexit           ; such process already exists

    mov  [esi + child], al    ; this is my child
    mov  cx, [esi + x_start]
    add  cx, 140              ; new x_start in cx
  movzx  edx, al
    shl  edx, 4
    add  edx, workarea        ; edx points to child's base address
    mov  [edx + x_start], cx  ; xstart for new thread
    mov  cx,  [esi + y_end]   ; y_end in cx
    mov  bl,  [esi + rows]    ; number of buttons in bl
    sub  bl,  ah              ; number of btn from bottom
  movzx  eax, al
    mov  [buffer], eax        ; thread id in buffer
  movzx  ebx, bl
    push edx
    mov  eax, BTN_HEIGHT
    mul  ebx
    sub  cx,  ax              ; new y_end for new thread
    pop  edx
    mov  [edx + y_end], cx    ; store y_end
    mov  edi, esi
    call backconvert          ; get number of this process (al)
    mov  [edx + parent], al   ; store number of parent process
    mov  al, [edx + rows]
    mov  [edx + cur_sel], al  ; clear current selected element
    mov  [edx + prev_sel], al ; clear previous selected element
    mov  [edx + child], 0

    sub  [thread_stack], 0x1000 ; start new thread
    mov  eax, 51
    mov  ebx, 1
    mov  ecx, thread
    mov  edx, [thread_stack]
    int  0x40

    jmp  searchexit


 mouse:                       ; MOUSE EVENT HANDLER
;   cmp  [edi + child], 0
;   jne  still
    mov  eax, 37
    mov  ebx, 2
    int  0x40
    test eax, eax             ; check buttons state
    jnz  click
    mov  eax, 37
    mov  ebx, 1
    int  0x40
    ror  eax, 16              ; eax = [ Y | X ] relative to window
    cmp  ax,  140             ; pointer in window?
    ja   noinwindow
;  in window 
    shr  eax, 16              ; eax = [ 0 | Y ]
    xor  edx, edx
    mov  ebx, BTN_HEIGHT
    div  ebx
    inc  eax                  ; number of "button" in eax
  movzx  ebx, [edi + rows]    ; total strings in ebx
    cmp  eax, ebx
    ja   noinwindow
    cmp  [edi + cur_sel], al
    je   noredrawbut
    mov  bl, [edi + cur_sel]
    mov  [edi + cur_sel], al
    mov  [edi + prev_sel], bl
  redrawbut:
    call draw_only_needed_buttons
  noredrawbut:
    call backconvert
    bts  [mousemask], eax
    jmp  still
  noinwindow:
    call backconvert
    btr  [mousemask], eax
    jmp  still
  click:
    cmp  [mousemask], 0
    je   close
    jmp  still


  close:
    or   eax, -1                ; close this thread
    mov  [edi + child], al      ; my child is not mine
    int  0x40


  backconvert:                  ; convert from pointer to process id
    mov  eax, edi
    sub  eax, workarea
    shr  eax, 4
    ret


;==================================
; get_number
;    load number from [edi] to ebx
;==================================
  get_number:
    push edi

    xor  eax, eax
    xor  ebx, ebx

   .get_next_char:
    mov  al, [edi]
    inc  edi
    cmp  al, '0'
    jb   .finish
    cmp  al, '9'
    ja   .finish
    sub  al, '0'
    imul ebx, 10
    add  ebx, eax
    jmp  .get_next_char

   .finish:
    pop  edi
    ret


;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************


draw_window:

    mov  eax, 12                   ; function 12:tell os about windowdraw
    mov  ebx, 1                    ; 1, start of draw
    int  0x40

  movzx  ebx, [edi + rows]
   imul  eax, ebx, BTN_HEIGHT      ; eax = height of window
  movzx  ecx, [edi + y_end]
    sub  ecx, eax                  ; ecx = Y_START
    shl  ecx, 16
    add  ecx, eax                  ; ecx = [ Y_START | Y_SIZE ]
    dec  ecx
  movzx  ebx, [edi + x_start]
    shl  ebx, 16
    mov  bx,  140                  ; ebx = [ X_START | X_SIZE ]
    xor  eax, eax                  ; function 0 : define and draw window
    mov  edx, 0x01000000           ; color of work area RRGGBB,8->color gl
    int  0x40

    call draw_all_buttons

    mov  eax,12
    mov  ebx,2
    int  0x40

    ret


 draw_all_buttons:
    xor  edx, edx
  .new_button:
    call draw_one_button
    inc  edx
    cmp  dl, [edi + rows]
    jb   .new_button

    ret


 draw_only_needed_buttons:
    xor  edx, edx
    mov  dl, [edi + cur_sel]
    dec  dl
    call draw_one_button
    mov  dl, [edi + prev_sel]
    dec  dl
    call draw_one_button
    ret


 draw_one_button:
 ; receives number of button in dl
    push edx;ad

    mov  eax, 8
    mov  ebx, 140
  movzx  ecx, dl
    imul ecx, BTN_HEIGHT
    shl  ecx, 16
    add  ecx, BTN_HEIGHT-1
;   edx = button identifier
    mov  esi, [sc.work_button]
    inc  dl
    cmp  [edi + cur_sel], dl
    jne  .nohighlight
    add  esi, 0x202020
  .nohighlight:
    int  0x40

    dec  dl
    imul ebx, edx, BTN_HEIGHT
    add  ebx, (4 shl 16) + TXT_Y

  movzx  ecx, dl
    inc  ecx
    mov  edx, [edi + pointer]
  .findline:
    cmp  byte [edx], 13
    je   .linefound
    inc  edx
    jmp  .findline
  .linefound:
    inc  edx
    cmp  byte [edx], 10
    jne  .findline
    dec  ecx
    jnz  .findline

    mov  ecx, [sc.work_button_text]
    mov  eax, 4
    mov  esi, 21
    int  0x40

    pop  edx;ad
    ret


 searchstartstring:
    mov  ecx, 40
    mov  al, 13
    cld
  repne  scasb
    cmp  byte [edi], 10
    jne  searchstartstring
    ret

; DATA AREA
thread_stack   dd   0x200000
processes      dd   0

fileinfo:
 .mode         dd   0          ; 0=READ
 .start_block  dd   0x0        ; 512 block to read 0+
 .size         dd   0x80       ; blocks to read (0x10000 bytes max)
 .return       dd   mem_end    ; return data pointer
 .work         dd   workarea   ; work area for os - 16384 bytes
 .name:
     db   '/RD/1/MENU.DAT',0   ; ASCIIZ dir & filename

fileinfo_start:
 .mode         dd   16         ; 16=START APPLICATION
 .start_block  dd   0x0        ; nop
 .size         dd   0x0        ; nop
 .return       dd   0x0        ; nop
 .work         dd   workarea1  ; work area for os - 16384 bytes
 .name:
     times 50 db ' '

I_END:

close_now      dd ?
end_pointer    dd ?
buffer         dd ?
mousemask      dd ?   ; mask for mouse pointer location

sc system_colors

workarea:
  rb 0x10000
workarea1:
  rb 0x10000

virtual at 0          ; PROCESSES TABLE (located at workarea)
  pointer      dd ?   ; +0    pointer in file
  rows         db ?   ; +4    numer of strings
  x_start      dw ?   ; +5    x start
  y_end        dw ?   ; +7    y end
  child        db ?   ; +9    id of child menu
  parent       db ?   ; +10   id of parent menu
  cur_sel      db ?   ; +11   current selection
  prev_sel     db ?   ; +12   previous selection
  rb           16-$+1 ; [16 bytes per element]
end virtual

mem_end:
