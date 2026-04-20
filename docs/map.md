# Map

### I/O Interface

| Registers | Arguments | Return values |
| :-: | :-: | :-: |
| **A** | *any* | *garbage data* |
| **X** | *any* | *garbage data* |
| **Y** | *any* | *garbage data* |

### Behavior

The map subroutine is responsible for moving the map itself and trigger map-related animations. It is not responsible for displaying data on the screen, which is the pen subroutine's task. It does not take any input and does not output anything significant.

### Variables

| Name | Addresses | Details |
| :-: | :-: | - |
| XPOS | `$60 $61` | The X position of the player. |
| LMSEG | `$70 $71` | The left position of the ASCII segment of the map displayed on the screen. |
| MSEGLEN | `$72` | The max length of a ASCII segment of the map that can be displayed whole on the screen.
