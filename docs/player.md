# Player

### I/O Interface

| Registers | Arguments | Return values |
| :-: | :-: | :-: |
| **A** | Boolean (jump) | Boolean (end game) |
| **X** | *any* | *unmodified* |
| **Y** | *any* | *unmodified* |

### Behavior

The player subroutine is responsible for the character's physics. When called, it animates the player with a provided boolean jump argument, apply acceleration physics (usually gravity), and verifies for any illegal collisions with the map (horizontal collision). In the event such game-ending collision occurs, the player subroutine will return `$FF` (instead of the usual `$00` flag).

### Variables

| Name | Addresses | Details |
| :-: | :-: | - |
| XPOS | `$60 $61` | The X position of the player. |
| YPOS | `$62` | The Y position of the player. Unlike XPOS, YPOS only needs to be one octet long because the map is not vertically scrollable. |
| YVEL | `$63` | The Y velocity of the player. A value of +/-128 travels at 1 block per frame. |
| YACC | `$64` | The Y acceleration of the player. Usually the gravity. A value of +/-128 speeds up at 1 block per frame. |
