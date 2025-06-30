# DOS-8

DOS-8 is a small fantasy operating system built for the [PICO-8](https://www.lexaloffle.com/pico-8.php) virtual console.
It simulates a DOS-style command line where you can browse a simple file system and run programs.

## Features
- File browsing, directory changing, and command execution
- A BBS program that sends and receives messages through JavaScript GPIO hooks

The project forms the basis of a retro website experiment. Users are greeted with a 90s-inspired "desk" image and can click the computer to access DOS-8.

## Running the demo
Open `index.html` in a modern web browser. It loads the PICO-8 runtime (`pico-8-lib/pico-8.js`) and the compiled cart (`index.js`).
The page also includes helper scripts that allow the cart to exchange data via the GPIO interface:

- `script/pico8-gpio-listener.js` – exposes GPIO pins in JavaScript.
- `script/dos8-gpio-lib.js` – handles data transfer and interprets messages.
- `script/dos8-gd.js` – communicates with Google Sheets to store BBS posts.

Once the page loads, click the canvas to start DOS-8. From the command prompt, you can use commands like `dir`, `cd`, `load`, `run`, `help`, or invoke the BBS with `bbs list`.

## Development
The source Lua files live under `src/lib/`, and the main PICO-8 cart is `src/carts/picos.p8`.
Any modifications to these files require exporting a new `index.js` via the PICO-8 export process.

This repository intentionally excludes `node_modules` and other build artifacts from version control.
