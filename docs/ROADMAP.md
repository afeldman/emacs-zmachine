# Roadmap: emacs-zmachine

## Phase A (fertigzustellen)
- dfrotz Play‑Mode im Emacs: comint‑Wrapper, Flags, Breitensteuerung
- README, LICENSE, minimale Tests

## Phase B (Native VM, V3 zuerst)
- Loader: Header lesen (big‑endian), Start‑PC, Speichergrenzen
- Z‑Strings: A0/A1/A2, Abkürzungen, ZSCII
- Opcodes: 0OP/1OP Grundbefehle, Operandendekodierung, Branching
- Stack/Routinen: Call/Return, Locals, Globals
- I/O: Ausgabe, Einfach‑Input, Transcript

## Phase C (Komfort & Persistenz)
- Save/Load (Quetzal)
- Statuszeile, History, Keybindings
- Tests (ERT) für Decoder/Opcode‑Dispatch
