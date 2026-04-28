# Input capture

### I/O Interface

| Registers | Arguments | Return values |
| :-: | :-: | :-: |
| **A** | *any* | Registered keystroke OR `$00` |
| **X** | *any* | *unmodified* |
| **Y** | *any* | *unmodified* |

### Behavior

> [!IMPORTANT]  
> Input capturing **cannot** be done through addresses `$FD6F (GETLN)` and `$FD0C (RDKEY)` — those routines **wait** for an user keyboard interaction.

Input capture subroutine **reads** at the memory address `$C000` and expects a value bigger or equal to `$80` if a keystroke gets registered. To acknowledge that the keypress has been processed, the subroutine may either read or write at `$C010` to clear the strobe. If there is no sign of a keyboard strobe, a neutral `$00` value is returned.

### Implementation

```asm
INPUT   LDA        $C000   ; read keystroke
        BPL        NOKEY   ; verify if A < $80
* Received positive keypress
        BIT        $C010   ; clear keyboard strobe
        RTS                ; return with key in A
* No positive keypress
NOKEY   LDA        #$00    ; load neutral $00 flag
        RTS                ; return with no key
```
