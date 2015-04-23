#lang setup/infotab

(define name "socketcan")
(define blurb
  (list
    `(p "socketcan bindings for Racket")))
(define homepage "https://github.com/abencz/racket-socketcan")
(define primary-file "main.rkt")
(define categories '(net))

(define pre-install-collection "private/install.rkt")
(define compile-omit-files '("private/install.rkt"))
