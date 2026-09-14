
;---------- Includes ----------
            INCDIR     "include"
            INCLUDE    "hw.i"
            INCLUDE    "funcdef.i"
            INCLUDE    "exec/exec_lib.i"
            INCLUDE    "graphics/graphics_lib.i"
            INCLUDE    "hardware/cia.i"

;--------------------------------------------------------------------------------
; main
;--------------------------------------------------------------------------------
in_:       
            ; movem.l    d0-a6,-(sp)
            move.l     4.w,a6                       ; execbase
            ; clr.l      d0
            ; move.l     #gfxname,a6
            ; jsr        -408(a6)
            ; move.l     d0,a1
            ; move.l     38(a1),copper_save                                ; save current copper
            ; jsr        -414(a6)
            move.l     156(a6),a6
            move.l     38(a6),copper_save           ; save current copper

            lea        CUSTOM,a6
            bsr        wait_VBL

            move.w     DMACONR(a6),dma_save         ; save current DMA
            move.w     #$7fff,DMACON(a6)            ; reset DMA
            move.w     #$8380,DMACON(a6)            ; enable copper + bitplane
            rts

out_:
            lea        CUSTOM,a6
            bsr        wait_VBL
            move.l     copper_save,COP1LC(a6)       ; restore previous copper list
            move.l     #$0,COPJMP1(a6)              ; activate copper
            move.w     #$7fff,DMACON(a6)            ; reset DMA
            or.w       #$8200,dma_save              ; re-enable DMA with copper bit set
            move.w     dma_save,DMACON(a6)          ; restore DMA control register state
            ; movem.l    (sp)+,d0-a6
            clr        d0                           ; Return code of the program
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
_var_tab_:  dc.w       0
gfxname: 
            dc.b       'graphics.library',0
            even
copper_save:
            dc.l       0
dma_save:
            dc.w       0
