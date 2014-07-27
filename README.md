# chicken-level

Provides a high-level API to leveldb implementations. Use in combination
with an implementation egg (eg, [leveldb][1]).

## Interface API

This module exposes an interface, which other eggs provide implementations
of. The API described below is what the interface provides.

### Basic read and write

```scheme
(db-get db key)
```

Returns the value of `key` in `db` as a string. Causes an exception if the
key does not exist.

```scheme
(db-put db key value #!key (sync #f))
```

Stores `value` under `key` in datbase `db`. If the sync option can be set to
`#t` to make the write operation not return until the data being written has
been pushed all the way to persistent storage. See the *Synchronous Writes*
section for more information.

```scheme
(db-delete db key #!key (sync #f))
```

Removes the value associated with `key` from `db`. If the sync option can be
set to `#t` to make the write operation not return until the data being
written has been pushed all the way to persistent storage. See the
*Synchronous Writes* section for more information.

### Atomic updates (batches)

```scheme
(db-batch db ops #!key (sync #f))
```

When making multiple changes that rely on each other you can apply a batch
of operations atomically using `db-batch`. The `ops` argument is a list of
operations which will be applied **in order** (meaning you can create then
later delete a value in the same batch, for example).

```scheme
(define myops '((put "abc" "123")
                (put "def" "456")
                (delete "abc")))

;; apply all operations in myops
(db-batch db myops)
```

The first item in an operation should be the symbol `put` or `delete`, any
other value will give an error. The next item is the key and in the case of
`put` the third item is the value.

Apart from its atomicity benefits, `db-batch` may also be used to speed up
bulk updates by placing lots of individual mutations into the same batch.

### Range queries (streams)

```scheme
(db-stream db #!key start end limit reverse (key #t) (value #t) fillcache)
```

Allows forward and backward iteration over the keys in alphabetical order.
Returns a lazy sequence of all key/value pairs from `start` to `end`
(up to `limit`). This uses the [lazy-seq][2] egg.

* __start__ - the key to start from (need not actually exist), if omitted
  starts from the first key in the database
* __end__ - the key to end on (need not actually exist), if omitted ends on
  the last key in the database
* __limit__ - stops after `limit` results have been returned
* __reverse__ - iterates backwards through the keys (reverse
  iteration may be somewhat slower than forward iteration)
* __key__ - whether to return the key for each result (default #t)
* __value__ - whether to return the value for each result (default #t)
* __fillcache__ - whether to fill leveldb's read cache when reading (turned
  off by default so the bulk read does not replace most of the cached
  contents)

When both `key: #t` and `value: #t` (as default) values are returned as a
list with two items, the `car` being the key and the `cadr` being the
value. When only `key: #t` or `value: #t` the keys or values are not
returned as a list but as a string representing the single key or value.

```scheme
(lazy-map display (db-stream db start: "foo:" end: "foo::" limit: 10)))
```

You can turn the lazy-seq into a list using `lazy-seq->list`, just be
warned that it will evaluate the entire key range and should be avoided
unless you know the number of values is small (eg, when using `limit`).

```scheme
(db-batch db '((put "foo" "1")
               (put "bar" "2")
               (put "baz" "3")))

(lazy-seq->list (db-stream db limit: 2)) ;; => (("foo" "1") ("bar" "2"))
(lazy-seq->list (db-stream db key: #f value: #t)) ;; => ("1" "2" "3")
(lazy-seq->list (db-stream db key: #t value: #f)) ;; => ("foo" "bar" "baz")
```

### Synchronous Writes

**Note:** this information is mostly copied from the [LevelDB docs][3]

By default, each write to leveldb is asynchronous: it returns after pushing
the write from the process into the operating system. The transfer from
operating system memory to the underlying persistent storage happens
asynchronously. The sync flag can be turned on for a particular write to
make the write operation not return until the data being written has been
pushed all the way to persistent storage. (On Posix systems, this is
implemented by calling either fsync(...) or fdatasync(...) or msync(...,
MS\_SYNC) before the write operation returns.)

Asynchronous writes are often more than a thousand times as fast as
synchronous writes. The downside of asynchronous writes is that a
crash of the machine may cause the last few updates to be lost. Note
that a crash of just the writing process (i.e., not a reboot) will
not cause any loss since even when sync is false, an update is pushed
from the process memory into the operating system before it is
considered done.

`db-batch` provides an alternative to asynchronous writes. Multiple
updates may be placed in the same batch and applied together
using a `sync: #t`. The extra cost of the synchronous write will be
amortized across all of the writes in the batch.


## Creating an interface

If you want to provide your own storage impelmentation, import this egg
and define the interface as follows:

```scheme
(use level)

(define myleveldb
  (implementation level-api

    (define (get db key) ...)
    (define (put db key value #!key (sync #f)) ...)
    (define (delete db key #!key (sync #f)) ...)
    (define (batch db ops #!key (sync #f)) ...)

    (define (stream db
                    #!key
                    start
                    end
                    limit
                    reverse
                    (key #t)
                    (value #t)
                    fillcache)
      ..)))
```

## Implementations

- [leveldb](https://github.com/caolan/chicken-leveldb) - provides the `level`
  API to libleveldb
- [sublevel](https://github.com/caolan/chicken-sublevel) - provides namespaced
  API access to another implementation

[1]: https://github.com/caolan/chicken-leveldb
[2]: http://wiki.call-cc.org/eggref/4/lazy-seq
[3]: http://leveldb.googlecode.com/svn/trunk/doc/index.html
