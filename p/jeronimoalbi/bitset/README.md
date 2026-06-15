# Bitset Package

Package implements an arbitrary-size bit set, also known as bit array.

Bit sets are useful when you need a compact way to track large sets of boolean flags,
such as permissions, feature toggles, or membership sets, using significantly less
memory than a slice of booleans while also supporting fast bulk operations across
entire sets.

## Usage

[embedmd]:# (filetests/readme_filetest.gno go)
```go
package main

import "gno.land/p/jeronimoalbi/bitset"

const (
	PermRead   = 0
	PermWrite  = 1
	PermDelete = 2
	PermAdmin  = 3
)

func main() {
	var perms bitset.BitSet
	perms.Set(PermRead)
	perms.Set(PermWrite)

	println("Can read:", perms.IsSet(PermRead))
	println("Can write:", perms.IsSet(PermWrite))
	println("Can delete:", perms.IsSet(PermDelete))
	println("Is admin:", perms.IsSet(PermAdmin))
	println("Permissions set:", perms.Len())
}

// Output:
// Can read: true
// Can write: true
// Can delete: false
// Is admin: false
// Permissions set: 2
```

## BitSet Type

### New(size)

Returns a new `BitSet` pre-allocated for `size` bits.

```go
func New(size uint64) BitSet
```

### BitSet.Set(i)

Turn on the bit at position `i`.

```go
func (*BitSet) Set(i uint64)
```

### BitSet.Clear(i)

Turn off the bit at position `i`.

```go
func (*BitSet) Clear(i uint64)
```

### BitSet.ClearAll()

Turn off all bits.

```go
func (*BitSet) ClearAll()
```

### BitSet.Compact()

Reclaim memory by removing trailing zero words.

```go
func (*BitSet) Compact()
```

### BitSet.IsSet(i)

Check whether the bit at position `i` is set.

```go
func (BitSet) IsSet(i uint64) bool
```

### BitSet.Size()

Return the total number of bits currently allocated.

```go
func (BitSet) Size() int
```

### BitSet.Len()

Return the number of set bits.

```go
func (BitSet) Len() int
```

### BitSet.And(other)

In-place intersection with another set.

```go
func (*BitSet) And(other BitSet)
```

### BitSet.Or(other)

In-place union with another set.

```go
func (*BitSet) Or(other BitSet)
```

### BitSet.Xor(other)

In-place symmetric difference with another set.

```go
func (*BitSet) Xor(other BitSet)
```

### BitSet.Equal(other)

Check whether two sets have the same bits set.

```go
func (BitSet) Equal(other BitSet) bool
```

### BitSet.String()

Return a binary (MSB-first) representation of the set.

```go
func (BitSet) String() string
```

### BitSet.PaddedString()

Return a zero-padded binary (MSB-first) representation of the set.

```go
func (BitSet) PaddedString() string
```
