#lang scribble/manual

@(require scribble/racket
	  (for-label racket
		     socketcan))

@title[#:version "0.1"]{socketcan}
@author[(author+email "Alex Bencz" "abencz@gmail.com")]

@section{Introduction}

This is a racket binding for the Linux socketcan interface.

@section{Installation}

At the command line:
@verbatim{raco pkg install --link socketcan}
or
@verbatim{make link}

@section{Opening a CAN interface}

Socketcan interfaces work a lot like UNIX sockets and can be opened with:

@racketblock[
	     (require socketcan)

	     (define sock (can-open "can0"))]

@section{Sending and receiving CAN data}

Once a can device is open, data is moved in/out using the
@racket[can-frame] structure. Each @racket[can-frame] consists of an id
and a byte string of data:

@racketblock[
	     (can-send sock (can-frame 10 (bytes 100 254)))
	     (define result (can-receive! sock))
	     (display (can-frame-id result))]

Only CAN 1.0 is supported which means that the id must be less than
0x1ff and the data must be no longer than 8 bytes.
