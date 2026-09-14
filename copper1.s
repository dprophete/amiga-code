;------------------------------
; - copperbars on a sin wave
; - thin 1 line copper bar with multiple colors
;
;---------- Includes ----------
            INCDIR     "include"
            INCLUDE    "hw.i"
            INCLUDE    "funcdef.i"
            INCLUDE    "exec/exec_lib.i"
            INCLUDE    "graphics/graphics_lib.i"
            INCLUDE    "hardware/cia.i"
;---------- Const ----------
TOP_COLOR_LINE        = $50
NB_COLOR_LINES        = 128

;--------------------------------------------------------------------------------
; main
;--------------------------------------------------------------------------------
main:       
            movem.l    d0-a6,-(sp)
            move.l     4.w,a6                                            ; execbase
            ; clr.l      d0
            ; move.l     #gfxname,a6
            ; jsr        -408(a6)
            ; move.l     d0,a1
            ; move.l     38(a1),copper_save                                ; save current copper
            ; jsr        -414(a6)
            move.l     156(a6),a6
            move.l     38(a6),copper_save                                ; save current copper


            lea        CUSTOM,a6
            bsr        wait_VBL

            move.w     DMACONR(a6),dma_save                              ; save current DMA
            move.w     #$7fff,DMACON(a6)                                 ; reset DMA
            move.w     #$8280,DMACON(a6)                                 ; enable copper
            ; bsr        init_bpls
            bsr        init_copper
            move.l     #copper,COP1LC(a6)                                ; set new copper
            move.w     #$0,COPJMP1(a6)                                   ; activate copper

main_loop:
            move.w     #$120,d1
            bsr        wait_raster
            bsr        draw_single_lines
            bsr        draw_bars

            ; bsr        wait_VBL
    		; mouse test
            btst       #6,$bfe001
            bne.b      main_loop
exit:
            lea        CUSTOM,a6
            bsr        wait_VBL
            move.l     copper_save,COP1LC(a6)                            ; restore previous copper list
            move.l     #$0,COPJMP1(a6)                                   ; activate copper
            move.w     #$7fff,DMACON(a6)                                 ; reset DMA
            or.w       #$8200,dma_save                                   ; re-enable DMA with copper bit set
            move.w     dma_save,DMACON(a6)                               ; restore DMA control register state
            movem.l    (sp)+,d0-a6
            clr        d0                                                ; Return code of the program
            rts

;--------------------------------------------------------------------------------
; init
;--------------------------------------------------------------------------------

init_copper:
            move.b     #TOP_COLOR_LINE,d1

            ; line above
            move.b     d1,line_above
            add        #10,d1

			; init color_lines
            lea        color_lines,a0
            move.w     #NB_COLOR_LINES-1,d0
.init_lines:
            move.b     d1,(a0)+
            move.b     #$07,(a0)+
            move.w     #$fffe,(a0)+
            move.w     #$0180,(a0)+
            move.w     #$0110,(a0)+
            add        #1,d1
            dbra       d0,.init_lines
            add        #9,d1

            ; line below
            move.b     d1,line_below
            rts

;--------------------------------------------------------------------------------
; misc
;--------------------------------------------------------------------------------

draw_single_lines:
            ; line above
            add.w      #2,(pos_line_above)
            cmp.w      #NB_COLORS_SINGLE_LINE*2,(pos_line_above)
            bne        .no_above
            move.w     #0,(pos_line_above)
.no_above:
            move.w     (pos_line_above),d0
            lea        line_above+6,a0
            bsr        draw_single_line

            ; line below
            cmp.w      #0,(pos_line_below)
            bne        .no_below
            move.w     #NB_COLORS_SINGLE_LINE*2,(pos_line_below)
.no_below:
            sub.w      #2,(pos_line_below)
            move.w     (pos_line_below),d0
            lea        line_below+6,a0
            bsr        draw_single_line


            lea        line_below+6,a0
            move.w     (pos_line_below),d0
            bsr        draw_single_line
            rts

; draw single line
; params: a0: copper pos, d0: color offset
draw_single_line:
            lea        colors_single_line,a1
            moveq      #43-1,d3
.loop
            move.w     (a1,d0),(a0)
            add.l      #4,a0
            add.l      #2,d0
            cmp.w      #NB_COLORS_SINGLE_LINE*2,d0
            bne        .no
            moveq      #0,d0
.no
            dbra       d3,.loop
            rts

draw_bars:
			; reset all the colors to 0
            move.w     #NB_COLOR_LINES-1,d0                              ; skip first + last 2
            lea        color_lines+6,a0                                  ; skip first upper line
.reset_lines:
            move.w     #$000,(a0)
            add        #8,a0
            dbra       d0,.reset_lines

    		; update vertical position and increment
            addq.w     #3,(pos_bar0)
            and.w      #NB_SIN1-1,(pos_bar0)
            move.w     (pos_bar0),d0                                     ; d0 = pos in sin table

            lea        colors,a3
            moveq      #NB_BARS-1,d4
.draw:
            move.l     (a3)+,a1
            add.w      #30,d0
            bsr        draw_bar
            dbra       d4,.draw
            rts

; params: 
; a1 = colors
; d0 = pos in sin table
draw_bar:
            lea        sin1,a0                                           ; a0 = address of sin1 table
            and.w      #NB_SIN1-1,d0
            moveq      #0,d1                                             ; d1 = y pos
            move.b     (a0,d0),d1
            lsl.w      #3,d1                                             ; *8 since 8 bytes per lines in copper
            lea        color_lines+6,a2                                  ; a2 = color lines
            add.l      d1,a2

            moveq      #COLORS_PER_BAR-1,d1
.bar:
            move.w     (a1)+,(a2)
            addq       #8,a2
            dbra       d1,.bar
            rts


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
pos_bar0:
            dc.w       0
pos_line_above:
            dc.w       0
pos_line_below:
            dc.w       0

sin1:
; height = (NB_COLOR_LINES - COLORS_PER_BAR)/2
;@generated-datagen-start----------------
; This code was generated by Amiga Assembly extension
;
;----- parameters : modify ------
;expression(x as variable): round(cos(x*2*pi/512-pi)*51)+51
;variable:
;   name:x
;   startValue:0
;   endValue:511
;   step:1
;outputType(B,W,L): B
;outputInHex: true
;valuesPerLine: 8
;--------------------------------
;- DO NOT MODIFY following lines -
            dc.b       $00, $00, $00, $00, $00, $00, $00, $00
            dc.b       $00, $00, $00, $00, $01, $01, $01, $01
            dc.b       $01, $01, $01, $01, $02, $02, $02, $02
            dc.b       $02, $02, $03, $03, $03, $03, $03, $04
            dc.b       $04, $04, $04, $05, $05, $05, $05, $06
            dc.b       $06, $06, $07, $07, $07, $08, $08, $08
            dc.b       $09, $09, $09, $0a, $0a, $0a, $0b, $0b
            dc.b       $0c, $0c, $0c, $0d, $0d, $0e, $0e, $0e
            dc.b       $0f, $0f, $10, $10, $11, $11, $12, $12
            dc.b       $13, $13, $14, $14, $15, $15, $16, $16
            dc.b       $17, $17, $18, $18, $19, $19, $1a, $1a
            dc.b       $1b, $1c, $1c, $1d, $1d, $1e, $1e, $1f
            dc.b       $1f, $20, $21, $21, $22, $22, $23, $24
            dc.b       $24, $25, $25, $26, $27, $27, $28, $28
            dc.b       $29, $2a, $2a, $2b, $2c, $2c, $2d, $2d
            dc.b       $2e, $2f, $2f, $30, $30, $31, $32, $32
            dc.b       $33, $34, $34, $35, $36, $36, $37, $37
            dc.b       $38, $39, $39, $3a, $3a, $3b, $3c, $3c
            dc.b       $3d, $3e, $3e, $3f, $3f, $40, $41, $41
            dc.b       $42, $42, $43, $44, $44, $45, $45, $46
            dc.b       $47, $47, $48, $48, $49, $49, $4a, $4a
            dc.b       $4b, $4c, $4c, $4d, $4d, $4e, $4e, $4f
            dc.b       $4f, $50, $50, $51, $51, $52, $52, $53
            dc.b       $53, $54, $54, $55, $55, $56, $56, $57
            dc.b       $57, $58, $58, $58, $59, $59, $5a, $5a
            dc.b       $5a, $5b, $5b, $5c, $5c, $5c, $5d, $5d
            dc.b       $5d, $5e, $5e, $5e, $5f, $5f, $5f, $60
            dc.b       $60, $60, $61, $61, $61, $61, $62, $62
            dc.b       $62, $62, $63, $63, $63, $63, $63, $64
            dc.b       $64, $64, $64, $64, $64, $65, $65, $65
            dc.b       $65, $65, $65, $65, $65, $66, $66, $66
            dc.b       $66, $66, $66, $66, $66, $66, $66, $66
            dc.b       $66, $66, $66, $66, $66, $66, $66, $66
            dc.b       $66, $66, $66, $66, $65, $65, $65, $65
            dc.b       $65, $65, $65, $65, $64, $64, $64, $64
            dc.b       $64, $64, $63, $63, $63, $63, $63, $62
            dc.b       $62, $62, $62, $61, $61, $61, $61, $60
            dc.b       $60, $60, $5f, $5f, $5f, $5e, $5e, $5e
            dc.b       $5d, $5d, $5d, $5c, $5c, $5c, $5b, $5b
            dc.b       $5a, $5a, $5a, $59, $59, $58, $58, $58
            dc.b       $57, $57, $56, $56, $55, $55, $54, $54
            dc.b       $53, $53, $52, $52, $51, $51, $50, $50
            dc.b       $4f, $4f, $4e, $4e, $4d, $4d, $4c, $4c
            dc.b       $4b, $4a, $4a, $49, $49, $48, $48, $47
            dc.b       $47, $46, $45, $45, $44, $44, $43, $42
            dc.b       $42, $41, $41, $40, $3f, $3f, $3e, $3e
            dc.b       $3d, $3c, $3c, $3b, $3a, $3a, $39, $39
            dc.b       $38, $37, $37, $36, $36, $35, $34, $34
            dc.b       $33, $32, $32, $31, $30, $30, $2f, $2f
            dc.b       $2e, $2d, $2d, $2c, $2c, $2b, $2a, $2a
            dc.b       $29, $28, $28, $27, $27, $26, $25, $25
            dc.b       $24, $24, $23, $22, $22, $21, $21, $20
            dc.b       $1f, $1f, $1e, $1e, $1d, $1d, $1c, $1c
            dc.b       $1b, $1a, $1a, $19, $19, $18, $18, $17
            dc.b       $17, $16, $16, $15, $15, $14, $14, $13
            dc.b       $13, $12, $12, $11, $11, $10, $10, $0f
            dc.b       $0f, $0e, $0e, $0e, $0d, $0d, $0c, $0c
            dc.b       $0c, $0b, $0b, $0a, $0a, $0a, $09, $09
            dc.b       $09, $08, $08, $08, $07, $07, $07, $06
            dc.b       $06, $06, $05, $05, $05, $05, $04, $04
            dc.b       $04, $04, $03, $03, $03, $03, $03, $02
            dc.b       $02, $02, $02, $02, $02, $01, $01, $01
            dc.b       $01, $01, $01, $01, $01, $00, $00, $00
            dc.b       $00, $00, $00, $00, $00, $00, $00, $00
;@generated-datagen-end----------------
NB_SIN1               = *-sin1

sin2:
;@generated-datagen-start----------------
; This code was generated by Amiga Assembly extension
;
;----- parameters : modify ------
;expression(x as variable): round(cos(x*2*pi/64-pi)*20)+20
;variable:
;   name:x
;   startValue:0
;   endValue:31
;   step:1
;outputType(B,W,L): B
;outputInHex: true
;valuesPerLine: 8
;--------------------------------
;- DO NOT MODIFY following lines -
            dc.b       $00, $00, $00, $01, $02, $02, $03, $05
            dc.b       $06, $07, $09, $0b, $0c, $0e, $10, $12
            dc.b       $14, $16, $18, $1a, $1c, $1d, $1f, $21
            dc.b       $22, $23, $25, $26, $26, $27, $28, $28
;@generated-datagen-end----------------
NB_SIN2               = *-sin2

            even

colors_single_line:
            ;#f00 -> $f0f
            dc.w       $f00, $f01, $f02, $f03, $f04, $f05, $f06, $f07
            dc.w       $f08, $f09, $f0a, $f0b, $f0c, $f0d, $f0e, $f0f
            ;#f0f -> $00f
            dc.w       $f0f, $e0f, $d0f, $c0f, $b0f, $a0f, $90f, $80f
            dc.w       $70f, $60f, $50f, $40f, $30f, $20f, $10f, $00f
            ;#00f -> $0ff
            dc.w       $00f, $01f, $02f, $03f, $04f, $05f, $06f, $07f
            dc.w       $08f, $09f, $0af, $0bf, $0cf, $0df, $0ef, $0ff
            ;#0ff -> $0f0
            dc.w       $0ff, $0fe, $0fd, $0fc, $0fb, $0fa, $0f9, $0f8
            dc.w       $0f7, $0f6, $0f5, $0f4, $0f3, $0f2, $0f1, $0f0
            ;#0f0 -> $ff0
            dc.w       $0f0, $1f0, $2f0, $3f0, $4f0, $5f0, $6f0, $7f0
            dc.w       $8f0, $9f0, $af0, $bf0, $cf0, $df0, $ef0, $ff0
            ;#ff0 -> $f00
            dc.w       $ff0, $fe0, $fd0, $fc0, $fb0, $fa0, $f90, $f80
            dc.w       $f70, $f60, $f50, $f40, $f30, $f20, $f10, $f00
NB_COLORS_SINGLE_LINE = (*-colors_single_line)/2

color1:
            dc.w       $311, $411, $522, $622, $733, $833, $944, $a44
            dc.w       $b55, $c55, $d66, $e66, $f77, $e66, $d66, $c55
            dc.w       $b55, $a44, $944, $833, $733, $622, $522, $411
            dc.w       $311
COLORS_PER_BAR        = (*-color1)/2
                                                                
color1a:
            dc.w       $301, $401, $502, $602, $703, $803, $904, $a04
            dc.w       $b05, $c05, $d06, $e06, $f07, $e06, $d06, $c05
            dc.w       $b05, $a04, $904, $803, $703, $602, $502, $401
            dc.w       $301
                                                                
color1b:
            dc.w       $310, $410, $520, $620, $730, $830, $940, $a40
            dc.w       $b50, $c50, $d60, $e60, $f70, $e60, $d60, $c50
            dc.w       $b50, $a40, $940, $830, $730, $620, $520, $410
            dc.w       $310
                                                                
color1c:
            dc.w       $300, $400, $500, $600, $700, $800, $900, $a00
            dc.w       $b00, $c00, $d00, $e00, $f00, $e00, $d00, $c00
            dc.w       $b00, $a00, $900, $800, $700, $600, $500, $400
            dc.w       $300
                                                                
color2:                                                         
            dc.w       $131, $141, $252, $262, $373, $383, $494, $4a4
            dc.w       $5b5, $5c5, $6d6, $6e6, $7f7, $6e6, $6d6, $5c5
            dc.w       $5b5, $4a4, $494, $383, $373, $262, $252, $141 
            dc.w       $131
color2a:                                                         
            dc.w       $031, $041, $052, $062, $073, $083, $094, $0a4
            dc.w       $0b5, $0c5, $0d6, $0e6, $0f7, $0e6, $0d6, $0c5
            dc.w       $0b5, $0a4, $094, $083, $073, $062, $052, $041 
            dc.w       $031
                                                                
color2b:                                                         
            dc.w       $130, $140, $250, $260, $370, $380, $490, $4a0
            dc.w       $5b0, $5c0, $6d0, $6e0, $7f0, $6e0, $6d0, $5c0
            dc.w       $5b0, $4a0, $490, $380, $370, $260, $250, $140 
            dc.w       $131
color2c:                                                         
            dc.w       $030, $040, $050, $060, $070, $080, $090, $0a0
            dc.w       $0b0, $0c0, $0d0, $0e0, $0f0, $0e0, $0d0, $0c0
            dc.w       $0b0, $0a0, $090, $080, $070, $060, $050, $040 
            dc.w       $030
                                                                
color3:
            dc.w       $113, $114, $225, $226, $337, $338, $449, $44a
            dc.w       $55b, $55c, $66d, $66e, $77f, $66e, $66d, $55c
            dc.w       $55b, $44a, $449, $338, $337, $226, $225, $114
            dc.w       $113                                         
                                                                    
color3a:                                                            
            dc.w       $013, $014, $025, $026, $037, $038, $049, $04a
            dc.w       $05b, $05c, $06d, $06e, $07f, $06e, $06d, $05c
            dc.w       $05b, $04a, $049, $038, $037, $026, $025, $014
            dc.w       $013                                         
                                                                    
color3b:                                                            
            dc.w       $103, $104, $205, $206, $307, $308, $409, $40a
            dc.w       $50b, $50c, $60d, $60e, $70f, $60e, $60d, $50c
            dc.w       $50b, $40a, $409, $308, $307, $206, $205, $104
            dc.w       $103
color3c:
            dc.w       $003, $004, $005, $006, $007, $008, $009, $00a
            dc.w       $00b, $00c, $00d, $00e, $00f, $00e, $00d, $00c
            dc.w       $00b, $00a, $009, $008, $007, $006, $005, $004
            dc.w       $003                                         

colors:
            dc.l       color1
            dc.l       color1a
            dc.l       color1b
            dc.l       color2
            dc.l       color2a
            dc.l       color2b
            dc.l       color3
            dc.l       color3a
            dc.l       color3b
            dc.l       color3c
NB_BARS               = (*-colors)/4

;--------------------------------------------------------------------------------
; COPPER
;--------------------------------------------------------------------------------
            section    data, data_c

            even
copper:      
            dc.w       BPLCON0, $1200                                    ; 2 bitplaces
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
line_above:
            dc.w       $0039, $fffe
            dcb.l      44, $01800ff0                                     ; the gradient
            dc.l       $01800000                                         ; back to black
color_lines:
            dcb.w      4*NB_COLOR_LINES                                  ; 1 wait + 1 color set
line_below:
            dc.w       $0039, $fffe
            dcb.l      44, $01800ff0                                     ; the gradient
            dc.l       $01800000                                         ; back to black

            dc.w       $ffdf, $fffe                                      ; Wait for vpos >= 0xff and hpos >= 0xde
            ; bottom of the screen
            dc.w       $3201, $fffe, $180, $f00                          ; Wait for vpos >= 0x2c
            dc.w       $ffff, $fffe