;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; package manager
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "http://melpa.milkbox.net/packages/") t)
(add-to-list 'package-archives
             ' ("marmalade" . "http://marmalade-repo.org/packages/") t)
(package-initialize)
(defconst demo-packages
  '(
    zenburn-theme
    golden-ratio
    window-number
    projectile
    helm
    helm-gtags
    helm-projectile
    auto-complete
    auto-complete-c-headers
    function-args
    clean-aindent-mode
    dtrt-indent
    ws-butler
    yasnippet
    smartparens
    savehist
    wgrep
    dictionary
    icomplete
    graphviz-dot-mode
    cmake-mode
    slime
    fill-column-indicator
    ))
(defun install-packages ()
  "Install all required packages."
  (interactive)
  (unless package-archive-contents
    (package-refresh-contents))
  (dolist (package demo-packages)
    (unless (package-installed-p package)
      (package-install package))))
(install-packages)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; helm
(require 'helm-config)
(require 'helm-eshell)
(require 'helm-files)
(require 'helm-buffers)
(require 'helm-command)
(require 'helm-imenu)
(require 'helm-grep)

(define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action) ; rebihnd tab to do persistent action
(define-key helm-map (kbd "C-i") 'helm-execute-persistent-action) ; make TAB works in terminal
(define-key helm-map (kbd "C-z")  'helm-select-action) ; list actions using C-z

(setq
 ;; helm-google-suggest-use-curl-p t
 ;; helm-scroll-amount 4 ; scroll 4 lines other window using M-<next>/M-<prior>
 ;; helm-quick-update t ; do not display invisible candidates
 ;; helm-idle-delay 0.01 ; be idle for this many seconds, before updating in delayed sources.
 ;; helm-input-idle-delay 0.01 ; be idle for this many seconds, before updating candidate buffer
 ;; helm-ff-search-library-in-sexp t ; search for library in `require' and `declare-function' sexp.
 ;; helm-split-window-default-side 'other ;; open helm buffer in another window
 ;; helm-split-window-in-side-p t ;; open helm buffer inside current window, not occupy whole other window
 ;; helm-buffers-favorite-modes (append helm-buffers-favorite-modes
 ;;                                     '(picture-mode artist-mode))
 ;; helm-candidate-number-limit 200 ; limit the number of displayed canidates
 ;; helm-M-x-requires-pattern 0     ; show all candidates when set to 0
 ;; helm-ff-file-name-history-use-recentf t
 ;; helm-move-to-line-cycle-in-source t ; move to end or beginning of source
 ;;                                        ; when reaching top or bottom of source.
 ;; ido-use-virtual-buffers t      ; Needed in helm-buffers-list
 ;; helm-buffers-fuzzy-matching t          ; fuzzy matching buffer names when non--nil
 ;;                                        ; useful in helm-mini that lists buffers
 helm-boring-file-regexp-list
 '("\\.git$" "\\.hg$" "\\.svn$" "\\.CVS$" "\\._darcs$" "\\.la$" "\\.o$" "\\.i$") ; do not show these files in helm buffer
 )

(helm-mode 1)
(global-set-key (kbd "M-x")	'helm-M-x)
(global-set-key (kbd "C-x b")	'helm-mini)
(global-set-key (kbd "C-x C-f") 'helm-find-files)
(global-set-key (kbd "M-s o")	'helm-occur)
(global-set-key (kbd "M-g s")	'helm-do-grep)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; helm-gtags
(setq
 helm-gtags-ignore-case nil
 helm-gtags-auto-update t
 helm-gtags-use-input-at-cursor nil
 helm-gtags-pulse-at-cursor t
 helm-gtags-suggested-key-mapping t
 helm-gtags-path-style 'relative
 )
(require 'helm-gtags)
(add-hook 'c-mode-hook 'helm-gtags-mode)
(add-hook 'c++-mode-hook 'helm-gtags-mode)
(add-hook 'asm-mode-hook 'helm-gtags-mode)
(add-hook 'dired-mode-hook 'helm-gtags-mode)
(add-hook 'eshell-mode-hook 'helm-gtags-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; helm-projejctile
(require 'helm-projectile)
(projectile-global-mode)
(setq projectile-enable-caching t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; cedet
(require 'cc-mode)
(require 'semantic)
(global-semanticdb-minor-mode 1)
(global-semantic-idle-scheduler-mode 1)
(global-semantic-stickyfunc-mode 1)
(semantic-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; function-args
(require 'function-args)
(fa-config-default)
;; It is bound to M-o, <tab>.
(define-key c-mode-map  [(tab)] 'moo-complete)
(define-key c++-mode-map  [(tab)] 'moo-complete)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GUD with 3 windows(comint, source, io)
(defvar gud-overlay
  (let* ((ov (make-overlay (point-min) (point-min))))
    (overlay-put ov 'face 'secondary-selection)
    ov)
  "Overlay variable for GUD highlighting.")

(defadvice gud-display-line (after my-gud-highlight act)
  "Highlight current line."
  (let* ((ov gud-overlay)
         (bf (gud-find-file true-file)))
    (with-current-buffer bf
      (move-overlay ov (line-beginning-position) (line-beginning-position 2)
                    ;;(move-overlay ov (line-beginning-position) (line-end-position)
                    (current-buffer)))))

(defun gud-kill-buffer ()
  (if (derived-mode-p 'gud-mode)
      (delete-overlay gud-overlay)))
(add-hook 'kill-buffer-hook 'gud-kill-buffer)

(defadvice gdb-setup-windows (after setup-more-gdb-windows activate)
  (switch-to-buffer gud-comint-buffer)
  (delete-other-windows)
  (setq win_source (selected-window)) ;; source
  (setq win_gdb (split-window-right)) ;; gdb
  (setq win_io (split-window win_gdb (/ (window-height) 2))) ;; input/output
  ;; source file
  (set-window-buffer
   win_source
   (if gud-last-last-frame
       (gud-find-file (car gud-last-last-frame))
     (if gdb-main-file
         (gud-find-file gdb-main-file)
       ;; Put buffer list in window if we
       ;; can't find a source file.
       (list-buffers-noselect))))
  ;; gud-cominit-buffer
  (set-window-buffer
   win_gdb
   (buffer-name gud-comint-buffer))
  ;; inferior-io
  (set-window-buffer
   win_io
   (gdb-get-buffer-create 'gdb-inferior-io))
  (select-window win_gdb)
  (set-window-dedicated-p win_io t)
  (set-window-dedicated-p win_gdb t)
  (toggle-truncate-lines t)
  )
(setq gdb-many-windows t)
(setq gdb-show-main t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; clean-aindent-mode
(require 'clean-aindent-mode)
(add-hook 'prog-mode-hook 'clean-aindent-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; dtrt-indent
(require 'dtrt-indent)
(dtrt-indent-mode 1)
(setq dtrt-indent-verbosity 0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ws-butler
(require 'ws-butler)
(add-hook 'prog-mode-hook 'ws-butler-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; yasnippet
(require 'yasnippet)
(yas-global-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; smartparens
(require 'smartparens-config)
(show-smartparens-global-mode +1)
(smartparens-global-mode 1)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; gnus
(require 'gnus)
(setq gnus-select-method '(nntp "news.gmane.org"))
(setq gnus-directory "~/News")
(setq gnus-startup-file (concat gnus-directory "/.newsrc"))
(add-hook 'gnus-group-mode-hook 'gnus-topic-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; savehist
(require 'savehist)
(savehist-mode t) ;; save minibuffer history
(setq savehist-save-minibuffer-history 1)
(setq savehist-additional-variables
      '(kill-ring
        search-ring
        regexp-search-ring
	compile-command))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; wgrep
(require 'wgrep)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; golden-ratio
(require 'golden-ratio)
(golden-ratio-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; window-number
(require 'window-number)
(window-number-mode 1)
(window-number-meta-mode)
(defadvice window-number-select (after after-window-number-select activate)
  (if (fboundp 'golden-ratio)           ;package golden-ratio
      (golden-ratio)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; dictionary
(require 'dictionary)
(setq dictionary-server "localhost")
(setq dictionary-tooltip-mode t)
(define-key global-map (kbd "C-c ds") 'dictionary-search)
(define-key global-map (kbd "C-c dw") 'dictionary-match-words)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; slime
(require 'slime-autoloads)
(slime-setup '(slime-repl))
(slime-setup '(slime-fancy))
;;curl -O http://beta.quicklisp.org/quicklisp.lisp
;; sbcl --load quicklisp.lisp
;; (ql:quickload "quicklisp-slime-helper")
(setq slime-net-coding-system 'utf-8-unix)
(load (expand-file-name "~/quicklisp/slime-helper.el"))
(setq inferior-lisp-program "/usr/bin/sbcl --noinform")
(add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
(setq slime-protocol-version 'ignore)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; zenburn-theme
(load-theme 'zenburn t )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; graphviz-dot-mode
(require 'graphviz-dot-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; cmake-mode
(require 'cmake-mode)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; plantuml
(org-babel-do-load-languages
 'org-babel-load-languages
 '(;; other Babel languages
   (plantuml . t)))
(setq org-plantuml-jar-path
      (expand-file-name "~/codes/script/plantuml.jar"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; dot
(org-babel-do-load-languages
 'org-babel-load-languages
 '(;; other Babel languages
   (dot . t)))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; misc
(setq inhibit-startup-message t)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(tooltip-mode -1)

;; hs-minor-mode for folding source code
(add-hook 'c-mode-common-hook 'hs-minor-mode)

(setq c-default-style  '((java-mode . "java")
                         (awk-mode . "awk")
                         (other . "gnu")))

;; maximize and fullscreen
(modify-frame-parameters nil '(
                               (fullscreen . fullscreen)
                               (maximized .  maximized)))

;; edit
(add-hook 'text-mode-hook 'turn-on-auto-fill)
(setq colon-double-space t)
(setq global-hl-line-mode t)
(defalias 'yes-or-no-p 'y-or-n-p)
(define-key global-map (kbd "<f5>") 'recompile)
(setq compilation-scroll-output 'first-error)
;;(setq split-height-threshold nil)
;;(setq split-width-threshold 100)
;;(setq display-buffer-prefer-horizontal-split t)
;; tabify untabify
;; completion-at-point: C-M-i

(global-linum-mode t)
(column-number-mode t)
(setq display-time-24hr-format t)
(display-time-mode t)

;; backup
;; (setq backup-inhibited t)
;; (setq make-backup-files nil) ; stop creating those backup~ files
;; (setq auto-save-default nil) ; stop creating those #autosave# files
(setq-default backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq delete-old-versions t)
(setq version-control t)
(setq auto-save-file-name-transforms
      '((".*" "~/.emacs.d/auto-save-list" t)))
(setq desktop-save-mode t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Max 80 cols per line, indent by two spaces, no tabs.
;; Apparently, this does not affect tabs in Makefiles.
(setq
 fill-column 80
 c++-indent-level 2
 c-basic-offset 2
 indent-tabs-mode nil)


;; Alternative to setting the global style.  Only files with "llvm" in
;; their names will automatically set to the llvm.org coding style.
(c-add-style "llvm.org"
             '((fill-column . 80)
               (c++-indent-level . 2)
               (c-basic-offset . 2)
               (indent-tabs-mode . nil)
               (c-offsets-alist . ((innamespace 0)))))

(add-hook 'c-mode-hook
          (function
           (lambda nil
             (if (string-match "llvm" buffer-file-name)
                 (progn
                   (c-set-style "llvm.org")
                   )
               ))))

(add-hook 'c++-mode-hook
          (function
           (lambda nil
             (if (string-match "llvm" buffer-file-name)
                 (progn
                   (c-set-style "llvm.org")
                   )
               ))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; auto-complete
(require 'auto-complete-config)
(ac-config-default)
(global-auto-complete-mode t)
;; (setq ac-auto-start t)
;; (setq ac-quick-help-delay 0.5)
;; ;; (add-to-list 'ac-sources 'ac-source-gtags)
(add-to-list 'ac-sources 'ac-source-imenu)
(add-to-list 'ac-sources 'ac-source-semantic)
;; (define-key ac-mode-map  [(control tab)] 'auto-complete)
;; (setq ac-auto-show-menu 0.2)
;; (setq ac-use-menu-map t)
;; (define-key ac-menu-map "\C-n" 'ac-next)
;; (define-key ac-menu-map "\C-p" 'ac-previous)
;; (add-hook 'c-mode-hook '(lambda () (company-mode)))
;; (add-hook 'c++-mode-hook '(lambda () (company-mode)))
;; (global-set-key [(control tab)] 'company-complete-common)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; auto-complete-c-headers
(require 'auto-complete-c-headers)
(defun my-get-include-dirs ()
  (let* ((command-result (shell-command-to-string "echo \"\" | g++ -v -x c++ -E -"))
         (start-string "#include <...> search starts here:\n")
         (end-string "End of search list.\n")
         (start-pos (string-match start-string command-result))
         (end-pos (string-match end-string command-result))
         (include-string (substring command-result (+ start-pos (length start-string)) end-pos)))
    (split-string include-string)))
(add-hook 'c-mode-common-hook
          (lambda()
            (add-to-list 'ac-sources 'ac-source-c-headers)))
(setq achead:include-directories (my-get-include-dirs))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; auto-complete-clang
;; (require 'cc-mode))
;; (require 'auto-complete-clang)
;; (setq ac-clang-auto-save nil)
;; ;; (define-key c-mode-map (kbd "C-S-<return>") 'ac-complete-clang)
;; ;; (define-key c-mode-map  [(control tab)] 'ac-complete-clang)
;; ;; (define-key c++-mode-map  [(control tab)] 'ac-complete-clang)
;; (setq ac-clang-flags
;;       (mapcar(lambda (item)(concat "-I" item))
;;              (my-get-include-dirs)))
;; (defun my-ac-cc-mode-setup ()
;;   (setq ac-sources (append '(ac-source-clang ) ac-sources))) ;; ac-source-yasnippet ac-source-gtags
;; (add-hook 'c-mode-common-hook 'my-ac-cc-mode-setup)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; irony
;; (add-to-list 'load-path "~/codes/irony-mode/elisp/")
;; (defun my-c++-hooks ()
;;   ;; "Enable the hooks in the preferred order: 'yas -> auto-complete -> irony'."
;;   (yas/minor-mode-on)
;;   (auto-complete-mode 1)
;;   ;; avoid enabling irony-mode in modes that inherits c-mode, e.g: php-mode
;;   (when (member major-mode irony-known-modes)
;;     (irony-mode 1)))
;; (eval-after-load 'auto-complete
;;   (progn
;;   (eval-after-load 'yasnippet
;;       (progn
;;         (require 'irony)    ;; Note: hit `C-c C-b' to open build menu
;;        ;; the ac plugin will be activated in each buffer using irony-mode
;;        (irony-enable 'ac)             ; hit C-RET to trigger completion
;;        (add-hook 'c-mode-commonhook 'my-c++-hooks)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; fill-column-indicator
(require 'fill-column-indicator)
(fci-mode)

(setq whitespace-style '(face trailing))
(message "Ready to play!")
