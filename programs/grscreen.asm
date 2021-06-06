;
;   NICE BACKGROUND
;
;   Compile with FASM for Menuet
;

;******************************************************************************
    use32
    org    0x0

    db     'MENUET01'      ; 8 byte id
    dd     0x01            ; header version
    dd     START           ; start of code
    dd     I_END           ; size of image
    dd     0x20000         ; memory for app
    dd     0x20000         ; esp
    dd     0x0 , 0x0       ; I_Param , I_Icon

include    'macros.inc'
;******************************************************************************

GRADES       =    85          ; count of grades
START_COLOR  =    0x0078b000
STEP         =    0x00010100
xxx          equ  sub         ; from dark to light

;******************************************************************************

defcol db 'GREEN.DTP'

START:

mov eax,6           ; open system colors file
mov ebx,defcol
mov ecx,0
mov edx,-1
mov esi,0x10000
int 0x40

mov eax,48          ; set system colors
mov ebx,2
mov ecx,0x10000
mov edx,10*4
int 0x40

mov eax,image+3     ; generate image
mov ecx,GRADES-1
@@:
mov ebx,[eax-3]
xxx ebx,STEP
mov [eax],ebx
add eax,3
dec ecx
jnz @b

mov eax,15          ; copy image to background memory
mov ebx,5
mov ecx,image
xor edx,edx
mov esi,(GRADES+1)*3
int 0x40

mov eax,15          ; set stretch backgound
mov ebx,4
mov ecx,2
int 0x40

mov eax,15          ; set background size
mov ebx,1
mov ecx,ebx
mov edx,GRADES
int 0x40

mov eax,15          ; draw background
mov ebx,3
int 0x40

exit:               ; quit program
or  eax,-1
int 0x40

image:
dd START_COLOR

I_END:
; EOF