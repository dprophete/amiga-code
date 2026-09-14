;================================================================================
; showing raw image of king tut
; + reflexion
;================================================================================

;---------- Const ----------
; largeur effective = (DDFSTOP-DDFSTART)*2+16 == 320/8
NB_BPLS   = 2
W         = 320                                                           ; -> will require modulo
H         = 256
; if non IL W/8*H         ; if IL :   W/8 
BPL_SIZE  = W/8

; if non IL W/8           ; if IL : W/8*NB_BPLS
LINE_SIZE = W/8*NB_BPLS                                                   

; if non IL : largeur ligne memoire - largeur effective
; if IL : W/8*NB_BPLS-largeur effective
MODULO    = W/8*NB_BPLS-320/8                                                


;--------------------------------------------------------------------------------
; main
;--------------------------------------------------------------------------------
run:       
            lea        CUSTOM,a6
            move.w     #$8380,DMACON(a6)                                  ; enable copper + bitplane
            bsr        init_bpls
            bsr        init_copper
            move.l     #copper,COP1LC(a6)                                 ; set new copper
            move.w     #$0,COPJMP1(a6)                                    ; activate copper

            move.b     #$f1,bpls
            move.b     #$8f,bpls+W/8-1
            ; move.b     #$f1,bpls+W/8*(H-1)
            ; move.b     #$8f,bpls+W/8-1+W/8*(H-1)
main_loop:
            move.w     #$120,d1
            bsr        wait_raster

            ; bsr        wait_VBL
    		; mouse test
            btst       #6,$bfe001
            bne.b      main_loop
            rts

;--------------------------------------------------------------------------------
; init
;--------------------------------------------------------------------------------

init_copper:
            rts

init_bpls:
            move.l     #bpls,d0
            lea        copper_bpls,a0
            moveq      #NB_BPLS-1,d2
.init_copper_bpl:
            move.w     d0,6(a0)
            swap       d0
            move.w     d0,2(a0)
            swap       d0
            add.l      #8,a0
            add.l      #BPL_SIZE,d0
            dbf        d2,.init_copper_bpl
            rts

;--------------------------------------------------------------------------------
; data
;--------------------------------------------------------------------------------

            even
var_tab__:  dc.w       0

;--------------------------------------------------------------------------------
; copper
;--------------------------------------------------------------------------------
            section    data, data_c

            even
copper:      
            dc.w       $1FC,0                                             ; compat. AGA
            dc.w       BPLCON0, NB_BPLS<<12+$0200                         ; 2 bitplaces
            dc.w       DIWSTRT, $2c81
            dc.w       DIWSTOP, $2cc1
            dc.w       DDFSTRT, $38
            dc.w       DDFSTOP, $d0
            dc.w       BPL1MOD, MODULO
            dc.w       BPL2MOD, MODULO

copper_bpls:
            dc.w       BPL1PTH, $0
            dc.w       BPL1PTL, $0
            dc.w       BPL2PTH, $0
            dc.w       BPL2PTL, $0
            dc.w       BPL3PTH, $0
            dc.w       BPL3PTL, $0
            dc.w       BPL4PTH, $0
            dc.w       BPL4PTL, $0
            dc.w       BPL5PTH, $0
            dc.w       BPL5PTL, $0
            dc.w       BPL6PTH, $0
            dc.w       BPL6PTL, $0

            ; top of the screen
            dc.w       $2507, $fffe, $180,$f00
            dc.w       $2607, $fffe, $180,$000

           ; default colors
            dc.w       $0180,$0000,$0182,$0f00,$0184,$00f0,$0186,$0ff0

            dc.w       $ffdf, $fffe                                       ; Wait for vpos >= 0xff and hpos >= 0xde
            ; bottom of the screen
            dc.w       $3201, $fffe, $180, $f00                           ; Wait for vpos >= 0x2c
            dc.w       $ffff, $fffe

            even
bpls:
            dcb.b      W/8*H*NB_BPLS,$00