;;; Directory Local Variables
;;; For more information see (info "(emacs) Directory Variables")

((nil . ((magit-large-repo-set-p . t)
         (magit-commit-show-diff . nil)
         (magit-large-repo-p . t)
         (magit-refresh-buffers . nil)
         (enable-local-eval . t)))
 (magit-status-mode . ((eval . (mapc 'magit-disable-section-inserter
                                     '('magit-insert-staged-changes 'magit-insert-unstaged-changes)))
                       (eval . (mapc 'magit-disable-section-inserter
                                     '('magit-insert-staged-changes 'magit-insert-unstaged-changes))))))
