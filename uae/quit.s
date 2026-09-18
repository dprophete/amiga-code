;--------------------------------------------------------------------------------
; quit.s - ask the UAE host to exit.  Kickstart 1.3 compatible.
;
; No C startup, no dos.library, no stack check, no OS 2.0 calls.
; Single CODE hunk, no relocations.
;
;   OpenResource("uae.resource") -> rtarea base at offset $2a
;   uaelib entry = rtarea + $FF60, function code passed on the stack
;   function 13 = ExitEmu   (4 = Reset, 3 = HardReset)
;
; uae_quit() is asynchronous: the trap returns and the host exits a frame or
; two later, so returning here is normal and not an error.
;
; Return codes:  0 = quit requested   10 = no uae.resource   11 = no UAE trap
;--------------------------------------------------------------------------------

_LVOOpenResource    EQU -498

RES_RTAREA          EQU $2a
UAELIB_OFFSET       EQU $FF60
UAELIB_EXITEMU      EQU 13
LINE_A_MASK         EQU $F000
LINE_A_OPCODE       EQU $A000

        move.l  4.w,a6                      ; ExecBase
        lea     resname(pc),a1
        jsr     _LVOOpenResource(a6)
        tst.l   d0
        beq.s   .noresource

        movea.l d0,a0
        move.l  RES_RTAREA(a0),d0           ; rtarea base
        beq.s   .notrap
        add.l   #UAELIB_OFFSET,d0           ; uaelib entry
        btst    #0,d0
        bne.s   .notrap
        movea.l d0,a1

        move.w  (a1),d1                     ; must be a line-A trap opcode
        and.w   #LINE_A_MASK,d1
        cmp.w   #LINE_A_OPCODE,d1
        bne.s   .notrap

        pea     UAELIB_EXITEMU.w
        jsr     (a1)
        addq.l  #4,sp
        moveq   #0,d0
        rts

.noresource
        moveq   #10,d0
        rts
.notrap
        moveq   #11,d0
        rts

resname dc.b    "uae.resource",0
        even
