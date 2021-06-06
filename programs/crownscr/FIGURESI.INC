;
;  include file for Crown_s Soft(c) Screensaver
;
;  You may add you own figures for Screensaver.
;    For example see tor function.
;    If you add new figures, please mail me (crown-s@narod.ru).
;
;input  parametrs:
;  alf=[word esi]   - random quantity     0<=alf<=0xffff
;  bet=[word esi+2] - random quantity     0<=bet<=0xffff
;  Fl  - number of point in frame
;            (may be used as random quantity) 0<=Fl<=mFl
;  p   - number of frame
;            (may be use for animated figures)
;
;output parametrs:
;  st0=x,st1=y,st2=z

  align 4

  const_mpi  dd   0.00009587672516830326  ; 1/00007fffh*pi
  const_m    dd   0.00003051850947599719  ; 1/00007fffh

  tabl_calls dd  cube
             dd  tor1
             dd  tors
             dd  spiral
             dd  tor
             dd  planet
             dd  balls
             dd  sin
             dd  galaxy
  num_tabl_calls=9

  tor_r     dw   55
  tor_R     dw   170

  balls_x1  dw   0
  balls_x2  dw   189
  balls_x3  dw   -94
  balls_x4  dw   -94
  balls_y1  dw   0
  balls_y2  dw   0
  balls_y3  dw   163
  balls_y4  dw   -163
  balls_z1  dw   200
  balls_z2  dw   -71
  balls_z3  dw   -71
  balls_z4  dw   -71
  balls_R   dw   38

  cube_R    dw   100

  spiral_R  dw   100
  spiral_r  dw   20
  spiral_h  dw   150
  spiral_L  dw   12

  sin_a     dw   170
  sin_c     dw   3
  sin_k     dw   20

  sin_A     dw   90
  sin_R     dw   10

  planet_R  dw   120
  planet_r  dw   25
  planet_h  dw   195
  planet_d  dw   30

  galaxy_rq dw   40
  galaxy_rz dw   30
  galaxy_R  dw   180
  galaxy_k  dd   9.42477796076937971538793014983851 ; 3*pi

  tors_r    dw   10
  tors_R1   dw   100
  tors_R2   dw   150
  tors_R3   dw   200
  tors_a1   dw   6
  tors_a2   dw   3

  tor1_R      dw 7
  tor1_r      dd 1.8
  tor1_turns  dd 25.132741228718345907701147066236  ; 2*4*pi
  tor1_whorls dd 87.9645943005142106769540147318261 ; 7*4*pi
  tor1_a      dw 20


;---------------------------------------------------------------------------
;----------------------- calculation figures -------------------------------
;---------------------------------------------------------------------------
tor:
  fild  word [esi]   ; st0=alf
  fmul  [const_mpi]  ; st0=a=pi*alf*malf
  fsincos            ; st0=cos(a)  st1=sin(a)
  fild  [tor_r]      ; st0=r st1=cos(a)  st2=sin(a)
  fmul  st2,st0      ; st0=r st1=cos(a)  st2=r*sin(a)
  fmulp st1,st0      ; st0=r*cos(a)  st1=r*sin(a)
  fiadd [tor_R]      ; st0=r*cos(a)+R  st1=r*sin(a)
  fild  word [esi+2] ; st0=bet  st1=r*cos(a)+R  st2=r*sin(a)
  fmul  [const_mpi]  ; st0=b=pi*bet*mbet  st1=r*cos(a)+R  st2=r*sin(a)
  fsincos       ; st0=cos(b)  st1=sin(b)  st2=r*cos(a)+R  st3=r*sin(a)
  fxch  st2     ; st0=r*cos(a)+R  st1=sin(b)  st2=cos(b)  st3=r*sin(a)
  fmul  st2,st0 ; st0=r*cos(a)+R st1=sin(b) st2=cos(b)*(r*cos(a)+R) st3=r*sin(a)

  fmulp st1,st0 ; st0=sin(b)*(r*cos(a)+R) st1=cos(b)*(r*cos(a)+R) st2=r*sin(a)
ret


balls:
   mov     eax,[Fl]
   and     eax,03h

   fild   word [esi] ; st0=alf
   fmul  [const_mpi] ; st0=a=pi*alf*malf
   fsincos           ; st0=cos(a)  st1=sin(a)
   fild   [balls_R]  ; st0=R  st1=cos(a)  st2=sin(a)
   fmul   st2,st0    ; st0=R  st1=cos(a)  st2=R*sin(a)
   fmulp  st1,st0    ; st0=R*cos(a)  st2=R*sin(a)
   fild word [esi+2] ; st0=bet  st1=R*cos(a)  st2=R*sin(a)
   fmul [const_mpi]  ; st0=pi*bet*mbet  st1=R*cos(a)  st2=R*sin(a)
   fsincos           ; st0=cos(b)  st1=sin(b)  st2=R*cos(a)  st3=R*sin(a)
   fxch     st2      ; st0=R*cos(a)  st1=sin(b)  st2=cos(b)  st3=R*sin(a)
   fmul   st2,st0    ; st0=R*cos(a)  st1=sin(b)  st2=R*cos(a)*cos(b)  st3=R*si
   fmulp  st1,st0    ; st0=R*cos(a)*sin(b)  st1=R*cos(a)*cos(b)  st2=R*sin(a)

   fiadd [balls_y1+2*eax] ; st0=y+R*cos(a)*sin(b)  st1=R*cos(a)*cos(b)  st2=R*
   fxch  st1              ; st0=R*cos(a)*cos(b)    st1=y+R*cos(a)*sin(b)  st2=
   fiadd [balls_z1+2*eax] ; st0=z+R*cos(a)*cos(b)  st1=y+R*cos(a)*sin(b)  st2=
   fxch  st2              ; st0=R*sin(a)  st1=y+R*cos(a)*sin(b)  st2=z+R*cos(a
   fiadd [balls_x1+2*eax] ; st0=x+R*sin(a)  st1=y+R*cos(a)*sin(b)  st2=z+R*cos
ret


sin:
   test    [Fl],3Fh

   fild   word [esi]    ; st0=alf

   jnz     sin_lb1
     fmul   [const_mpi] ; st0=a=pi*alf*malf
     fsincos            ; st0=cos(a)  st1=sin(a)
     fild    [sin_R]    ; st0=R  st1=cos(a)  st2=sin(a)
     fmul   st2,st0     ; st0=R  st1=cos(a)  st2=R*sin(a)
     fmulp  st1,st0     ; st0=R*cos(a)  st2=R*sin(a)
     fild  word [esi+2] ; st0=bet  st1=R*cos(a)  st2=R*sin(a)
     fmul  [const_mpi]  ; st0=b=pi*bet*mbet  st1=R*cos(a)  st2=R*sin(a)
     fsincos            ; st0=cos(b)  st1=sin(b)  st2=R*cos(a)  st3=R*sin(a)
     fxch   st2         ; st0=R*cos(a)  st1=sin(b)  st2=cos(b)  st3=R*sin(a)
     fmul   st2,st0     ; st0=R*cos(a)  st1=sin(b)  st2=R*cos(a)*cos(b)  st3=R
     fmulp  st1,st0     ; st0=R*cos(a)*sin(b)  st1=R*cos(a)*cos(b)  st2=R*sin(
     fiadd   [sin_A]    ; st0=A+R*cos(b)*sin(a)  st2=R*cos(a)*cos(b)  st3=R*si
   ret

   sin_lb1:
   fmul    [const_m]  ; st0=alf*malf
   fild word [esi+2]  ; st0=bet  st1=alf*malf
   fmul    [const_m]  ; st0=bet*mbet  st1=alf*malf

   fld   st0       ; st0=bet*mbet  st1=bet*mbet  st2=alf*malf
   fmul  st0,st0   ; st0=(bet*mbet)^2  st1=bet*mbet  st2=alf*malf
   fld   st2       ; st0=alf*malf st1=(bet*mbet)^2  st2=bet*mbet  st3=alf*malf
   fmul  st0,st0   ; st0=(alf*malf)^2  st1=(bet*mbet)^2  st2=bet*mbet  st3=alf
   faddp st1,st0   ; st0=(alf*malf)^2+(bet*mbet)^2  st1=bet*mbet  st2=alf*malf
   fsqrt           ; st0=r=sqr((alf*malf)^2*(bet*mbet)^2)  st1=bet*mbet  st2=a
   fild    [sin_k] ; st0=k  st1=r  st2=bet*mbet  st3=alf*malf
   fmul  st0,st1   ; st0=k*r  st1=r  st2=bet*mbet  st3=alf*malf
   fsin            ; st0=sin(k*r)  st1=r  st2=bet*mbet  st3=alf*malf
   fdivrp  st1,st0 ; st0=sin(k*r)/r  st1=bet*mbet  st2=alf*malf
   fimul   [sin_c] ; st0=c*sin(k*r)/r  st1=bet*mbet  st2=alf*malf

   fild  [sin_a]   ; st0=a  st1=c*sin(k*r)/r  st2=bet*mbet  st3=alf*malf
   fmul  st2,st0   ; st0=a  st1=c*sin(k*r)/r  st2=a*bet*mbet  st3=alf*malf
   fmulp st3,st0   ; st0=c*sin(k*r)/r  st1=a*bet*mbet  st2=a*alf*malf
ret


tors:
   push    edx
   xor     edx,edx
   mov     eax,[Fl]
   div     [const3]
   mov     al,dl
   pop     edx

   fild    word [esi] ; st0=alf
   fmul   [const_mpi] ; st0=a=pi*alf*malf
   fsincos            ; st0=cos(a)  st1=sin(a)
   fild    [tors_r]   ; st0=r st1=cos(a)  st2=sin(a)
   fmul   st2,st0     ; st0=r st1=cos(a)  st2=r*sin(a)
   fmulp  st1,st0     ; st0=r*cos(a)  st1=r*sin(a)
   bt      ax,1
   jc      tors_l1     ; ax=xxxx xxxx xxxx xx1xb
   bt      ax,0
   jc      tors_l2     ; ax=xxxx xxxx xxxx xxx1b
     fiadd   [tors_R3] ; st0=r*cos(a)+R  st1=r*sin(a)
     fild word [esi+2] ; st0=bet  st1=r*cos(a)+R  st2=r*sin(a)
     fmul  [const_mpi] ; st0=b=pi*bet*mbet  st1=r*cos(a)+R  st2=r*sin(a)
     fsincos           ; st0=cos(b)  st1=sin(b)  st2=r*cos(a)+R  st3=r*sin(a)
     fxch    st2       ; st0=r*cos(a)+R  st1=sin(b)  st2=cos(b)  st3=r*sin(a)
     fmul   st2,st0    ; st0=r*cos(a)+R  st1=sin(b)  st2=cos(b)*(r*cos(a)+R)
     fmulp  st1,st0    ; st0=sin(b)*(r*cos(a)+R)  st1=cos(b)*(r*cos(a)+R)  st2
   ret

   tors_l1:
     fiadd   [tors_R2]  ; st0=r*cos(a)+R  st1=r*sin(a)
     fild  word [esi+2] ; st0=bet  st1=r*cos(a)+R  st2=r*sin(a)
     fmul  [const_mpi]  ; st0=b=pi*bet*mbet  st1=r*cos(a)+R  st2=r*sin(a)
     fsincos            ; st0=cos(b)  st1=sin(b)  st2=r*cos(a)+R  st3=r*sin(a)
     fxch    st2        ; st0=r*cos(a)+R  st1=sin(b)  st2=cos(b)  st3=r*sin(a)
     fmul   st2,st0     ; st0=r*cos(a)+R  st1=sin(b)  st2=cos(b)*(r*cos(a)+R)
     fmulp  st1,st0     ; st0=sin(b)*(r*cos(a)+R)  st1=cos(b)*(r*cos(a)+R)  st
   jmp tors_l3

   tors_l2:
     fiadd   [tors_R1]  ; st0=r*cos(a)+R  st1=r*sin(a)
     fild  word [esi+2] ; st0=bet  st1=r*cos(a)+R  st2=r*sin(a)
     fmul  [const_mpi]  ; st0=b=pi*bet*mbet  st1=r*cos(a)+R  st2=r*sin(a)
     fsincos            ; st0=cos(b)  st1=sin(b)  st2=r*cos(a)+R  st3=r*sin(a)
     fxch    st2        ; st0=r*cos(a)+R  st1=sin(b)  st2=cos(b)  st3=r*sin(a)
     fmul   st2,st0     ; st0=r*cos(a)+R  st1=sin(b)  st2=cos(b)*(r*cos(a)+R)
     fmulp  st1,st0     ; st0=sin(b)*(r*cos(a)+R)  st1=cos(b)*(r*cos(a)+R)  st


     ; around Y
     ;  x= x*cos(a)-z*sin(a)
     ;  y= y
     ;  z= x*sin(a)+z*cos(a)
     fld   st2       ; st0=z  st1=x  st2=y  st3=z
     fld   st1       ; st0=x  st1=z  st2=x  st3=y  st4=z
     fld   [al_r]
     fimul [tors_a1]   ; st0=a  st1=x  st2=z  st3=x  st4=y  st5=z
     fsincos           ; st0=cos(a)  st1=sin(a)  st2=x  st3=z  st4=x  st5=y  s
     fmul  st4,st0
     fmulp st6,st0     ; st0=sin(a)  st1=x  st2=z  st3=x*cos(a)  st4=y  st5=z*
     fmul  st2,st0
     fmulp st1,st0     ; st0=x*sin(a)  st1=z*sin(a)  st2=x*cos(a) st3=y st4=z*
     faddp st4,st0
     fsubp st1,st0

   tors_l3:
     ; around X
     ;  x=x
     ;  y= y*cos(b)+z*sin(b)
     ;  z=-y*sin(b)+z*cos(b)
     fld   st2       ; st0=z  st1=x  st2=y  st3=z
     fld   st2       ; st0=y  st1=z  st2=x  st3=y  st4=z
     fld   [al_r]
     fimul [tors_a2] ; st0=b  st1=y  st2=z  st3=x  st4=y  st5=z
     fsincos         ; st0=cos(b)  st1=sin(b)  st2=y  st3=z  st4=x  st5=y  st6
     fmul  st5,st0
     fmulp st6,st0   ; st0=sin(b)  st1=y  st2=z  st3=x  st4=y*cos(b)  st5=z*co
     fmul  st2,st0
     fmulp st1,st0   ; st0=y*sin(b) st1=z*sin(b) st2=x st3=y*cos(b) st4=z*co
     fsubp st4,st0   ; st0=z*sin(b)  st1=x  st2=y*cos(b)  st3=z*cos(b)-y*sin(b
     faddp st2,st0
ret



tor1:
   fild    [tor1_a]   ; st0=a
   fild  word [esi+2] ; st0=bet  st1=a
   fmul  [const_mpi]  ; st0=b=pi*bet*mbet  st1=a
   fsincos            ; st0=cos(b)  st1=sin(b)  st2=a
   fild    word [esi] ; st0=alf  st1=cos(b)  st2=sin(b)  st3=a
   fmul    [const_m]  ; st0=alf*malf  st1=cos(b)  st2=sin(b)  st3=a
   fld     st0        ; st0=alf*malf  st1=alf*malf  st2=cos(b)  st3=sin(b)  st
   fmul [tor1_whorls] ; st0=wa=whorls*alf*malf  st1=alf*malf  st2=cos(b)  st3=
   fsincos            ; st0=cos(wa)  st1=sin(wa)  st2=alf*malf  st3=cos(b)  st
   fld     [tor1_r]   ; st0=r  st1=cos(wa)  st2=sin(wa)  st3=alf*malf  st4=cos
   fmul   st2,st0     ; st0=r  st1=cos(wa)  st2=r*sin(wa)  st3=alf*malf  st4=c
   fmulp  st1,st0     ; st0=r*cos(wa)  st1=r*sin(wa)  st2=alf*malf  st3=cos(b)
   fiadd   [tor1_R]   ; st0=R+r*cos(wa)  st1=r*sin(wa)  st2=alf*malf  st3=cos(
   faddp  st3,st0     ; st0=r*sin(wa)  st1=alf*malf  st2=R+r*cos(wa)+cos(b)  s
   faddp  st3,st0     ; st0=alf*malf  st1=R+r*cos(wa)+cos(b)  st2=r*sin(wa)+si
   fmul  [tor1_turns] ; st0=ta=turns*alf*malf  st1=R+r*cos(wa)+cos(b)  st2=r*s
   fsincos            ; st0=cos(ta)  st1=sin(ta)  st2=R+r*cos(wa)+cos(b)  st3=
   fmul   st0,st2     ; st0=cos(ta)*(R+r*cos(wa)+cos(b))  st1=sin(ta)  st2=R+r
   fmul   st0,st4     ; st0=a*cos(ta)*(R+r*cos(wa)+cos(b))  st1=sin(ta)  st2=R
   fstp   st5         ; st0=sin(ta)  st1=R+r*cos(wa)+cos(b)  st2=r*sin(wa)+sin
   fmulp  st1,st0     ; st0=sin(ta)*(R+r*cos(wa)+cos(b))  st1=r*sin(wa)+sin(b)
   fmul   st0,st2     ; st0=z=a*sin(ta)*(R+r*cos(wa)+cos(b))  st1=r*sin(wa)+si
   fstp   st4         ; st0=r*sin(wa)+sin(b)  st1=a  st2=y  st3=z
   fmulp  st1,st0     ; st0=x=a*(r*sin(wa)+sin(b))  st1=y  st2=z
ret


spiral:
   fild  word [esi+2] ; st0=bet
   fmul  [const_m]    ; st0=bet*mbet
   fild  word [esi]   ; st0=alf  st1=bet*mbet
   fmul  [const_mpi]  ; st0=a=pi*alf*malf  st1=bet*mbet
   fsincos            ; st0=cos(a)  st1=sin(a)  st2=bet*mbet
   fimul [spiral_r]   ; st0=r*cos(a)  st1=sin(a)  st2=bet*mbet
   fld   st2          ; st0=bet*mbet  st1=r*cos(a)  st2=sin(a)  st3=bet*mbet
   fimul [spiral_h]   ; st0=bet*mbet*h  st1=r*cos(a)  st2=sin(a)  st3=bet*mbet
   faddp  st1,st0     ; st0=z=bet*mbet*h+r*cos(a)  st1=sin(a)  st2=bet*mbet
   fstp  st3          ; st0=sin(a)  st1=bet*mbet  st2=z
   fimul [spiral_r]   ; st0=r*sin(a)  st1=bet*mbet  st2=z
   fiadd [spiral_R]   ; st0=r*sin(a)+R  st1=bet*mbet  st2=z
   fxch  st1          ; st0=bet*mbet  st1=r*sin(a)+R  st2=z
   fimul [spiral_L]   ; st0=b=L*bet*mbet  st1=r*sin(a)+R  st2=z
   fsincos            ; st0=cos(b)  st1=sin(b)  st2=r*sin(a)+R  st3=z
   fxch  st2          ; st0=r*sin(a)+R  st1=sin(b)  st2=cos(b)  st3=z
   fmul  st2,st0      ; st0=r*sin(a)+R  st1=sin(b)  st2=(r*sin(a)+R)*cos(b)  s
   fmulp  st1,st0     ; st0=x=(r*sin(a)+R)*sin(b)  st2=y=(r*sin(a)+R)*cos(b)
ret

cube:
   push    edx
   xor     edx,edx
   mov     eax,[Fl]
   div     [const6]
   mov     al,dl
   pop     edx

   fild    [cube_R]   ; st0=R
   bt      ax,0
   jc      cube_l0
                      ; ax=xxxx xxxx  xxxx xxx0b
     fchs             ; st0=-R
   cube_l0:

   fild  word [esi+2] ; st0=bet         st1=R
   fmul  [const_m]    ; st0=bet*mbet    st1=R
   fmul  st0,st1      ; st0=R*bet*mbet  st1=R

   fild  word [esi]   ; st0=alf  st1=R*bet*mbet  st2=R
   fmul  [const_m]    ; st0=alf*malf  st1=R*bet*mbet  st2=R
   fmul   st0,st2     ; st0=R*alf*malf  st1=R*bet*mbet  st2=R

   bt      ax,2
   jc      cube_l1    ; ax=xxxx xxxx  xxxx x10xb
   bt      ax,1
   jc      cube_l2    ; ax=xxxx xxxx  xxxx x01xb
                      ; ax=xxxx xxxx  xxxx x00xb
     fstp  st3
   cube_l1:
     fstp  st3
   cube_l2:
ret


planet:
   mov  eax,[Fl]
   test ax,03h
   jz   planet_lb1

   test ax,01h
   jz   planet_lb0
     fild    word [esi] ; st0=alf
     fmul   [const_mpi] ; st0=a=pi*alf*malf
     fsincos            ; st0=cos(a)  st1=sin(a)
     fild    [planet_R] ; st0=R  st1=cos(a)  st2=sin(a)
     fmul   st2,st0     ; st0=R  st1=cos(a)  st2=R*sin(a)
     fmulp  st1,st0     ; st0=R*cos(a)  st2=R*sin(a)
     fild  word [esi+2] ; st0=bet  st1=R*cos(a)  st2=R*sin(a)
     fmul  [const_mpi]  ; st0=b=pi*bet*mbet  st1=R*cos(a)  st2=R*sin(a)
     fsincos            ; st0=cos(b)  st1=sin(b)  st2=R*cos(a)  st3=R*sin(a)
     fxch    st2        ; st0=R*cos(a)  st1=sin(b)  st2=cos(b)  st3=R*sin(a)
     fmul st2,st0       ; st0=R*cos(a)  st1=sin(b)  st2=R*cos(a)*cos(b)  st3=R
     fmulp  st1,st0     ; st0=R*cos(a)*sin(b)  st1=R*cos(a)*cos(b)  st2=R*sin(
   ret
   planet_lb0:
     fild    word [esi] ; st0=alf
     fmul   [const_mpi] ; st0=a=pi*alf*malf
     fsincos            ; st0=cos(a)  st1=sin(a)
     fild    [planet_r] ; st0=R  st1=cos(a)  st2=sin(a)
     fmul   st2,st0     ; st0=R  st1=cos(a)  st2=R*sin(a)
     fmulp  st1,st0     ; st0=R*cos(a)  st2=R*sin(a)
     fild  word [esi+2] ; st0=bet  st1=R*cos(a)  st2=R*sin(a)
     fmul  [const_mpi]  ; st0=b=pi*bet*mbet  st1=R*cos(a)  st2=R*sin(a)
     fsincos            ; st0=cos(b)  st1=sin(b)  st2=R*cos(a)  st3=R*sin(a)
     fxch    st2        ; st0=R*cos(a)  st1=sin(b)  st2=cos(b)  st3=R*sin(a)
     fmul   st2,st0     ; st0=R*cos(a)  st1=sin(b)  st2=R*cos(a)*cos(b)  st3=R
     fmulp  st1,st0     ; st0=R*cos(a)*sin(b)  st1=R*cos(a)*cos(b)  st2=R*sin(
     fiadd   [planet_h] ; st0=R*cos(a)*sin(b)+h  st1=R*cos(a)*cos(b)  st2=R*si
     fxch   st1         ; st0=R*cos(a)*cos(b)  st1=R*cos(a)*sin(b)+h  st2=R*si
   ret
   planet_lb1:
     fild  word [esi+2] ; st0=bet
     fmul    [const_m]  ; st0=bet*mbet
     fimul   [planet_d] ; st0=d*bet*mbet
     fiadd   [planet_h] ; st0=h+d*bet*mbet
     fild    word [esi] ; st0=alf  st1=h+d*bet*mbet
     fmul  [const_mpi]  ; st0=a=pi*alf*malf  st1=h+d*bet*mbet
     fsincos            ; st0=cos(a)  st1=sin(a)  st2=h+d*bet*mbet
     fxch    st2        ; st0=h+d*bet*mbet  st1=sin(a)  st2=cos(a)
     fmul   st2,st0     ; st0=h+d*bet*mbet  st1=sin(a)  st2=cos(a)*(h+d*bet*mb
     fmulp  st1,st0     ; st0=(h+d*bet*mbet)*sin(a)  st1=cos(a)*(h+d*bet*mbet)
     fldz               ; st0=0  st1=(h+d*bet*mbet)*sin(a)  st2=cos(a)*(h+d*be
ret


galaxy:
   fild    [Fl]
   fidiv   [mFl]        ; st0=f=Fl/mFl
   fild    word [esi+2] ; st0=bet  st1=f
   fmul    [const_mpi]  ; st0=b=pi*bet*mbet  st1=f
   fsincos              ; st0=cos(b)  st1=sin(b)  st2=f
   fild    word [esi]   ; st0=alf  st1=cos(b)  st2=sin(b)  st3=f
   fmul    [const_m]    ; st0=a=alf*malf  st1=cos(b)  st2=sin(b)  st3=f
   fmul    st2,st0      ; st0=a  st1=cos(b)  st2=a*sin(b)  st3=f
   fmulp   st1,st0      ; st0=a*cos(b)       st1=a*sin(b)  st2=f
   fmul    st0,st2      ; st0=f*a*cos(b)     st1=a*sin(b)  st2=f
   fimul   [galaxy_rz]  ; st0=rz*f*a*cos(b)  st1=a*sin(b)  st2=f
   fstp    st3          ; st0=a*sin(b)           st1=f  st2=Z
   fimul   [galaxy_rq]  ; st0=a*rq*sin(b)        st1=f  st2=Z
   fiadd   [galaxy_R]   ; st0=R+a*rq*sin(b)      st1=f  st2=Z
   fxch    st1          ; st0=f  st1=R+rq*a*sin(b)      st2=Z
   fmul    st1,st0      ; st0=f  st1=f*(R+rq*a*sin(b))  st2=Z
   fmul    [galaxy_k]   ; st0=F=k*f  st1=f*(R+rq*a*sin(b))  st2=Z

   bt  [Fl],0
   jc  galaxy_lb
     fldpi
     faddp st1,st0      ; st0=F=F+pi  st1=f*(R+rq*a*sin(b))  st2=Z
   galaxy_lb:

   fsincos           ; st0=cos(F)  st1=sin(F)  st2=f*(R+rq*a*sin(b))  st3=Z
   fxch  st2         ; st0=f*(R+rq*a*sin(b))  st1=sin(F)  st2=cos(F)  st3=Z
   fmul  st2,st0
   fmulp st1,st0     ; st0=cos(F)*f*(R+rq*a*sin(b))  st1=sin(F)*f*(R+rq*a*sin(
ret