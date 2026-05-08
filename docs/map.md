# Map

### I/O Interface

| Registers | Arguments | Return values |
| :-: | :-: | :-: |
| **A** | Int (displacement quantity) | *garbage data* |
| **X** | *any* | *garbage data* |
| **Y** | *any* | *garbage data* |

### Behavior

The map subroutine is responsible for moving the map itself and displaying it on screen. It takes as input a quantity in the A register and displace the map to the left by that quantity.

Since the map's height is 12 units, the map subroutine will be provided 12 different compressed ASCII strings (one per line) instead of one single map data. The "compressed" string is made of an ASCII character followed by the number of times that character is repeated.

```txt
BD 1F A3 03 BC 20 D9 0A C0 07
      ║
      ╠══ Pointing at: A3
      ╚══ Displayed: 02 out of 03
```

A pointer will keep track of what the current character is, and a counter will count how many times that character has been drawn out of the desired repeated amount.


### Variables

| Name | Addresses | Details |
| :-: | :-: | - |
| XPOS | `$60 $61` | The X position of the player. |
| LVL[0-B] | *absolute* | The compressed level data for each line from 0 to B. |
| LVLPTR | *absolute* | A table of 12 pointers for each level line. |
| LVLCHRS | *absolute* | A table of 12 current ASCII tiles. |
| LVLQNT | *absolute* | A table of 12 ints that counts, in reverse, the remaining quantity of tiles to duplicate. |

### Modules

#### Update tile datum

The goal of this module is to extract one single tile's datum from a provided column/row (y/x). It returns the tile type and the number of times that character is repeated.

| Registers | Arguments | Return values |
| :-: | :-: | :-: |
| **A** | *any* | *garbage data* |
| **X** | Int (row/line) | *garbage data* |
| **Y** | *any* | *garbage data* |

```asm
* Multiply X and Y registers by 2
TXA
ASL             ; each pointer is 2 bytes
TAX

* Build tile pointer
LDA     LVLPTR,X
STA     PTR
LDA     LVLPTR+1,X
STA     PTR+1

* Access tile datum
LDY     #0
TXA
ASL             ; each table element is 1 byte
TAX

LDA     (PTR),Y
STA     LVLCHRS,X

INY
LDA     (PTR),Y
STA     LVLQNT,X

RTS
```

#### Increment pointer table

Each pointer of the pointers table `LVLPTR` all initially point at the beginning of each ASCII string lines. As you progress in the game, it is necessary to update the pointer's value.

| Registers | Arguments | Return values |
| :-: | :-: | :-: |
| **A** | *any* | *garbage data* |
| **X** | Int (increment) | *garbage data* |
| **Y** | Int (#nth pointer) | *garbage data* |

```asm
* Multiply X and Y registers by 2
TYA
ASL     A   ; each pointer is 2 bytes
TAY
TXA
ASL     A   ; each map datum is 2 bytes
TAX

* Add X to pointer
TXA
CLC
ADC LVLPTR,Y
STA LVLPTR,Y

LDA LVLPTR+1,Y
ADC #0      ; propagate carry
STA LVLPTR+1,Y

RTS
```
