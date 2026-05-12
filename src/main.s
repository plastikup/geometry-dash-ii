HOME	EQU	$FC58
** =============== Zero page ===============
* Global
PTR	EQU	$F6	; quick temporary pointer storage
TEMP	EQU	$F5	; quick random value storage
* Player
HPOS	EQU	$80	; CONSTANT - horizontal position of the player
VPOS	EQU	$81	; vertical position of the player, times 8
VVELPOS	EQU	$82	; POSITIVE vertical velocity, times 8
VVELNEG	EQU	$83	; NEGATIVE vertical velocity, times
ISAIR	EQU	$85	; flag indicating whether the player is in the air
FORCEDJMP	EQU	$86	; FF if forced jump

SCRNREFRESH	EQU	$90	; frames between next refresh

** ============ Start of program ===========
	ORG	$8000
	JSR	HOME
** INITIALIZATIONS
	LDA	#5	; player is always at column #5, starting from #0
	STA	HPOS

	LDA	#16	; 8th row starting counting from 0th row
	STA	VPOS

	LDA	#0
	STA	VVELNEG
	STA	VVELPOS
	STA	ISAIR

	LDA	#1
	STA	SCRNREFRESH

** LOAD LVLPTRS
	LDX	#0
LOADLVLPTRS	LDA	INITIALLVLPTR,X
	STA	LVLPTR,X
	INX
	CPX	#24
	BNE	LOADLVLPTRS

	LDX	#0
	LDA	#0
RESETQNTCHRS	STA	LVLCHRS,X
	STA	LVLQNT,X
	INX
	CPX	#12
	BNE	RESETQNTCHRS

** LOAD MAP
	LDA	#40
INITSCRN	PHA
	LDA	#1	; overwrite screen refresh
	STA	SCRNREFRESH
	JSR	SCROLLSCRN
	PLA
	SEC
	SBC	#1
	BNE	INITSCRN
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
WAIT	LDA	#101	; 38Hz refresh rate
	JSR	$FCA8	; builtin wait subroutine
	RTS


** ============= Main Functions ============
** MAIN LOOP
MAIN	JSR	WAIT
	JSR	DEATH
	CMP	#$A0
	BEQ	CONTINUE
	CMP	#$00
	BEQ	CONTINUE
	RTS
CONTINUE	JSR	PLAYER
	JSR	SCROLLSCRN
* Capture keypress
	JSR	INPUT
	CMP	#$D1	; check against: Q key (quit)
	BEQ	QUIT	; exit if quit key is pressed
	CMP	#$A0	; check against: space key (jump)
	BNE	SKIPJUMP
JUMP	LDA	#8	; jump height
	STA	VVELPOS
	LDA	#$00
	STA	FORCEDJMP

SKIPJUMP	LDA	FORCEDJMP
	CMP	#$FF
	BEQ	JUMP
	JSR	DEBUG
	JMP	MAIN
QUIT	RTS

** SCROLL THE SCREEN AND PUT NEW TILES
SCROLLSCRN	DEC	SCRNREFRESH
	BEQ	SCRNRFRSHNOW
	RTS
* Reset refresh count
SCRNRFRSHNOW	LDA	#2	; frames per screen refresh
	STA	SCRNREFRESH
* Copy the content of the screen 1 block to the left
	JSR	COPYSCRN
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

	RTS

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
* Verify if standing on ground
	JSR	PLAYERAIRTIME
* Apply physics if physics frame
	JSR	PLAYERPHYS
	RTS


** Display player on screen (TBD: erase shadow)
* Load player's current position
DSPLYPLAYER	LDY	HPOS
	LDA	VPOS	; player's vertical position, times 8
	LSR
	LSR
	LSR		; player's actual vertical position
	CLC
	ADC	#6	; top row does not start at row 0
	TAX
* Print player on screen
	LDA	#$0	; ctrl-@ is the player
	JSR	PRINT

	RTS

** Verify if player is airtime
* Get pointer pointing the row below the player
PLAYERAIRTIME   LDA             VPOS
                LSR		; divide by 2
                LSR		; divide by 4
                LSR		; divide by 8 to drop the sub-row remainder
                ASL		; multiply by 2 because pointers are 2 bytes long
                CLC		; first row of the game does not start at row 0
                ADC	#14	; and we need an extra incr to reach the row below
                TAX		; final vertical position
* Load pointer to the row below
	LDA	SCRNROWPTR,X
	STA	PTR
	LDA	SCRNROWPTR+1,X
	STA	PTR+1
* Get the ASCII character below the user
	LDY	HPOS
	LDA	(PTR),Y
* Airtime if standing on space ($A0) character
	CMP	#$A0	; space character
	BEQ	SETAIRTIME
	CMP	#$CF
	BEQ	SETJUMP
	CMP	#$AF
	BEQ	SETAIRTIME
	CMP	#$DC
	BEQ	SETAIRTIME
* No air
	LDA	#$00
	STA	ISAIR
	STA	FORCEDJMP
	RTS
* Yes air
SETAIRTIME	LDA	#$FF
	STA	ISAIR
	RTS
* Forced jump
SETJUMP	LDA	#$FF
	STA	FORCEDJMP
	LDA	#$00
	STA	ISAIR
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
	RTS
* IS AIR
* Verify if negative gravity does not exceed 8
APPLYGRAVITY	LDA	VVELNEG
	CMP	VVELPOS
	BCC	INCVVELNEG	; if neg smaller than pos, dont think
	SEC		; otherwise, pos is smaller so check
	SBC	VVELPOS	; overall downwards speed
	CMP	#8
	BCS	SKIPNEGGRAV	; speeds that exceed 8 skips lines
* Apply gravity
INCVVELNEG	INC	VVELNEG
* Apply positional physics on player
SKIPNEGGRAV	LDA	VPOS
	SEC
	SBC	VVELPOS	; because subtracting goes up on screen
	CLC
	ADC	VVELNEG	; same logic, adding goes down on screen
	STA	VPOS

	RTS

** Check if the player is dead
DEATH	LDA             VPOS	; VPOS times 8
                LSR		; divide by 2
                LSR		; divide by 4
                LSR		; divide by 8
	CLC
	ADC	#6
                ASL		; multiply by 2 because pointers are 2 bytes long
	TAX
* Load pointer
	LDA	SCRNROWPTR,X
	STA	PTR
	LDA	SCRNROWPTR+1,X
	STA	PTR+1
* Get the ASCII character
	LDY	HPOS
	LDA	(PTR),Y
	RTS

** ======== CONSTANTS AND VARIABLES ========
** MAP MODULE DATA AND POINTERS
* Common tables
INITIALLVLPTR
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

LVLPTR	DS	24
LVLCHRS	DS	12
LVLQNT	DS	12

* Level data
LVL0	HEX	FFFFFFFFFF39
LVL1	HEX	FF29DC01AD0BAF01FF19C905FF10A016FF02A302FF3FA003FF16C903FF46A049
	HEX	D801A00FFF0EC902FF0DA013FF09A006FF0DC904FF0DC904FF5E
LVL2	HEX	FF04A017D501D701D501A00CDC01AD09AF01A009C901A00AC905A002C907A002
	HEX	FF23A302FF3EA001AE01A001AE01A001FF5EA043E601A801F801A901BD01E101
	HEX	D801AB01E201A011FF0AC901FF03C902A01FFF05A00AFF08C905FF03C903FF0B
	HEX	C903FF07C904FF51
LVL3	HEX	FF03A01CAA01A00BDC01AD07AF01A00AC901A009C909A003C902A00FAA01A00C
	HEX	FF06A004A302A007FF05A001FF05A017FF13A004BE01A004FF36A06FD801A01C
	HEX	C905A01DFF08A015C90BA007C903A00BC903A008DC01AD04AF01A005DC01AD02
	HEX	AF01A010FF06C201D201C101D601CF01AC01FF1D
LVL4	HEX	FF02A01CAA01A001AA01A00BDC01AD05AF01A016C904A007C901A007AA01A005
	HEX	AA01A019A302A00AFF05A020FF0EA002DF03A002FF05A001DC01AD04AF01A007
	HEX	DC01A001AD02A001AF01A005DC01A002AD01A002AF01A07FD801CF01D801CF01
	HEX	A01CC903A01FDC01AF01DC01AF01DC01AF01A019C904A002C903A008C904A007
	HEX	C903A00ADC01AD02AF01A007DC01AF01A011FF07C201D201C101D601CF01A101
	HEX	FF1C
LVL5	HEX	FF11A00EAA01A00DDC01AD03AF01A022C901A00BAA01A00CBE01BA01A901A00C
	HEX	A302A01FBC01DB01BD0ADD01BE01A007FF0AA005FF05A010DC01AD02AF01A007
	HEX	DC01A001AD01A001AF01A008CF01CB01C101D901A001D001C101CC01D301AC01
	HEX	A01DD501D001A05DDB01BD08DD01A007C903A029AF01DC01AF01DC01AF01DB01
	HEX	BD05DD01A009C904A00AC905A008C904A00CDC01AF01A01BFF29
LVL6	HEX	FF08A026DC01AD01AF01A008AF01DC01A041A302A023DC03AF03A04BD001C901
	HEX	C301CB01A001C101A001D001C101D401C801A102A01CCF01D201A029DB01BD15
	HEX	CF02BD1BDD01A028AF01DC01A001DB01BD18DD01A009C905A00AC902A00AC905
	HEX	A010DB01BD05DD01A00FFF08D401D501A001C101D301A001D301D501D201D601
	HEX	C501C301D501A001D401CF01CE01A001C301C501C701C501D001A101FF09
LVL7	HEX	FF03A035AF01AD02DC01A066DC02AF02A051CF01C601A001D901CF01D501D201
	HEX	A001C301C801CF01C901C301C501A103A019C401CF01D701CE01BF01A02BD601
	HEX	A001EF01F201A001E401E901E501A001E401EF01F701EE01A001F401E801E501
	HEX	F201E501A001D601A008DB01BD08DD01A004DB01BD08DD01A007DB01CF0BAF01
	HEX	DC01CF05DD01A001DC01AF01A014DB01BD07DD01A009C902A02EDB01BD06DD01
	HEX	A00CFF29
LVL8	HEX	FF13CF05FF0FCF01FF33A048DC01AF01A08DDB01BD0FDD01A033DB01BD07DD01
	HEX	A004DB01CF0EDD01A006DC01AF01A02EC902A007C905A016AF01DC01A01FFF06
	HEX	D001C101D201A001CA01C501C101CE02C501A001C301C101DA01C501CC01C101
	HEX	C901D301FF10
LVL9	HEX	FF0AE801E501EC02EF01FF01F701EF01F201EC01E401FF37BE0AFF09A029DB01
	HEX	BD0FDD01A030AF01AD02DC01A009AF01AD01DC01A05ADE01A001F401E801E901
	HEX	F301A001F701E101F901A001F501F001A001DE01A02AFF08A05FC905A007C904
	HEX	A009AF01AD02DC01A01EFF0AC501D401A001CA01D501CE01D901C901A001DA01
	HEX	C801C101CE01C701FF11
LVLA	HEX	FF14DB01BD26DD01FF13DE05FF13A013FF08A00CDB01BD0FDD01A011FF0AA00E
	HEX	AF01A001AD02A001DC01A007AF01A001AD01A001DC01A007AF01AD03DC01A085
	HEX	FF02D301CF01D202D901A101FF02A033AF01DC01A00DFF08DB01BD11DD01C904
	HEX	FF0CC905FF16DB01BD0BDD01FF2D
LVLB	HEX	FF21DB01BD2ADD01FF60CF02FF4BDB01BD1BDD01FFFFFF21


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
