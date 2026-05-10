** =============== Zero page ===============
* Global
PTR	EQU	$F6	; quick temporary pointer storage
TEMP	EQU	$F5	; quick random value storage
* Player
VPOS	EQU	$80	; vertical position of the player, times 8
VVELPOS	EQU	$81	; POSITIVE vertical velocity, times 8
VVELNEG	EQU	$82	; NEGATIVE vertical velocity, times
PHYSDELAY	EQU	$83	; physics frames delay
ISAIR	EQU	$84	; flag indicating whether the player is in the air

** ============ Start of program ===========
	ORG	$8000
** INITIALIZATIONS
	LDA	#$00
	STA	ISAIR

	LDA	#1	; minimum required to start with physics counter
	STA	PHYSDELAY

	LDA	#64	; 8th row starting counting from 0th row
	STA	VPOS
	JMP	MAIN

** ================= Utils =================
** READ KEYPRESS
INPUT	LDA	$C000	; read keystroke
	BPL	NOKEY	; verify if A < $80
* Received positive keypress
	BIT	$C010	; clear keyboard strobe
	RTS		; return with key in A
* No positive keypress
NOKEY	LDA	#$00	; load neutral $00 flag
	RTS		; return with no key

** REQUEST_ANIMATION_FRAME SUBROUTINE
WAIT	LDA	#0	; 6Hz refresh rate
	JSR	$FCA8	; builtin wait subroutine
	RTS


** ============= Main Functions ============
** MAIN LOOP
MAIN	JSR	WAIT
	JSR	PLAYER
* Capture keypress
	JSR	INPUT
	CMP	#$00	; check against: neutral $00 flag
	BEQ	MAIN	; jump if neutral flag
	CMP	#$D1	; check against: Q key (quit)
	BEQ	QUIT	; exit if quit key is pressed
	CMP	#$C3	; check against: C key (copy screen)
	BEQ	SCROLLSCRN	; jump if copy screen requested
* Print keypress
	JSR	DEBUG
	JMP	MAIN
QUIT	RTS


** SCROLL THE SCREEN AND PUT NEW TILES
* Copy the content of the screen 1 block to the left
SCROLLSCRN	JSR	COPYSCRN
* Put new tiles on the last column
	LDX	#11	; # of rows
SCROLLSCRNLP	LDA	LVLQNT,X
	BNE	SKIPFETCH
* Load new characters and count onto CHARS and QNT tables
	TXA		; save X register value (FETCHMAPDATA is destructive)
	PHA
	JSR	FETCHMAPDATA	; fetch data
	PLA		; restore X register
	TAX
* Get character to print and push to stack
SKIPFETCH	LDA	LVLCHRS,X
	PHA
* Adjust arguments and call print
	LDY	#39
	TXA
	CLC
	ADC	#6
	TAX
	PLA
	JSR	PRINT
* Restore X register after call
	TXA
	SEC
	SBC	#6
	TAX
* Decrease QNT table
	LDA	LVLQNT,X
	SEC
	SBC	#1
	STA	LVLQNT,X
* Increment pointer value if count is null
	BNE	SKIPINCRPTR
	TXA
	TAY
	PHA
	LDX	#1
	JSR	INCRLVLPTR
	PLA
	TAX
* Next row
SKIPINCRPTR	DEX
	BPL	SCROLLSCRNLP

	JMP	MAIN

** =============== Map module ===============
** UPDATE TILE DATA TABLES
* Multiply X and Y registers by 2
FETCHMAPDATA	TXA
	ASL		; each pointer is 2 bytes
	TAX

* Build tile pointer
	LDA	LVLPTR,X
	STA	PTR
	LDA	LVLPTR+1,X
	STA	PTR+1

* Access tile datum
	LDY	#0
	TXA
	LSR		; each table element is 1 byte
	TAX

	LDA	(PTR),Y
	STA	LVLCHRS,X

	INY
	LDA	(PTR),Y
	STA	LVLQNT,X

	RTS


** INCREMENT POINTER TABLE
* Multiply X and Y registers by 2
INCRLVLPTR	TYA
	ASL		; each pointer is 2 bytes
	TAY
	TXA
	ASL		; each map datum is 2 bytes
	TAX

* Add X to pointer
	TXA
	CLC
	ADC	LVLPTR,Y
	STA	LVLPTR,Y

	LDA	LVLPTR+1,Y
	ADC	#0	; propagate carry
	STA	LVLPTR+1,Y

	RTS


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

	TXA
	LSR		; restore X register to initial state
	TAX

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
COPYSCRN	LDY	#1
ADVCLOOP	LDX	#17	; repeat copying 12 times starting with 17
* COPYING LOOP
* Multiply X by 2 because 2 bits per line
COPYLP	TXA
	ASL
	TAX
* Retrieve the value to copy
 	LDA	SCRNROWPTR,X
	STA	PTR
	LDA	SCRNROWPTR+1,X	; repeat with higher bit
	STA	PTR+1
	LDA	(PTR),Y
	PHA		; save the value to retrieve later
* Restore modified X register
	TXA
	LSR
	TAX
* Adjust Y for printing coordinates
	DEY
* Copy screen value
	PLA		; retrieve value to print
	JSR	PRINT	; print
* Reset Y for retrieving coordinates
	INY
* Decrease innermost copying loop
	DEX
	CPX	#5	; #6 is the last to copy, so #5 is overflow
	BNE	COPYLP	; jump if X is still positive
* Increase outermost loop
	INY
	CPY	#40	; 40 is the first column to overflow
	BNE	ADVCLOOP	; no overflow so continue loop
	RTS


** ========= Player related modules ========
** PRIMARY PLAYER LOOP
* Display player on screen
PLAYER	JSR	DSPLYPLAYER
* Apply physics if physics frame
	DEC	PHYSDELAY
	BNE	SKIPPHYS
	LDA	#10	; frames between physics frame
	STA	PHYSDELAY
	JSR	PLAYERPHYS
SKIPPHYS	RTS


** Display player on screen (TBD: erase shadow)
* Load player's current position
DSPLYPLAYER	LDY	#5	; player is always at column #5, starting from #0
	LDA	VPOS	; player's vertical position, times 8
	LSR
	LSR
	LSR
	TAX		; player's actual vertical position relative to the screen
* Print player on screen
	LDA	#$0	; ctrl-@ is the player
	JSR	PRINT

	RTS

** Apply gravity physics to player
* Test which type of physics to apply
PLAYERPHYS	BIT	ISAIR
	BNE	APPLYGRAVITY	; isair != 0 AKA isair isnt false AKA isair is true
	LDA	VVELNEG
	CMP	VVELPOS
	BCC	APPLYGRAVITY	; NEG smaller than POS AKA jumping up into air
* IS GROUND
	LDA	#0	; nullify velocities on ground
	STA	VVELPOS
	STA	VVELNEG
	JSR	DEBUG
	RTS
* IS AIR
APPLYGRAVITY	INC	VVELNEG	; gravity
* apply positional physics on player
	LDA	VPOS
	SEC
	SBC	VVELPOS	; because subtracting goes up on screen
	CLC
	ADC	VVELNEG	; same logic, adding goes down on screen
	STA	VPOS

	RTS


** ======== CONSTANTS AND VARIABLES ========
** MAP MODULE DATA AND POINTERS
* Common tables
LVLPTR
	DA	LVL0
	DA	LVL1
	DA	LVL2
	DA	LVL3
	DA	LVL4
	DA	LVL5
	DA	LVL6
	DA	LVL7
	DA	LVL8
	DA	LVL9
	DA	LVLA
	DA	LVLB

LVLCHRS	DS	12
LVLQNT	DS	12

* Level data
LVL0	HEX	A0FF
LVL1	HEX	A0FF
LVL2	HEX	A0FF
LVL3	HEX	A0FF
LVL4	HEX	A0FF
LVL5	HEX	A0FF
LVL6	HEX	A0FF
LVL7	HEX	A025FF01A0FF
LVL8	HEX	A024FF01A001FF01A0FF
LVL9	HEX	A007DE01A006DE02A00CDE03A004FF01D501F701D501FF01A0FF
LVLA	HEX	FFFF
LVLB	HEX	FFFF

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
