(module level

;; exports
(make-level
 make-level-api
 level-resource
 level-resource-set!
 level-implementation
 level?
 level-api
 db-get
 db-get/default
 db-put
 db-delete
 db-batch
 db-stream)

(import scheme chicken)
(use interfaces)

;; type: symbol describing the implementation being used (to aid debugging)
;; implementation: the implementation of the level-api interface
;; resource: the underlying resource (eg, pointer to leveldb DB object)
(define-record level type implementation resource)
(define-record-printer (level x out)
  (fprintf out "#<level ~S ~S>"
           (level-type x)
           (level-resource x)))

(define (db-get db key)
  ((level-get (level-implementation db))
   (level-resource db) key))

(define (db-get/default db key default)
  ((level-get/default (level-implementation db))
   (level-resource db) key default))

(define (db-put db key value #!key (sync #f))
  ((level-put (level-implementation db))
   (level-resource db) key value sync: sync))

(define (db-delete db key #!key (sync #f))
  ((level-delete (level-implementation db))
   (level-resource db) key sync: sync))

(define (db-batch db ops #!key (sync #f))
  ((level-batch (level-implementation db))
   (level-resource db) ops sync: sync))

(define (db-stream db #!key start end limit reverse
                   (key #t) (value #t) fillcache)
  ((level-stream (level-implementation db))
   (level-resource db)
   start: start
   end: end
   limit: limit
   reverse: reverse
   key: key
   value: value
   fillcache: fillcache))

(interface level-api
  (define (level-get db key))
  (define (level-get/default db key default))
  (define (level-put db key value #!key (sync #f)))
  (define (level-delete db key #!key (sync #f)))
  (define (level-batch db ops #!key (sync #f)))
  (define (level-stream db #!key start end limit reverse
                        (key #t) (value #t) fillcache))))
