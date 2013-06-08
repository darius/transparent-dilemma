Modified Prisoner's Dilemma lab.
===============================

Sparked by
http://lesswrong.com/lw/7f2/prisoners_dilemma_tournament_results/4ru9
(See also the refs at
http://lesswrong.com/lw/duv/ai_cooperation_is_already_studied_in_academia_as/
)

A match brings together two programs written in a custom dialect of
Scheme. Each is called with two inputs: the source code of itself and
the other. (Giving it its own source code is only a convenience, of
course.) It's allowed to run for some standard number of steps
('fuel'). The output should be 'C or 'D within the allotted time. If
not, both programs earn 0. Otherwise, standard prisoner's-dilemma
payoffs.

In a round-robin tournament, agents get ranked by total score over all
matches.

Implementation in Gambit Scheme using its WITH-EXCEPTION-CATCHER 
primitive; I believe it's portable Scheme otherwise.

(RUN fuel expression environment) is like the standard EVAL but with
limited fuel, and returning a list like (unconsumed-fuel
result-value). In the scope of this run, (GLOBAL-ENVIRONMENT) returns
the environment passed in. The result in the case of an error or fuel
exhaustion is defined in terp.scm -- I may want to change all these
particulars.

To implement Eliezer's 

> This enables you to say, "Simulate my opponent, and if it tries to
> simulate me, see what it will do if it simulates me outputting
> Cooperate."

rebind RUN to your preferred function in the environment passed to RUN.
(For convenience a REBIND function is supplied.)

    ;; Example agents

    ;; Trivial cooperator and defector
    (lambda (me them) 'C)
    (lambda (me them) 'D)

    ;; Cooperate with shallow, cooperative agents (first cut)
    (lambda (me them)
      (let ((result (run 1000
                         (list them them me)
                         (rebind 'run run  ;TODO: interpose a new RUN
                                 (global-environment)))))
        (let ((remaining (car result))
              (value (cadr result)))
          (if (< 500 remaining)
              (if (equal? value 'C)
                  'C
                  'D)
              'D))))

Language reference
==================

Besides `run` it's a subset of standard Scheme: (TODO add explanations)

Core forms
==========

* Variable reference

* Constant (TODO always expand these out to quotes)

* `(quote datum)`

* `(if exp exp exp)`

* `(lambda (variable ...) exp)`

* `(exp exp ...)`

TODO probably nicest overall to include `letrec` too

Datatypes
=========

* boolean
* symbol
* IEEE double
* empty list
* pair
* procedure

Standard primitive procedures
====================

* `cons`
* `car`
* `cdr`
* `cadr`
* `<`
* `equal?`

New primitive procedures
====================

* `expand`: expand out derived forms, reducing to core forms
* `rebind`
* `global-environment`
* `run`

Derived forms
==========

* `(let ((variable exp) ...) exp)`

TODO add the usual macros
