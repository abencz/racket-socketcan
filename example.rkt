#lang racket

(require socketcan)


(define s (can-open "can0"))
(can-send s (can-frame 64 (bytes 1 2 3 4 5 6)))
(display (can-frame-id (can-receive! s)))
(can-close s)
