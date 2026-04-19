# Input capture

### I/O Interface

| Registers | Arguments | Return values |
| :-: | :-: | :-: |
| **A** | *any* | Registered keystroke OR `$FF` |
| **X** | *any* | *unmodified* |
| **Y** | *any* | *unmodified* |

### Behavior

> [!IMPORTANT]  
> Input capturing **cannot** be done through addresses `$FD6F (GETLN)` and `$FD0C (RDKEY)` — those routines **wait** for an user keyboard interaction.

Input capture subroutine **reads** at the memory address `$C000` and expects a value bigger or equal to `$80` if a keystroke gets registered. To acknowledge that the keypress has been processed, the subroutine may either read or write at `$C010` to clear the strobe. If there is no sign of a keyboard strobe, a neutral `$FF` value is returned.

### Example Implementation

```asm
INPT    LDA     $C000    ; read keystroke
        BPL     NOKEY    ; verify if A < $80

RCVD    BIT     $C010    ; clear keyboard strobe
        AND     #$7F     ; remove bit 7
        RTS              ; return with key in A

NOKEY   LDA     #$FF     ; load neutral flag
        RTS              ; return with no key
```
