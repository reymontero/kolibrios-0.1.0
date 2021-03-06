;
;   �ਬ�� �ணࠬ�� ��� MenuetOS
;   ����稢��� ��� ����⮩ ������ ;)
;
;   �������஢��� FASM'��
;
;   ��. ⠪��:
;     template.asm  -  �ਬ�� ���⥩襩 �ணࠬ�� (����!)
;     paint.asm     -  �ਬ�⨢�� ����᪨� ।����
;     rb.asm        -  ���⥪�⭮� ���� ࠡ�祣� �⮫�
;     example2.asm  -  �ਬ�� ���� � �������⥫��� ����
;     example3.asm  -  �ਬ�� ����, ॠ����������� ��-��㣮��

use32                ; ������� 32-���� ०�� ��ᥬ����

  org    0x0         ; ������ � ���

  db     'MENUET01'  ; 8-����� �����䨪��� MenuetOS
  dd     0x01        ; ����� ��������� (�ᥣ�� 1)
  dd     START       ; ���� ��⪨, � ���ன ��稭����� �믮������ �ணࠬ��
  dd     I_END       ; ࠧ��� �ணࠬ��
  dd     0x100000    ; ������⢮ �����
  dd     0x100000    ; ���� ���設� �����
  dd     0x0         ; ���� ���� ��� ��ப� ��ࠬ��஢ (�� �ᯮ������)
  dd     0x0         ; ��१�ࢨ஢���

include 'macros.inc' ; 㬥��蠥� ࠧ��� �ணࠬ��
                     ; � ᮤ�ন� ������� ������


START:                  ; ����� ��稭����� �믮������ �ணࠬ��

red:                    ; ����ᮢ��� ����

    call draw_window    ; ��뢠�� ��楤��� ���ᮢ�� ����

still:                  ; ������� ���� ���������

    mov  eax,10         ; �㭪�� 10 - ����� ᮡ���
    int  0x40           ; ��뢠�� ��⥬�

    cmp  eax,1          ; ����ᮢ��� ���� ?
    je   red            ; �᫨ �� - �� ���� red
    cmp  eax,2          ; ����� ������ ?
    je   key            ; �᫨ �� - �� key
    cmp  eax,3          ; ����� ������ ?
    je   button         ; �᫨ �� - �� button

    jmp  still          ; �᫨ ��㣮� ᮡ�⨥ - � ��砫� 横��

  key:                  ; ����� ������ �� ���������
    mov  eax,2          ; �㭪�� 2 - ����� ��� ᨬ����
    int  0x40           ; �맮� ��⥬�

    mov  [Music+1],ah   ;

; play music now
    mov  eax,55
    mov  ebx,eax
    mov  esi,Music
    int  0x40

    jmp  still          ; �������� � ��砫� 横��

  button:               ; ����� ������ � ���� �ணࠬ��
    mov  eax,17         ; 17 - ������� �����䨪��� ����⮩ ������
    int  0x40           ; �맮� ��⥬�

    cmp  ah,1           ; �����䨪��� == 1 ?
    jne  noclose        ; �᫨ ��� - ��� ����� �� noclose

    or   eax,-1         ; ��室 �� �ணࠬ��
    int  0x40           ; �맮� ��⥬�

  noclose:

    jmp  still          ; �����頥���



Music:
  db  0x90
  db  0x30
  db  0x00



;   *********************************************
;   *******  ����������� � ��������� ���� *******
;   *********************************************

draw_window:


    mov  eax,12                    ; �㭪�� 12: ᮮ���� �� �� ���ᮢ�� ����
    mov  ebx,1                     ; 1 - ��稭��� �ᮢ���
    int  0x40

                                   ; ������� ����
    mov  eax,0                     ; �㭪�� 0 : ��।����� � ���ᮢ��� ����
    mov  ebx,200*65536+200         ; [x ����] *65536 + [x ࠧ���]
    mov  ecx,200*65536+100         ; [y ����] *65536 + [y ࠧ���]
    mov  edx,0x02aabbcc            ; 梥� ࠡ�祩 ������  RRGGBB,8->color gl
    mov  esi,0x805080d0            ; 梥� ������ ��������� RRGGBB,8->color gl
    mov  edi,0x005080d0            ; 梥� ࠬ��            RRGGBB
    int  0x40

                                   ; ��������� ����
    mov  eax,4                     ; �㭪�� 4 : ������� � ���� ⥪��
    mov  ebx,8*65536+8             ; [x] *65536 + [y]
    mov  ecx,0x10ddeeff            ; ���� 1 � 梥� ( 0xF0RRGGBB )
    mov  edx,zagolovok             ; ���� ��ப�
    mov  esi,zag_konets-zagolovok  ; � �� �����
    int  0x40

    mov  eax,4
    mov  ebx,8 shl 16 + 30
    mov  ecx,0
    mov  edx,message
    mov  esi,msg_end-message
    int  0x40

                                   ; ������ �������� ����
    mov  eax,8                     ; �㭪�� 8 : ��।����� � ���ᮢ��� ������
    mov  ebx,(200-19)*65536+12     ; [x ����] *65536 + [x ࠧ���]
    mov  ecx,5*65536+12            ; [y ����] *65536 + [y ࠧ���]
    mov  edx,1                     ; �����䨪��� ������ - 1
    mov  esi,0x6688dd              ; 梥� ������ RRGGBB
    int  0x40

    mov  eax,12                    ; �㭪�� 12: ᮮ���� �� �� ���ᮢ�� ����
    mov  ebx,2                     ; 2, �����稫� �ᮢ���
    int  0x40

    ret                            ; ��室�� �� ��楤���


; ����� ��室���� ����� �ணࠬ��:

; ����䥩� �ணࠬ�� ������� - ������ �� � macros.inc
message:
if lang eq ru                      ; �᫨ �� = ���᪨�, �
     db '������ ���� �������...'
else                               ; ����
     db 'Press any key...'
end if                             ; ����� ��⢫����
msg_end:

zagolovok:               ; ��ப� ���������
if lang eq ru
     db   '���������� ���������'
else
     db   'EXAMPLE APPLICATION'
end if
zag_konets:              ; � �� �����

I_END: