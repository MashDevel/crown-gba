# Crown GBA

A Game Boy Advance emulator written in [Crown](https://github.com/MashDevel/crown-lang). The emulator core, save handling, command line, and native frontends are implemented in Crown. macOS uses AppKit, Metal, and AVFAudio; Linux uses X11, PipeWire, and joystick input through the host's system libraries.

![Crown GBA emulator running a game](screenshot.png)

`src/frontend/playback` runs frames, maps controls, and coordinates playback. `src/platform` contains the macOS, Linux, and Bedrock system bindings used by that frontend.

The included `roms/circuit-breaker.gba` is an original game, Circuit Breaker. No commercial game ROM or GBA BIOS is included. Bring your own legally obtained games and BIOS files.

## Set up

Install Crown revision `3345dc0e998d` or later, with named toolchain-library support, following the [Crown setup instructions](https://github.com/MashDevel/crown-lang#start). The initial bootstrap compiler must rebuild that checkout before it can consume this manifest.

For example, run these commands from any working directory:

```sh
git clone https://github.com/MashDevel/crown-lang.git crown-lang
sh crown-lang/bootstrap/install
export PATH="$PWD/crown-lang/bootstrap:$PATH"
crown --version
git clone https://github.com/MashDevel/crown-gba.git gba
cd gba
```

The installer configures future shells; the `export` above enables Crown in the current shell.

Crown and GBA can live in separate locations. GBA declares `source = "src"` and selects the bundled `platform` and `integrations` libraries by name. The standard library is automatic. Its test runner selects the bundled `toolchain` library. No manifest refers to Crown's internal source directories.

Then, in `gba`, build and play Circuit Breaker:

```sh
crown run . -- roms/circuit-breaker.gba
```

Pass a cartridge path to play another game:

```sh
crown run . -- path/to/game.gba
```

`crown run` builds the project before launching it. The compiler supplies the standard library from its selected installation. The executable is written to `target/debug/gba_crown`.

The macOS frontend presents a 240×160 framebuffer in a 720×480 window with nearest-neighbor scaling. The keyboard controls are arrows for the directional pad, Z for A, X for B, Backspace for Select, Return for Start, A for L, S for R, and Escape to quit. Save-backed cartridges write a `.sav` file beside the ROM when the window closes normally.

## BIOS and headless use

An optional BIOS path may follow the ROM. With a BIOS, execution starts at the ARM reset vector; without one, the emulator uses direct boot and its HLE BIOS implementation. The HLE implementation does not cover every BIOS call, and game compatibility is incomplete.

```sh
crown run . -- path/to/game.gba --headless 60
crown run . -- path/to/game.gba --steps 1000000
crown run . -- path/to/game.gba --headless 60 --screenshot frame.bmp
crown run . -- path/to/game.gba path/to/gba_bios.bin --headless 60
```

Only one execution mode may be selected. `--screenshot` writes the last frame as a 240×160, 24-bit BMP. The older `screenshot frame.bmp` form is also accepted.

## Test

```sh
crown test . --filter headless
```

The project test suite builds the emulator, runs CPU and frame fixtures, checks screenshots and command-line failures, and verifies the macOS clock binding. On a logged-in macOS desktop, run `crown test .` to include the native Metal drawable memory check. Crown's `check .` type-checks the emulator; `test .` executes its project tests. For manual playback QA, play Circuit Breaker for at least 30 seconds and check movement, sprites, sound, and normal window close. Repeat with another cartridge and confirm save persistence if it uses backup memory.

The ROM in `roms/` matches the build from the separate, original `projects/circuit-breaker` workspace project (SHA-256 `d27c606729141ca009bcfb51e37acc061775163c6c248342ee1acf3d582b0f57`). The small ROMs in `tests/fixtures` are generated from the adjacent assembly fixtures.

## Quality checks

The [Test workflow](.github/workflows/test.yml) runs on every push, pull request, manual dispatch, and weekly schedule. It checks x86-64 Linux and both macOS architectures using the Crown revision pinned in the workflow. It checks formatting, types, structural limits, duplication, functional tests, and coverage. The workflow keeps running independent checks after a failure and uploads reports and test diagnostics for each host.

`Crown.toml` sets the same structural and formatting limits as Crown: 300 code lines per file, 60 per function, cyclomatic complexity 10, cognitive complexity 15, nesting depth 4, and 5 parameters. Duplication must stay at or below 3%. Both line and branch coverage must reach 95% in every reported source package; a workspace average cannot satisfy the gate.

Run the checks from `gba`:

```sh
mkdir -p target/quality
crown fmt src tests --check
crown lint . --output target/quality/app.json
crown lint tests --output target/quality/suite.json
crown lint tests/core --output target/quality/core.json
crown lint tests/validation --output target/quality/validation.json
crown duplication /path/to/workspace --output target/quality/duplication.json
crown test . --filter headless --coverage target/quality/coverage
crown coverage target/quality/coverage --output target/quality/coverage.json
```

Lint each project separately because the app and test executables have different entry points and source sets. The duplication command must receive the root of your full workspace so it scans source and tests as one corpus. The CI workspace contains both GBA and its Crown toolchain checkout.

CI uses the documented headless suite because hosted runners have no interactive desktop. On a logged-in macOS desktop, omit `--filter headless` to include the native Metal drawable check. For release QA, run all quality commands, inspect every host's reports, and perform the playback and save-persistence checks above. A failed lint or coverage command must remain a failed check.

The initial release has existing structural and coverage failures. The macOS baseline has three files over the line limit and four functions over the cognitive complexity limit. Its full functional suite passes 24 checks, while GBA coverage is 82.19% of lines and 69.09% of branches. Those initial measurements compiled libraries as application sources; the current dependency model measures each project's owned sources. Formatting passes and GBA's source-and-test duplication is 1.01%, which is a project measurement rather than the required workspace result. These figures describe the initial baseline; CI reports contain the current measurements. Thresholds are enforced without waivers, so the quality workflow remains failing until the outstanding gaps are fixed.

## Linux and Steam Deck

On a supported x86-64 glibc Linux host with X11 and PipeWire, `crown run` uses the Linux frontend. The Steam Deck also reads its controller and left stick. Linux audio is resampled to 48 kHz and the frontend may skip video frames to recover from audio starvation.

To cross-compile Linux assembly on macOS and link it on the Deck:

```sh
crown compile target/gba-linux.s . --target x86_64-linux
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
