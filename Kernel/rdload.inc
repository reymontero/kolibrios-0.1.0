; READ RAMDISK IMAGE FROM HD

	cmp   [boot_dev],1
	jne   no_sys_on_hd
	mov   [fat32part],1	  ; Partition
	mov   [hdbase],0x1f0	  ; Controller base
	mov   [hdpos],1 	  ;
	mov   [0xfe10],dword 0	  ; entries in hd cache
	mov   [0x800000+1474560/1024],dword 0xffffffff
	xor   ecx,ecx
	inc   ecx
      hdbootl1:
	mov   eax,hdsysimage
	mov   ebx,12
	xor   edx,edx
	inc   edx
	mov   esi,0x90000
	pusha
	call  read_hd_file
	test  eax,eax		       ; image not found
	jne   $
	popa
	mov   eax,ecx
	dec   eax
	shr   eax,1
	mov   [eax+0x800000],byte 0xff
	push  ecx
	mov   edi,ecx
	dec   edi
	shl   edi,9
	add   edi,0x100000
	mov   esi,0x90000+1024
	mov   ecx,512/4
	cld
	rep   movsd		   ; move 0x90000+1024 -> 0x100000+
	pop   ecx
	inc   ecx
	cmp   ecx,1474560/512+1
	jb    hdbootl1
      no_sys_on_hd:
