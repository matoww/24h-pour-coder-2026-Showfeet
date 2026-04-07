# TIC-80 API

## Drawing
- `cls(color)`: Clear the screen with a specific color.
- `spr(id x y [colorkey=-1] [scale=1] [flip=0] [rotate=0] [w=1 h=1])`: Draw a sprite.
- `print(text x y [color=15] [fixed=false] [scale=1] [smallfont=false])`: Print text to the screen.

## Input
- `btn(id)`: Get pressed state of a button (0: up, 1: down, 2: left, 3: right, 4: z, 5: x, 6: a, 7: s). Returns true if pressed.

## Math/Logic
- `mget(x y)`: Get map tile.
- `mset(x y id)`: Set map tile.

Check the [TIC-80 Wiki](https://github.com/nesbox/TIC-80/wiki) for more.
