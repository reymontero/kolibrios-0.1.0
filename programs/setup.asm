;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                               ;;
;;          DEVICE SETUP         ;;
;;                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Authors: Ville       - original version
;          A. Ivushkin - autostart (w launcher)
;          M. Lisovin  - added many feauters (apply all, save all, set time...)
;          I. Poddubny - fixed russian keymap

;******************************************************************************
  use32
  org     0x0
  db      'MENUET01'   ; 8 byte identifier
  dd      0x01         ; header version
  dd      START        ; pointer to program start
  dd      I_END        ; size of image
  dd      0x90000      ; reguired amount of memory
  dd      0x90000      ; stack pointer (esp)
  dd      I_PARAM,0    ; parameters, reserved
  include 'macros.inc'
;******************************************************************************

LLL equ (56+3)
BBB equ 25


START:
 cmp [I_PARAM],dword 'LANG'
 jne nolang
 mov eax,26
 mov ebx,2
 mov ecx,9
 int 0x40
 cmp eax,5
 jne lang
 xor eax,eax
lang:
 mov [keyboard],eax
 call _keyboard
 jmp close
nolang:
 mov eax,6
 mov ebx,filename
 xor ecx,ecx
 or  edx,-1
 mov esi,keyboard
 int 0x40
 cmp [I_PARAM],dword 'BOOT'
 jne no_param
_param:
    call _midibase
    call _cdbase
    call _hdbase
    call _sound_dma
    call _lba_read
    call _pci_acc
    call _f32p
    call _sb16
    call _wssp
    call _syslang
    call _keyboard
;    call settime
    jmp  close

no_param:
    call loadtxt
red:
    call draw_window

still:
    cmp  word [blinkpar],0
    jne  blinker
    mov  eax,29             ;get system date
    int  0x40
    cmp  eax,[date]
    je   gettime
    mov  [date],eax
 gettime:
    mov  eax,3              ;get system time
    int  0x40
    cmp  ax,[time]
    je   sysevent
    mov  [time],ax
    call drawtime

 sysevent:
    mov  eax,23
    mov  ebx,8              ; wait here for event with timeout
    int  0x40

    cmp  eax,1
    jz   red
    cmp  eax,2
    jz   key
    cmp  eax,3
    jz   button

    jmp  still

 blinker:
    cmp  byte [count],6
    jb   noblink
    btc  dword [blinkpar],16
    mov  byte [count],0
    call drawtime
 noblink:
    inc  byte [count]
    jmp  sysevent

incdectime:
    cmp byte [blinkpar],0
    je  still
    mov esi,time
    mov bl,0x23  ;border
    cmp byte [blinkpar],1
    je  hours
    mov bl,0x59           ;minutes
    inc esi
  hours:
    mov al,byte [esi]
    cmp ah,112
    je  dectime
    cmp al,bl
    je  noinctime
     inc al
     daa
    jmp incdectime1
  noinctime:
    xor al,al
  incdectime1:
    mov byte [esi],al
    jmp still
  dectime:
    cmp al,0
    je  nodectime
    dec al
    das
    jmp incdectime1
  nodectime:
    mov al,bl
    jmp incdectime1

incdecdate:
    cmp byte [blinkpar+1],0
    je  still
    mov esi,date
    mov bl,0      ;border of years
    cmp byte [blinkpar+1],1
    jne days
    mov bl,0x12             ;months
    inc esi
  days:
    cmp byte [blinkpar+1],2
    jne nodays
    mov bl,0x31
    add esi,2
  nodays:
    mov al,byte [esi]
    cmp ah,122
    je  decdate
    cmp al,bl
    je  noincdate
    inc al ;add al,1
    daa
    jmp incdecdate1
  noincdate:
    mov al,1
  incdecdate1:
    mov byte [esi],al
    jmp still
  decdate:
    cmp al,1
    je  nodecdate
    dec al
    das
    jmp incdecdate1
  nodecdate:
    mov al,bl
    jmp incdecdate1


  key:
    ;mov  eax,2
    int  0x40
    cmp  ah,27
    jne  still
    mov dword [blinkpar],0
    call drawtime
    jmp  still

  button:

    mov  eax,17
    int  0x40

    cmp ah,112
    je  incdectime
    cmp ah,113
    je  incdectime
    cmp ah,122
    je  incdecdate
    cmp ah,123
    je  incdecdate
    cmp ah,111
    jne noseltime
    mov al,byte [blinkpar]
    cmp al,2
    jae seltime
    inc al
    jmp seltime1
  seltime:
    xor al,al
  seltime1:
    mov byte [blinkpar],al
    call drawtime
    jmp still
noseltime:
    cmp ah,121
    jne noseldate
    mov al,byte [blinkpar+1]
    cmp al,3
    jae seldate
    inc al
    jmp seldate1
 seldate:
    xor al,al
 seldate1:
    mov byte [blinkpar+1],al
    call drawtime
    jmp  still
noseldate:
    cmp ah,99
    jne nosaveall
    mov eax,33
    mov ebx,filename
    mov ecx,keyboard
    mov edx,48
    xor esi,esi
    int 0x40
    call settime
    mov dword [blinkpar],0
    call drawtime
    jmp still
nosaveall:
    cmp ah,100
    jne no_apply_all
    jmp _param
no_apply_all:

    cmp  ah,1                ; CLOSE APPLICATION
    jne  no_close
close:
    xor  eax,eax
    dec  eax
    int  0x40
  no_close:

    cmp  ah,11               ; SET MIDI BASE
    jnz  nosetbase1
    call _midibase
   nosetbase1:
    cmp  ah,12
    jnz  nomm
    sub  [midibase],2
    call draw_infotext
  nomm:
    cmp  ah,13
    jnz  nomp
    add  [midibase],2
    call draw_infotext
  nomp:


    cmp  ah,4                ; SET KEYBOARD
    jnz  nokm
    mov  eax,[keyboard]
    test eax,eax
    je   downuplbl
    dec  eax
    jmp  nodownup
   downuplbl:
    mov  eax,4
   nodownup:
    mov  [keyboard],eax
    call draw_infotext
  nokm:
    cmp  ah,5
    jnz  nokp
    mov  eax,[keyboard]
    cmp  eax,4
    je   updownlbl
    inc  eax
    jmp  noupdown
   updownlbl:
    xor  eax,eax
   noupdown:
    mov  [keyboard],eax
    call draw_infotext
  nokp:


    cmp  ah,22                ; SET CD BASE
    jnz  nocm
    mov  eax,[cdbase]
    sub  eax,2
    and  eax,3
    inc  eax
    mov  [cdbase],eax
    call draw_infotext
  nocm:
    cmp  ah,23
    jnz  nocp
    mov  eax,[cdbase]
    and  eax,3
    inc  eax
    mov  [cdbase],eax
    call draw_infotext
  nocp:
    cmp  ah,21
    jnz  nocs
    call _cdbase
  nocs:

    cmp  ah,62              ; SET HD BASE
    jnz  hnocm
    mov  eax,[hdbase]
    sub  eax,2
    and  eax,3
    inc  eax
    mov  [hdbase],eax
    call draw_infotext
  hnocm:
    cmp  ah,63
    jnz  hnocp
    mov  eax,[hdbase]
    and  eax,3
    inc  eax
    mov  [hdbase],eax
    call draw_infotext
  hnocp:
    cmp  ah,61
    jnz  hnocs
    call _hdbase
  hnocs:

    cmp  ah,82              ; SET SOUND DMA
    jne  no_sdma_d
    mov  eax,[sound_dma]
    dec  eax
   sdmal:
    and  eax,3
    mov  [sound_dma],eax
    call draw_infotext
    jmp  still
  no_sdma_d:
    cmp  ah,83
    jne  no_sdma_i
    mov  eax,[sound_dma]
    inc  eax
    jmp  sdmal
  no_sdma_i:
    cmp  ah,81
    jne  no_set_sound_dma
    call _sound_dma
    jmp  still
  no_set_sound_dma:

    cmp  ah,92                   ; SET LBA READ
    jne  no_lba_d
  slbal:
    btc  [lba_read],0
    call draw_infotext
    jmp  still
   no_lba_d:
    cmp  ah,93
    jne  no_lba_i
    jmp  slbal
  no_lba_i:
    cmp  ah,91
    jne  no_set_lba_read
    call _lba_read
    jmp  still
   no_set_lba_read:


    cmp  ah,102                   ; SET PCI ACCESS
     jne  no_pci_d
  pcip:
     btc  [pci_acc],0
     call draw_infotext
     jmp  still
  no_pci_d:
     cmp  ah,103
     jne  no_pci_i
     jmp  pcip
   no_pci_i:
    cmp  ah,101
    jne  no_set_pci_acc
    call _pci_acc
    jmp  still
  no_set_pci_acc:

    cmp  ah,72                  ; SET FAT32 PARTITION
    jnz  fhnocm
    mov  eax,[f32p]
    sub  eax,2
;**********************
; Mario79 - explanation
;**********************
    and  eax,7 ; quantity of partitions = 7+1...15+1...31+1...
;**********************
    inc  eax
    mov  [f32p],eax
    call draw_infotext
  fhnocm:
    cmp  ah,73
    jnz  fhnocp
    mov  eax,[f32p]
;*********************
; Mario79 - explanation
;**********************
    and  eax,7 ; quantity of partitions = 7+1...15+1...31+1...
;*********************
    inc  eax
    mov  [f32p],eax
    call draw_infotext
  fhnocp:
    cmp  ah,71
    jnz  fhnocs
    call _f32p
  fhnocs:

    cmp  ah,32                  ; SET SOUND BLASTER 16 BASE
    jnz  nosbm
    sub  [sb16],2
    call draw_infotext
  nosbm:
    cmp  ah,33
    jnz  nosbp
    add  [sb16],2
    call draw_infotext
  nosbp:
    cmp  ah,31
    jnz  nosbs
    call _sb16
  nosbs:

    cmp  ah,52                  ; SET WINDOWS SOUND SYSTEM BASE
    jnz  nowssm
    mov  eax,[wss]
    sub  eax,2
    and  eax,3
    inc  eax
    mov  [wss],eax
    call draw_infotext
  nowssm:
    cmp  ah,53
    jnz  nowssp
    mov  eax,[wss]
    and  eax,3
    inc  eax
    mov  [wss],eax
    call draw_infotext
  nowssp:
    cmp  ah,51
    jnz  nowsss
    call _wssp
  nowsss:

    cmp  ah,42                ; SET SYSTEM LANGUAGE BASE
    jnz  nosysm
    mov  eax,[syslang]
    dec  eax
    jz   still
    mov  [syslang],eax
    call draw_infotext
  nosysm:
    cmp  ah,43
    jnz  nosysp
    mov  eax,[syslang]
    cmp  eax,4
    je   nosysp
    inc  eax
    mov  [syslang],eax
    call draw_infotext
  nosysp:
    cmp  ah,41
    jnz  nosyss
    call _syslang
    call cleantxt
    call loadtxt
    call draw_window
    call drawtime
  nosyss:

    cmp  ah,3                  ; SET KEYMAP
    jne  still
    call _keyboard
    jmp  still

  _keyboard:
    cmp [keyboard],0
    jnz  nosetkeyle
    mov  eax,21       ; english
    mov  ebx,2
    mov  ecx,1
    mov  edx,en_keymap
    int  0x40
    mov  eax,21
    inc  ecx
    mov  edx,en_keymap_shift
    int  0x40
    mov  eax,21
    mov  ecx,9
    mov  edx,1
    int  0x40
    call alt_gen
  nosetkeyle:
    cmp  [keyboard],1
    jnz  nosetkeylfi
    mov  eax,21       ; finnish
    mov  ebx,2
    mov  ecx,1
    mov  edx,fi_keymap
    int  0x40
    mov  eax,21
    inc  ecx
    mov  edx,fi_keymap_shift
    int  0x40
    mov  eax,21
    mov  ecx,9
    mov  edx,2
    int  0x40
    call alt_gen
  nosetkeylfi:
    cmp  [keyboard],2
    jnz  nosetkeylge
    mov  eax,21       ; german
    mov  ebx,2
    mov  ecx,1
    mov  edx,ge_keymap
    int  0x40
    mov  eax,21
    inc  ecx
    mov  edx,ge_keymap_shift
    int  0x40
    mov  eax,21
    mov  ecx,9
    mov  edx,3
    int  0x40
    call alt_gen
  nosetkeylge:
    cmp  [keyboard],3
    jnz  nosetkeylru
    mov  eax,21       ; russian
    mov  ebx,2
    mov  ecx,1
    mov  edx,ru_keymap
    int  0x40
    mov  eax,21
    inc  ecx
    mov  edx,ru_keymap_shift
    int  0x40
    call alt_gen
    mov  eax,21
    mov  ecx,9
    mov  edx,4
    int  0x40
  nosetkeylru:
    cmp  [keyboard],4         ;french
    jnz  nosetkeylfr
    mov  eax,21
    mov  ebx,2
    mov  ecx,1
    mov  edx,fr_keymap
    int  0x40
    mov  eax,21
    inc  ecx
    mov  edx,fr_keymap_shift
    int  0x40
    mov  eax,21
    inc  ecx
    mov  edx,fr_keymap_alt_gr
    int  0x40
    mov  eax,21
    mov  ecx,9
    mov  edx,5
    int  0x40
  nosetkeylfr:
    ret

 alt_gen:
   mov eax,21
   mov ecx,3
   mov edx,alt_general
   int 0x40
   ret



draw_buttons:

    pusha

    shl  ecx,16
    add  ecx,12
    mov  ebx,(350-50)*65536+46+BBB

    mov  eax,8
    int  0x40

    mov  ebx,(350-79)*65536+9
    inc  edx
    int  0x40

    mov  ebx,(350-67)*65536+9
    inc  edx
    int  0x40

    popa
    ret



; ********************************************
; ******* WINDOW DEFINITIONS AND DRAW  *******
; ********************************************


draw_window:

    pusha

    mov  eax,12
    mov  ebx,1
    int  0x40

    xor  eax,eax                   ; DRAW WINDOW
    mov  ebx,40*65536+355+BBB
    mov  ecx,40*65536+270
    mov  edx,0x82111199
    mov  esi,0x805588dd
    mov  edi,0x005588dd
    int  0x40

    mov  eax,4
    mov  ebx,8*65536+8
    mov  ecx,0x10ffffff
    mov  edx,labelt
    cmp  [syslang],4
    je   ruslabel
    add  edx,20
  ruslabel:
    mov  esi,26
    int  0x40

    mov  eax,8                     ; CLOSE BUTTON
    mov  ebx,(355+BBB-19)*65536+12
    mov  ecx,5*65536+12
    mov  edx,1
    mov  esi,0x005588dd
    int  0x40
                                   ; APPLY ALL
    mov  ebx,(350-79)*65536+100
    mov  ecx,219*65536+12
    mov  edx,100
    int  0x40
    add  ecx,16*65536              ; SAVE ALL
    dec  edx
    int  0x40

    mov  esi,0x5580c0

    mov  edx,11
    mov  ecx,43
    call draw_buttons

    mov  edx,41
    mov  ecx,43+8*8
    call draw_buttons

    mov  edx,21
    mov  ecx,43+4*8
    call draw_buttons

    mov  edx,31
    mov  ecx,43+2*8
    call draw_buttons

    mov  edx,3
    mov  ecx,43+10*8
    call draw_buttons

    mov  edx,51
    mov  ecx,43+12*8
    call draw_buttons

    mov  edx,61
    mov  ecx,43+6*8
    call draw_buttons

 ;   mov  edx,91
 ;   mov  ecx,43+18*8
 ;   call draw_buttons

    mov  edx,71
    mov  ecx,43+14*8
    call draw_buttons

    mov  edx,81
    mov  ecx,43+16*8
    call draw_buttons

 ;   mov  edx,101
 ;   mov  ecx,43+20*8
 ;   call draw_buttons

    mov  edx,111
    mov  ecx,43+18*8 ; 22
    call draw_buttons

    mov  edx,121
    mov  ecx,43+20*8 ; 24
    call draw_buttons

    call draw_infotext

    mov  eax,12
    mov  ebx,2
    int  0x40

    popa
    ret



draw_infotext:

    pusha

    mov  eax,[keyboard]                       ; KEYBOARD
    test eax,eax
    jnz  noen
    mov  [text00+LLL*10+28],dword 'ENGL'
    mov  [text00+LLL*10+32],dword 'ISH '
  noen:
    cmp  eax,1
    jnz  nofi
    mov  [text00+LLL*10+28],dword 'FINN'
    mov  [text00+LLL*10+32],dword 'ISH '
  nofi:
    cmp  eax,2
    jnz  noge
    mov  [text00+LLL*10+28],dword 'GERM'
    mov  [text00+LLL*10+32],dword 'AN  '
  noge:
    cmp  eax,3
    jnz  nogr
    mov  [text00+LLL*10+28],dword 'RUSS'
    mov  [text00+LLL*10+32],dword 'IAN '
  nogr:
    cmp  eax,4
    jnz  nofr
    mov  [text00+LLL*10+28],dword 'FREN'
    mov  [text00+LLL*10+32],dword 'CH  '
  nofr:


    mov  eax,[syslang]                          ; SYSTEM LANGUAGE
    dec  eax
    test eax,eax
    jnz  noen5
    mov  [text00+LLL*8+28],dword 'ENGL'
    mov  [text00+LLL*8+32],dword 'ISH '
  noen5:
    cmp  eax,1
    jnz  nofi5
    mov  [text00+LLL*8+28],dword 'FINN'
    mov  [text00+LLL*8+32],dword 'ISH '
  nofi5:
    cmp  eax,2
    jnz  noge5
    mov  [text00+LLL*8+28],dword 'GERM'
    mov  [text00+LLL*8+32],dword 'AN  '
  noge5:
    cmp  eax,3
    jnz  nogr5
    mov  [text00+LLL*8+28],dword 'RUSS'
    mov  [text00+LLL*8+32],dword 'IAN '
  nogr5:
    cmp  eax,4
    jne  nofr5
    mov  [text00+LLL*8+28],dword 'FREN'
    mov  [text00+LLL*8+32],dword 'CH  '
  nofr5:


    mov  eax,[midibase]
    mov  esi,text00+LLL*0+32
    call hexconvert                          ; MIDI BASE


    mov  eax,[sb16]                          ; SB16 BASE
    mov  esi,text00+LLL*2+32
    call hexconvert


    mov  eax,[wss]                           ; WSS BASE
    cmp  eax,1
    jnz  nowss1
    mov  [wssp],dword 0x530
  nowss1:
    cmp  eax,2
    jnz  nowss2
    mov  [wssp],dword 0x608
  nowss2:
    cmp  eax,3
    jnz  nowss3
    mov  [wssp],dword 0xe80
  nowss3:
    cmp  eax,4
    jnz  nowss4
    mov  [wssp],dword 0xf40
  nowss4:

    mov  eax,[wssp]
    mov  esi,text00+LLL*12+32
    call hexconvert

    mov  eax,[cdbase]                           ; CD BASE
    cmp  eax,1
    jnz  noe1
    mov  [text00+LLL*4+28],dword 'PRI.'
    mov  [text00+LLL*4+32],dword 'MAST'
    mov  [text00+LLL*4+36],dword 'ER  '
  noe1:
    cmp  eax,2
    jnz  nof1
    mov  [text00+LLL*4+28],dword 'PRI.'
    mov  [text00+LLL*4+32],dword 'SLAV'
    mov  [text00+LLL*4+36],dword 'E   '
  nof1:
    cmp  eax,3
    jnz  nog1
    mov  [text00+LLL*4+28],dword 'SEC.'
    mov  [text00+LLL*4+32],dword 'MAST'
    mov  [text00+LLL*4+36],dword 'ER  '
  nog1:
    cmp  eax,4
    jnz  nog2
    mov  [text00+LLL*4+28],dword 'SEC.'
    mov  [text00+LLL*4+32],dword 'SLAV'
    mov  [text00+LLL*4+36],dword 'E   '
  nog2:


    mov  eax,[hdbase]                         ; HD BASE
    cmp  eax,1
    jnz  hnoe1
    mov  [text00+LLL*6+28],dword 'PRI.'
    mov  [text00+LLL*6+32],dword 'MAST'
    mov  [text00+LLL*6+36],dword 'ER  '
  hnoe1:
    cmp  eax,2
    jnz  hnof1
    mov  [text00+LLL*6+28],dword 'PRI.'
    mov  [text00+LLL*6+32],dword 'SLAV'
    mov  [text00+LLL*6+36],dword 'E   '
  hnof1:
    cmp  eax,3
    jnz  hnog1
    mov  [text00+LLL*6+28],dword 'SEC.'
    mov  [text00+LLL*6+32],dword 'MAST'
    mov  [text00+LLL*6+36],dword 'ER  '
  hnog1:
    cmp  eax,4
    jnz  hnog2
    mov  [text00+LLL*6+28],dword 'SEC.'
    mov  [text00+LLL*6+32],dword 'SLAV'
    mov  [text00+LLL*6+36],dword 'E   '
  hnog2:


    mov  eax,[f32p]                       ; FAT32 PARTITION
    add  al,48
    mov  [text00+LLL*14+28],al

    mov  eax,[sound_dma]                  ; SOUND DMA
    add  eax,48
    mov  [text00+LLL*16+28],al

;    mov  eax,[lba_read]
;    call onoff                            ; LBA READ
;    mov  [text00+LLL*18+28],ebx

;    mov  eax,[pci_acc]
;    call onoff                            ; PCI ACCESS
;    mov  [text00+LLL*20+28],ebx

    mov  eax,13
    mov  ebx,175*65536+85
    mov  ecx,40*65536+205
    mov  edx,0x80111199-19
    int  0x40

    mov  edx,text00
    mov  ebx,10*65536+45
    mov  eax,4
    mov  ecx,0xffffff
    mov  esi,LLL
  newline:
    int  0x40
    add  ebx,8
    add  edx,LLL
    cmp  [edx],byte 'x'
    jnz  newline

    popa
    ret

  drawtime:
    mov  ax,[time]                        ;hours 22
    mov  cl,1
    call unpacktime
    mov  [text00+LLL*18+28],word bx
    mov  al,ah                            ;minutes
    inc  cl
    call unpacktime
    mov  [text00+LLL*18+31],word bx
    mov  eax,[date]
    mov  ch,3
    call unpackdate
    mov  [text00+LLL*20+34],word bx       ;year   24
    mov  al,ah
    mov  ch,1
    call unpackdate
    mov  [text00+LLL*20+28],word bx       ;month
    bswap eax
    mov  al,ah
    inc  ch
    call unpackdate
    mov  [text00+LLL*20+31],word bx       ;day

    mov  eax,13
    mov  ebx,175*65536+85
    mov  ecx,40*65536+205
    mov  edx,0x80111199-19
    int  0x40

    mov  edx,text00
    mov  ebx,10*65536+45
    mov  eax,4
    mov  ecx,0xffffff
    mov  esi,LLL
  newline1:
    int  0x40
    add  ebx,8
    add  edx,LLL
    cmp  [edx],byte 'x'
    jnz  newline1
    ret

  unpacktime:
    cmp  byte [blinkpar],cl       ;translate packed number to ascii
    jne  unpack1
  chkblink:
    bt dword [blinkpar],16
    jnc  unpack1
    xor  bx,bx
    ret
  unpackdate:
    cmp  byte [blinkpar+1],ch
    je   chkblink
  unpack1:
    xor  bx,bx
    mov  bh,al
    mov  bl,al
    and  bh,0x0f
    shr  bl,4
    add  bx,0x3030
    ret

  hexconvert:             ;converting dec to hex in ascii
    xor  ebx,ebx
    mov  bl,al
    and  bl,15
    add  ebx,hex
    mov  cl,[ebx]
    mov  [esi],cl
    shr  eax,4
    xor  ebx,ebx
    mov  bl,al
    and  bl,15
    add  ebx,hex
    mov  cl,[ebx]
    dec  esi
    mov  [esi],cl
    shr  eax,4
    xor  ebx,ebx
    mov  bl,al
    and  bl,15
    add  ebx,hex
    mov  cl,[ebx]
    dec  esi
    mov  [esi],cl
    ret

onoff:
    cmp [syslang],4
    jne norus1
    mov ebx,'??  '
    cmp eax,1
    je  exitsub
    mov ebx,'??? '
    ret
 norus1:
    mov ebx,'ON  '
    cmp eax,1
    je  exitsub
    mov ebx,'OFF '
 exitsub:
    ret

_midibase:
    mov  eax,21
    mov  ebx,1
    mov  ecx,[midibase]
    int  0x40
 ret

_cdbase:
    mov  eax,21
    mov  ebx,3
    mov  ecx,[cdbase]
    int  0x40
 ret

_hdbase:
    mov  eax,21
    mov  ebx,7
    mov  ecx,[hdbase]
    int  0x40
    ret

_sound_dma:
    mov  eax,21
    mov  ebx,10
    mov  ecx,[sound_dma]
    int  0x40
    ret

_lba_read:
    mov  eax,21
    mov  ebx,11
    mov  ecx,[lba_read]
    int  0x40
    ret

_pci_acc:
    mov  eax,21
    mov  ebx,12
    mov  ecx,[pci_acc]
    int  0x40
    ret

_f32p:
    mov  eax,21
    mov  ebx,8
    mov  ecx,[f32p]
    int  0x40
 ret

_sb16:
    mov  eax,21
    mov  ebx,4
    mov  ecx,[sb16]
    int  0x40
    ret

_wssp:
    mov  eax,21
    mov  ebx,6
    mov  ecx,[wssp]
    int  0x40
 ret

_syslang:
    mov  eax,21
    mov  ebx,5
    mov  ecx,[syslang]
    int  0x40
 ret

loadtxt:
    cld
    mov  edi,text00
    mov  ecx,428
    cmp  [syslang],4
    jne  norus
    mov  esi,textrus
    jmp  sload
  norus:
    mov  esi,texteng
  sload:
    rep  movsd
    ret

cleantxt:
    xor  eax,eax
    mov  ecx,428
    cld
    mov  edi,text00
    rep stosd
    mov  [text00+1711],byte 'x'
    ret

settime:
    mov  dx,0x70
    call startstopclk
    dec  dx
    mov  al,2            ;set minutes
    out  dx,al
    inc  dx
    mov  al,byte [time+1]
    out  dx,al
    dec  dx
    mov  al,4            ;set hours
    out  dx,al
    inc  dx
    mov  al,byte [time]
    out  dx,al
    dec  dx
    mov  al,7            ;set day
    out  dx,al
    inc  dx
    mov  al,byte [date+2]
    out  dx,al
    dec  dx
    mov  al,8            ;set month
    out  dx,al
    inc  dx
    mov  al,byte [date+1]
    out  dx,al
    dec  dx
    mov  al,9            ;set year
    out  dx,al
    inc  dx
    mov  al,byte [date]
    out  dx,al
    dec  dx
    call startstopclk
    ret

startstopclk:
    mov  al,0x0b
    out  dx,al
    inc  dx
    in   al,dx
    btc  ax,7
    out  dx,al
    ret

; DATA AREA
count:    db 0x0
blinkpar: dd 0x0
time:     dw 0x0
date:     dd 0x0

filename: db 'SETUP   DAT',0

textrus:

    db '???? MIDI ROLAND MPU-401  : 0x320           - +   ?????????'
    db '                                                           '
    db '???? SoundBlaster 16      : 0x240           - +   ?????????'
    db '                                                           '
    db '???? CD-ROM?              : PRI.SLAVE       - +   ?????????'
    db '                                                           '
    db '???? ??-1                 : PRI.MASTER      - +   ?????????'
    db '                                                           '
    db '???? ???????              : ENGLISH         - +   ?????????'
    db '                                                           '
    db '????????? ??????????      : ENGLISH         - +   ?????????'
    db '                                                           '
    db '???? WSS                  : 0x200           - +   ?????????'
    db '                                                           '
    db '?????? FAT32 ?? ??-1      : 1               - +   ?????????'
    db '                                                           '
    db '???????? ????? DMA        : 1               - +   ?????????'
    db '                                                           '
;    db '???????? LBA              : OFF             - +   ?????????'
;    db '                                                           '
;    db '?????? ? ???? PCI         : OFF             - +   ?????????'
;    db '                                                           '
    db '????????? ?????           :  0:00           - +     ?????  '
    db '                                                           '
    db '????????? ???? (?,?,?)    : 00/00/00        - +     ?????  '
    db '                                                           '
    db '????????:                                    ????????? ??? '
    db '??????????? ?????? ? FAT-32 ?????????!                     '
    db '?? ???????? ????????? ?????????              ????????? ??? '
    db 'x'

texteng:

    db 'MIDI: ROLAND MPU-401 BASE : 0x320           - +     APPLY  '
    db '                                                           '
    db 'SOUND: SB16 BASE          : 0x240           - +     APPLY  '
    db '                                                           '
    db 'CD-ROM BASE               : PRI.SLAVE       - +     APPLY  '
    db '                                                           '
    db 'HARDDISK-1 BASE           : PRI.MASTER      - +     APPLY  '
    db '                                                           '
    db 'SYSTEM LANGUAGE           : ENGLISH         - +     APPLY  '
    db '                                                           '
    db 'KEYBOARD LAYOUT           : ENGLISH         - +     APPLY  '
    db '                                                           '
    db 'WINDOWS SOUND SYSTEM BASE : 0x200           - +     APPLY  '
    db '                                                           '
    db 'FAT32-1 PARTITION IN HD-1 : 1               - +     APPLY  '
    db '                                                           '
    db 'SOUND DMA CHANNEL         : 1               - +     APPLY  '
    db '                                                           '
;    db 'LBA READ ENABLED          : OFF             - +     APPLY  '
;    db '                                                           '
;    db 'PCI ACCESS FOR APPL.      : OFF             - +     APPLY  '
;    db '                                                           '
    db 'SYSTEM TIME               :  0:00           - +    SELECT  '
    db '                                                           '
    db 'SYSTEM DATE (M,D,Y)       : 00/00/00        - +    SELECT  '
    db '                                                           '
    db 'NOTE:                                           APPLY ALL  '
    db 'TEST FAT32 FUNCTIONS WITH EXTREME CARE                     '
    db 'SAVE YOUR SETTINGS BEFORE QUIT MENUET           SAVE ALL   '
    db 'x'

labelt:
    db   '????????? ????????? MENUET DEVICE SETUP       '

hex db   '0123456789ABCDEF'

alt_general:

     db   ' ',27
     db   ' @ $  {[]}\ ',8,9
     db   '            ',13
     db   '             ',0,'           ',0,'4',0,' '
     db   '             ',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'ABCD',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'


en_keymap:

     db   '6',27
     db   '1234567890-=',8,9
     db   'qwertyuiop[]',13
     db   '~asdfghjkl;',39,96,0,'\zxcvbnm,./',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'


en_keymap_shift:

     db   '6',27
     db   '!@#$%^&*()_+',8,9
     db   'QWERTYUIOP{}',13
     db   '~ASDFGHJKL:"~',0,'|ZXCVBNM<>?',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB>D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'


fr_keymap:

     db   '6',27
     db   '&?"',39,'(-?_??)=',8,9
     db   'azertyuiop^$',13
     db   '~qsdfghjklm?',0,0,'*wxcvbn,;:!',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'



fr_keymap_shift:


     db   '6',27
     db   '1234567890+',8,9
     db   'AZERTYUIOP??',13
     db   '~QSDFGHJKLM%',0,'?WXCVBN?./',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB>D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'


fr_keymap_alt_gr:


     db   '6',27
     db   28,'~#{[|?\^@]}',8,9
     db   'azertyuiop^$',13
     db   '~qsdfghjklm?',0,0,'*wxcvbn,;:!',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'




fi_keymap:

     db   '6',27
     db   '1234567890+[',8,9
     db   'qwertyuiop',192,'~',13
     db   '~asdfghjkl',194,193,'1',0,39,'zxcvbnm,.-',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'


fi_keymap_shift:

     db   '6',27
     db   '!"#?%&/()=?]',8,9
     db   'QWERTYUIOP',200,'~',13
     db   '~ASDFGHJKL',202,201,'1',0,'*ZXCVBNM;:_',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB>D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'



ge_keymap:

     db   '6',27
     db   '1234567890?[',8,9
     db   'qwertzuiop',203,'~',13
     db   '~asdfghjkl',194,193,'1',0,39,'yxcvbnm,.-',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'


ge_keymap_shift:

     db   '6',27
     db   '!"#$%&/()=',197,']',8,9
     db   'QWERTZUIOP',195,'~',13
     db   '~ASDFGHJKL',202,201,'1',0,'*YXCVBNM;:_',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB>D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

ru_keymap:

     db   '6',27
     db   '1234567890-=',8,9
     db   '????????????',13
     db   0,"???????????"
     db   0xf1, '-/'
     db   "?????????",'.-','45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'



ru_keymap_shift:

     db   '6',27
     db   '!"N;%:?*()_+',8,0
     db   "????????????",13
     db   0,"???????????"
     db   0xf0, '-\'
     db   "?????????",',-','45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB>D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

I_PARAM   dd 0

keyboard  dd 0x0
midibase  dd 0x320
cdbase    dd 0x2
sb16      dd 0x220
syslang   dd 0x1
wss       dd 0x1
wssp      dd 0x0
hdbase    dd 0x1
f32p      dd 0x1
sound_dma dd 0x1
lba_read  dd 0x1
pci_acc   dd 0x1

text00:

I_END:
