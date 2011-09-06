(define (start e)
  (run 100000 e global-environment))

(define (run fuel e r)
  (maybe-error (lambda ()
                 (ev fuel (expand e) r (lambda (remaining-fuel value)
                                         (list remaining-fuel value))))))

(define (maybe-error thunk)
;  (thunk)   ; Uncomment this line, and comment the following one, to debug errors.
  (with-exception-catcher (lambda (exc) `(0 (error ,exc))) thunk)
  )

(define (expand e)
  (if (not (pair? e))
      e
      (case (car e)
        ((let)
         (let ((bindings (cadr e))
               (body (caddr e)))
           `((lambda ,(map car bindings) ,(expand body))
             ,@(map (lambda (b) (expand (cadr b))) bindings))))
        (else
         (map expand e)))))

(define (pump needed fuel k)
  (if (< fuel needed)
      (list 0 'exhausted)
      (k (- fuel needed))))

(define (ev fuel e r k)
  (pump 1 fuel
   (lambda (fuel)
     (cond ((symbol? e)
            (k fuel (cadr (assq e r))))
           ((not (pair? e))
            (k fuel e))
           (else
            (case (car e)
              ((quote)
               (k fuel (cadr e)))
              ((if)
               (ev fuel (cadr e) r
                   (lambda (fuel value)
                     (ev fuel (if value (caddr e) (cadddr e)) r k))))
              ((lambda)
               (k fuel (lambda (fuel args k)
                         (ev fuel (caddr e)
                             (append (map list (cadr e) args) r)
                             k))))
              (else
               (ev fuel (car e) r
                   (lambda (fuel proc)
                     (let looping ((fuel fuel)
                                   (rands (cdr e))
                                   (k (lambda (fuel args)
                                        (pump 1 fuel (lambda (fuel)
                                                       (proc fuel args k))))))
                       (if (null? rands)
                           (k fuel '())
                           (ev fuel (car rands) r
                               (lambda (fuel arg)
                                 (looping fuel (cdr rands)
                                          (lambda (fuel args)
                                            (k fuel (cons arg args)))))))))))))))))

(define (primitive procedure)
  (lambda (fuel args k)
    (k fuel (apply procedure args))))

(define (rebind var val env)
  (cons (list var val)
        (a-list-remove var env)))

(define (a-list-remove key pairs)
  (cond ((null? pairs) '())
        ((eq? key (caar pairs))
         (a-list-remove key (cdr pairs)))
        (else (cons (car pairs)
                    (a-list-remove key (cdr pairs))))))

(define global-environment
  `((list   ,(primitive list))
    (cons   ,(primitive cons))
    (car    ,(primitive car))
    (cdr    ,(primitive cdr))
    (cadr   ,(primitive cadr))
    (<      ,(primitive <))
    (equal? ,(primitive equal?))
    (expand ,(primitive expand))
    (rebind ,(primitive rebind))
    (global-environment ,(primitive (lambda () global-environment)))
    (run    ,(lambda (fuel args k)
               (let ((requested-fuel (car args))
                     (expr (cadr args))
                     (env (caddr args)))
                 (let ((subfuel (min fuel requested-fuel)))
                   (let ((result (run subfuel expr 
                                      (rebind 'global-environment
                                              (primitive (lambda () env))
                                              env))))
                     (let ((remaining (car result))
                           (value (cadr result)))
                       (let ((consumed (- requested-fuel remaining)))
                         ;; XXX That seems unfair since we get 0 remaining
                         ;; after hitting an error. Probably want to change
                         ;; that.
                         (pump consumed fuel
                               (lambda (fuel)
                                 (k fuel result))))))))))))
