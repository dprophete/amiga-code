;================================================================================
; function to plot dots on a bitplane
;================================================================================

;---------- Const ----------
; largeur effective (LE) = (DDFSTOP-DDFSTART)*2+16 == 320/8
NB_BPLS   = 2
W         = 320
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
            move.w     #$50,d1
            bsr        wait_raster

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
; misc
;--------------------------------------------------------------------------------

;a0: bpls, d0:x, d1:y, d2: color
plot_dot:
            movem.l    d0-d4/a0,-(a7)
            mulu.w     #LINE_SIZE,d1
            add.w      d1,a0
            move.w     d0,d3
            lsr.w      #3,d0
            add.w      d0,a0
            and.w      #7,d3
            eor.w      #7,d3
            ; need to figure out in which bitplane we want to set the bit
            moveq      #NB_BPLS-1,d4
.plot_in_bpl:
            lsr.b      #1,d2
            bcc        .not_in_bpl
            bset       d3,(a0)
.not_in_bpl:
            add.l      #BPL_SIZE,a0
            dbf        d4,.plot_in_bpl
            movem.l    (a7)+,d0-d4/a0
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


;--------------------------------------------------------------------------------
; bitplanes
; use bss when you want to initialize the bitplanes to zero at runtime rather than storing them in the data section 
;--------------------------------------------------------------------------------

font:  
            incbin     "../raw_files/melonfont.raw"

            section    bss, bss_c
bpls:
            ds.b       W/8*H*NB_BPLS
