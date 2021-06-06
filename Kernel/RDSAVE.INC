     cmp  eax,6         ; SAVE FLOPPY IMAGE (HD version only)
     jnz  nosaveimage

     call restorefatchain      ; restore FAT !!!

     mov  eax,image_save
     mov  ebx,1440*1024        ; size 1440 Kb
     mov  ecx,0x100000         ; address of image
     mov  edx,path             ; path = 0 (root dir)
     call file_write

     ret

     path db 0

   nosaveimage:
