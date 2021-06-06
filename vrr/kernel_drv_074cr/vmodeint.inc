;
; Call of videomode driver's functions
;
; (Add in System function 21 (and/or 26) as a subfunction 13)
;
; Author: Trans
; Date:  19.07.2003
;
; Include in MeOS kernel and compile with FASM
;
     cmp  eax,13                     ; CALL VIDEOMODE DRIVER FUNCTIONS
     jne  .no_vmode_drv_access
     xor eax,eax                 ; If driver is absent then eax no change
     dec eax                     ;
     call 0x760100               ; Entry point to driver
     mov  [esp+36],eax
     mov  [esp+24],ebx
     mov  [esp+32],ecx
;     mov  [esp+28],edx
     ret
   .no_vmode_drv_access:

