;================================================================================
; sin scroll by with each font moving independently
;================================================================================

;---------- Const ----------
; largeur effective (LE) = (DDFSTOP-DDFSTART)*2+16 == 320/8
NB_BPLS             = 2 
W                   = 336
H                   = 256
BPL_SIZE            = W/8                                                        ; if non IL W/8*H         ; if IL : W/8 
LINE_SIZE           = W/8*NB_BPLS                                                ; if non IL W/8           ; if IL : W/8*NB_BPLS
MODULO              = W/8*NB_BPLS-320/8                                          ; if non IL : W/8 - LE/8  ; if IL : W/8*NB_BPLS-LE/8


;--------------------------------------------------------------------------------
; main
;--------------------------------------------------------------------------------
run:       
            lea        CUSTOM,a6
            move.w     #$83c0,DMACON(a6)                                         ; enable copper + bitplane + blitter
            bsr        init_bpls
            bsr        init_copper
            bsr        init_font_offset
            bsr        init_sin1
            move.l     #copper,COP1LC(a6)                                        ; set new copper
            move.w     #$0,COPJMP1(a6)                                           ; activate copper

            ; bsr        test_blit_chars
main_loop:
            move.w     #$10,d1
            bsr        wait_raster
            bsr        do_scroll1

    		; mouse test
            btst       #6,$bfe001
            bne.b      main_loop
            rts

;--------------------------------------------------------------------------------
; init
;--------------------------------------------------------------------------------

init_font_offset:
            lea        font_order,a0
            moveq      #0,d0                                                     ; ptr to font data
            moveq      #0,d1                                                     ; line
            lea        font_offset,a1
            moveq      #NB_FONTS-1,d7
.init_font_offset:
            moveq      #0,d2
            move.b     (a0)+,d2                                                  ; char
            add.w      d2,d2
            move.w     d0,(a1,d2.w)
            add.w      #CHAR_W/8,d0
            add.w      #1,d1
            cmp.w      #FONT_W/CHAR_W,d1                                         ; nb fonts/line
            bne        .not_end_of_line
            moveq      #0,d1                                                     ; ptr to font data
            add.w      #FONT_W/8*CHAR_H*NB_BPLS-FONT_W/8,d0                      ; go to next line
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

init_sin1:
            lea        sin1,a0
            moveq      #NB_SIN1-1,d0
.init_sin1:
            move.w     (a0),d1
            mulu.w     #LINE_SIZE,d1
            move.w     d1,(a0)+
            dbf        d0,.init_sin1
            rts

;--------------------------------------------------------------------------------
; scroll1
;   redraw all chars on the line
;--------------------------------------------------------------------------------

SCROLL1_Y           = 70
CHAR_W_FOR_BLT      = CHAR_W+16                                                  ; keep some space at the end
SIN_OFFSET_PER_FONT = 8

do_scroll1:
            bsr        clear_scroll1

            ; change scroll_x1 position
            clr.l      d0
            move.w     scroll_x1,d0
            addq       #1,d0
            cmp.w      #SCROLL_SIZE_IN_PX,d0
            bne        .scroll_wrap
            moveq      #0,d0
.scroll_wrap:
            move.w     d0,scroll_x1

            ; change syn_pos
            move.w     sin_pos,d3
            addq       #2,d3

            ; plot char
            bsr        wait_blit
            lea        scroll_txt,a3
            ror.l      #4,d0
            add.w      d0,a3
            swap       d0

            ; if new char, update sin_pos
            cmp.w      #0,d0
            bne        .not_new_char
            add.w      #SIN_OFFSET_PER_FONT,d3
.not_new_char:
            and.w      #NB_SIN1*2-1,d3
            move.w     d3,sin_pos

            eor.w      #$f000,d0
            or.w       #$0dfc,d0                                                 ; D = A + B
            move.w     d0,BLTCON0(a6)
            move.w     #0,BLTCON1(a6)
            move.w     #$ffff,BLTAFWM(a6)
            move.w     #$0000,BLTALWM(a6)
            move.w     #(FONT_W-CHAR_W_FOR_BLT)/8,BLTAMOD(a6)
            move.w     #(W-CHAR_W_FOR_BLT)/8,BLTBMOD(a6)
            move.w     #(W-CHAR_W_FOR_BLT)/8,BLTDMOD(a6)

            lea        sin1,a4
            lea        font_offset,a2
            lea        bpls+SCROLL1_Y*LINE_SIZE-2,a1
            moveq      #W/CHAR_W-1,d7                                            ; how many 16-pixel blocks fit in the width
.blit_char:
            add.w      #SIN_OFFSET_PER_FONT,d3
            and.w      #NB_SIN1*2-1,d3
            move.w     (a4,d3.w),d4
            move.l     a1,a5
            add.w      d4,a5

            moveq      #0,d1
            move.b     (a3)+,d1                                                  ; char
            cmp.b      #" ",d1                                                   ; optimization - skip space characters
            beq        .skip_char
            add.w      d1,d1
            move.w     (a2,d1.w),d2                                              ;d2 == offset from #font 
            lea        font,a0
            add.w      d2,a0

            bsr        wait_blit
            move.l     a0,BLTAPTH(a6)
            move.l     a5,BLTBPTH(a6)
            move.l     a5,BLTDPTH(a6)
            move.w     #CHAR_H*NB_BPLS*64+CHAR_W_FOR_BLT/16,BLTSIZE(a6)          ;h=16, w=16/16 (1 word)

.skip_char:
            add        #2,a1
            dbf        d7,.blit_char
            rts

clear_scroll1:
            bsr        wait_blit
            lea        bpls+SCROLL1_Y*LINE_SIZE,a1
            move.w     #$0100,BLTCON0(a6)
            move.w     #0,BLTCON1(a6)
            move.w     #$ffff,BLTAFWM(a6)
            move.w     #$0000,BLTALWM(a6)
            move.w     #0,BLTDMOD(a6)
            move.l     a1,BLTDPTH(a6)
            move.w     #(CHAR_H+SIN1_HEIGHT)*NB_BPLS*64+W/16,BLTSIZE(a6)         ;h=16, w=16/16 (1 word)
            rts

;--------------------------------------------------------------------------------
; misc
;--------------------------------------------------------------------------------

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
NB_FONTS            = (*-font_order)

            even
font_offset:
            dcb.w      256,0

scroll_txt:     
            dcb.b      21," "
            dc.b       "hello everybody this"
            dc.b       " is my first scroll "
            dc.b       "in a very long "
            dc.b       "time. hope you enjoy it!"
SCROLL_SIZE         = (*-scroll_txt)
SCROLL_SIZE_IN_PX   = SCROLL_SIZE*16
            dcb.b      20," "

            even
scroll_ptr: 
            dc.l       scroll_txt
scroll_x1:
            dc.w       0
sin_pos:
            dc.w       0

sin1:
;@generated-datagen-start----------------
; This code was generated by Amiga Assembly extension
;
;----- parameters : modify ------
;expression(x as variable): round(sin(x*2*pi/128-pi)*30)+30
;variable:
;   name:x
;   startValue:0
;   endValue:63
;   step:1
;outputType(B,W,L): W
;outputInHex: true
;valuesPerLine: 8
;--------------------------------
;- DO NOT MODIFY following lines -
            dc.w       $001e, $001d, $001b, $001a, $0018, $0017, $0015, $0014
            dc.w       $0013, $0011, $0010, $000f, $000d, $000c, $000b, $000a
            dc.w       $0009, $0008, $0007, $0006, $0005, $0004, $0004, $0003
            dc.w       $0002, $0002, $0001, $0001, $0001, $0000, $0000, $0000
            dc.w       $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0002
            dc.w       $0002, $0003, $0004, $0004, $0005, $0006, $0007, $0008
            dc.w       $0009, $000a, $000b, $000c, $000d, $000f, $0010, $0011
            dc.w       $0013, $0014, $0015, $0017, $0018, $001a, $001b, $001d
;@generated-datagen-end----------------

NB_SIN1             = (*-sin1)/2
SIN1_HEIGHT         = 30

;--------------------------------------------------------------------------------
; copper
;--------------------------------------------------------------------------------
            section    data, data_c

            even
copper:      
            dc.w       $1FC,0                                                    ; compat. AGA
            dc.w       BPLCON0,NB_BPLS<<12+$0200                                 ; 2 bitplaces
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
            dc.w       $0180,$0000,$0182,$0f80
            dc.w       $0184,$08f0,$0186,$0af8

TOP_SCROLL          = $2c+SCROLL1_Y
SCROLL_HEIGHT       = SIN1_HEIGHT+CHAR_H
            dc.b       TOP_SCROLL,$07,$ff,$fe
            dc.w       $0180,$0000,$0182,$0f80
            dc.w       $0184,$08f0,$0186,$008f
            ; mirror
            dc.b       TOP_SCROLL+SCROLL_HEIGHT,$07,$ff,$fe
            dc.w       $0180,$0004,$0182,$0840
            dc.w       $0184,$0480,$0186,$0048
            dc.w       BPL1MOD,-W/8*NB_BPLS-320/8
            dc.w       BPL2MOD,-W/8*NB_BPLS-320/8

            dc.b       TOP_SCROLL+SCROLL_HEIGHT*2,$07,$ff,$fe
            dc.w       $0180,$0000
            ; one more line refrelcted -> should be empty
            dc.b       TOP_SCROLL+SCROLL_HEIGHT*2+1,$07,$ff,$fe
            dc.w       BPL1MOD,-320/8
            dc.w       BPL2MOD,-320/8

            dc.w       $ffdf,$fffe                                               ; Wait for vpos >= 0xff and hpos >= 0xde
            ; bottom of the screen
            dc.w       $3201,$fffe,$180,$f00                                     ; Wait for vpos >= 0x2c
            dc.w       $ffff,$fffe


;--------------------------------------------------------------------------------
; bitplanes
; use bss when you want to initialize the bitplanes to zero at runtime rather than storing them in the data section 
;--------------------------------------------------------------------------------

            even
CHAR_W              = 16
CHAR_H              = 16
FONT_W              = 320
FONT_H              = CHAR_H*3
font:  
            ; 3 lines of fonts 16x16*2
            ; abcdefghijklmnopqrst
            ; uvwxyz,,'!?:=/#-1234
            ; 567890()<heart><heart with letter c>
            incbin     "../raw_files/melonfontbis.raw"

            section    bss, bss_c
bpls:
            ds.b       W/8*H*NB_BPLS,0