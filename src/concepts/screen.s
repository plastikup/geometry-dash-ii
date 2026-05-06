** =============== Zero page ===============
PTR	EQU	$F6	; quick temporary pointer storage (occupies $F6 and $F7)
TEMP	EQU	$F5	; quick random value storage

** ============ Start of program ===========
** MAIN LOOP
	ORG	$8000

	LDY	#1	; TEMPORARY - value to test the displacement module
MAIN	JSR	WAIT
* Capture keypress
	JSR	INPUT
	CMP	#$00	; check against: neutral $00 flag
	BEQ	MAIN	; jump if neutral flag
	CMP	#$D1	; check against: Q key (quit)
	BEQ	RTS	; exit if quit key is pressed
	CMP	#$C3	; check against: C key (copy screen)
	BEQ	MAINCOPYSCRN	; jump if copy screen requested
* Print keypress
	JSR	DEBUG
	JMP	MAIN
MAINCOPYSCRN	JSR	COPYSCRN
	JMP	MAIN


** ========== Input capture module ==========
** READ KEYPRESS
INPUT	LDA	$C000	; read keystroke
	BPL	NOKEY	; verify if A < $80
* Received positive keypress
	BIT	$C010	; clear keyboard strobe
	RTS		; return with key in A
* No positive keypress
NOKEY	LDA	#$00	; load neutral $00 flag
	RTS		; return with no key


** ============ Screen modules =============
** WRITE VALUES
PRINT	PHA		; save ASCII text into stack

	TXA
	ASL		; each pointer is 2 bits long
	TAX

	LDA	SCRNROWPTR,X	; load the screen row pointer
	STA	PTR	; save the row coordinate to use it with indirect mode
	LDA	SCRNROWPTR+1,X	; repeat with higher bit
	STA	PTR+1

	PLA		; retrieve the ASCII text from stack
	STA	(PTR),Y	; write the character on screen in the exact coordinate

	RTS

** WRITE DEBUG VALUES
DEBUG	STA	TEMP	; keep the debugging ASCII text aside
* Push the values of the X and Y registers to the stack
	TXA
	PHA
	TYA
	PHA
* Print debugging value
	LDA	TEMP	; load back the debugging ASCII text
	LDX	#23	; define debugging destination
	LDY	#39
	JSR	PRINT	; print debugging ASCII text
* Retrieve & restore for A, X and Y registers from stack
	PLA
	TAY
	PLA
	TAX
	LDA	TEMP            ; restore value of A register
	RTS

** COPY SCREEN TOWARDS THE LEFT
COPYSCRN	STY	TEMP	; store displacement value for reuse
* OUTERMOST LOOP
ADVCLOOP	LDX	#24	; repeat copying 24 times (24 rows) starting with the bottom
* COPYING LOOP
* Retrieve the value to copy
COPYLP 	LDA	SCRNROWPTR,X
	STA	PTR
	LDA	SCRNROWPTR+1,X	; repeat with higher bit
	STA	PTR+1
	LDA	(PTR),Y
	PHA		; save the value to retrieve later
* Adjust Y for printing coordinates
	TYA
	SEC
	SBC	TEMP	; adjust printing position to destination
	TAY		; transfer destination to Y register
* Copy screen value
	PLA		; retrieve value to print
	JSR	PRINT	; print
* Reset Y for retrieving coordinates
	TYA
	CLC
	ADC	TEMP	; adjust retrieving position to source
	TAY		; transfer source to Y register
* Decrease innermost copying loop
	DEX
	BCS	COPYLP	; jump if X is still positive
* Increase outermost loop
	INY
	TYA		; transfer to A to check #columns overflow
	SEC
	SBC	#39	; 40 columns, so minus 39 to get A=0 if need to RTS
	BEQ	RTS	; RTS if A-39=0
	JMP	ADVCLOOP

** ================= Utils =================
** REQUEST_ANIMATION_FRAME SUBROUTINE
WAIT	LDA	#0	; 6Hz refresh rate
	JSR	$FCA8	; builtin wait subroutine
	RTS

** GLOBAL RTS CALLABLE FROM BRANCHES
RTS	RTS



** ======== CONSTANTS AND VARIABLES ========
** SCREEN MODULE DATA
* First columns pointers for the screen's pixels
SCRNROWPTR
	DA	$400
	DA	$480
	DA	$500
	DA	$580
	DA	$600
	DA	$680
	DA	$700
	DA	$780
	DA	$428
	DA	$4A8
	DA	$528
	DA	$5A8
	DA	$628
	DA	$6A8
	DA	$728
	DA	$7A8
	DA	$450
	DA	$4D0
	DA	$550
	DA	$5D0
	DA	$650
	DA	$6D0
	DA	$750
	DA	$7D0
