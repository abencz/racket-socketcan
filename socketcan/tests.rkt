#lang racket/base
;(require (submod "main.rkt" safe) rackunit)
(require socketcan
         rackunit)

(check-equal? (integer->can-bytes #x2a 1 #t) #"\x2a")
(check-equal? (integer->can-bytes #x-2a 1 #t) #"\xd6")
(check-equal? (integer->can-bytes #xd6 1 #f) #"\xd6")

; little endian
(check-equal? (integer->can-bytes #x30a3 2 #t) #"\xa3\x30")
(check-equal? (integer->can-bytes #x-30a3 2 #t) #"\x5d\xcf")
(check-equal? (integer->can-bytes #xcf5d 2 #f) #"\x5d\xcf")

(check-equal? (integer->can-bytes #x13fd4c 3 #t) #"\x4c\xfd\x13")
(check-equal? (integer->can-bytes #x-13fd4c 3 #t) #"\xb4\x02\xec")
(check-equal? (integer->can-bytes #xec02b4 3 #f) #"\xb4\x02\xec")

(check-equal? (integer->can-bytes #x71442bca 4 #t) #"\xca\x2b\x44\x71")
(check-equal? (integer->can-bytes #x-71442bca 4 #t) #"\x36\xd4\xbb\x8e")
(check-equal? (integer->can-bytes #x8ebbd436 4 #f) #"\x36\xd4\xbb\x8e")

; big endian
(check-equal? (integer->can-bytes #x30a3 2 #t #t) #"\x30\xa3")
(check-equal? (integer->can-bytes #x-30a3 2 #t #t) #"\xcf\x5d")
(check-equal? (integer->can-bytes #xcf5d 2 #f #t) #"\xcf\x5d")

(check-equal? (integer->can-bytes #x13fd4c 3 #t #t) #"\x13\xfd\x4c")
(check-equal? (integer->can-bytes #x-13fd4c 3 #t #t) #"\xec\x02\xb4")
(check-equal? (integer->can-bytes #xec02b4 3 #f #t) #"\xec\x02\xb4")

(check-equal? (integer->can-bytes #x71442bca 4 #t #t) #"\x71\x44\x2b\xca")
(check-equal? (integer->can-bytes #x-71442bca 4 #t #t) #"\x8e\xbb\xd4\x36")
(check-equal? (integer->can-bytes #x8ebbd436 4 #f #t) #"\x8e\xbb\xd4\x36")


(check-equal? (can-bytes->integer #"\x7c") #x7c)
(check-equal? (can-bytes->integer #"\x84") #x-7c)

(check-equal? (can-bytes->integer #"\x59\x5c") #x5c59)
(check-equal? (can-bytes->integer #"\xa7\xa3") #x-5c59)
(check-equal? (can-bytes->integer #"\x59\x5c" 0 2 #t #t) #x595c)

(check-equal? (can-bytes->integer #"\x7f\x01\x7a") #x7a017f)
(check-equal? (can-bytes->integer #"\x81\xfe\x85") #x-7a017f)

(check-equal? (can-bytes->integer #"\x54\x7a\x0f\x4c") #x4c0f7a54)
(check-equal? (can-bytes->integer #"\xac\x85\xf0\xb3") #x-4c0f7a54)

(define test-bytes #"\x54\x7a\x0f\x4c")
(check-equal? (can-bytes->integer test-bytes 3) #x4c)
(check-equal? (can-bytes->integer test-bytes 2) #x4c0f)
(check-equal? (can-bytes->integer test-bytes 1) #x4c0f7a)
(check-equal? (can-bytes->integer test-bytes 0) #x4c0f7a54)
(check-equal? (can-bytes->integer test-bytes 0 3) #x0f7a54)
(check-equal? (can-bytes->integer test-bytes 0 2) #x7a54)
(check-equal? (can-bytes->integer test-bytes 0 1) #x54)
