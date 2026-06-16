# Bloom Package

Package implements a Bloom filter, a space-efficient probabilistic data structure
used to test whether an element is a member of a set.

A Bloom filter never returns a false negative: if `Contains` returns `false`, the
element was definitely never added. It may return a false positive: `Contains` can
return `true` for an element that was never added. This trade-off lets the filter
use far less memory than storing the elements themselves, which makes it useful for
membership checks such as caches, deduplication, or "have I seen this before?" tests.

## Usage

[embedmd]:# (filetests/readme_filetest.gno go)
```go
package main

import "gno.land/p/jeronimoalbi/bloom"

func main() {
	// Create a filter expecting up to 1000 items with a 1% false-positive rate.
	b := bloom.New(1000, 0.01)

	b.AddString("apple").AddString("banana")

	println("Has apple:", b.ContainsString("apple"))
	println("Has banana:", b.ContainsString("banana"))
	println("Has cherry:", b.ContainsString("cherry"))
}

// Output:
// Has apple: true
// Has banana: true
// Has cherry: false
```

## Bloom Type

### New(maxItems, falsePositiveRate)

Returns a filter sized optimally for up to `maxItems` elements at the given false-positive rate (e.g. `0.01`).

```go
New(maxItems uint64, falsePositiveRate float64) *Bloom
```

### NewWithMK(m, k)

Returns a filter with an explicit bit-array size `m` and hash count `k`.

```go
NewWithMK(m, k uint64) *Bloom
```

### Bloom.Add(data)

Insert `data` into the filter (returns the filter for chaining).

```go
func (*Bloom) Add(data []byte) *Bloom
```

### Bloom.AddString(data)

Insert string `data` into the filter (returns the filter for chaining).

```go
func (*Bloom) AddString(data string) *Bloom
```

### Bloom.Contains(data)

Report whether `data` is possibly in the set (`false` means definitely absent).

```go
func (*Bloom) Contains(data []byte) bool
```

### Bloom.ContainsString(data)

Report whether string `data` is possibly in the set (`false` means definitely absent).

```go
func (*Bloom) ContainsString(data string) bool
```

### Bloom.Reset()

Clear all values, keeping the filter's capacity and hash count (returns the filter for chaining).

```go
func (*Bloom) Reset() *Bloom
```

### Bloom.Capacity()

Return the bit-array size `m` of the filter.

```go
func (*Bloom) Capacity() uint64
```

### Bloom.HashFunctions()

Return the number of hash functions `k` of the filter.

```go
func (*Bloom) HashFunctions() uint64
```
