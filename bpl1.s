;------------------------------
; simple display of bitplanes
;---------- Includes ----------
            INCDIR     "include"
            INCLUDE    "hw.i"
            INCLUDE    "funcdef.i"
            INCLUDE    "exec/exec_lib.i"
            INCLUDE    "graphics/graphics_lib.i"
            INCLUDE    "hardware/cia.i"
;---------- Const ----------
NB_BPLS = 2
W       = 320
WB      = W/8
H       = 256


;--------------------------------------------------------------------------------
; main
;--------------------------------------------------------------------------------
main:       
            movem.l    d0-a6,-(sp)
            move.l     4.w,a6                          ; execbase
            ; clr.l      d0
            ; move.l     #gfxname,a6
            ; jsr        -408(a6)
            ; move.l     d0,a1
            ; move.l     38(a1),copper_save                                ; save current copper
            ; jsr        -414(a6)
            move.l     156(a6),a6
            move.l     38(a6),copper_save              ; save current copper

            lea        CUSTOM,a6
            bsr        wait_VBL

            move.w     DMACONR(a6),dma_save            ; save current DMA
            move.w     #$7fff,DMACON(a6)               ; reset DMA
            move.w     #$8380,DMACON(a6)               ; enable copper + bitplane
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
exit:
            lea        CUSTOM,a6
            bsr        wait_VBL
            move.l     copper_save,COP1LC(a6)          ; restore previous copper list
            move.l     #$0,COPJMP1(a6)                 ; activate copper
            move.w     #$7fff,DMACON(a6)               ; reset DMA
            or.w       #$8200,dma_save                 ; re-enable DMA with copper bit set
            move.w     dma_save,DMACON(a6)             ; restore DMA control register state
            movem.l    (sp)+,d0-a6
            clr        d0                              ; Return code of the program
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
            dbra       d2,.init_copper_bpl

            move.b     #$f1,bpls
            move.b     #$8f,bpls+WB-1
            move.b     #$f1,bpls+WB*(H-1)
            move.b     #$8f,bpls+WB-1+WB*(H-1)
            rts

;--------------------------------------------------------------------------------
; misc
;--------------------------------------------------------------------------------

; check if we reach line
; param: line: d1.w
wait_raster: 
            move.l     VPOSR(a6),d0
            lsr.l      #8,d0
            and.w      #$1ff,d0
            cmp.w      d1,d0
            bne.b      wait_raster
            rts
wait_VBL:
            move.l     VPOSR(a6),d0
            lsr.l      #8,d0
            and.w      #$1FF,d0	
            cmp.w      #$138,d0
            bne        wait_VBL
            rts

;--------------------------------------------------------------------------------
; DATA
;--------------------------------------------------------------------------------

            even
var_tab__:  dc.w       0
gfxname: 
            dc.b       'graphics.library',0
            even
copper_save:
            dc.l       0
dma_save:
            dc.w       0

;--------------------------------------------------------------------------------
; COPPER
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