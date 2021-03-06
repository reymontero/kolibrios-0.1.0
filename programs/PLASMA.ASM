; Originally written by Jarek Pelczar
include "MACROS.INC"

WND_SIZE_X		= 320
WND_SIZE_Y		= 200

MEOS_APP_START
CODE
    fninit
    mov al,40
    mov bl,101b
    int 0x40
    call init_palette
    call init_texture
    jmp .paint_window
.event_loop:
    mov al,23
    mov ebx,1
    int 0x40
    test eax,eax
    je .draw_screen
    dec eax
    je .paint_window

    or  eax,-1
    int 0x40

.draw_screen:
    call blit_8_to_32
    mov al,7
    mov ebx,virtual_screen_32
    mov ecx,(WND_SIZE_X shl 16)+WND_SIZE_Y
    mov edx,(4 shl 16)+24
    int 0x40
    call rotate_pal
    jmp .event_loop

.paint_window:
    mov al,12
    push eax
    xor ebx,ebx
    inc ebx
    int 0x40

    xor eax,eax
    mov ebx,(100 shl 16)+(WND_SIZE_X+8)
    mov ecx,(100 shl 16)+(WND_SIZE_Y+28)
    mov edx,0x03000000
    int 0x40

    mov al,7
    mov ebx,virtual_screen_32
    mov ecx,(WND_SIZE_X shl 16)+WND_SIZE_Y
    mov edx,(4 shl 16)+24
    int 0x40

    mov al,4
    mov ebx,0x00060006
    mov ecx,0x10ffffff
    mov edx,window_title
    mov esi,window_title_len
    int 0x40

    pop eax
    and ebx,2 ; bit 1 is set
    int 0x40

    jmp .event_loop

init_palette:
    mov edi,_palette
    mov ecx,64
    xor eax,eax
.color1:
    inc ah
    mov al,ah
    stosb
    xor al,al
    stosb
    stosb
    inc edi
    loop .color1
    mov ecx,64
    push ecx
    xor eax,eax
.color2:
    mov al,63
    stosb
    mov al,ah
    stosb
    xor al,al
    stosb
    inc ah
    inc edi
    loop .color2
    pop ecx
    push ecx
    xor eax,eax
.color3:
    mov al,63
    stosb
    stosb
    mov al,ah
    stosb
    inc ah
    inc edi
    loop .color3
    pop ecx
    mov eax,0x003f3f3f
    rep stosd
    ret

init_texture:
    fldpi
    mov [_fpom16],180
    fidiv [_fpom16]
    fstp [_st_rad]
    mov edi,virtual_screen_8
    cdq
.itex_vertical:
    xor ecx,ecx
    fld [_st_rad]
    mov [_fpom16],5
    fimul [_fpom16]
    mov [_fpom16],dx
    fimul [_fpom16]
    fsin
    fmul [_multiplier]
    fstp [_fpom32]
.itex_horizontal:
    fld [_st_rad]
    mov [_fpom16],3
    fimul [_fpom16]
    mov [_fpom16],cx
    fimul [_fpom16]
    fsin
    fmul [_multiplier]
    fadd [_fpom32]
    mov [_fpom16],127
    fiadd [_fpom16]
    fistp [_fpom16]
    mov ax,[_fpom16]
    inc eax
    stosb
    inc ecx
    cmp ecx,WND_SIZE_X
    jne .itex_horizontal
    inc edx
    cmp edx,WND_SIZE_Y
    jne .itex_vertical
    ret

rotate_pal:
    mov ebx,[_palette+4]
    mov edi,_palette+4
    mov esi,_palette+8
    xor ecx,ecx
    mov cl,255
;    cld
    rep movsd
    mov [_palette+1020],ebx
    ret

include "GRAPH8.INC"

DATA
  _multiplier	dd 63.5

  window_title:
      db 'Plasma'
  window_title_len = $ - window_title

UDATA
  _fpom32		rd 1
  _fpom16		rw 1
  _st_rad		rd 1
  _palette:	rd 256

  virtual_screen_8:
   	rb WND_SIZE_X*WND_SIZE_Y

  virtual_screen_32:
   	rb WND_SIZE_X*WND_SIZE_Y*3

MEOS_APP_END
