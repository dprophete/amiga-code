;--------------------------------------------------------------------------------
; demo.s - entry point
;
; base.s must be included FIRST: its 'in_' label is the first byte of the first
; code hunk, i.e. the executable's entry point. It does the init, calls 'run',
; then restores the system and returns to the OS.
;
; Then include exactly ONE program: it defines 'run' plus its own data/copper.
;--------------------------------------------------------------------------------

  INCLUDE    "./base.s"

  ; INCLUDE    "./copper1.s"
  ; INCLUDE    "./bpl1.s"
  INCLUDE    "./bpl_king_tut.s"
