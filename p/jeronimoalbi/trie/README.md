# Trie Package

Package implements a simple prefix-tree (trie) for Gno realms, keyed by
`string` with values of any type.

`Tree` implements the [`avl.ITree`](https://gno.land/p/nt/avl/v0$source&file=tree.gno)
interface from `gno.land/p/nt/avl`, so it can be used as a drop-in alternative
to an AVL tree.

## Usage

[embedmd]:# (filetests/readme_filetest.gno go)
```go
package main

import "gno.land/p/jeronimoalbi/trie"

func main() {
    tree := trie.NewTree()
    tree.Set("apple", 1)
    tree.Set("app", 2)
    tree.Set("banana", 3)

    // Get value for app
    v, ok := tree.Get("app")
    println(v, ok)

    // Iterate keys in lexicographic order: app, apple, banana.
    tree.Iterate("", "", func(key string, value any) bool {
        println(key, value)
        return false
    })
}

// Output:
// 2 true
// app 2
// apple 1
// banana 3
```

## Tree Type

`Tree` implements the full `avl.ITree` API.

The zero `Tree` value is a valid empty tree.

### NewTree()

Creates a new empty trie.

```go
func NewTree() *Tree
```

### Tree.Size()

Return the number of key-value pairs stored in the tree.

```go
func (*Tree) Size() int
```

### Tree.Has(key)

Report whether `key` exists in the tree.

```go
func (*Tree) Has(key string) bool
```

### Tree.Get(key)

Retrieve the value associated with `key`, and whether it exists.

```go
func (*Tree) Get(key string) (value any, exists bool)
```

### Tree.GetByIndex(index)

Retrieve the key-value pair at `index` in lexicographic order (panics if out of range).

```go
func (*Tree) GetByIndex(index int) (key string, value any)
```

### Tree.Set(key, value)

Insert or update a pair; returns `true` when the key already existed and was updated.

```go
func (*Tree) Set(key string, value any) (updated bool)
```

### Tree.Remove(key)

Delete the pair stored under `key`, returns the removed value and whether it was found.

```go
func (*Tree) Remove(key string) (value any, removed bool)
```

### Tree.Iterate(start, end, cb)

Ascending traversal over the range `[start, end)`, `start` inclusive, `end` exclusive.
An empty bound is unbounded on that side.
Returns whether the callback stopped iteration early.

```go
func (*Tree) Iterate(start, end string, cb avl.IterCbFn) bool
```

### Tree.ReverseIterate(start, end, cb)

Descending traversal over the range `[start, end]`, both bounds inclusive.
An empty bound is unbounded on that side.
Returns whether the callback stopped iteration early.

```go
func (*Tree) ReverseIterate(start, end string, cb avl.IterCbFn) bool
```

### Tree.IterateByOffset(offset, count, cb)

Ascending traversal that skips the first `offset` keys then visits up to `count` keys.
Returns whether the callback stopped iteration early.

```go
func (*Tree) IterateByOffset(offset int, count int, cb avl.IterCbFn) bool
```

### Tree.ReverseIterateByOffset(offset, count, cb)

Descending variant of `IterateByOffset`.
Returns whether the callback stopped iteration early.

```go
func (*Tree) ReverseIterateByOffset(offset int, count int, cb avl.IterCbFn) bool
```
