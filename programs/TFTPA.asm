;
;    TFTP Wave Player
;
;    Compile with FASM for Menuet
;
;
;    12.7.2002 - Audio system calls by VT
;
   
use32
   
                org     0x0
   
                db      'MENUET00'              ; 8 byte id
                dd      38                      ; required os
                dd      START                   ; program start
                dd      I_END                   ; program image size
                dd      0x100000                ; required amount of memory
                dd      0x00000000              ; reserved=no extended header

include 'macros.inc'
   
delay      dd  145
wait_for   dd  0x0
   
START:                          ; start of execution
   
    mov  dword [prompt], p9
    mov  dword [promptlen], p9len - p9
   
    call draw_window            ; at first, draw the window
   
still:
   
    mov  eax,10                 ; wait here for event
    int  0x40
   
    cmp  eax,1                  ; redraw request ?
    jz   red
    cmp  eax,2                  ; key in buffer ?
    jz   key
    cmp  eax,3                  ; button in buffer ?
    jz   button
   
    jmp  still
   
red:                           ; redraw
    call draw_window
    jmp  still
   
key:                           ; Keys are not valid at this part of the
    mov  eax,2                  ; loop. Just read it and ignore
    int  0x40
    jmp  still
   
button:                        ; button
    mov  eax,17                 ; get id
    int  0x40
   
    cmp  ah,1                   ; button id=1 ?
    jnz  noclose
   
   
    ; close socket before exiting
 mov  eax, 53
 mov  ebx, 1
 mov  ecx, [socketNum]
    int   0x40
   
 mov  [socketNum], dword 0
   
   
    mov  eax,0xffffffff         ; close this program
    int  0x40
   
noclose:
    cmp  ah,2                   ; copy file to local machine?
    jnz  nocopyl
   
    mov   dword [prompt], p5
    mov  dword [promptlen], p5len - p5
    call  draw_window            ;
   
    ; Copy File from Remote Host to this machine
    call translateData  ; Convert Filename & IP address
    mov  edi, tftp_filename + 1
    mov  [edi], byte 0x01 ; setup tftp msg
    call copyFromRemote
   
    jmp  still
   
nocopyl:
   
   
    cmp  ah,4
    jz   f1
    cmp  ah,5
    jz   f2
    jmp  nof12
   
  f1:
    mov  [addr],dword source
    mov  [ya],dword 35
    jmp  rk
   
  f2:
    mov  [addr],dword destination
    mov  [ya],dword 35+16
   
  rk:
    mov  ecx,15
    mov  edi,[addr]
    mov  al,' '
    rep  stosb
   
    call print_text
   
    mov  edi,[addr]
   
  f11:
    mov  eax,10
    int  0x40
    cmp  eax,2
    jz   fbu
    jmp  still
  fbu:
    mov  eax,2
    int  0x40  ; get key
    shr  eax,8
    cmp  eax,8
    jnz  nobs
    cmp  edi,[addr]
    jz   f11
    sub  edi,1
    mov  [edi],byte ' '
    call print_text
    jmp  f11
  nobs:
    cmp  eax,dword 31
    jbe  f11
    cmp  eax,dword 95
    jb   keyok
    sub  eax,32
  keyok:
    mov  [edi],al
   
    call print_text
   
    add  edi,1
    mov  esi,[addr]
    add  esi,15
    cmp  esi,edi
    jnz  f11
   
    jmp  still
   
print_text:
   
    mov  eax,13
    mov  ebx,103*65536+15*6
    mov  ecx,[ya]
    shl  ecx,16
    mov  cx,8
    mov  edx,0x224466
    int  0x40
   
    mov  eax,4
    mov  ebx,103*65536
    add  ebx,[ya]
    mov  ecx,0xffffff
    mov  edx,[addr]
    mov  esi,15
    int  0x40
   
    ret
   
   
  nof12:
    jmp  still
   
   
;***************************************************************************
;   Function
;      translateData
;
;   Description
;      Coverts the filename and IP address typed in by the user into
;      a format suitable for the IP layer.
;
;    The filename, in source, is converted and stored in tftp_filename
;      The host ip, in destination, is converted and stored in tftp_IP
;
;***************************************************************************
translateData:
   
 ; first, build up the tftp command string. This includes the filename
 ; and the transfer protocol
   
   
 ; First, write 0,0
 mov  al, 0
 mov  edi, tftp_filename
 mov  [edi], al
 inc  edi
 mov  [edi], al
 inc  edi
   
 ; Now, write the file name itself, and null terminate it
 mov  ecx, 15
 mov  ah, ' '
 mov  esi, source
   
td001:
 lodsb
 stosb
 cmp  al, ah
 loopnz td001
   
 cmp  al,ah  ; Was the entire buffer full of characters?
 jne  td002
 dec  edi   ; No - so remove ' ' character
   
td002:
 mov  [edi], byte 0
 inc  edi
 mov  [edi], byte 'O'
 inc  edi
 mov  [edi], byte 'C'
 inc  edi
 mov  [edi], byte 'T'
 inc  edi
 mov  [edi], byte 'E'
 inc  edi
 mov  [edi], byte 'T'
 inc  edi
 mov  [edi], byte 0
   
 mov  esi, tftp_filename
 sub  edi, esi
 mov  [tftp_len], edi
   
   
 ; Now, convert the typed IP address into a real address
 ; No validation is done on the number entered
 ; ip addresses must be typed in normally, eg
 ; 192.1.45.24
   
 xor  eax, eax
 mov  dh, 10
 mov  dl, al
 mov  [tftp_IP], eax
   
 ; 192.168.24.1   1.1.1.1       1. 9.2.3.
   
 mov  esi, destination
 mov  edi, tftp_IP
   
 mov  ecx, 4
   
td003:
 lodsb
 sub  al, '0'
 add  dl, al
 lodsb
 cmp  al, '.'
 je  ipNext
 cmp  al, ' '
 je  ipNext
 mov  dh, al
 sub  dh, '0'
 mov  al, 10
 mul  dl
 add  al, dh
 mov  dl, al
 lodsb
 cmp  al, '.'
 je  ipNext
 cmp  al, ' '
 je  ipNext
 mov  dh, al
 sub  dh, '0'
 mov  al, 10
 mul  dl
 add  al, dh
 mov  dl, al
 lodsb
   
ipNext:
 mov  [edi], dl
 inc  edi
 mov  dl, 0
 loop td003
   
 ret
   
   
   
;***************************************************************************
;   Function
;      copyFromRemote
;
;   Description
;
;***************************************************************************
copyFromRemote:
   
 mov  eax,0x20000-512
 mov  [fileposition], eax
   
 ; Get a random # for the local socket port #
 mov  eax, 3
 int  0x40
 mov  ecx, eax
 shr  ecx, 8    ; Set up the local port # with a random #
   
   ; open socket
 mov  eax, 53
 mov  ebx, 0
 mov  edx, 69    ; remote port
 mov  esi, [tftp_IP]  ; remote IP ( in intenet format )
 int  0x40
   
 mov  [socketNum], eax
   
 ; make sure there is no data in the socket - there shouldn't be..
   
cfr001:
 mov  eax, 53
 mov  ebx, 3
 mov  ecx, [socketNum]
 int  0x40    ; read byte
   
 mov  eax, 53
 mov  ebx, 2
 mov  ecx, [socketNum]
 int  0x40    ; any more data?
   
 cmp  eax, 0
 jne  cfr001    ; yes, so get it
   
 ; Now, request the file
 mov  eax, 53
 mov  ebx, 4
 mov  ecx, [socketNum]
 mov  edx, [tftp_len]
 mov  esi, tftp_filename
 int  0x40
   
cfr002:
   
    mov  eax,23                 ; wait here for event
    mov  ebx,1                  ; Time out after 10ms
    int  0x40
   
    cmp  eax,1                  ; redraw request ?
    je   cfr003
    cmp  eax,2                  ; key in buffer ?
    je   cfr004
    cmp  eax,3                  ; button in buffer ?
    je   cfr005
   
    ; Any data to fetch?
 mov  eax, 53
 mov  ebx, 2
 mov  ecx, [socketNum]
 int   0x40
   
 cmp  eax, 0
 je  cfr002
   
 push eax     ; eax holds # chars
   
 ; Update the text on the display - once
 mov  eax, [prompt]
 cmp  eax, p3
 je  cfr008
 mov   dword [prompt], p3
 mov  dword [promptlen], p3len - p3
 call  draw_window            ;
   
cfr008:
 ; we have data - this will be a tftp frame
   
 ; read first two bytes - opcode
 mov  eax, 53
 mov  ebx, 3
 mov  ecx, [socketNum]
 int  0x40   ; read byte
   
 mov  eax, 53
 mov  ebx, 3
 mov  ecx, [socketNum]
 int  0x40   ; read byte
   
 pop  eax
 ; bl holds tftp opcode. Can only be 3 (data) or 5 ( error )
   
 cmp  bl, 3
 jne  cfrerr
   
 push eax
   
 ; do data stuff. Read block #. Read data. Send Ack.
 mov  eax, 53
 mov  ebx, 3
 mov  ecx, [socketNum]
 int  0x40   ; read byte
   
 mov  [blockNumber], bl
   
 mov  eax, 53
 mov  ebx, 3
 mov  ecx, [socketNum]
 int  0x40   ; read byte
   
 mov  [blockNumber+1], bl
   
cfr007:
 mov  eax, 53
 mov  ebx, 3
 mov  ecx, [socketNum]
 int  0x40   ; read byte
   
 mov  esi, [fileposition]
 mov  [esi], bl
 mov  [esi+1],bl
 add  dword [fileposition],2
   
 mov  eax, 53
 mov  ebx, 2
 mov  ecx, [socketNum]
 int  0x40   ; any more data?
   
 cmp  eax, 0
 jne  cfr007  ; yes, so get it
   
 cmp  [fileposition],0x20000+0xffff
 jb   get_more_stream
   
wait_more:
   
 mov  eax,5    ; wait for correct timer position
               ; to trigger new play block
 mov  ebx,1
 int  0x40
   
 mov  eax,26
 mov  ebx,9
 int  0x40
   
 cmp  eax,[wait_for]
 jb   wait_more
   
 add  eax,[delay]
 mov  [wait_for],eax
   
 mov  esi,0x20000
 mov  edi,0x10000
 mov  ecx,65536
 cld
 rep  movsb
   
 mov  eax,55
 mov  ebx,0
 mov  ecx,0x10000
 int  0x40
   
 mov  eax,55
 mov  ebx,1
 int  0x40
   
 mov  [fileposition],0x20000
   
get_more_stream:
   
 ; write the block number into the ack
 mov  al, [blockNumber]
 mov  [ack + 2], al
   
 mov  al, [blockNumber+1]
 mov  [ack + 3], al
   
 ; send an 'ack'
 mov  eax, 53
 mov  ebx, 4
 mov  ecx, [socketNum]
 mov  edx, ackLen - ack
 mov  esi, ack
 int   0x40
   
 ; If # of chars in the frame is less that 516,
 ; this frame is the last
 pop  eax
 cmp  eax, 516
 je  cfr002
   
 ; Write the file
 mov  eax, 33
 mov  ebx, source
 mov  edx, [filesize]
 mov  ecx, I_END + 512
 mov  esi, 0
 int  0x40
   
 jmp  cfrexit
   
cfrerr:
 ; simple implementation on error - just read all data, and return
 mov  eax, 53
 mov  ebx, 3
 mov  ecx, [socketNum]
    int   0x40    ; read byte
   
 mov  eax, 53
 mov  ebx, 2
 mov  ecx, [socketNum]
    int   0x40    ; any more data?
   
 cmp  eax, 0
 jne  cfrerr    ; yes, so get it
   
 jmp  cfr006    ; close socket and close app
   
cfr003:                         ; redraw request
    call draw_window
    jmp  cfr002
   
cfr004:                         ; key pressed
    mov  eax,2                  ; just read it and ignore
    int  0x40
    jmp  cfr002
   
cfr005:                        ; button
    mov  eax,17                 ; get id
    int  0x40
   
    cmp  ah,1                   ; button id=1 ?
    jne  cfr002     ; If not, ignore.
   
cfr006:
    ; close socket
 mov  eax, 53
 mov  ebx, 1
 mov  ecx, [socketNum]
    int   0x40
   
 mov  [socketNum], dword 0
   
    mov  eax,-1                 ; close this program
    int  0x40
   
    jmp $
   
cfrexit:
    ; close socket
 mov  eax, 53
 mov  ebx, 1
 mov  ecx, [socketNum]
    int   0x40
   
 mov  [socketNum], dword 0
   
    mov   dword [prompt], p4
    mov  dword [promptlen], p4len - p4
    call  draw_window            ;
   
 ret
   
   
   
   
;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************
   
   
draw_window:
   
    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40
   
                                   ; DRAW WINDOW
    mov  eax,0                     ; function 0 : define and draw window
    mov  ebx,100*65536+230         ; [x start] *65536 + [x size]
    mov  ecx,100*65536+170         ; [y start] *65536 + [y size]
    mov  edx,0x03224466            ; color of work area RRGGBB
    mov  esi,0x00334455            ; color of grab bar  RRGGBB,8->color gl
    mov  edi,0x00ddeeff            ; color of frames    RRGGBB
    int  0x40
   
                                   ; WINDOW LABEL
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov  ecx,0x00ffffff            ; color of text RRGGBB
    mov  edx,labelt                ; pointer to text beginning
    mov  esi,labellen-labelt       ; text length
    int  0x40
   
   
    mov  eax,8              ; COPY BUTTON
    mov  ebx,20*65536+190
    mov  ecx,79*65536+15
    mov  edx,3
    mov  esi,0x557799
;    int  0x40
   
    mov  eax,8              ; DELETE BUTTON
    mov  ebx,20*65536+190
    mov  ecx,111*65536+15
    mov  edx,2
    mov  esi,0x557799
    int  0x40
   
    mov  eax,8
    mov  ebx,200*65536+10
    mov  ecx,34*65536+10
    mov  edx,4
    mov  esi,0x557799
    int  0x40
   
    mov  eax,8
    mov  ebx,200*65536+10
    mov  ecx,50*65536+10
    mov  edx,5
    mov  esi,0x557799
    int  0x40
   
   
 ; Copy the file name to the screen buffer
 ; file name is same length as IP address, to
 ; make the math easier later.
    cld
    mov  esi,source
    mov  edi,text+13
    mov  ecx,15
    rep  movsb
   
   
 ; copy the IP address to the screen buffer
    mov  esi,destination
    mov  edi,text+40+13
    mov  ecx,15
    rep  movsb
   
  ; copy the prompt to the screen buffer
    mov  esi,[prompt]
    mov  edi,text+280
    mov  ecx,[promptlen]
    rep  movsb
   
    ; Re-draw the screen text
    cld
    mov  ebx,25*65536+35           ; draw info text with function 4
    mov  ecx,0xffffff
    mov  edx,text
    mov  esi,40
  newline:
    mov  eax,4
    int  0x40
    add  ebx,16
    add  edx,40
    cmp  [edx],byte 'x'
    jnz  newline
   
   
    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40
   
    ret
   
   
; DATA AREA
   
source       db  'HEAT8M22.WAV   '
destination  db  '192.168.1.24   '
   
   
tftp_filename:  times 15 + 9 db 0
tftp_IP:   dd 0
tftp_len:   dd 0
   
addr  dd  0x0
ya    dd  0x0
   
fileposition dd 0 ; Points to the current point in the file
filesize  dd 0 ; The number of bytes written / left to write
fileblocksize dw 0 ; The number of bytes to send in this frame
   
text:
    db 'SOURCE FILE: xxxxxxxxxxxxxxx            '
    db 'HOST IP ADD: xxx.xxx.xxx.xxx            '
    db '                                        '
    db 'WAVE FORMAT: 8 BIT,MONO,22050HZ         '
    db '                                        '
    db '     SERVER -> PLAY FILE                '
    db '                                        '
    db '                                        '
    db 'x <- END MARKER, DONT DELETE            '
   
   
labelt:
    db   'TFTP Wave Player'
labellen:
   
   
prompt: dd 0
promptlen: dd 0
   
   
p1:  db 'Waiting for Command '
p1len:
   
p9:  db 'Define SB with setup'
p9len:
   
p2:  db 'Sending File        '
p2len:
   
p3:  db 'Playing File        '
p3len:
   
p4:  db 'Complete            '
p4len:
   
p5:  db 'Contacting Host...  '
p5len:
   
p6:  db 'File not found.     '
p6len:
   
ack:
 db 00,04,0,1
ackLen:
   
socketNum:
 dd 0
   
blockNumber:
 dw 0
   
; This must be the last part of the file, because the blockBuffer
; continues at I_END.
blockBuffer:
 db 00, 03, 00, 01
I_END:
   
   
   
   
   
   
   