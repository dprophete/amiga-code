;================================================================================
; simple display of bitplanes
;================================================================================

;---------- Const ----------
NB_BPLS = 2
W       = 320
WB      = W/8
H       = 256


;--------------------------------------------------------------------------------
; main
;--------------------------------------------------------------------------------
run:       
            lea        CUSTOM,a6
            bsr        init_bpls
            bsr        init_copper
            move.l     #copper,COP1LC(a6)              ; set new copper
            move.w     #$0,COPJMP1(a6)                 ; activate copper

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
            add.l      #WB*H,d0
            dbf        d2,.init_copper_bpl

            move.b     #$f1,bpls
            move.b     #$8f,bpls+WB-1
            move.b     #$f1,bpls+WB*(H-1)
            move.b     #$8f,bpls+WB-1+WB*(H-1)
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
            dc.w       BPLCON0, NB_BPLS<<12 + $0200    ; 2 bitplaces
            dc.w       DIWSTRT, $2c81
            dc.w       DIWSTOP, $2cc1
            dc.w       DDFSTRT, $38
            dc.w       DDFSTOP, $D0
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

            ; default colors
            dc.w       $180, $420
            dc.w       $182, $0f0
            dc.w       $184, $f8f
            dc.w       $186, $00f
            dc.w       $180, $f00
            dc.w       $182, $0f0

            ; top of the screen
            dc.w       $2507, $fffe, $180,$f00
            dc.w       $2607, $fffe, $180,$000

            dc.w       $ffdf, $fffe                    ; Wait for vpos >= 0xff and hpos >= 0xde
            ; bottom of the screen
            dc.w       $3201, $fffe, $180, $f00        ; Wait for vpos >= 0x2c
            dc.w       $ffff, $fffe

bpls:
            dcb.b      WB*H*NB_BPLS,$aa