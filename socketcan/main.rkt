#lang racket/base

(provide can-open
         can-close
         can-send
         can-receive!
         can-receive!*)

(require "private/socketcan_ext.rkt")


(define (can-open interface-name)
  (can-open-raw interface-name))

(define (can-close sock)
  (can-close-raw sock))

(define (can-send sock can-id data)
  (can-send-raw sock can-id data))

(define (can-receive! sock)
  (can-receive!-raw sock))

(define (can-receive!* sock)
  (can-receive!*-raw sock))
