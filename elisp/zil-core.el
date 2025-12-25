;;; zil-core.el --- ZIL (Zork Implementation Language) Core Engine -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Free Software Foundation, Inc.
;; License: GPL-3.0-or-later

;;; Commentary:

;; ZIL Core Engine - Complete ZIL implementation in Emacs Lisp.
;; Implements all ZIL primitives needed for Zork I, II, and III:
;;
;; - Object system (OBJECT, IN, LOC, FIRST?, NEXT?)
;; - Properties and attributes (FLAGS, DESC, SYNONYM, etc.)
;; - Global variables (PRSO, PRSI, WINNER, HERE, SCORE, etc.)
;; - Control flow (ROUTINE, COND, EQUAL?, VERB?, ROOM?)
;; - I/O (TELL, PRINTI, PRINTD, CRLF, READ)
;; - Flags (FSET?, FCLEAR, BSET, BCLEAR)
;; - Movement (MOVE, GOTO, REMOVE)
;; - Randomness (RANDOM, PICK-ONE, PROB)
;; - Death/Win (JIGS-UP, FINISH)

;;; Code:

(require 'cl-lib)

;;; ========== DATA STRUCTURES ==========

(defvar zil-objects (make-hash-table :test 'eq)
  "Object database: ID → (:parent ID :props PLIST :flags LIST :desc STRING :synonyms LIST).")

(defvar zil-globals (make-hash-table :test 'eq)
  "Global variables (SETG/GETG).")

(defvar zil-routines (make-hash-table :test 'eq)
  "Routine functions (ROUTINE).")

(defvar zil-verbs (make-hash-table :test 'eq)
  "Verb action constants (V?TAKE, V?DROP, etc.).")

(defvar zil-directions '(NORTH SOUTH EAST WEST NE NW SE SW UP DOWN IN OUT LAND)
  "Valid movement directions.")

(defvar zil-output-buffer "*ZIL Game*"
  "Buffer for game text output.")

(defvar zil-dead nil
  "Player death flag.")

(defvar zil-won nil
  "Player win flag.")

;;; ========== GLOBAL VARIABLES (Game State) ==========

(defun zil-init-globals ()
  "Initialize core ZIL global variables."
  ;; Parser globals
  (zil-setg 'PRSO nil)         ; Direct object
  (zil-setg 'PRSI nil)         ; Indirect object
  (zil-setg 'PRSA nil)         ; Current verb action
  (zil-setg 'WINNER 'PLAYER)   ; Current actor
  (zil-setg 'HERE nil)         ; Current room
  (zil-setg 'PLAYER 'PLAYER)   ; Player object
  
  ;; Game state
  (zil-setg 'SCORE 0)
  (zil-setg 'MOVES 0)
  (zil-setg 'VERBOSE nil)
  (zil-setg 'SUPER-BRIEF nil)
  (zil-setg 'WON-FLAG nil)
  (zil-setg 'DEAD-FLAG nil)
  
  ;; Parser state
  (zil-setg 'P-CONT nil)
  (zil-setg 'QUOTE-FLAG nil)
  (zil-setg 'P-OFLAG nil)
  
  ;; Inventory limits
  (zil-setg 'LOAD-MAX 100)
  (zil-setg 'LOAD-ALLOWED 100))

(defun zil-setg (name value)
  "Set global variable NAME to VALUE (ZIL SETG)."
  (puthash name value zil-globals)
  value)

(defun zil-getg (name)
  "Get global variable NAME (ZIL GETG)."
  (gethash name zil-globals))

;;; ========== OBJECT SYSTEM ==========

(cl-defun zil-defobj (id &key parent desc synonyms adjectives flags action size ldesc fdesc)
  "Define ZIL object with all properties.
ID: Object identifier (symbol)
PARENT: Parent object ID
DESC: Description string
SYNONYMS: List of synonym atoms
ADJECTIVES: List of adjective atoms
FLAGS: List of flag symbols (TAKEBIT, CONTBIT, etc.)
ACTION: Action routine function
SIZE: Object size/weight
LDESC: Long description
FDESC: First description"
  (puthash id
           (list :parent parent
                 :desc desc
                 :synonyms synonyms
                 :adjectives adjectives
                 :flags (or flags '())
                 :action action
                 :size (or size 0)
                 :ldesc ldesc
                 :fdesc fdesc
                 :props (make-hash-table :test 'eq))
           zil-objects)
  id)

(defun zil-object-get (obj-id)
  "Retrieve object structure for OBJ-ID."
  (gethash obj-id zil-objects))

(defun zil-object-parent (obj-id)
  "Get parent of object OBJ-ID (ZIL LOC)."
  (when-let ((obj (zil-object-get obj-id)))
    (plist-get obj :parent)))

(defun zil-object-desc (obj-id)
  "Get description of object OBJ-ID."
  (when-let ((obj (zil-object-get obj-id)))
    (plist-get obj :desc)))

(defun zil-object-flags (obj-id)
  "Get flags list for object OBJ-ID."
  (when-let ((obj (zil-object-get obj-id)))
    (plist-get obj :flags)))

(defun zil-object-action (obj-id)
  "Get action routine for object OBJ-ID."
  (when-let ((obj (zil-object-get obj-id)))
    (plist-get obj :action)))

(defun zil-object-prop (obj-id key &optional default)
  "Get property KEY from object OBJ-ID."
  (when-let* ((obj (zil-object-get obj-id))
              (props (plist-get obj :props)))
    (gethash key props default)))

(defun zil-object-set-prop (obj-id key value)
  "Set property KEY to VALUE for object OBJ-ID (ZIL PUTP)."
  (when-let* ((obj (zil-object-get obj-id))
              (props (plist-get obj :props)))
    (puthash key value props)
    value))

;;; ========== FLAGS SYSTEM ==========

(defun zil-fset? (obj-id flag)
  "Check if FLAG is set on object OBJ-ID (ZIL FSET?)."
  (when-let ((flags (zil-object-flags obj-id)))
    (memq flag flags)))

(defun zil-fset (obj-id flag)
  "Set FLAG on object OBJ-ID (ZIL FSET)."
  (when-let ((obj (zil-object-get obj-id)))
    (let ((flags (plist-get obj :flags)))
      (unless (memq flag flags)
        (plist-put obj :flags (cons flag flags)))))
  obj-id)

(defun zil-fclear (obj-id flag)
  "Clear FLAG from object OBJ-ID (ZIL FCLEAR)."
  (when-let ((obj (zil-object-get obj-id)))
    (plist-put obj :flags (delq flag (plist-get obj :flags))))
  obj-id)

;;; ========== MOVEMENT & CONTAINMENT ==========

(defun zil-move (obj-id new-parent)
  "Move object OBJ-ID to NEW-PARENT (ZIL MOVE)."
  (when-let ((obj (zil-object-get obj-id)))
    (plist-put obj :parent new-parent))
  obj-id)

(defun zil-remove (obj-id)
  "Remove object OBJ-ID from world (ZIL REMOVE)."
  (zil-move obj-id nil))

(defun zil-in? (obj-id parent-id)
  "Check if OBJ-ID is directly in PARENT-ID (ZIL IN?)."
  (equal (zil-object-parent obj-id) parent-id))

(defun zil-loc (obj-id &optional levels)
  "Get location of OBJ-ID, optionally traversing LEVELS up (ZIL LOC)."
  (let ((parent (zil-object-parent obj-id)))
    (if (and levels (> levels 1) parent)
        (zil-loc parent (1- levels))
      parent)))

(defun zil-children (parent-id)
  "Get all direct children of PARENT-ID."
  (let (children)
    (maphash (lambda (id obj)
               (when (equal (plist-get obj :parent) parent-id)
                 (push id children)))
             zil-objects)
    (nreverse children)))

(defun zil-first? (parent-id)
  "Get first child of PARENT-ID (ZIL FIRST?)."
  (car (zil-children parent-id)))

(defun zil-next? (obj-id)
  "Get next sibling of OBJ-ID (ZIL NEXT?)."
  (when-let* ((parent (zil-object-parent obj-id))
              (siblings (zil-children parent))
              (pos (cl-position obj-id siblings)))
    (nth (1+ pos) siblings)))

(defun zil-visible? (obj-id location)
  "Check if OBJ-ID is visible from LOCATION.
Objects are visible if:
  1. They are directly in LOCATION, OR
  2. They are in a container in LOCATION and container has OPENBIT set, OR
  3. They are in PLAYER's inventory (LOCATION is PLAYER's parent)"
  (let ((parent (zil-object-parent obj-id)))
    (cond
     ;; Directly in location
     ((eq parent location) t)
     ;; In a container that's in location and container is open
     ((and parent
           (eq (zil-object-parent parent) location)
           (or (zil-fset? parent 'OPENBIT)
               (zil-fset? parent 'TRANSBIT))) t)
     ;; Otherwise not visible
     (t nil))))

;;; ========== I/O SYSTEM ==========

(defun zil-print (text)
  "Print TEXT to game buffer (ZIL PRINT)."
  (with-current-buffer (get-buffer-create zil-output-buffer)
    (let ((was-at-end (= (point) (point-max))))
      (save-excursion
        (goto-char (point-max))
        (let ((inhibit-read-only t))
          (insert (format "%s" text))))
      (when was-at-end
        (goto-char (point-max)))))
  text)

(defun zil-printi (text)
  "Print string TEXT (ZIL PRINTI)."
  (zil-print text))

(defun zil-printd (obj-id)
  "Print description of object OBJ-ID (ZIL PRINTD)."
  (zil-print (or (zil-object-desc obj-id) (symbol-name obj-id))))

(defun zil-printn (num)
  "Print number NUM (ZIL PRINTN)."
  (zil-print (number-to-string num)))

(defun zil-printc (char)
  "Print character CHAR (ZIL PRINTC)."
  (zil-print (char-to-string char)))

(defun zil-crlf ()
  "Print newline (ZIL CRLF / CR)."
  (zil-print "\n"))

(defun zil-tell (&rest args)
  "Print formatted text (ZIL TELL macro).
Supports: strings, 'D obj (desc), 'N num (number), 'CR (newline)."
  (let ((i 0)
        (len (length args)))
    (while (< i len)
      (let ((arg (nth i args)))
        (cond
         ;; CR/CRLF
         ((memq arg '(CR CRLF))
          (zil-crlf))
         
         ;; 'D obj -> print description
         ((eq arg 'D)
          (setq i (1+ i))
          (zil-printd (nth i args)))
         
         ;; 'N num -> print number
         ((eq arg 'N)
          (setq i (1+ i))
          (zil-printn (nth i args)))
         
         ;; 'C char -> print character
         ((eq arg 'C)
          (setq i (1+ i))
          (zil-printc (nth i args)))
         
         ;; String
         ((stringp arg)
          (zil-printi arg))
         
         ;; Default: print as-is
         (t
          (zil-print arg))))
      (setq i (1+ i)))))

;;; ========== CONTROL FLOW ==========

(defmacro zil-routine (name args &rest body)
  "Define ZIL routine (ZIL ROUTINE).
NAME: Routine name (symbol)
ARGS: Argument list
BODY: Routine body"
  `(progn
     (defun ,name ,args
       ,@body)
     (puthash ',name #',name zil-routines)
     ',name))

(defun zil-rtrue ()
  "Return true from routine (ZIL RTRUE)."
  (throw 'zil-return t))

(defun zil-rfalse ()
  "Return false from routine (ZIL RFALSE)."
  (throw 'zil-return nil))

(defun zil-rfatal ()
  "Fatal error return (ZIL RFATAL)."
  (throw 'zil-return 'FATAL))

(defun zil-return (value)
  "Return VALUE from routine (ZIL RETURN)."
  (throw 'zil-return value))

(defmacro zil-cond (&rest clauses)
  "ZIL COND - like Elisp cond but with ZIL semantics."
  `(cond ,@clauses))

(defun zil-equal? (&rest args)
  "ZIL EQUAL? - check if all args are equal."
  (if (< (length args) 2)
      t
    (let ((first (car args))
          (rest (cdr args)))
      (cl-every (lambda (x) (equal x first)) rest))))

;;; ========== VERB SYSTEM ==========

(defun zil-verb-register (name value)
  "Register verb action constant (e.g., V?TAKE = :take)."
  (puthash name value zil-verbs))

(defun zil-verb? (&rest verbs)
  "Check if current action (PRSA) matches any of VERBS (ZIL VERB?)."
  (let ((prsa (zil-getg 'PRSA)))
    (cl-some (lambda (v)
               (equal prsa (gethash v zil-verbs v)))
             verbs)))

(defun zil-prso? (&rest objects)
  "Check if PRSO matches any of OBJECTS (ZIL PRSO?)."
  (let ((prso (zil-getg 'PRSO)))
    (memq prso objects)))

(defun zil-prsi? (&rest objects)
  "Check if PRSI matches any of OBJECTS (ZIL PRSI?)."
  (let ((prsi (zil-getg 'PRSI)))
    (memq prsi objects)))

(defun zil-room? (&rest rooms)
  "Check if HERE matches any of ROOMS (ZIL ROOM?)."
  (let ((here (zil-getg 'HERE)))
    (memq here rooms)))

;;; ========== RANDOMNESS ==========

(defun zil-random (n)
  "Return random number 1..N (ZIL RANDOM)."
  (if (> n 0)
      (1+ (random n))
    (- (1+ (random (- n))))))

(defun zil-pick-one (table)
  "Pick random element from TABLE (ZIL PICK-ONE).
TABLE should be a list/vector of strings."
  (when (and table (> (length table) 0))
    (elt table (random (length table)))))

(defun zil-prob (base)
  "Return true with BASE% probability (ZIL PROB)."
  (< (random 100) base))

;;; ========== GAME FLOW ==========

(defun zil-jigs-up (message)
  "Player death (ZIL JIGS-UP).
MESSAGE: Death message string."
  (zil-tell message 'CR 'CR)
  (zil-tell "    ****  You have died  ****" 'CR 'CR)
  (zil-setg 'DEAD-FLAG t)
  (setq zil-dead t)
  (throw 'zil-game-over 'DEAD))

(defun zil-finish ()
  "Player victory (ZIL FINISH)."
  (zil-tell "    ****  You have won  ****" 'CR 'CR)
  (zil-setg 'WON-FLAG t)
  (setq zil-won t)
  (throw 'zil-game-over 'WON))

;;; ========== GOTO (Room Movement) ==========

(defun zil-goto (room-id)
  "Move player to ROOM-ID (ZIL GOTO)."
  (zil-setg 'HERE room-id)
  (zil-move (zil-getg 'PLAYER) room-id)
  ;; Call room's look action
  (when-let ((action (zil-object-action room-id)))
    (funcall action 'M-LOOK))
  room-id)

;;; ========== UTILITY ==========

(defun zil-empty? (obj)
  "Check if OBJ is empty/nil (ZIL EMPTY?)."
  (or (null obj)
      (and (listp obj) (null obj))
      (and (stringp obj) (string-empty-p obj))))

(defun zil-g? (a b)
  "Greater than (ZIL G?)."
  (> a b))

(defun zil-l? (a b)
  "Less than (ZIL L?)."
  (< a b))

(defun zil-0? (n)
  "Zero check (ZIL 0?)."
  (zerop n))

(defun zil-yes? ()
  "Read yes/no answer (ZIL YES?)."
  (let ((answer (read-string ">>> ")))
    (string-match-p "^[yY]" answer)))

;;; ========== INITIALIZATION ==========

(defun zil-init ()
  "Initialize ZIL engine."
  (clrhash zil-objects)
  (clrhash zil-globals)
  (clrhash zil-routines)
  (clrhash zil-verbs)
  (zil-init-globals)
  (setq zil-dead nil)
  (setq zil-won nil)
  
  ;; Create output buffer with zil-mode
  (zil-setup-buffer)
  
  ;; Register standard verbs
  (zil-verb-register 'TAKE :take)
  (zil-verb-register 'DROP :drop)
  (zil-verb-register 'LOOK :look)
  (zil-verb-register 'EXAMINE :examine)
  (zil-verb-register 'INVENTORY :inventory)
  (zil-verb-register 'GO :go)
  (zil-verb-register 'OPEN :open)
  (zil-verb-register 'CLOSE :close)
  (zil-verb-register 'READ :read)
  (zil-verb-register 'MOVE :move)
  (zil-verb-register 'LIFT :lift)
  (zil-verb-register 'RAISE :raise)
  (zil-verb-register 'TURN :turn)
  (zil-verb-register 'ON :on)
  (zil-verb-register 'TURNOFF :turnoff)
  (zil-verb-register 'OFF :off)
  (zil-verb-register 'LIGHT :light)
  (zil-verb-register 'ATTACK :attack)
  (zil-verb-register 'KILL :kill))

;;; ========== ZIL GAME MODE ==========

(defvar zil-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") 'zil-send-input)
    map)
  "Keymap for ZIL game mode.")

(defvar zil-input-start-marker nil
  "Marker for start of input area.")

(defvar zil-command-callback nil
  "Callback function to process commands.")

(define-derived-mode zil-mode fundamental-mode "ZIL"
  "Major mode for ZIL text adventure games.

\\{zil-mode-map}"
  (setq-local zil-input-start-marker (point-marker))
  (set-marker-insertion-type zil-input-start-marker nil))

(defun zil-send-input ()
  "Send the current input line to the game."
  (interactive)
  (when (>= (point) zil-input-start-marker)
    (let ((input (buffer-substring-no-properties zil-input-start-marker (point-max))))
      (goto-char (point-max))
      (insert "\n")
      (when zil-command-callback
        (funcall zil-command-callback input))
      (setq zil-input-start-marker (point-marker))
      (set-marker-insertion-type zil-input-start-marker nil))))

(defun zil-setup-buffer ()
  "Setup the ZIL game buffer with proper mode."
  (with-current-buffer (get-buffer-create zil-output-buffer)
    (unless (eq major-mode 'zil-mode)
      (zil-mode)
      (setq buffer-read-only nil))
    (current-buffer)))

(provide 'zil-core)
;;; zil-core.el ends here
