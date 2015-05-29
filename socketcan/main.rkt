#lang racket/base

(require racket/contract)
(require "private/socketcan_ext.rkt")

(provide (contract-out
           [struct can-frame ((id can-id/c) (data can-data/c))]
           [struct can-value ((data integer?) (length (integer-in 1 4)))]
           [can-open (-> string? integer?)]
           [can-close (-> integer? any/c)]
           [can-send (-> integer? can-frame? boolean?)]
           [can-receive! (-> integer? can-frame?)]
           [can-receive!* (-> integer? can-frame?)]
           [can-bytes->integer (->* (bytes?)
                                (natural-number/c (integer-in 0 8) boolean? boolean?)
                                integer?)]
           [integer->can-bytes (->* (integer? (integer-in 1 8))
                                (boolean? boolean?)
                                bytes?)]))

(struct can-frame (id data))
(struct can-value (data length))

(define (can-id/c id)
  (integer-in 0 2047))

(define (can-data/c data)
  (and/c bytes?
         (<= (bytes-length data) 8)))

(define (data-size-offset/c n)
  (and/c integer?
         (<= n 8)
         (>= n 0)))

(define (list->frame a-list)
  (can-frame (car a-list) (cadr a-list)))

(define (can-open interface-name)
  (can-open-raw interface-name))

(define (can-close sock)
  (can-close-raw sock))

(define (can-send sock frame)
  (= 16
     (can-send-raw sock
                   (can-frame-id frame)
                   (can-frame-data frame))))

(define (can-receive! sock)
  (list->frame (can-receive!-raw sock)))

(define (can-receive!* sock)
  (list->frame (can-receive!*-raw sock)))

(define (b->i-iter blist value)
  (cond [(null? blist)
         value]
        [else
         (b->i-iter (cdr blist) (+ (arithmetic-shift value 8) (car blist)))]))
        
(define (b->i bytes start width [big-endian #f])
  (let ([blist (bytes->list (subbytes bytes start (+ start width)))])
    (cond [big-endian
            (b->i-iter blist 0)]
          [else
            (b->i-iter (reverse blist) 0)])))

(define (can-bytes->integer bytes [start 0] [width 0] [signed #t] [big-endian #f])
  (let* ([calc-width
          (cond [(= width 0)
                 (- (bytes-length bytes) start)]
                [else
                 width])]
         [bit-width (* calc-width 8)]
         [base-integer (b->i bytes start calc-width big-endian)])
    (cond [(and signed (bitwise-bit-set? base-integer (- bit-width 1)))
           (- base-integer (expt 2 bit-width))]
          [else
           base-integer])))

(define (i->b-iter value blist width)
  (cond [(= 0 width)
         blist]
        [else
         (i->b-iter (arithmetic-shift value -8)
                    (cons (bitwise-bit-field value 0 8) blist)
                    (- width 1))]))

(define (integer->can-bytes value width [signed #t] [big-endian #f])
  (let ([blist (i->b-iter value '() width)])
    (cond [big-endian
           (list->bytes blist)]
          [else
           (list->bytes (reverse blist))])))
