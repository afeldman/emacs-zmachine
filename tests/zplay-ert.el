;;; zplay-ert.el --- Tests für zplay -*- lexical-binding: t; -*-

(require 'ert)
(require 'zplay)

(ert-deftest zplay-args-include-width ()
  (let ((zplay-width-mode 'auto))
    (let ((args (zplay--compute-args)))
      (should (member "-w" args))
      (should (> (string-to-number (car (cdr (member "-w" args)))) 0)))))

(ert-deftest zplay-buffer-created ()
  (let ((buf (get-buffer-create "*Z-Play*")))
    (zplay--ensure-comint buf)
    (with-current-buffer buf
      (should (derived-mode-p 'comint-mode)))))

;; Hinweis: Der eigentliche Prozessstart wird nicht getestet, da dfrotz
;; extern ist. Diese Tests sichern die Argumentberechnung und Buffer-Setup.

(provide 'zplay-ert)
