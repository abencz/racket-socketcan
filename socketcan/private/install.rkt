#lang racket/base

(require make/setup-extension)

(provide pre-installer)

(define (pre-installer collections-top-path socketcan-path)
  (pre-install socketcan-path
	       (build-path socketcan-path "private")
	       "socketcan_ext.c"
	       "."
	       '()
	       '()
	       '()
	       '()
	       '()
	       '()
	       (lambda (thunk) (thunk))
	       #t))
