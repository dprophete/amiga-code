;================================================================================
; showing raw image of king tut
; + reflexion
;================================================================================

;---------- Const ----------
; largeur effective = (DDFSTOP-DDFSTART)*2+16 == 320/8
NB_BPLS   = 5
W         = 336
H         = 256
BPL_SIZE  = W/8                                                           ; if non IL W/8*H         ; if IL : W/8 
LINE_SIZE = W/8*NB_BPLS                                                   ; if non IL W/8           ; if IL : W/8*NB_BPLS
MODULO    = W/8*NB_BPLS-320/8                                             ; if non IL : W/8 - LE/8  ; if IL : W/8*NB_BPLS-LE/8


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
            dc.w       BPLCON0, NB_BPLS<<12 + $0200                       ; 2 bitplaces
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
            dc.w       $0180,$0000,$0182,$0558,$0184,$0001,$0186,$0011
            dc.w       $0188,$0012,$018a,$0023,$018c,$0233,$018e,$0003
            dc.w       $0190,$0113,$0192,$0226,$0194,$0337,$0196,$0035
            dc.w       $0198,$0256,$019a,$0110,$019c,$0210,$019e,$0320
            dc.w       $01a0,$0310,$01a2,$0430,$01a4,$0540,$01a6,$0850
            dc.w       $01a8,$0640,$01aa,$0740,$01ac,$0751,$01ae,$0861
            dc.w       $01b0,$0a72,$01b2,$0850,$01b4,$0862,$01b6,$0a71
            dc.w       $01b8,$0d93,$01ba,$0fc5,$01bc,$0530,$01be,$0000

            ; reflection
            dc.w       $f407, $fffe, $180, $220
            dc.w       BPL1MOD,-LINE_SIZE*3+MODULO
            dc.w       BPL2MOD,-LINE_SIZE*3+MODULO

            dc.w       $ffdf, $fffe                                       ; Wait for vpos >= 0xff and hpos >= 0xde
            ; bottom of the screen
            dc.w       $3201, $fffe, $180, $f00                           ; Wait for vpos >= 0x2c
            dc.w       $ffff, $fffe

bpls:
            incbin     "./raw_files/KingTutbisIL.raw"