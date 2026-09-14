;--------------------------------------------------------------------------------
; includes
;--------------------------------------------------------------------------------

            INCDIR     "include"
            INCLUDE    "hw.i"
            INCLUDE    "funcdef.i"
            INCLUDE    "exec/exec_lib.i"
            INCLUDE    "graphics/graphics_lib.i"
            INCLUDE    "hardware/cia.i"

;--------------------------------------------------------------------------------
; main
;--------------------------------------------------------------------------------
            movem.l    d0-a6,-(sp)
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
            move.w     DMACONR(a6),dma_save         ; save current DMA
            move.w     INTENAR(a6),interna_save     ; save current interruptions

            bsr        wait_VBL
            move.w     #$7fff,DMACON(a6)            ; reset DMA
            move.w     #$7fff,INTENA(a6)            ; reset interruptions
            move.w     #$7fff,INTREQ(a6)

            jsr        run

            lea        CUSTOM,a6
            bsr        wait_VBL
            move.l     copper_save,COP1LC(a6)       ; restore previous copper list

            or.w       #$8200,dma_save              ; re-enable DMA with copper bit set
            move.w     #$7fff,DMACON(a6)            ; reset DMA
            move.w     dma_save,DMACON(a6)          ; restore DMA control register state

            or.w       #$C000,interna_save
            move.w     #$7fff,INTENA(a6)            ; reset interruptions
            move.w     interna_save,INTENA(a6)      ; restore interruptions

            movem.l    (sp)+,d0-a6
            clr        d0                           ; Return code of the program
            rts

;--------------------------------------------------------------------------------
; misc
;--------------------------------------------------------------------------------

; check if we reach line
; param: line: d1.w
wait_raster: 
            move.l     d0,-(sp)
.wait_raster: 
            move.l     CUSTOM+VPOSR,d0
            lsr.l      #8,d0
            and.w      #$1ff,d0
            cmp.w      d1,d0
            bne.b      .wait_raster
            move.l     (sp)+,d0
            rts
wait_VBL:
            move.l     d0,-(sp)
.wait_VBL:
            move.l     CUSTOM+VPOSR,d0
            lsr.l      #8,d0
            and.w      #$1FF,d0	
            cmp.w      #$138,d0
            bne        .wait_VBL
            move.l     (sp)+,d0
            rts

;--------------------------------------------------------------------------------
; data
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
interna_save:
            dc.w       0
