;
;   DESKTOP CONTEXT MENU
;   written by Ivan Poddubny
;
;   ���� - ���� ����㡭�
;   e-mail: ivan-yar@bk.ru
;
;   Compile with flat assembler
;

include 'macros.inc'

meos_app_start
code

  mov   eax,40       ; ��⠭���� ���� ᮡ�⨩
  mov   ebx,100000b  ; ��� ������� ⮫쪮 ����
  int   0x40

still:               ; ������ 横� �᭮����� �����

  mov   eax,10       ; ��� ᮡ���
  int   0x40

  cmp   eax,6        ; ����?
  jne   still

  mov   eax,37       ; ����� ������ ������?
  mov   ebx,2
  int   0x40

  cmp   eax,2        ; �᫨ �� �ࠢ��, ������
  jne   still

;---���堫�!---

  mov   eax,37       ; �� ��� �⫠��� - �᫨ ���� � �窥 (0;0), ���஥���
  xor   ebx,ebx
  int   0x40
  test  eax,eax      ; ����� � �窥 (0;0), �.�. eax = 0
  je    exit


  mov   eax,9        ; ����稬 �᫮ ����ᮢ � ��⥬�
  mov   ebx,procinfo
  xor   ecx,ecx
  int   0x40

  inc   eax          ; ⥯��� � eax ᮤ�ন��� �᫮ ����ᮢ + 1
  mov   [processes],eax
  mov   ecx,1

 new_process:
  pushad
  mov   eax,9        ; ����稬 ���ଠ�� � �����; ����� - � ecx
  mov   ebx,procinfo
  int   0x40
  mov   eax,37       ; ���न���� �����
  xor   ebx,ebx
  int   0x40
  mov   ebx,eax                  ; eax = cursor_x
  shr   eax,16                   ; ebx = cursor_y
  and   ebx,0xffff
  mov   [curx1],eax              ; curx1 = cursor_x
  mov   [cury1],ebx              ; cury1 = cursor_y
  mov   eax,[procinfo.x_start]   ; eax = wnd_x_start
  mov   ebx,[procinfo.y_start]   ; ebx = wnd_y_start

  mov   ecx,[procinfo.x_size]
  add   ecx,eax                  ; ecx = wnd_x_end
  mov   edx,[procinfo.y_size]
  add   edx,ebx                  ; ecx = wnd_y_end

  cmp   eax,[curx1]  ; wnd_x_start > cursor_x => ����� ����� ����
  jg    ne_goden
  cmp   ecx,[curx1]  ; wnd_x_end   < cursor_x => ����� �ࠢ�� ����
  jl    ne_goden
  cmp   ebx,[cury1]  ; wnd_y_start > cursor_y => ����� ��� ����
  jg    ne_goden
  cmp   edx,[cury1]  ; wnd_y_end   < cursor_y => ����� ���� ����
  jl    ne_goden

goden:               ; ���� �� ����� ������-� ����, ���⮬� ��祣� �� ������
  popad
  jmp   still

ne_goden:            ; ���� �� ᭠�㦨 ��ᬠ�ਢ������ ����, ���⮬�
  popad
  inc   ecx
  cmp   ecx,[processes]
  jl    new_process  ; ���� ᬮਬ ᫥���饥 ����, ���� ����᪠�� ����


@@:             ; �������, ���� ���짮��⥫� �� ����⨫ �ࠢ�� ������ ���
  mov   eax,37
  mov   ebx,2   ; �㭪�� 37-2:
  int   0x40    ;   ������ �� ������ ���?
  cmp   eax,ebx ; �᫨ ����⨫, (eax != 2)
  jnz   @f      ;   ��� � ��砫� �������� 横��

  mov   eax,5   ; ����
  mov   ebx,2   ;   ������� 2 ��
  int   0x40

  jmp   @b      ;   � �஢�ਬ ���� �����
@@:

; �᫨ 㦥 �뫮 ����� ����, �㦭� ���������, ���� ��� ���஥���:
@@:
  cmp   [menu_opened],0
  je    @f
  mov   eax,5
  mov   ebx,3  ; ��� 3 ��
  int   0x40
  jmp   @b
@@:

  mov   eax,51           ; � ⥯��� ����� ᬥ�� ����᪠�� ����� (��⮪) ����
  mov   ebx,1            ; ᮧ��� ��⮪ (thread)
  mov   ecx,start_wnd    ; �窠 �室� ��⮪�
  mov   edx,stack_wnd    ; ���設� ����� ��� ��⮪�
  int   0x40

  jmp   still



exit_menu:            ; �᫨ ��室�� �� ����, ���� ������� � [menu_opened] 0
  mov   [menu_opened],0
exit:                 ; � �� ���, ����� ��室�� �� �᭮����� �����
  or    eax,-1        ; eax = -1
  int   0x40




; ����� ������ ����� ����
start_wnd:
  mov   [menu_opened],1
  call  draw_window

  mov   eax,40      ; ��⠭���� ���� �������� ᮡ�⨩ ��� �⮣� �����
  mov   ebx,100101b ; ���� + ������ + ����ᮢ��
  int   0x40

still2:             ; ������ 横� ����� ����

  mov   eax,10      ; ��� ᮡ���
  int   0x40

  cmp   eax,1       ; ����ᮢ��?
  je    red
  cmp   eax,3       ; ������?
  je    button
  cmp   eax,6       ; ����?
  je    mouse

  jmp   still2      ; ������ � ��砫� �������� 横��


; ���������� ����
mouse:            ; ����� ���짮��⥫� ������ ������ ���, ���஥���
  mov   eax,37
  mov   ebx,2     ; ����� ������ ������?
  int   0x40
  test  eax,eax   ; �������? - ⮣�� �४�᭮! ������ � ����� 横�
  jz    still2
  jmp   exit_menu ; � �᫨ ���-⠪� ������ - ���஥� ����


; ������������ ����
red:
  call  draw_window
  jmp   still2


; ������ ������
button:
  mov   eax,17        ; ������� �����䨪��� ����⮩ ������
  int   0x40

  cmp   ah,10         ; �ࠢ������ � 10
  jl    nofuncbtns    ; �᫨ ����� - ����뢠�� ����

  add   ah,-10        ; ���⥬ �� �����䨪��� ������ 10
  movzx ebx,ah        ; ����稫� ����� �ணࠬ�� � ᯨ᪥ � ebx
  imul  ebx,11        ; 㬭���� ��� �� 11 - ����� ��ப�
  add   ebx,startapps ; ⥯��� � ebx ᮤ�ন��� ���� ��ப� � ������ �ணࠬ��
  mov   eax,19        ; �㭪�� 19 - ����� �ணࠬ�� � ࠬ��᪠
  xor   ecx,ecx       ; ��� ��ࠬ��஢
  int   0x40

;  mov   eax,5         ; �������, ���� �ணࠬ�� ����������
;  mov   ebx,1         ; � � �� ���� �� �㤥� ���ᮢ��� (��� � ��???)
;  int   0x40          ; �᪮�������� �� ��ப�, �᫨ � ��� �஡����
                       ; � ���ᮢ���

nofuncbtns:           ; ����뢠�� ����
  jmp   exit_menu



_BTNS_          = 6     ; ������⢮ ������ ("�㭪⮢ ����")
wnd_x_size      = 105   ; �ਭ� ����
string_length   = 12    ; ����� ��ப�

;*******************************
;********  ������ ����  ********
;*******************************

draw_window:

  mov   eax,12           ; ��稭��� "�ᮢ���"
  mov   ebx,1
  int   0x40

  mov   eax,[curx1]      ; ⥪�騥 ���न���� �����
  mov   [curx],eax       ; ����襬 � ���न���� ����
  mov   eax,[cury1]
  mov   [cury],eax

; ⥯��� �㤥� ����� ���न���� ����, �⮡� ��� �� �ࠩ ��࠭� �� �뫥���
  mov   eax,14                ; ����稬 ࠧ��� ��࠭�
  int   0x40
  mov   ebx,eax
  shr   eax,16                ; � eax - x_screen
  and   ebx,0xffff            ; � ebx - y_screen
  add   eax,-wnd_x_size       ; eax = [x_screen - �ਭ� ����]
  add   ebx,-_BTNS_*15-21     ; ebx = [y_screen - ���� ����]

  cmp   eax,[curx]
  jg    okx                   ; �᫨ ���� ᫨誮� ������ � �ࠢ��� ���,
  add   [curx],-wnd_x_size    ; ᤢ���� ��� ����� �� 100
 okx:

  cmp   ebx,[cury]
  jg    oky                   ; �� ���⨪��� �筮 ⠪��
  add   [cury],-_BTNS_*15-21
 oky:

  mov   eax,48                   ; ������� ��⥬�� 梥�
  mov   ebx,3
  mov   ecx,sc                   ;  ���� ��������
  mov   edx,sizeof.system_colors ;  � �� ࠧ���
  int   0x40

  xor   eax,eax           ; �㭪�� 0 - ᮧ���� ����
  mov   ebx,[curx]        ;  ebx = [���न��� �� x] shl 16 + [�ਭ�]
  shl   ebx,16
  add   ebx,wnd_x_size
  mov   ecx,[cury]        ;  ecx = [���न��� �� y] shl 16 + [����]
  shl   ecx,16
  add   ecx,_BTNS_*15+21
  mov   edx,[sc.work]     ;  梥� ࠡ�祩 ������
  mov   esi,[sc.grab]     ;  梥� ���������
  or    esi,0x80000000
  mov   edi,[sc.frame]    ;  梥� ࠬ��
  int   0x40

  mov   eax,4             ; ���������
  mov   ebx,27*65536+7    ;  [x] shl 16 + [y]
  mov   ecx,[sc.grab_text];  ���� � 梥� (���)
  add   ecx,-0x333333
  or    ecx,0x10000000
  mov   edx,header        ;  ���� ���������
  mov   esi,header_len    ;  ����� ��������� ("M E N U")
  int   0x40
  add   ecx,0x333333      ;  梥� ����
  add   ebx,1 shl 16      ;  ᤢ���� ��ࠢ� �� 1
  int   0x40

  mov   ebx,1*65536+wnd_x_size-2  ; ��稭��� ������ ������
  mov   ecx,20*65536+15
  mov   edx,10 or 0x40000000 ; ��� 30 ��⠭����� => ������ �� ������

  mov   edi,_BTNS_           ; ������⢮ ������ (����稪)

 newbtn:                     ; ��砫� 横��
  mov   eax,8                ;  ᮧ��� ������
  int   0x40

                             ;  ��襬 ⥪�� �� ������
  pushad                     ;   ᯠᠥ� ॣ�����
  shr   ecx,16
  and   ebx,0xffff0000
  add   ebx,ecx              ;   ebx = [x] shl 16 + [y];
  add   ebx,10*65536+4       ;   ebx += ᬥ饭�� �⭮�⥫쭮 ��� ������;
  mov   ecx,[sc.work_text]   ;   ���� � 梥�
  or    ecx,0x10000000
  add   edx,-10              ;   edx = ����� ������;
  imul  edx,string_length    ;   edx *= ����� ��ப�;
  add   edx,text             ;   edx += text;  ⥯��� � edx ���� ��ப�
  mov   esi,12               ;   � esi - ����� ��ப�
  mov   eax,4                ;   �㭪�� 4 - �뢮� ⥪��
  int   0x40
  popad

  inc   edx                  ;  ����� ������++;
  add   ecx,15*65536         ;  㢥��稬 ᬥ饭�� �� y
  dec   edi                  ;  㬥��訬 ����稪
  jnz   newbtn               ; �᫨ �� ����, ����ਬ ��� ��� ࠧ

  mov   eax,12               ; �����稫� "�ᮢ���"
  mov   ebx,2
  int   0x40

ret                          ; ������



; ������ ���������
data
  startapps:         ; ᯨ᮪ �ਫ������
    db 'PIC4       '
    db 'DESKTOP    '
    db 'MV         '
    db 'CPU        '
    db 'SPANEL     '
    db 'ICONMNGR   '

  header:            ; ���������
    db 'M E N U'
  header_len = $ - header

  text:              ; ⥪�� �� �������
  ; 12 bytes
    db 'Background  '
    db 'Colors      '
    db 'MeView      '
    db 'Processes   '
    db 'Panel setup '
    db 'Icon manager'



; �������������������� ������
udata
  processes   dd ?              ; ������⢮ ����ᮢ � ��⥬�
  curx1       dd ?              ; ���न���� �����
  cury1       dd ?
  curx        dd ?              ; ���न���� ���� ����
  cury        dd ?

  menu_opened db ?              ; ����� ���� ��� ���? (1-��, 0-���)

  sc       system_colors        ; ��⥬�� 梥�
  procinfo process_information  ; ���ଠ�� � �����

  rb 1024                       ; ���� ��� ���� ���� - 墠�� � 1 ��
  align 32
  stack_wnd:


meos_app_end
; ����� ���������