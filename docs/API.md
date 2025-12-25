# ZIL Engine API Reference

Complete API documentation for the Emacs ZMachine ZIL engine.

## Table of Contents

- [Object Management](#object-management)
- [Properties & Flags](#properties--flags)
- [Movement & Location](#movement--location)
- [I/O Functions](#io-functions)
- [Control Flow](#control-flow)
- [Verb System](#verb-system)
- [Game Flow](#game-flow)
- [Utilities](#utilities)
- [Global Variables](#global-variables)

## Object Management

### `zil-defobj`

Define a new object.

```elisp
(zil-defobj ID &key parent desc synonyms adjectives flags action size ldesc fdesc)
```

**Parameters:**
- `ID` - Object identifier (symbol)
- `:parent` - Parent object ID
- `:desc` - Description string
- `:synonyms` - List of synonym words
- `:adjectives` - List of adjective words
- `:flags` - List of flag symbols
- `:action` - Action routine function
- `:size` - Object size/weight (number)
- `:ldesc` - Long description (for room listings)
- `:fdesc` - First-time description

**Example:**
```elisp
(zil-defobj 'LAMP
  :desc "brass lantern"
  :synonyms '(LAMP LANTERN LIGHT)
  :adjectives '(BRASS)
  :flags '(TAKEBIT ONBIT)
  :parent 'LIVING-ROOM
  :action 'lamp-action
  :ldesc "A brass lantern is on the ground.")
```

### `zil-object-get`

Retrieve object structure.

```elisp
(zil-object-get obj-id) → plist
```

**Returns:** Property list with `:parent`, `:desc`, `:synonyms`, `:flags`, etc.

### `zil-object-parent`

Get parent of object (synonym: `zil-loc`).

```elisp
(zil-object-parent obj-id) → parent-id
```

### `zil-object-desc`

Get description string.

```elisp
(zil-object-desc obj-id) → string
```

### `zil-object-action`

Get action routine function.

```elisp
(zil-object-action obj-id) → function
```

## Properties & Flags

### `zil-object-prop`

Get property value.

```elisp
(zil-object-prop obj-id key &optional default) → value
```

**Example:**
```elisp
(zil-object-prop 'LAMP 'fuel-level 100)  ; Get fuel level, default 100
```

### `zil-object-set-prop`

Set property value (ZIL PUTP).

```elisp
(zil-object-set-prop obj-id key value) → value
```

**Example:**
```elisp
(zil-object-set-prop 'LAMP 'fuel-level 50)
```

### `zil-fset?`

Check if flag is set (ZIL FSET?).

```elisp
(zil-fset? obj-id flag) → boolean
```

**Example:**
```elisp
(zil-fset? 'LAMP 'ONBIT)  ; Is lamp lit?
```

### `zil-fset`

Set flag (ZIL FSET).

```elisp
(zil-fset obj-id flag) → obj-id
```

**Example:**
```elisp
(zil-fset 'LAMP 'ONBIT)  ; Turn lamp on
```

### `zil-fclear`

Clear flag (ZIL FCLEAR).

```elisp
(zil-fclear obj-id flag) → obj-id
```

**Example:**
```elisp
(zil-fclear 'LAMP 'ONBIT)  ; Turn lamp off
```

## Movement & Location

### `zil-move`

Move object to new parent (ZIL MOVE).

```elisp
(zil-move obj-id new-parent) → obj-id
```

**Example:**
```elisp
(zil-move 'LAMP 'PLAYER)  ; Put lamp in inventory
```

### `zil-remove`

Remove object from world (ZIL REMOVE).

```elisp
(zil-remove obj-id) → obj-id
```

Sets parent to `nil`.

### `zil-in?`

Check if object is directly in location (ZIL IN?).

```elisp
(zil-in? obj-id parent-id) → boolean
```

**Example:**
```elisp
(zil-in? 'LAMP 'PLAYER)  ; Is lamp in inventory?
```

### `zil-loc`

Get location, optionally traversing levels up (ZIL LOC).

```elisp
(zil-loc obj-id &optional levels) → parent-id
```

**Example:**
```elisp
(zil-loc 'LAMP)     ; Direct parent
(zil-loc 'LAMP 2)   ; Parent's parent
```

### `zil-children`

Get all direct children.

```elisp
(zil-children parent-id) → list
```

**Example:**
```elisp
(zil-children 'PLAYER)  ; Get inventory
```

### `zil-first?`

Get first child (ZIL FIRST?).

```elisp
(zil-first? parent-id) → obj-id
```

### `zil-next?`

Get next sibling (ZIL NEXT?).

```elisp
(zil-next? obj-id) → obj-id
```

## I/O Functions

### `zil-tell`

Print formatted text (ZIL TELL macro).

```elisp
(zil-tell &rest args)
```

**Special arguments:**
- `'CR` or `'CRLF` - Newline
- `'D obj` - Print object description
- `'N num` - Print number
- `'C char` - Print character
- Strings - Print as-is

**Example:**
```elisp
(zil-tell "You see a " 'D 'LAMP " here." 'CR)
(zil-tell "Score: " 'N 42 'CR)
```

### `zil-print`

Print value (ZIL PRINT).

```elisp
(zil-print text) → text
```

### `zil-printi`

Print string (ZIL PRINTI).

```elisp
(zil-printi text) → text
```

### `zil-printd`

Print object description (ZIL PRINTD).

```elisp
(zil-printd obj-id) → string
```

### `zil-printn`

Print number (ZIL PRINTN).

```elisp
(zil-printn num) → num
```

### `zil-printc`

Print character (ZIL PRINTC).

```elisp
(zil-printc char) → char
```

### `zil-crlf`

Print newline (ZIL CRLF/CR).

```elisp
(zil-crlf)
```

## Control Flow

### `zil-routine`

Define routine (ZIL ROUTINE macro).

```elisp
(zil-routine name args &rest body)
```

**Example:**
```elisp
(zil-routine lamp-action ()
  (cond
   ((zil-verb? 'TAKE)
    (zil-tell "Taken." 'CR))))
```

### `zil-cond`

Conditional (ZIL COND).

```elisp
(zil-cond &rest clauses)
```

Same as Elisp `cond`.

### `zil-equal?`

Equality check (ZIL EQUAL?).

```elisp
(zil-equal? &rest args) → boolean
```

**Example:**
```elisp
(zil-equal? 'LAMP (zil-getg 'PRSO))
```

### `zil-rtrue`

Return true from routine (ZIL RTRUE).

```elisp
(zil-rtrue)
```

### `zil-rfalse`

Return false from routine (ZIL RFALSE).

```elisp
(zil-rfalse)
```

### `zil-return`

Return value from routine (ZIL RETURN).

```elisp
(zil-return value)
```

## Verb System

### `zil-verb-register`

Register verb action constant.

```elisp
(zil-verb-register name value)
```

**Example:**
```elisp
(zil-verb-register 'TAKE :take)
```

### `zil-verb?`

Check if current action matches verbs (ZIL VERB?).

```elisp
(zil-verb? &rest verbs) → boolean
```

**Example:**
```elisp
(zil-verb? 'TAKE 'GET)  ; Is action TAKE or GET?
```

### `zil-prso?`

Check if direct object matches (ZIL PRSO?).

```elisp
(zil-prso? &rest objects) → boolean
```

### `zil-prsi?`

Check if indirect object matches (ZIL PRSI?).

```elisp
(zil-prsi? &rest objects) → boolean
```

### `zil-room?`

Check if current room matches (ZIL ROOM?).

```elisp
(zil-room? &rest rooms) → boolean
```

## Game Flow

### `zil-goto`

Move player to room (ZIL GOTO).

```elisp
(zil-goto room-id) → room-id
```

Calls room's M-LOOK action.

### `zil-jigs-up`

Player death (ZIL JIGS-UP).

```elisp
(zil-jigs-up message)
```

**Example:**
```elisp
(zil-jigs-up "The troll kills you.")
```

### `zil-finish`

Player victory (ZIL FINISH).

```elisp
(zil-finish)
```

## Utilities

### `zil-random`

Random number 1..N (ZIL RANDOM).

```elisp
(zil-random n) → number
```

**Example:**
```elisp
(zil-random 6)  ; Roll 1d6
```

### `zil-pick-one`

Pick random element (ZIL PICK-ONE).

```elisp
(zil-pick-one table) → element
```

**Example:**
```elisp
(zil-pick-one ["heads" "tails"])
```

### `zil-prob`

Probability check (ZIL PROB).

```elisp
(zil-prob base) → boolean
```

**Example:**
```elisp
(zil-prob 50)  ; 50% chance
```

### `zil-yes?`

Yes/no prompt (ZIL YES?).

```elisp
(zil-yes?) → boolean
```

### `zil-empty?`

Check if empty/nil (ZIL EMPTY?).

```elisp
(zil-empty? obj) → boolean
```

### `zil-g?`

Greater than (ZIL G?).

```elisp
(zil-g? a b) → boolean
```

### `zil-l?`

Less than (ZIL L?).

```elisp
(zil-l? a b) → boolean
```

### `zil-0?`

Zero check (ZIL 0?).

```elisp
(zil-0? n) → boolean
```

## Global Variables

Access with `zil-setg` and `zil-getg`.

### Parser Globals

- `PRSO` - Direct object
- `PRSI` - Indirect object  
- `PRSA` - Current verb action
- `WINNER` - Current actor
- `HERE` - Current room
- `PLAYER` - Player object

### Game State

- `SCORE` - Game score
- `MOVES` - Move counter
- `VERBOSE` - Verbose mode
- `SUPER-BRIEF` - Super-brief mode
- `WON-FLAG` - Victory flag
- `DEAD-FLAG` - Death flag

### Parser State

- `P-CONT` - Parser continuation
- `QUOTE-FLAG` - Quote flag
- `P-OFLAG` - Parser object flag

### Inventory

- `LOAD-MAX` - Max inventory weight
- `LOAD-ALLOWED` - Allowed inventory weight

## Examples

### Complete Object Definition

```elisp
(zil-defobj 'SWORD
  :desc "elvish sword"
  :synonyms '(SWORD BLADE WEAPON)
  :adjectives '(ELVISH ELF ANCIENT)
  :flags '(TAKEBIT WEAPONBIT)
  :parent 'TROPHY-CASE
  :size 10
  :action (lambda ()
            (cond
             ((zil-verb? 'EXAMINE)
              (zil-tell "The sword glows with a faint light." 'CR))
             ((zil-verb? 'TAKE)
              (zil-move 'SWORD 'PLAYER)
              (zil-tell "Taken." 'CR))))
  :ldesc "An elvish sword hangs on the wall.")
```

### Room Definition

```elisp
(zil-defobj 'LIVING-ROOM
  :desc "Living Room"
  :action (lambda (msg)
            (when (eq msg 'M-LOOK)
              (zil-tell "Living Room" 'CR
                        "You are in the living room. There is a trophy case here." 'CR))))
```

### Combat Example

```elisp
(defun attack-troll ()
  (if (zil-in? 'SWORD 'PLAYER)
      (if (zil-prob 60)
          (progn
            (zil-tell "You defeat the troll!" 'CR)
            (zil-remove 'TROLL)
            (zil-setg 'SCORE (+ (zil-getg 'SCORE) 10)))
        (zil-tell "The troll dodges!" 'CR))
    (zil-jigs-up "The troll kills you with his axe.")))
```

## See Also

- [README.md](../README.md) - Main documentation
- [QUICKSTART.md](../QUICKSTART.md) - Quick start guide
- [zork-emacs](https://github.com/afeldman/zork-emacs) - Example games
