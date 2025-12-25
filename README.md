# Emacs ZMachine

A ZIL (Zork Implementation Language) engine for Emacs, enabling classic interactive fiction games written in ZIL to run natively in Emacs.

## Features

- **Complete ZIL Runtime**: Full implementation of ZIL primitives in Emacs Lisp
- **Object System**: Hash-table based object model with properties and flags
- **Verb Dispatch**: Complete verb handling system (TAKE, DROP, EXAMINE, etc.)
- **Movement System**: Room navigation with direction handling
- **I/O System**: Text output formatting with TELL, PRINT, CRLF
- **Game Flow**: Death/victory conditions (JIGS-UP, FINISH)
- **Randomness**: RANDOM, PICK-ONE, PROB functions
- **Native Emacs**: No external dependencies, pure Elisp

## Installation

### Manual

Add to your `~/.emacs.d/init.el`:

```elisp
(add-to-list 'load-path "<PATH TO>/emacs-zmachine/elisp")
(require 'zil-core)
```

### Via ELPA (Planned)

```elisp
M-x package-install RET emacs-zmachine RET
```

## Usage

The engine provides a complete ZIL runtime for creating interactive fiction games.

See QUICKSTART.md for a quick introduction and examples.

## Requirements

- Emacs 27.1 or higher
- No external dependencies

## License

GPL-3.0-or-later

## See Also

- [zork-emacs](https://github.com/afeldman/zork-emacs) - Complete Zork trilogy using this engine
- [ZILF](http://zilf.io/) - ZIL compiler (for reference)
