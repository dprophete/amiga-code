;================================================================================
; function to plot dots on a bitplane
;================================================================================

;---------- Const ----------
; largeur effective (LE) = (DDFSTOP-DDFSTART)*2+16 == 320/8
NB_BPLS           = 1
W                 = 320
H                 = 256
BPL_SIZE          = W/8                                                  ; if non IL W/8*H         ; if IL : W/8 
LINE_SIZE         = W/8*NB_BPLS                                          ; if non IL W/8           ; if IL : W/8*NB_BPLS
MODULO            = W/8*NB_BPLS-320/8                                    ; if non IL : W/8 - LE/8  ; if IL : W/8*NB_BPLS-LE/8


;--------------------------------------------------------------------------------
; main
;--------------------------------------------------------------------------------
run:       
            lea        CUSTOM,a6
            move.w     #$83c0,DMACON(a6)                                 ; enable copper + bitplane + blitter
            bsr        init_bpls
            bsr        init_copper
            bsr        init_font_offset
            move.l     #copper,COP1LC(a6)                                ; set new copper
            move.w     #$0,COPJMP1(a6)                                   ; activate copper

            bsr        blit_fonts_to_screen
main_loop:
            move.w     #$50,d1
            bsr        wait_raster
            bsr        clear_scroll
            bsr        do_scroll1
            bsr        do_scroll2

    		; mouse test
            btst       #6,$bfe001
            bne.b      main_loop
            rts

;--------------------------------------------------------------------------------
; init
;--------------------------------------------------------------------------------

init_font_offset:
            lea        font_order,a0
            moveq      #0,d0                                             ; ptr to font data
            moveq      #0,d1                                             ; line
            lea        font_offset,a1
            moveq      #NB_FONTS-1,d7
.init_font_offset:
            moveq      #0,d2
            move.b     (a0)+,d2                                          ; char
            lsl        #1,d2
            move.w     d0,(a1,d2.w)
            add.w      #CHAR_W/8,d0
            add.w      #1,d1
            cmp.w      #FONT_W/CHAR_W,d1                                 ; nb fonts/line
            bne        .not_end_of_line
            moveq      #0,d1                                             ; ptr to font data
            add.w      #FONT_W/8*(CHAR_H-1),d0                           ; go to next line
.not_end_of_line:
            dbf        d7,.init_font_offset
            rts

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
; scroll1
;   redraw all chars on the line
;--------------------------------------------------------------------------------

SCROLL1_Y         = 150
do_scroll1:
            ; change do_scroll1 position
            clr.l      d0
            move.w     scroll_x1,d0
            addq       #1,d0
            cmp.w      #SCROLL_SIZE_IN_PX,d0
            bne        .scroll_wrap
            moveq      #0,d0
.scroll_wrap:
            move.w     d0,scroll_x1

CHAR_W_FOR_BLT    = CHAR_W+16                                            ; keep some space at the end
            ; plot char
            bsr        wait_blit
            lea        scroll_txt,a3
            ror.l      #4,d0
            add.w      d0,a3
            swap       d0
            eor.w      #$f000,d0
            or.w       #$09f0,d0
            move.w     d0,BLTCON0(a6)
            move.w     #0,BLTCON1(a6)
            move.w     #$ffff,BLTAFWM(a6)
            move.w     #$0000,BLTALWM(a6)
            move.w     #(W-CHAR_W_FOR_BLT)/8,BLTAMOD(a6)
            move.w     #(W-CHAR_W_FOR_BLT)/8,BLTDMOD(a6)

            lea        bpls+SCROLL1_Y*LINE_SIZE,a1
            lea        font_offset,a2

            moveq      #18,d7                                            ; how many 16-pixel blocks fit in the width
.blit_char:
            moveq      #0,d1
            move.b     (a3)+,d1                                          ; char
            cmp.b      #" ",d1
            beq        .skip_char
            lsl        #1,d1
            move.w     (a2,d1.w),d2                                      ;d2 == offset from #font 
            lea        font,a0
            add.w      d2,a0

            bsr        wait_blit
            move.l     a0,BLTAPTH(a6)
            move.l     a1,BLTDPTH(a6)
            move.w     #CHAR_H*64+CHAR_W_FOR_BLT/16,BLTSIZE(a6)          ;h=16, w=16/16 (1 word)

.skip_char:
            add        #2,a1
            dbf        d7,.blit_char


            ; plot a dot
            ; lea        bpls,a0
            ; move.w     scroll_x1,d0
            ; move.w     #SCROLL1_Y-2,d1
            ; move.w     #1,d2
            ; bsr        plot_dot

;             ; plot char
; BLTW      = 32
;             bsr        wait_blit
;             lea        font,a0
;             lea        bpls+SCROLL1_Y*LINE_SIZE,a1
;             clr.l      d0
;             move.w     scroll_x1,d0
;             ror.l      #4,d0
;             lsl.w      #1,d0
;             add.w      d0,a1
;             swap       d0
;             or.w       #$09f0,d0
;             move.w     d0,BLTCON0(a6)

;             move.w     #0,BLTCON1(a6)
;             move.w     #$ffff,BLTAFWM(a6)
;             move.w     #$0000,BLTALWM(a6)
;             move.w     #(W-BLTW)/8,BLTAMOD(a6)
;             move.w     #(W-BLTW)/8,BLTDMOD(a6)
;             move.l     a0,BLTAPTH(a6)
;             move.l     a1,BLTDPTH(a6)
;             move.w     #16*64+BLTW/16,BLTSIZE(a6)                                ;h=16, w=16/16 (1 word)
            rts

;--------------------------------------------------------------------------------
; scroll 2 (move scroll text by 1px and only insert new one when needed)
;--------------------------------------------------------------------------------

SCROLL2_Y         = 100
do_scroll2:
            ; change do_scroll1 position
            clr.l      d0
            move.w     scroll_x2,d0
            addq       #1,d0
            cmp.w      #SCROLL_SIZE_IN_PX,d0
            bne        .scroll_wrap
            moveq      #0,d0
.scroll_wrap:
            move.w     d0,scroll_x2

            bsr        scroll_by_1px

            lea        scroll_txt,a3
            move.w     scroll_x2,d0
            move.w     d0,d1
            and.w      #$0f,d1
            bne        .not_inserting_char

            ; inserting new char
            lsr.w      #4,d0
            move.b     (a3,d0.w),d1                                      ; char
            lsl.w      #1,d1
            lea        font_offset,a2
            moveq      #0,d2
            move.w     (a2,d1.w),d2                                      ;d2 == offset from #font 
            lea        font,a0
            add.l      d2,a0

            ; blit char
            bsr        wait_blit
            move.w     #$09f0,BLTCON0(a6)
            move.w     #0,BLTCON1(a6)
            move.w     #$ffff,BLTAFWM(a6)
            move.w     #$ffff,BLTALWM(a6)
            move.w     #(W-CHAR_W)/8,BLTAMOD(a6)
            move.w     #(W-CHAR_W)/8,BLTDMOD(a6)
            lea        bpls+SCROLL2_Y*LINE_SIZE+W/8-2,a1
            move.l     a0,BLTAPTH(a6)
            move.l     a1,BLTDPTH(a6)
            move.w     #CHAR_H*64+CHAR_W/16,BLTSIZE(a6)                  ;h=16, w=16/16 (1 word)

.not_inserting_char:
            rts

scroll_by_1px:
            ; scroll everything  by 1bit
            bsr        wait_blit
            move.w     #$19f0,BLTCON0(a6)
            move.w     #2,BLTCON1(a6)
            move.w     #$ffff,BLTAFWM(a6)
            move.w     #$7fff,BLTALWM(a6)
            move.w     #(W-W)/8,BLTAMOD(a6)
            move.w     #(W-W)/8,BLTDMOD(a6)
            lea        bpls+SCROLL2_Y*LINE_SIZE+CHAR_H*LINE_SIZE-2,a0
            lea        bpls+SCROLL2_Y*LINE_SIZE+CHAR_H*LINE_SIZE-2,a1
            move.l     a0,BLTAPTH(a6)
            move.l     a1,BLTDPTH(a6)
            move.w     #CHAR_H*64+W/16,BLTSIZE(a6)                       ;h=16, w=16/16 (1 word)
            rts

;--------------------------------------------------------------------------------
; misc
;--------------------------------------------------------------------------------

CLR_W             = 320
CLR_H             = 16
clear_scroll:
            bsr        wait_blit
            lea        bpls+SCROLL1_Y*LINE_SIZE,a1
            move.w     #$0100,BLTCON0(a6)
            move.w     #0,BLTCON1(a6)
            move.w     #$ffff,BLTAFWM(a6)
            move.w     #$0000,BLTALWM(a6)
            move.w     #0,BLTDMOD(a6)
            move.l     a1,BLTDPTH(a6)
            move.w     #CLR_H*64+CLR_W/16,BLTSIZE(a6)                    ;h=16, w=16/16 (1 word)
            rts
blit_fonts_to_screen:
            bsr        wait_blit
            lea        font,a0
            lea        bpls,a1
            move.w     #$09f0,BLTCON0(a6)
            move.w     #0,BLTCON1(a6)
            move.w     #$ffff,BLTAFWM(a6)
            move.w     #$ffff,BLTALWM(a6)
            move.w     #(W-FONT_W)/8,BLTAMOD(a6)
            move.w     #(W-FONT_W)/8,BLTDMOD(a6)
            move.l     a0,BLTAPTH(a6)
            move.l     a1,BLTDPTH(a6)
            move.w     #FONT_H*64+FONT_W/16,BLTSIZE(a6)                  ;h=16, w=16/16 (1 word)
            rts

wait_blit:
            tst        $dff002
.wait:
            ; btst       #6,DMACONR(a6)                                     ; check if blitter is busy
            btst       #6,$dff002
            bne.b      .wait
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

font_order:
            dc.b       "abcdefghijklmnopqrst"
            dc.b       "uvwxyz.,'!?:=/#-1234"
            dc.b       "567890()<> "
NB_FONTS          = (*-font_order)

            even
font_offset:
            dcb.w      256,0

scroll_txt:     
            dcb.b      20," "
            dc.b       "hello everybody this"
            dc.b       " is my first scroll "
            dc.b       "in a very long "
            dc.b       "time. hope you enjoy it!"
SCROLL_SIZE       = (*-scroll_txt)
SCROLL_SIZE_IN_PX = SCROLL_SIZE*16
            dcb.b      20," "

            even
scroll_ptr: 
            dc.l       scroll_txt
scroll_x1:
            dc.w       0
scroll_x2:
            dc.w       18*CHAR_W

;--------------------------------------------------------------------------------
; copper
;--------------------------------------------------------------------------------
            section    data, data_c

            even
copper:      
            dc.w       $1FC,0                                            ; compat. AGA
            dc.w       BPLCON0,NB_BPLS<<12+$0200                         ; 2 bitplaces
            dc.w       DIWSTRT,$2c81
            dc.w       DIWSTOP,$2cc1
            dc.w       DDFSTRT,$38
            dc.w       DDFSTOP,$d0
            dc.w       BPL1MOD,MODULO
            dc.w       BPL2MOD,MODULO

copper_bpls:
            dc.w       BPL1PTH,$0
            dc.w       BPL1PTL,$0
            dc.w       BPL2PTH,$0
            dc.w       BPL2PTL,$0
            dc.w       BPL3PTH,$0
            dc.w       BPL3PTL,$0
            dc.w       BPL4PTH,$0
            dc.w       BPL4PTL,$0
            dc.w       BPL5PTH,$0
            dc.w       BPL5PTL,$0
            dc.w       BPL6PTH,$0
            dc.w       BPL6PTL,$0

            ; top of the screen
            dc.w       $2507,$fffe,$180,$f00
            dc.w       $2607,$fffe,$180,$000

           ; default colors
            dc.w       $0180,$0000,$0182,$0f00
            dc.w       $0184,$00f0,$0186,$0ff0

            dc.w       $ffdf,$fffe                                       ; Wait for vpos >= 0xff and hpos >= 0xde
            ; bottom of the screen
            dc.w       $3201,$fffe,$180,$f00                             ; Wait for vpos >= 0x2c
            dc.w       $ffff,$fffe


;--------------------------------------------------------------------------------
; bitplanes
; use bss when you want to initialize the bitplanes to zero at runtime rather than storing them in the data section 
;--------------------------------------------------------------------------------

            even
CHAR_W            = 16
CHAR_H            = 16
FONT_W            = 320
FONT_H            = CHAR_H*3
font:  
            ; 3 lines of fonts 16x16
            ; abcdefghijklmnopqrst
            ; uvwxyz,,'!?:=/#-1234
            ; 567890()<heart><heart with letter c>
            incbin     "../raw_files/melonfont.raw"

;             section    bss, bss_c
; bpls:
;             ds.b       W/8*H*NB_BPLS,0
            section    data, data_c
bpls:
            dcb.b      W/8*H*NB_BPLS,$0
