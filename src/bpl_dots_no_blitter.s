;================================================================================
; function to plot dots on a bitplane
;================================================================================

;---------- Const ----------
; largeur effective (LE) = (DDFSTOP-DDFSTART)*2+16 == 320/8
NB_BPLS   = 2
W         = 320
H         = 256
BPL_SIZE  = W/8                                                                  ; if non IL W/8*H         ; if IL : W/8 
LINE_SIZE = W/8*NB_BPLS                                                          ; if non IL W/8           ; if IL : W/8*NB_BPLS
MODULO    = W/8*NB_BPLS-320/8                                                    ; if non IL : W/8 - LE/8  ; if IL : W/8*NB_BPLS-LE/8


;--------------------------------------------------------------------------------
; main
;--------------------------------------------------------------------------------
run:       
            lea        CUSTOM,a6
            move.w     #$8380,DMACON(a6)                                         ; enable copper + bitplane
            bsr        init_bpls
            bsr        init_copper
            move.l     #copper,COP1LC(a6)                                        ; set new copper
            move.w     #$0,COPJMP1(a6)                                           ; activate copper


main_loop:
            ; move.w     #$01,d1
            ; bsr        wait_raster
            ; move.w     #$400,COLOR00(a6)
            ; bsr        plot_wave
            ; move.w     #$000,COLOR00(a6)
            move.w     #$f8,d1
            bsr        wait_raster
            move.w     #$004,COLOR00(a6)
            bsr        clear_bpls
            move.w     #$400,COLOR00(a6)
            bsr        plot_wave
            move.w     #$000,COLOR00(a6)

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

clear_bpls:
            lea        bpls+201*LINE_SIZE,a0
            ; we are going to set the values 12 at a time (d1-d7/a1-a5)
            move.w     #201*LINE_SIZE/(4*12)-1,d0
            move.l     #$0,a1
            move.l     #$0,a2
            move.l     #$0,a3
            move.l     #$0,a4
            move.l     #$0,a5
            move.l     #$0,d1
            move.l     #$0,d2
            move.l     #$0,d3
            move.l     #$0,d4
            move.l     #$0,d5
            move.l     #$0,d6
            move.l     #$0,d7
.clear:
            movem.l    d1-d7/a1-a5,-(a0)
            dbf        d0,.clear
            rts

plot_wave:
            ; draw sin wave by plotting dots
            lea        bpls,a0
            lea        sin1,a1
            move.w     pos_sin1_x,d3                                             ; x idx
            move.w     pos_sin1_y,d4                                             ; x idx
            add.w      #2,d3                                                     ; vx
            add.w      #4,d4                                                     ; vy
            and.w      #(NB_SIN1*2)-1,d3
            and.w      #(NB_SIN1*2)-1,d4
            move.w     d3,pos_sin1_x
            move.w     d4,pos_sin1_y
            move       #1,d2                                                     ; set color

            move.w     #64-1,d7                                                  ; nb dots
.loop1:
            move.w     (a1,d3),d0                                                ; set x coordinate
            move.w     (a1,d4),d1                                                ; set y coordinate
            bsr        plot_dot
            add        #1,d2
            cmp        #4,d2
            bne.b      .skip_reset
            move       #1,d2
.skip_reset:
            add.w      #2,d3                                                     ; step x
            add.w      #4,d4                                                     ; step y
            and.w      #(NB_SIN1*2)-1,d3
            and.w      #(NB_SIN1*2)-1,d4
            dbf        d7,.loop1
            rts

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
pos_sin1_x:   
            dc.w       0
pos_sin1_y:   
            dc.w       NB_SIN1*2/4

sin1:
;@generated-datagen-start----------------
; This code was generated by Amiga Assembly extension
;
;----- parameters : modify ------
;expression(x as variable): round(cos(x*2*pi/256)*100)+100
;variable:
;   name:x
;   startValue:0
;   endValue:255
;   step:1
;outputType(B,W,L): W
;outputInHex: true
;valuesPerLine: 8
;--------------------------------
;- DO NOT MODIFY following lines -
            dc.w       $00c8, $00c8, $00c8, $00c8, $00c8, $00c7, $00c7, $00c7
            dc.w       $00c6, $00c6, $00c5, $00c4, $00c4, $00c3, $00c2, $00c1
            dc.w       $00c0, $00bf, $00be, $00bd, $00bc, $00bb, $00ba, $00b8
            dc.w       $00b7, $00b6, $00b4, $00b3, $00b1, $00b0, $00ae, $00ac
            dc.w       $00ab, $00a9, $00a7, $00a5, $00a3, $00a2, $00a0, $009e
            dc.w       $009c, $0099, $0097, $0095, $0093, $0091, $008f, $008d
            dc.w       $008a, $0088, $0086, $0083, $0081, $007f, $007c, $007a
            dc.w       $0078, $0075, $0073, $0070, $006e, $006b, $0069, $0066
            dc.w       $0064, $0062, $005f, $005d, $005a, $0058, $0055, $0053
            dc.w       $0050, $004e, $004c, $0049, $0047, $0045, $0042, $0040
            dc.w       $003e, $003b, $0039, $0037, $0035, $0033, $0031, $002f
            dc.w       $002c, $002a, $0028, $0026, $0025, $0023, $0021, $001f
            dc.w       $001d, $001c, $001a, $0018, $0017, $0015, $0014, $0012
            dc.w       $0011, $0010, $000e, $000d, $000c, $000b, $000a, $0009
            dc.w       $0008, $0007, $0006, $0005, $0004, $0004, $0003, $0002
            dc.w       $0002, $0001, $0001, $0001, $0000, $0000, $0000, $0000
            dc.w       $0000, $0000, $0000, $0000, $0000, $0001, $0001, $0001
            dc.w       $0002, $0002, $0003, $0004, $0004, $0005, $0006, $0007
            dc.w       $0008, $0009, $000a, $000b, $000c, $000d, $000e, $0010
            dc.w       $0011, $0012, $0014, $0015, $0017, $0018, $001a, $001c
            dc.w       $001d, $001f, $0021, $0023, $0025, $0026, $0028, $002a
            dc.w       $002c, $002f, $0031, $0033, $0035, $0037, $0039, $003b
            dc.w       $003e, $0040, $0042, $0045, $0047, $0049, $004c, $004e
            dc.w       $0050, $0053, $0055, $0058, $005a, $005d, $005f, $0062
            dc.w       $0064, $0066, $0069, $006b, $006e, $0070, $0073, $0075
            dc.w       $0078, $007a, $007c, $007f, $0081, $0083, $0086, $0088
            dc.w       $008a, $008d, $008f, $0091, $0093, $0095, $0097, $0099
            dc.w       $009c, $009e, $00a0, $00a2, $00a3, $00a5, $00a7, $00a9
            dc.w       $00ab, $00ac, $00ae, $00b0, $00b1, $00b3, $00b4, $00b6
            dc.w       $00b7, $00b8, $00ba, $00bb, $00bc, $00bd, $00be, $00bf
            dc.w       $00c0, $00c1, $00c2, $00c3, $00c4, $00c4, $00c5, $00c6
            dc.w       $00c6, $00c7, $00c7, $00c7, $00c8, $00c8, $00c8, $00c8
;@generated-datagen-end----------------

NB_SIN1   = (*-sin1)/2

;--------------------------------------------------------------------------------
; copper
;--------------------------------------------------------------------------------
            section    data, data_c

            even
copper:      
            dc.w       $1FC,0                                                    ; compat. AGA
            dc.w       BPLCON0, NB_BPLS<<12+$0200                                ; 2 bitplaces
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

            dc.w       $ffdf, $fffe                                              ; Wait for vpos >= 0xff and hpos >= 0xde
            ; bottom of the screen
            dc.w       $3201, $fffe, $180, $f00                                  ; Wait for vpos >= 0x2c
            dc.w       $ffff, $fffe


;--------------------------------------------------------------------------------
; bitplanes
; use bss when you want to initialize the bitplanes to zero at runtime rather than storing them in the data section 
;--------------------------------------------------------------------------------
            section    bss, bss_c
bpls:
            ds.b       W/8*H*NB_BPLS