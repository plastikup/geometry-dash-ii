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
| VPOS | `$80` | The vertical position of the player, times 8. |
| VVELPOS | `$81` | The POSITIVE vertical velocity of the player, times 8. |
| VVELNEG | `$81` | The NEGATIVE vertical velocity of the player, times 8. |
| PHYSDELAY | `$82` | The delay between physics frames, relative to the game's framerate. |
| ISAIR | `$83` | Boolean modified elsewhere that holds the truth whether the player is in the air or on the ground |

### Vertical velocity positive-negative behavior

The double positive-negative velocity variable is meant to be an alternative using signed numbers, which is used nowhere at all in the game. Jump inputs get translated into the positive velocity, whereas gravity is applied through the negative velocity.

When `ISAIR` is false **AND** the negative velocity is greater than the positive one, ground collision is applied and both velocities are nullified.
