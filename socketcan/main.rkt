#lang racket/base

(require racket/contract)
(require "private/socketcan_ext.rkt")

(provide (contract-out
           [struct can-frame ((id can-id/c) (data can-data/c))]
           [can-open (-> string? integer?)]
           [can-close (-> integer? any/c)]
           [can-send (-> integer? can-frame? boolean?)]
           [can-receive! (-> integer? can-frame?)]
           [can-receive!* (-> integer? can-frame?)]))

(struct can-frame (id data))

(define (can-id/c id)
  (and/c integer?
         (< id 2048)
         (>= id 0)))

(define (can-data/c data)
  (and/c bytes?
         (<= (bytes-length data) 8)))

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
