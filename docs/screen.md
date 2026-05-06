# Screen

### Behavior

The Screen is a set of function that is supposed to write directly instead of using `COUT`. It can:

- Write any value to any coordinate
- Write any value to a predefined coordinate, used for quick debugging
- Scroll the screen left (copy every column to the left) by a given displacement quantity

### Modules

#### Write values 

The goal of this module is to take an ASCII value and print it on the screen on a given coordinate.

| Registers | Arguments | Return values |
| :-: | :-: | :-: |
| **A** | ASCII (printed text) | *unmodified* |
| **X** | Int (row) | *garbage data* |
| **Y** | Int (column) | *unmodified* |

> [!IMPORTANT]  
> This module changes the value of the `PTR` ZP variables.

```asm
PHA                     ; save ASCII text into stack

TXA
ASL                     ; each pointer is 2 bits long
TAX

LDA     SCRNROWPTR,X    ; load the screen row pointer
STA     PTR             ; save the row coordinate to use it with indirect mode
LDA     SCRNROWPTR,X    ; repeat with higher bit
STA     PTR

PLA                     ; retrieve the ASCII text from stack
STA     (PTR),Y         ; write the character on screen in the exact coordinate

RTS
```


#### Write debug values

The goal of this module is to provide a fast way to debug our code during testing, by keeping intact every registers and by always writing to a predefined destination on the screen.

| Registers | Arguments | Return values |
| :-: | :-: | :-: |
| **A** | ASCII (debugged text) | *unmodified* |
| **X** | *any* | *unmodified* |
| **Y** | *any* | *unmodified* |

> [!IMPORTANT]  
> This module changes the value of the `TEMP` ZP variable.

```asm
STA     TEMP            ; keep the debugging ASCII text aside

TXA                     ; push the values of the X and Y registers to the stack
PHA
TYA
PHA

LDA     TEMP            ; load back the debugging ASCII text
LDX     #0              ; define debugging destination
LDY     #0
JSR     PRINT           ; print debugging ASCII text

PLA                     ; retrieve and restore values of the X and Y registers from stack
TAY
PLA
TAX
LDA     TEMP            ; restore value of A register
RTS
```

#### Copy the screen left

The goal of this oddly specific module is to provide a way to copy the content of the screen towards the left by a specific given amount. This emulates "scrolling" during the game.

| Registers | Arguments | Return values |
| :-: | :-: | :-: |
| **A** | *any* | *garbage data* |
| **X** | *any* | *garbage data* |
| **Y** | Int (displacement amount) | *garbage data* |

> [!IMPORTANT]  
> This module changes the value of the `TEMP` ZP variable.

```asm
        STY     TEMP    ; store displacement value for reuse
* OUTERMOST LOOP
LOOP    LDX     #24     ; repeat the copying 24 times (24 rows on screen), starting with the bottom
* COPYING LOOP
* Retrieve the value to copy
COPYLP  LDA     SCRNROWPTR,X
        STA     PTR
        LDA     (PTR),Y
        PHA             ; save the value to retrieve later
* Adjust Y for printing coordinates
        TYA
        SEC
        SBC     TEMP    ; adjust printing position to destination
        TAY             ; transfer destination to Y register
* Copy screen value
        PLA             ; retrieve value to print
        JSR     PRINT   ; print
* Reset Y for retrieving coordinates
        TYA
        CLC
        ADC    TEMP     ; adjust retrieving position to source
        TAY             ; transfer source to Y register
* Decrease innermost copying loop
        DEX
        BCS     COPYLP  ; jump if X is still positive
* Increase outermost loop
        INY
        TYA             ; transfer to A to check #columns overflow
        SEC
        SBC     #39     ; 40 columns, so minus 39 to get A=0 if need to RTS
        BEQ     RTS     ; RTS if A-39=0
        JMP     LOOP
```
