;;;;添加Emacs搜索路径
;;;(add-to-list 'load_path "~/.emacs.d")

;; Set the debug option when there is trouble...
;;(setq debug-on-error t)

(require 'cl) ;; turn on Common Lisp support
(defvar *emacs-load-start* (current-time))

;;-----------------------------------------------------------------

;;-----------------------------------------------------------------
; Color and Fonts.
;;-----------------------------------------------------------------


(require 'font-lock)
(if (fboundp 'global-font-lock-mode)
    (global-font-lock-mode t))        ; By default turn on colorization.
(setq font-lock-mode-maximum-decoration t)
;(setq frame-background-mode 'dark)

(prefer-coding-system 'utf-8);; Enable UTF-8 by default
;; Emacs < 23 sometimes require setting these directly.
;; Now they cause more problems than they solve.
;; (setq locale-coding-system 'utf-8)
;; (set-terminal-coding-system 'utf-8)
;; (set-keyboard-coding-system 'utf-8)
;; (set-selection-coding-system 'utf-8)

;;If images are supported than display them when visiting them
(if (fboundp 'auto-image-file-mode)
   (auto-image-file-mode 1))
;;-----------------------------------------------------------------

;;-----------------------------------------------------------
;;      SERVER MODE
;;-----------------------------------------------------------
;; FIXME: I never got this to work correctly.
;;
;; Using server mode means that after starting emacs, eg from an
;; icon, there is an always-running process, which handles editing
;; requests.
;;
;; Client:
;;   alias emacs='emacsclient --alternate-editor emacs '
;; in $HOME/.bashrc. You can get this startup file re-read without
;; re-starting a terminal window, by a command such as
;;    % . .bashrc
;;

;; A function to wrap up editing of a buffer, saving it first if edited.
;; Below, this is attached to a function key. This function is only useful
;; if you are using server mode.
;;(defun wrap-up ()
;;  (interactive)
;;  (save-buffer)
;;  (server-edit))
;; (add-hook 'server-done-hook (lambda nil (kill-buffer nil)) t)
;; (add-hook 'server-visit-hook 'raise-frame t)


;; Make shifted direction keys work on the Linux console or in an xterm
 (when (member (getenv "TERM") '("linux" "xterm"))
   (dolist (prefix '("\eO" "\eO1;" "\e[1;"))
     (dolist (m '(("2" . "S-") ("3" . "M-") ("4" . "S-M-") ("5" . "C-")
                  ("6" . "S-C-") ("7" . "C-M-") ("8" . "S-C-M-")))
       (dolist (k '(("A" . "<up>") ("B" . "<down>") ("C" . "<right>")
                    ("D" . "<left>") ("H" . "<home>") ("F" . "<end>")))
         (define-key function-key-map
                     (concat prefix (car m) (car k))
                     (read-kbd-macro (concat (cdr m) (cdr k))))))))

; X selection manipulation
(if (not (fboundp 'x-own-selection))
    (defun x-own-selection (s) (x-set-selection `PRIMARY s))
  (message ".emacs: x-own-selection already defined!"))

(global-set-key [(shift insert)] '(lambda () (interactive)
       (insert (x-get-selection))))
(global-set-key [(control insert)] '(lambda () (interactive)
       (x-own-selection (buffer-substring (point) (mark)))))

;;; alt -> meta
(setq x-alt-keysym 'meta)

;;; XEmacs compatibility
(global-set-key [(control tab)] `other-window)
(global-set-key [(meta g)] `goto-line)
(defun switch-to-other-buffer ()
  (interactive) (switch-to-buffer (other-buffer) 1))
(global-set-key [(meta control ?l)] `switch-to-other-buffer)
(global-set-key [(meta O) ?H] 'beginning-of-line)
(global-set-key [(meta O) ?F] 'end-of-line)


;;;(global-set-key [f3] 'ps-print-buffer-with-faces)
(define-key global-map [f5] 'font-lock-fontify-buffer)
(define-key global-map [f6] 'isearch-repeat-forward)
(define-key global-map [f10] 'wrap-up)
(global-set-key [home] 'beginning-of-line)
(global-set-key [end] 'end-of-line)
(global-set-key [(control home)] 'beginning-of-buffer)
(global-set-key [(control end)] 'end-of-buffer)
;; Make control+pageup/down scroll the other buffer
(global-set-key [(control next)] 'scroll-other-window)
(global-set-key [(control prior)] 'scroll-other-window-down)
;; I do this by accident too often
;;(global-set-key [(control z)]       'undo)
(global-set-key [(control shift z)] 'redo)
;;(global-unset-key "\C-z")
(global-unset-key "\C-x\C-z")
; Replace buffer-list (if we're not going to use ibuffer.el):
(global-set-key "\C-x\C-b" 'electric-buffer-list)
;;(global-set-key "\C-x\C-b" 'buffer-menu)

;(global-set-key "\C-c\C-c" 'compile)
;(global-set-key "\C-cc" 'comment-region)
(defun swap-compile-comment-keys ()
 "Swap compile and commen-region keybindings"
 (local-unset-key "\C-c\C-c")
 (local-unset-key "\C-cc")
 (local-set-key "\C-c\C-c" 'compile)
 (local-set-key "\C-cc" 'comment-region)
)
(add-hook 'makefile-mode-hook 'swap-compile-comment-keys)

(global-set-key "\C-cg" 'goto-line)
(global-set-key "\C-x\C-r" 'revert-buffer)
;; This runs mark-sexp which is not useful. Better give it another
;; purpose outside Emacs.
(global-unset-key (read-kbd-macro "C-M-SPC"))

;; DEPRECATED: This is already the default in recent emacs
;; (defun centerer ()
;;    "Repositions current line: once middle, twice top, thrice bottom"
;;    (interactive)
;;    (cond ((eq last-command 'centerer2)  ; 3 times pressed = bottom
;;        (recenter -1))
;;       ((eq last-command 'centerer1)  ; 2 times pressed = top
;;        (recenter 0)
;;        (setq this-command 'centerer2))
;;       (t                             ; 1 time pressed = middle
;;        (recenter)
;;        (setq this-command 'centerer1))))
;;(global-set-key "\C-l"             'centerer)

(defun shuffle-lines (beg end)
  "Scramble all the lines in region defined by BEG END
If region contains less than 2 lines, lines are left untouched."
  (interactive "*r")
  (catch 'cancel
    (save-restriction
      (narrow-to-region beg end)
      ;;   Exit when there is not enough lines in region
      (if (< (- (point-max) (point-min)) 3)
      (throw 'cancel t))

      ;;    Prefix lines with a random number and a space
      (goto-char (point-min))
      (while (not (eobp))
        (insert (int-to-string (random 32000)) " ")
        (forward-line 1))

      ;;  Sort lines according to first field (random number)
      (sort-numeric-fields 1 (point-min) (point-max))

      (goto-char (point-min))  ;Remove the prefix fields
      (while (not (eobp))
        (delete-region (point) (progn (forward-word 1) (+ (point) 1)))
        (forward-line 1))
      )))


;; ISearch mods
;; Always use regexps
(global-set-key [(control s)]               'isearch-forward-regexp)
(global-set-key [(control r)]               'isearch-backward-regexp)
(global-set-key [(control c)(meta %)]       'query-replace-regexp)

;; Not really key-bindings.  These just rename a few commonly used
;; functions
(defalias 'cr 'comment-region)
(defalias 'ucr 'uncomment-region)
(defalias 'rr 'replace-rectangle)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Moving lines up & down with <M-up> & <M-down>
(defun move-line (&optional n)
  "Move current line N (1) lines up/down leaving point in place."
  (interactive "p")
  (when (null n)
    (setq n 1))
  (let ((col (current-column)))
    (beginning-of-line)
    (forward-line)
    (transpose-lines n)
    (forward-line -1)
    (forward-char col))
  (indent-according-to-mode))

(defun move-line-up (n)
  "Moves current line N (1) lines up leaving point in place."
  (interactive "p")
  (move-line (if (null n) -1 (- n))))

(defun move-line-down (n)
  "Moves current line N (1) lines down leaving point in place."
  (interactive "p")
  (move-line (if (null n) 1 n)))

(defun move-region (start end n)
  "Move the current region up or down by N lines."
  (interactive "r\np")
  (let ((line-text (delete-and-extract-region start end)))
    (forward-line n)
    (let ((start (point)))
      (insert line-text)
      (setq deactivate-mark nil)
      (set-mark start))))

(defun move-region-up (start end n)
  "Move the current region up by N lines."
  (interactive "r\np")
  (move-region start end (if (null n) -1 (- n))))

(defun move-region-down (start end n)
  "Move the current region down by N lines."
  (interactive "r\np")
  (move-region start end (if (null n) 1 n)))

;; http://www.emacswiki.org/emacs/MoveLineRegion
;; These, in combination with MoveLine and MoveRegion, provide
;; behavior similar to Eclipse’s Alt-Up/Down. They use MoveLine if
;; there is no active region, MoveRegion if there is. Note that unlike
;; in Eclipse, the region will not expand to the beginning of the
;; first line or the end of the last line.
(defun move-line-region-up (start end n)
  (interactive "r\np")
  (if (region-active-p) (move-region-up start end n) (move-line-up n)))

(defun move-line-region-down (start end n)
  (interactive "r\np")
  (if (region-active-p) (move-region-down start end n) (move-line-down n)))

;;(global-set-key (kbd "M-p") 'move-line-region-up)
;;(global-set-key (kbd "M-n") 'move-line-region-down)
(global-set-key [(meta up)]   'move-line-region-up)
(global-set-key [(meta down)] 'move-line-region-down)


;; Rectangle

(defun insert-date-string ()
  "Insert a nicely formated date string."
  (interactive)
  (insert (format-time-string "%Y-%m-%d")))

(defun delete-horizontal-space-forward ()
  ;; adapted from `delete-horizontal-space'
  "*Delete all spaces and tabs after point."
  (interactive "*")
  (delete-region (point) (progn (skip-chars-forward " \t") (point))))
(global-set-key "\M- " 'delete-horizontal-space-forward)

;;-----------------------------------------------------------------


;;-----------------------------------------------------------------
;; PACKAGES CONF
;;-----------------------------------------------------------------
;(dynamic-completion-mode) ; Use alt-enter
;; By default start in TEXT mode.
(setq default-major-mode (lambda () (text-mode) (font-lock-mode t)))
;; One may want to disable auto-fill through
;(remove-hook 'text-mode-hook 'turn-on-auto-fill)
(add-hook 'text-mode-hook 'turn-on-auto-fill)
;(add-hook 'text-mode-hook 'turn-on-flyspell);; flyspell is ispell on-the-fly
;(setq fill-column 79)

; Don't add lines on the end of lines unless we want.
(setq next-line-add-newlines nil)
;; Indentation can insert tabs if this is non-nil.
(setq-default indent-tabs-mode nil)
(setq default-tab-width 4)

; Don't ask to revert for TAGS
(setq revert-without-query (cons "TAGS" revert-without-query))

;; turn on auto (de)compression
(auto-compression-mode t)

(put 'downcase-region 'disabled nil)

;; Adjust load path to include $HOME/lib/emacs/, etc
;;(setq load-path
;;      (cons (concat (getenv "HOME") "/.emacs.d/")
;;            (cons "/usr/local/share/emacs/site-lisp/" load-path)))
;;      (cons (concat (getenv "HOME") "/.ESS/ess/lisp/") load-path))

;; Does not trigger error if we do not have the following

;;;  Jonas.Jarnestrom<at>ki.ericsson.se A smarter
;;;  find-tag that automagically reruns etags when it cant find a
;;;  requested item and then makes a new try to locate it.
;;;  Fri Mar 15 09:52:14 2002
(defadvice find-tag (around refresh-etags activate)
  "Rerun etags and reload tags if tag not found and redo find-tag.
   If buffer is modified, ask about save before running etags."
  (let ((extension (file-name-extension (buffer-file-name))))
    (condition-case err
        ad-do-it
      (error (and (buffer-modified-p)
                  (not (ding))
                  (y-or-n-p "Buffer is modified, save it? ")
                  (save-buffer))
             (refresh-etags extension)
             ad-do-it))))

(defun refresh-etags (&optional extension)
  "Run etags on all peer files in current dir and reload them silently."
  (interactive)
  (shell-command (format "etags *.%s" (or extension "el")))
  (let ((tags-revert-without-query t))  ; don't query, revert silently
    (visit-tags-table default-directory nil)))

;;------------------------
;; ISPELL / ASPELL
;;------------------------
;; Switch to using aspell, it's much cleverer than ispell:
;;(setq-default ispell-program-name "aspell")
;; (setq ispell-local-dictionary-alist
;;       '(
;;      ("spanish"
;;       "[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]" "[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ]" "[']" t
;;       ("-d" "spanish" "-T" "latin1") "~latin1" iso-latin-9)
;;      ("spanish-html"
;;       "[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]" "[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ]" "" nil
;;       ("-B" "-H" "-d" "spanish" "-T" "latin1") "~latin1" iso-latin-9)
;;      )
;; )




;;---------------------------------------------------
;; WHITESPACE Deletes trailing whitespace in email/files when save/send
;; See: http://www.splode.com/~friedman/software/emacs-lisp/
;;---------------------------------------------------
;; (if (require 'whitespace "whitespace" t)
;;     (progn (add-hook 'write-file-hooks 'whitespace-write-file-hook)
;;            (setq whitespace-auto-cleanup t)
;;            (setq whitespace-display-in-modeline nil) )
;;   (message "Warning: .emacs: whitespace.el not available!"))

;; (if (and (require 'nuke-trailing-whitespace "nuke-trailing-whitespace" t)
;;          (fboundp 'nuke-trailing-whitespace))
;;     (progn  (autoload 'nuke-trailing-whitespace "nuke-trailing-whitespace" nil t)
;;             (message "OK: .emacs: nuke-trailing-whitespace in  nuke-trailing-whitespace.el!"))
;;   ;;   (if (and (require 'whitespace "whitespace" t)
;;   ;;            (fboundp 'whitespace-cleanup))
;;   ;;       (progn  (autoload 'whitespace-cleanup "whitespace" nil t)
;;   ;;               (defun nuke-trailing-whitespace () (delete-trailing-whitespace))
;;   ;;               (message "OK: .emacs: whitespace-cleanup in whitespace.el!"))
;;   (if (and (require 'whitespace "whitespace" t)
;;            (fboundp 'nuke-trailing-whitespace))
;;       (progn  (autoload 'nuke-trailing-whitespace "whitespace" nil t)
;;               (message "OK: .emacs: nuke-trailing-whitespace in whitespace.el!"))
;;     (if (fboundp 'delete-trailing-whitespace)
;;         (progn (defun nuke-trailing-whitespace () (delete-trailing-whitespace))
;;                (message "Warning: .emacs: nuke-trailing-whitespace not available, using delete-trailing-whitespace!"))
;;       (message "Warning: .emacs: nuke-trailing-whitespace not available!"))
;;     ))
;;(setq whitespace-modes (cons 'bibtex-mode (cons 'bibtex-mode
;;                                                whitespace-modes)))

;; ;;(add-hook 'mail-send-hook 'nuke-trailing-whitespace)
;(add-hook 'write-file-hooks 'nuke-trailing-whitespace)



;; -----------------------------------------------------
;; iswitchb -- switch buffers
;; -----------------------------------------------------
(iswitchb-mode t)
(setq iswitchb-buffer-ignore '("^ " "*Buffer"))
(add-hook
 'iswitchb-define-mode-map-hook
 '(lambda ()
    (define-key iswitchb-mode-map [up] 'iswitchb-next-match)
    (define-key iswitchb-mode-map [down] 'iswitchb-prev-match)
    (define-key iswitchb-mode-map [right] 'iswitchb-next-match)
    (define-key iswitchb-mode-map [left] 'iswitchb-prev-match)))

(defadvice iswitchb-kill-buffer (after rescan-after-kill activate)
  "*Regenerate the list of matching buffer names after a kill.
    Necessary if using `uniquify' with `uniquify-after-kill-buffer-p'
    set to non-nil."
  (setq iswitchb-buflist iswitchb-matches)
  (iswitchb-rescan))

(defun iswitchb-rescan ()
  "*Regenerate the list of matching buffer names."
  (interactive)
  (iswitchb-make-buflist iswitchb-default)
  (setq iswitchb-rescan t))
;; -----------------------------------------------------

;;I never use this
;;Make a "recent file list"
;; (if (require 'recentf "recentf" t)
;;     (recentf-mode 1)
;;   (message "Warning: .emacs: recentf file list not available!"))



;; Save minibuffer history between sessions
(when (fboundp 'savehist-mode)
  (savehist-mode 1))


(autoload 'tidy-buffer "tidy" "Run Tidy HTML parser on current buffer" t)
(autoload 'tidy-parse-config-file "tidy" "Parse the `tidy-config-file'" t)
(autoload 'tidy-save-settings "tidy" "Save settings to `tidy-config-file'" t)
(autoload 'tidy-build-menu  "tidy" "Install an options menu for HTML Tidy." t)
(defun my-html-helper-mode-hook () "Customize my html-helper-mode."
  (tidy-build-menu html-helper-mode-map)
  (local-set-key [(control c) (control c)] 'tidy-buffer)
  (setq sgml-validate-command "tidy")
  (tidy-build-menu))
(add-hook 'html-helper-mode-hook 'my-html-helper-mode-hook)
(add-hook 'html-mode-hook 'my-html-helper-mode-hook)

(defun html-helper-custom-insert-timestamp ()
  "Custom timestamp insertion function."
  (insert "Last modified: ")
  (insert (format-time-string "%e %B %Y")))
(setq html-helper-timestamp-hook 'html-helper-custom-insert-timestamp)

;; CSS-mode
(setq cssm-indent-level 4)
(setq cssm-newline-before-closing-bracket t)
(setq cssm-indent-function 'cssm-c-style-indenter)
(setq cssm-mirror-mode nil)

;;----------------
;; AUTO-SAVE
;;----------------
(setq
 auto-save-interval 300 ;auto-save every 5 minutes
 auto-save-timeout nil
; version-control 'never
)


;;---------------------------
;;  C/C++  MODE
;;---------------------------
(c-add-style
 "my-c-common-style"
 '("k&r"
   ;;    (setq tab-width 3
   ;; make sure spaces are used instead of tabs
   ;;            indent-tabs-mode nil)
   (c-basic-offset . 4)
   ))

(defun my-c-mode-common-hook ()
 "C/C++ mode with adjusted defaults."
 (c-set-style "my-c-common-style")
 (setq c++-tab-always-indent t)
 (setq c-backslash-column 79)
 (setq c-backslash-max-column 79)
 (c-set-offset 'inextern-lang '0) ; Do not indent extern "C" blocks.
 (message "Loading my-c-common-mode-hook...")
 (swap-compile-comment-keys)
 ;; (setq fill-column 79)
 )

(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

(defun linux-c-mode ()
  "C mode with adjusted defaults for use with the Linux kernel."
  (interactive)
  (c-mode)
  (c-set-style "k&r")
  (setq c-basic-offset 3)
  (swap-compile-comment-keys)
  (message "Loading linux-c-mode...")
)

(defun gcc-c-mode-hook ()
  "C mode for GCC development."
  (which-function-mode t)       ; Show function name in modeline
  (setq which-func-maxout 0)  ; No limitp
  (c-set-style "gnu")
  (c-set-offset 'inline-open 0)
  (swap-compile-comment-keys)
  (message "Loading gcc-c-mode...")
  )

(defun gcc-c-mode ()
  "C mode for GCC development."
  (interactive)
  (remove-hook 'c-mode-common-hook 'my-c-mode-common-hook)
;  (c-set-style "gnu")
;  (c-set-offset 'inline-open 0)
  (add-hook 'c-mode-common-hook 'gcc-c-mode-hook)
  (text-mode)
  (c-mode)
  )

;; -------------------------------------------
;; gnuplot mode
;; -------------------------------------------
(eval-after-load "gnuplot"
  (add-hook 'gnuplot-mode-hook
            '(lambda ()
               (define-key gnuplot-mode-map "\C-c\C-c" 'gnuplot-send-buffer-to-gnuplot)))
)

(eval-after-load "flyspell"
  '(local-set-key [(control ?\;)] 'flyspell-auto-correct-word)
  )

;;----------------------
;; PERL MODE
;;----------------------
;; Use cperl-mode instead of the default perl-mode
(add-to-list 'auto-mode-alist '("\\.\\([pP][Llm]\\|al\\)\\'" . cperl-mode))
(add-to-list 'interpreter-mode-alist '("perl" . cperl-mode))
(add-to-list 'interpreter-mode-alist '("perl5" . cperl-mode))
(add-to-list 'interpreter-mode-alist '("miniperl" . cperl-mode))
;;
(defun n-cperl-mode-hook ()
  "cPerl mode with adjusted defaults."
  (setq cperl-indent-level 4)
  (setq cperl-continued-statement-offset 0)
  (setq cperl-extra-newline-before-brace t)
  (set-face-background 'cperl-array-face "dark slate gray")
  (set-face-background 'cperl-hash-face "dark slate gray")
  )
(add-hook 'cperl-mode-hook 'n-cperl-mode-hook t)
;;(setq cperl-auto-newline t)
(setq cperl-invalid-face (quote off))
;; expands for keywords such as foreach, while, etc...
;;(setq cperl-electric-keywords t)


;;------------------------------------------------------------------------
;; Save a buffer in a specified EOL format with the C-x RET f
;;------------------------------------------------------------------------
;; For example, to save a buffer with Unix EOL format, type:
;;     C-x RET f unix RET C-x C-s.
;; To save it as DOS EOL format, type:  C-x RET f dos RET C-x C-s.
;;------------------------------------------------------------------------
(defun find-non-ascii ()
  "Find any non-ascii characters in the current buffer."
  (interactive)
  (occur "[^[:ascii:]]"))


(defun count-words-region (beginning end)
  "Print number of words in the region."
  (interactive "r")
  (message "Counting words in region ... ")
;;; 1. Set up appropriate conditions.
  (save-excursion
    (let ((count 0))
      (goto-char beginning)
;;; 2. Run the while loop.
      (while (and (< (point) end)
                  (re-search-forward "\\w+\\W*" end t))
        (setq count (1+ count)))
;;; 3. Send a message to the user.
      (cond ((zerop count)
             (message
              "The region does NOT have any words."))
            ((= 1 count)
             (message
              "The region has 1 word."))
            (t
             (message
              "The region has %d words." count)))))
  )

;; This is a macro I use in my research but it is useless for anyone else.
(fset 'pump_replace
   [?\C-  C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right C-right ?\C-w down C-right ?  ?\C-y ?\C-k ?\C-  home ?\C-w delete up return up ?\C-y home down])

;; Unset the debug option when there is trouble...
;;(setq debug-on-error nil)


;;;Color Theme
(add-to-list 'load-path "~/.emacs.d/color-theme-6.6.0/")
(load-file "~/.emacs.d/color-theme-6.6.0/color-theme.el")
(require 'color-theme)
(color-theme-initialize)
;;(color-theme-late-night)
;;(color-theme-calm-forest)


;; ;;;emacs-for-python
;; (load-file "~/.emacs.d/emacs-for-python/epy-init.el")
;; ;;flymake checker
;; (epy-setup-checker "pyflakes %f")
;; ;;snippets
;; (epy-django-snippets)
;; ;;ipython
;; (epy-setup-ipython)
;; ;;line highlighting
;; (global-hl-line-mode t) ;; To enable
;; (set-face-background 'hl-line "black") ;; change with the color that you like
;;                                        ;; for a list of colors: http://raebear.net/comp/emacscolors.html
;;highlight indentation
;;FIXME
;;(require 'highlight-indentation)
;;(add-hook 'python-mode-hook 'highlight-indentation)

;; Smart copy, if no region active, it simply copy the current whole line
(defadvice kill-line (before check-position activate)
  (if (member major-mode
              '(emacs-lisp-mode scheme-mode lisp-mode
                                c-mode c++-mode objc-mode js-mode
                                latex-mode plain-tex-mode))
      (if (and (eolp) (not (bolp)))
          (progn (forward-char 1)
                 (just-one-space 0)
                 (backward-char 1)))))

(defadvice kill-ring-save (before slick-copy activate compile)
  "When called interactively with no active region, copy a single line instead."
  (interactive (if mark-active (list (region-beginning) (region-end))
                 (message "Copied line")
                 (list (line-beginning-position)
                       (line-beginning-position 2)))))

(defadvice kill-region (before slick-cut activate compile)
  "When called interactively with no active region, kill a single line instead."
  (interactive
   (if mark-active (list (region-beginning) (region-end))
     (list (line-beginning-position)
           (line-beginning-position 2)))))

;; Copy line from point to the end, exclude the line break
(defun qiang-copy-line (arg)
  "Copy lines (as many as prefix argument) in the kill ring"
  (interactive "p")
  (kill-ring-save (point)
                  (line-end-position))
                  ;; (line-beginning-position (+ 1 arg)))
  (message "%d line%s copied" arg (if (= 1 arg) "" "s")))

(global-set-key (kbd "M-k") 'qiang-copy-line)
;;

;;
(defun increase-font-size ()
(interactive)
(set-face-attribute 'default
nil
:height
(ceiling (* 1.10
(face-attribute 'default :height)))))
(defun decrease-font-size ()
(interactive)
(set-face-attribute 'default
nil
:height
(floor (* 0.9
(face-attribute 'default :height)))))
(global-set-key (kbd "C-+") 'increase-font-size)
(global-set-key (kbd "C--") 'decrease-font-size)
;;

;;
;;定义compile快捷键
(global-set-key (kbd "C-c c") 'compile)
;;

;;删除光标前字符
;(global-set-key (kbd "C-h") 'delete-backward-char)

;;启动时显示行号
;(add-hook 'find-file-hook '(lambda ()(linum-mode t)))
;;;

;;;
(setq python-check-command "pyflakes")
;;;

(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(org-agenda-files (quote ("~/notes/city.org")))
 '(py-pychecker-command "pychecker.sh")
 '(py-pychecker-command-args (quote ("")))
 '(python-check-command "pychecker.sh"))

;; ;;;slime
;;  (setq inferior-lisp-program "/usr/share/emacs23/site-lisp/slime")
;;      (add-to-list 'load-path "/usr/share/emacs23/site-lisp/slime")
;;      (require 'slime)
;;      (slime-setup)
;; ;;;

;;;
;; 处理空格，保存时自动删除行尾空格deal with white spaces
(require 'whitespace)
(global-whitespace-mode)
(setq whitespace-style
      '(face trailing tabs lines lines-tail empty
             space-after-tab space-before-tab))
(add-hook 'before-save-hook 'delete-trailing-whitespace)
;;;

;;;防止页面滚动时跳动， scroll-margin 3 可以在靠近屏幕边沿3行时就开始滚动，可以很好的看到上下文。
(setq scroll-margin 3
      scroll-conservatively 10000)
;;;

;;设置字体大小
;(set-default-font "DejaVu Sans Mono-18")
;;

;; ;;设置aspell
;; (setq-default ispell-program-name "aspell")
;; (setq flyspell-default-dictionary "english")
;; (setq ispell-local-dictionary "american")
;; (setq ispell-dictionary "english")


;;自动换行
;;(add-hook 'org-mode-hook (lambda () (setq truncate-lines nil)))
;;

;;
;;(global-set-key "\C-m" 'reindent-then-newline-and-indent)
;;

;;设置redo快捷键
(global-set-key (kbd "C-x z") 'redo)
;;



;;;设置yasnippet
;; (add-to-list 'load-path
;;              "~/.emacs.d/plugins/yasnippet")
;; (require 'yasnippet)
;; (yas-global-mode 1)
;;;

;;;设置pep8 and pylint
;(add-to-list 'load-path "/Users/nipeng/.emacs.d/")
;(load-file "/Users/nipeng/.emacs.d/python-pylint.el")
;(require 'python-pylint)
;(load-file "~/.emacs.d/python-pep8.el")
;(require 'python-pep8)
;;;

;;;自动补全括号,并且将光标放置到括号中间
;; (setq skeleton-pair-alist
;;        '((?\" _ "\"" >)
;;          (?\' _ "\'" >)
;;          (?\( _ ")" >)
;;          (?\[ _ "]" >)
;;          (?\{ _ "}" >)))

;; (setq skeleton-pair t)
;; (global-set-key (kbd "(")  'skeleton-pair-insert-maybe)
;; (global-set-key (kbd "{")  'skeleton-pair-insert-maybe)
;; (global-set-key (kbd "\'") 'skeleton-pair-insert-maybe)
;; (global-set-key (kbd "\"") 'skeleton-pair-insert-maybe)
;; (global-set-key (kbd "[")  'skeleton-pair-insert-maybe)
;;;



;; cedit--semantic配置
;; (setq semantic-default-submodes '(global-semantic-idle-scheduler-mode
;;                                   global-semanticdb-minor-mode
;;                                   global-semantic-idle-summary-mode
;;                                   global-semantic-mru-bookmark-mode))
;; (semantic-mode 1)
;;;;======== end of C++==============


;;; 本地连接服务器并编辑服务器文件
;;;(require 'tramp)
;;;end


;; (add-to-list 'load-path "~/.emacs.d/tramp-2.2.8/lisp/")
;; (add-to-list 'Info-default-directory-list "~/.emacs.d/tramp-2.2.8/info/")
;; (require 'tramp)
;; (setq tramp-default-method "ssh")
;; (setq password-cache-expiry 36000)

;;; 显示时间
(display-time)


;;; 显示匹配的括号
(show-paren-mode 1)


(fset 'yes-or-no-p 'y-or-n-p) ; Make all "yes or no" prompts show "y
                              ; or n" instead
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )

;;;
(define-key global-map [C-return] 'set-mark-command)
