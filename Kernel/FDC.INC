cylinder 		db 0
sector 		db 1
head		db 0

fdcmem		dd 0x100000
cpymem		dd 0x100000
dmamem		dd 0x100000
dmasize		db 0x0
dmamode	db 0x0

fdc_irq_func	dd fdc_dummy

fdc_st0		db 0


fdc_writeramdisk:
;   D000  ->   DFFF   free
	mov eax,0x100000
	mov ebx,0xD000
	mov ecx,512
	call memmove

	mov [dmamode],0x4A	;read from memory to floppy.
	mov [dmasize],0x1		;read 512 bytes sectors.
	call fdc_floppy_on		;start floppy A: moter.
	call fdc_recalibrate		;retract the head to cylinder 0, sector 1
	mov[head],0		;set variables.
	mov[cylinder],0
	mov [sector],1	
	mov[cpymem],0x102400

	call fdc_write		;fdc_write will start interruptflow
ret

fdc_pump:
	add [dmamem],512
	add [sector],1
	cmp [sector],19
	jnz .clusterread
	sub [dmamem],9216
	mov eax,[cpymem]
	mov ebx,[fdcmem]
	mov ecx,9216
	call memmove
	add [cpymem],9216
	cmp [head],0
	je .nocylinderchange
	add [cylinder],1
	.nocylinderchange:
	xor [head],1
	cmp [cylinder],80
	jnz .noendofwrite
	mov[fdc_irq_func],fdc_complete
	call fdc_floppy_off
	jmp .end
	.noendofwrite:
	mov [sector],1
	.clusterread:
	call fdc_write
	.end:
ret

fdc_write:
	call fdc_program_dma
	call fdc_seek
ret

fdc_seek:
	mov al, 0x0f
	call fdc_write_reg
	mov al,[head]
	shl al,2
	call fdc_write_reg
	mov al,[cylinder]
	call fdc_write_reg
	mov [fdc_irq_func],fdc_seek_result
ret
fdc_seek_result:
	call fdc_sensei
	cmp al,[cylinder]
	jz .succes
	call fdc_seek
	jmp .end
	.succes:
	call fdc_write_sector
	.end:
ret

fdc_write_sector:
	mov al,0x45		;write sector command
	call fdc_write_reg
	mov al,[head]		
	shl al,2	
	call fdc_write_reg
	mov al,[cylinder]
	call fdc_write_reg
	mov al,[head]
	call fdc_write_reg
	mov al,[sector]
	call fdc_write_reg
	mov al,2			;Sector size (2 ~> 512 bytes)
	call fdc_write_reg
	mov al,18			;last sector on track.
	call fdc_write_reg
	mov al,27			;length of GAP3 
	call fdc_write_reg
	mov al,0xFF		;data length, ignored.
	call fdc_write_reg
	mov [fdc_irq_func],fdc_write_result
ret

fdc_write_result:
	call fdc_read_reg
	mov [fdc_st0],al
	mov cx,6
	.readresult:
	call fdc_read_reg
	loop .readresult
	and [fdc_st0],11000000b
	cmp [fdc_st0],byte 0
	jz .succes
	call fdc_seek
	jmp .end
	.succes:
	call fdc_pump
	.end:
ret


fdc_sensei:	
	mov al,0x08		;get interrupt status command
	call fdc_write_reg		
	call fdc_read_reg		;get result in al;
	and al,0x80
	cmp al,0x80
	je fdc_sensei		;retry
	call fdc_read_reg
ret

fdc_program_dma:	
	mov al,0
	out 0x0c,al	; reset the flip-flop to a known state.
	mov al,6		; mask channel 2 so we can reprogram it. 
	out 0x0a,al
	mov al,[dmamode]	; 0x46 -> Read from floppy - 0x4A Write to floppy
	out 0x0b,al	
	mov al,0
	out 0x0c,al	; reset the flip-flop to a known state.
	mov eax,[dmamem]	
	out 0x04,al	; set the channel 2 starting address to 0
	shr eax,8
	out 0x04,al
	shr eax,8
	out 0x81,al
	mov al,0
	out 0x0c, al	; reset flip-flop
 	mov al, 0xff	;set count (actual size -1)
    	out 0x5, al
    	mov al, [dmasize]	;(0x1ff = 511 / 0x23ff =9215)
	out 0x5,al
	mov al,2
	out 0xa,al
ret

fdc_recalibrate:
	mov al,0x07		;calibrate command
	call fdc_write_reg
	mov al,0			;select drive 0
	call fdc_write_reg
	mov esi,300
	call delay_ms
	tot2:
	mov al,0x08		;get interrupt status command
	call fdc_write_reg	  	;send it
	call fdc_read_reg		;get command in al;
	cmp al,0x80
	je tot2
	mov ah,al
	call fdc_read_reg
	cmp ah,0x70
	je fdc_recalibrate
ret

fdc_busy:
	.command_check:
	mov dx,0x3F4
	in al,dx
	and al,0x10
	cmp al,0x10
	je .command_check
ret

fdc_read_reg:
	status_check:
	mov dx,0x3F4
	in al,dx
	and al,0xc0
	cmp al,0xc0
	jne status_check
	mov dx, 0x3F5 
	in al, dx 
ret

fdc_write_reg:
	mov bl,al
	.command_check:
	mov dx,0x3F4
	in al,dx
	and al,0x80
	cmp al,0x80
	jne .command_check
	mov al,bl
	mov dx,0x3F5
	out dx,al
ret

fdc_floppy_off:
	mov al,0x0
	mov dx,0x3f2             
	out dx,al
ret

fdc_floppy_on:
	mov al,0x1C
	mov dx,0x3f2             
	out dx,al
	mov  esi,100		
	call delay_ms		;Wait a bit.
ret

endtext db 'FDC0 Ramdisk written to floppy.',13,10,0
fdc_complete:
	mov eax,0xD000
	mov ebx,0x100000
	mov ecx,512
	call memmove

	mov esi,endtext
	call sys_msg_board_str
	mov [fdc_irq_func],fdc_dummy
ret

dummytext db 'FDC0 Dummy called',13,10,0
fdc_dummy:
	mov esi,dummytext
	call sys_msg_board_str
ret

fdc_irq:
	call [fdc_irq_func]
ret