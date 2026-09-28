# Crown GBA

A Game Boy Advance emulator written in [Crown](https://github.com/MashDevel/crown-lang). The emulator core, save handling, command line, and native frontends are implemented in Crown. macOS uses AppKit, Metal, and AVFAudio; Linux uses X11, PipeWire, and joystick input through the host's system libraries.

The included `roms/circuit-breaker.gba` is an original game, Circuit Breaker. No commercial game ROM or GBA BIOS is included. Bring your own legally obtained games and BIOS files.

## Set up

Clone this project and `crown-lang` as sibling directories named `gba` and `lang`:

```text
parent/
  gba/
  lang/
```

The [Crown setup instructions](https://github.com/MashDevel/crown-lang#start) cover the compiler's host requirements. In `lang`, fetch its verified bootstrap seed once:

```sh
sh bootstrap/fetch
./bootstrap/crown --version
```

Then, in `gba`, build and play Circuit Breaker:

```sh
../lang/bootstrap/crown run . -- roms/circuit-breaker.gba
```

Pass a cartridge path to play another game:

```sh
../lang/bootstrap/crown run . -- path/to/game.gba
```

`crown run` builds the project before launching it. The manifest uses the Crown standard library from the sibling `lang` checkout. The executable is written to `target/debug/gba_crown`.

The macOS frontend presents a 240×160 framebuffer in a 720×480 window with nearest-neighbor scaling. The keyboard controls are arrows for the directional pad, Z for A, X for B, Backspace for Select, Return for Start, A for L, S for R, and Escape to quit. Save-backed cartridges write a `.sav` file beside the ROM when the window closes normally.

## BIOS and headless use

An optional BIOS path may follow the ROM. With a BIOS, execution starts at the ARM reset vector; without one, the emulator uses direct boot and its HLE BIOS implementation. The HLE implementation does not cover every BIOS call, and game compatibility is incomplete.

```sh
../lang/bootstrap/crown run . -- path/to/game.gba --headless 60
../lang/bootstrap/crown run . -- path/to/game.gba --steps 1000000
../lang/bootstrap/crown run . -- path/to/game.gba --headless 60 --screenshot frame.bmp
../lang/bootstrap/crown run . -- path/to/game.gba path/to/gba_bios.bin --headless 60
```

Only one execution mode may be selected. `--screenshot` writes the last frame as a 240×160, 24-bit BMP. The older `screenshot frame.bmp` form is also accepted.

## Test

```sh
sh tests/run.sh --headless-only
```

This runs the noninteractive build, CPU and frame fixtures, core tests, screenshot checks, and command-line error checks. On macOS it also verifies the Mach-O clock binding. On a logged-in macOS desktop, `sh tests/run.sh` checks native Metal drawable memory. Crown's `check .` type-checks the emulator but does not run these checks; Crown's `test` command runs the compiler's own suite. For manual playback QA, play Circuit Breaker for at least 30 seconds and check movement, sprites, sound, and normal window close. Repeat with another cartridge and confirm save persistence if it uses backup memory.

The ROM in `roms/` matches the build from the separate, original `projects/circuit-breaker` workspace project (SHA-256 `d27c606729141ca009bcfb51e37acc061775163c6c248342ee1acf3d582b0f57`). The small ROMs in `tests/fixtures` are generated from the adjacent assembly fixtures.

## Linux and Steam Deck

On a supported x86-64 glibc Linux host with X11 and PipeWire, `crown run` uses the Linux frontend. The Steam Deck also reads its controller and left stick. Linux audio is resampled to 48 kHz and the frontend may skip video frames to recover from audio starvation.

To cross-compile Linux assembly on macOS and link it on the Deck:

```sh
../lang/bootstrap/crown compile target/gba-linux.s . --target x86_64-linux
```

Transfer the assembly to the Deck, then run:

```sh
as --fatal-warnings -o gba.o gba-linux.s
ld --fatal-warnings -o gba_crown /usr/lib/crt1.o /usr/lib/crti.o gba.o -lc -lm /usr/lib/crtn.o --dynamic-linker /lib64/ld-linux-x86-64.so.2
./gba_crown path/to/game.gba
```

The cross-link command assumes the listed glibc startup files and loader exist at those paths. Verify image, sound, controls, and save loading and writing on the target machine.

## License

MIT; see [LICENSE](LICENSE). The bundled Circuit Breaker ROM and test fixtures are included under the same license. Crown itself is a separate dependency with its own MIT license.
