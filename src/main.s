** Debugging only
HOME	EQU	$FC58
COUT	EQU	$FDED

	ORG	$8000


** Start of program
* Main loop
MAIN	JSR	WAIT
* Capture keypress
	JSR	INPUT
	CMP	#$00	; check against: neutral $00 flag
	BEQ	MAIN	; jump if neutral flag
	CMP	#$D1	; check against: Q key (quit)
	BEQ	RTS	; exit if quit key is pressed
* Print keypress
	JSR	COUT
	JMP	MAIN

	RTS


** Input capture module
INPUT	LDA	$C000	; read keystroke
	BPL	NOKEY	; verify if A < $80
* Received positive keypress
	BIT	$C010	; clear keyboard strobe
	RTS		; return with key in A
* No positive keypress
NOKEY	LDA	#$00	; load neutral $00 flag
	RTS		; return with no key


** Utils
* RequestAnimationFrame subroutine
WAIT	LDA	#0	; 6Hz refresh rate
	JSR	$FCA8	; builtin wait subroutine
	RTS

* Global RTS callable from branch instructions
RTS	RTS
