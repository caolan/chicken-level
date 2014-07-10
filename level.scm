(module level
  (
   make-level
   make-level-api
   level-resource
   set-level-resource!
   level-implementation
   level?
   level-api
   db-get
   db-put
   db-delete
   db-batch
   db-stream
   )

(import scheme chicken)
(use interfaces records)

(define level (make-record-type 'level '(implementation resource)))
(define level? (record-predicate level))
(define make-level (record-constructor level))
(define level-resource (record-accessor level 'resource))
(define set-level-resource! (record-modifier level 'resource))
(define level-implementation (record-accessor level 'implementation))


(define (db-get db key)
  ((get (level-implementation db)) (level-resource db) key))

(define (db-put db key value #!key (sync #f))
  ((put (level-implementation db)) (level-resource db) key value sync: sync))

(define (db-delete db key #!key (sync #f))
  ((delete (level-implementation db)) (level-resource db) key sync: sync))

(define (db-batch db ops #!key (sync #f))
  ((batch (level-implementation db)) (level-resource db) ops sync: sync))

(define (db-stream db
                   #!key
                   start
                   end
                   limit
                   reverse
                   (key #t)
                   (value #t)
                   fillcache)
  ((stream (level-implementation db))
   (level-resource db)
   start: start
   end: end
   limit: limit
   reverse: reverse
   key: key
   value: value
   fillcache: fillcache))


(interface level-api
  (define (get db key))
  (define (put db key value #!key (sync #f)))
  (define (delete db key #!key (sync #f)))
  (define (batch db ops #!key (sync #f)))
  (define (stream db
                  #!key
                  start
                  end
                  limit
                  reverse
                  (key #t)
                  (value #t)
                  fillcache))))
