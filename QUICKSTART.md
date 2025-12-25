# Emacs ZMachine - Quickstart Guide

Get started with the ZIL engine for Emacs in 5 minutes.

## Installation

1. Clone the repository:

```bash
cd ~/Projects/priv
git clone https://github.com/afeldman/emacs-zmachine.git
```

2. Add to your Emacs config:

```elisp
(add-to-list 'load-path "~/Projects/priv/emacs-zmachine/elisp")
(require 'zil-core)
```

## Your First ZIL Game

```elisp
;; Initialize
(zil-init)

;; Define a room
(zil-defobj 'ROOM
  :desc "Test Room"
  :action (lambda (msg)
            (when (eq msg 'M-LOOK)
              (zil-tell "You are in a test room." 'CR))))

;; Define an object
(zil-defobj 'LAMP
  :desc "brass lamp"
  :synonyms '(LAMP LANTERN)
  :flags '(TAKEBIT)
  :parent 'ROOM)

;; Set up player
(zil-defobj 'PLAYER :desc "you" :parent 'ROOM)
(zil-setg 'HERE 'ROOM)
(zil-setg 'PLAYER 'PLAYER)
```

## Playing Complete Games

Install zork-emacs:

```bash
git clone https://github.com/afeldman/zork-emacs.git
```

Then:

```elisp
(require 'zork-emacs)
M-x zork-play-game
```

## See Also

- README.md - Full API documentation
- zork-emacs - Complete game examples
