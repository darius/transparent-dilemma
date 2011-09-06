(define (play player-1 player-2)
  (let ((decision-1 (run-1 player-1 player-2))
        (decision-2 (run-1 player-2 player-1)))
    (let ((p (assoc (list decision-1 decision-2) payoff-matrix)))
      (list (if p (cadr p) '(0 0))
            decision-1
            decision-2))))

(define payoff-matrix
  '(((C C) (4 4))
    ((D D) (1 1))
    ((C D) (0 7))
    ((D C) (7 0))))

(define (run-1 player other)
  (let ((result (start (list player player other))))
    (let ((remaining (car result))
          (value (cadr result)))
      (and (<= 0 remaining) value))))

;; Tests

(define (test1)
  (play all-C all-D))

(define all-C '(lambda (me them) 'C))
(define all-D '(lambda (me them) 'D))

(define erroneous '(lambda (me them) (car)))

(define too-deep '(lambda (me them)
                    ((lambda (f) (f f))
                     (lambda (f) (f f)))))

;; Example agent: cooperate with shallow, cooperative agents (first cut)
(define eg
  '(lambda (me them)
     (let ((result (run 1000
                        (list them them me)
                        (cons (list 'run run) ;TODO: interpose a new RUN
                              (global-environment)))))
       (let ((remaining (car result))
             (value (cadr result)))
         (if (< 500 remaining)
             (if (equal? value 'C)
                 'C
                 'D)
             'D)))))

(define all-players (list all-C all-D erroneous too-deep eg))

(define (tournament)
  (let outer ((players all-players))
    (if (or (null? players) (null? (cdr players)))
        '()
        (let ((player (car players))
              (others (cdr players)))
          (cons (map (lambda (other) (list player other (play player other)))
                     others)
                (outer others))))))
