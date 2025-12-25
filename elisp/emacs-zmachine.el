;;; emacs-zmachine.el --- Z-Machine interpreter for Emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Free Software Foundation, Inc.

;; Author: Anton Feldmann <anton.feldmann@example.com>
;; Maintainer: Anton Feldmann <anton.feldmann@example.com>
;; URL: https://github.com/afeldman/emacs-zmachine
;; Version: 0.2.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: games, interpreter, zil, zork
;; License: GPL-3.0-or-later

;; This file is part of emacs-zmachine.

;; emacs-zmachine is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; emacs-zmachine is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with emacs-zmachine.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a complete ZIL (Zork Implementation Language)
;; runtime engine for Emacs, enabling native implementation of classic
;; text adventure games like Zork I, II, and III.
;;
;; The engine implements core ZIL primitives including:
;; - Object system (parent/child relationships, properties, flags)
;; - Verb dispatch and command parsing
;; - Movement and location tracking
;; - Text output and formatting
;; - Game flow control
;; - Randomness and probability
;;
;; For detailed API documentation, see docs/API.md in the repository.

;;; Code:

(require 'zil-core)

(provide 'emacs-zmachine)
;;; emacs-zmachine.el ends here
