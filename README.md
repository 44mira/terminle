# TERMINLE

![image](https://github.com/user-attachments/assets/0961d67c-86f6-46d1-9959-fed722ce9ab3)

This was made as a project to practice [`zig`](https://ziglang.org/) with. So most, if not all, of the code choices made are pretty *naive*.

> Feel free to peruse the code, but do be warned, by the last commit I just gave up on maintainability to finish it before my motivation ran out.

## Building

~Currently terminle doesn't ship out its binaries (I might get on that if there's demand) but here's how you build it from source~

Here's how to build it from source:

> [!NOTE]
> This was made with Zig version `0.14.0`. As the language is not currently stable, it might be in your best interest to build with that version.
> Moreover, make sure your terminal supports [ANSI Escape Sequences](https://en.wikipedia.org/wiki/ANSI_escape_code) and displaying [UTF-8](https://en.wikipedia.org/wiki/UTF-8) characters.

```bash
git clone --depth=1 https://github.com/44mira/terminle
cd terminle

# creates the executable at ./zig-out/bin/terminle
zig build
./zig-out/bin/terminle

# builds and then runs
zig build run

# builds and runs unit tests
zig build test
```
