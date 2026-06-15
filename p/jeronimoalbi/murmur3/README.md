# MurmurHash3 Package

Package implements Austin Appleby's MurmurHash3 algorithm.

MurmurHash3 is a fast, non-cryptographic hash function well suited for hash tables,
bloom filters, data partitioning, and deduplication where speed and good distribution
matter more than cryptographic security.

## Usage

[embedmd]:# (filetests/readme_filetest.gno go)
```go
package main

import "gno.land/p/jeronimoalbi/murmur3"

func main() {
	data := []byte("Hello, world!")
	seed := uint32(42)

	// Hash32 without seed
	h32 := murmur3.New32()
	h32.Write(data)
	sum32 := uint64(h32.Sum32())
	println(murmur3.EncodeToString(sum32))

	// Hash32 with seed
	h32 = murmur3.NewWithSeed32(seed)
	h32.Write(data)
	sum32 = uint64(h32.Sum32())
	println(murmur3.EncodeToString(sum32))

	// Hash32 without seed using a helper function
	sum32 = uint64(murmur3.Sum32(data))
	println(murmur3.EncodeToString(sum32))

	// Hash32 with seed using a helper function
	sum32 = uint64(murmur3.Sum32WithSeed(data, seed))
	println(murmur3.EncodeToString(sum32))

	// Hash64 without seed
	h64 := murmur3.New64()
	h64.Write(data)
	sum64 := h64.Sum64()
	println(murmur3.EncodeToString(sum64))

	// Hash64 with seed
	h64 = murmur3.NewWithSeed64(0, seed)
	h64.Write(data)
	sum64 = h64.Sum64()
	println(murmur3.EncodeToString(sum64))

	// Hash64 without seed using a helper function
	sum64 = murmur3.Sum64(data)
	println(murmur3.EncodeToString(sum64))

	// Hash64 with seed using a helper function
	sum64 = murmur3.Sum64WithSeed(data, 0, seed)
	println(murmur3.EncodeToString(sum64))
}

// Output:
// c0363e43
// 2c8c8533
// c0363e43
// 2c8c8533
// c0363e43aa5dc85b
// c0363e432c8c8533
// c0363e43aa5dc85b
// c0363e432c8c8533
```

## Hash32 Digest Type

### New32()

Returns a `hash.Hash32` with seed zero.

```go
func New32() hash.Hash32
```

### NewWithSeed32(seed)

Returns a `hash.Hash32` with the given seed.

```go
func NewWithSeed32(seed uint32) hash.Hash32
```

### Sum32(data)

One-shot hash with seed zero.

```go
func Sum32(data []byte) uint32
```

### Sum32WithSeed(data, seed)

One-shot hash with the given seed.

```go
func Sum32WithSeed(data []byte, seed uint32) uint32
```

### Hash32.Write(data)

Add `data` to the running hash (never returns an error).

```go
func (Hash32) Write(data []byte) (int, error)
```

### Hash32.Sum(b)

Append the hash, in little-endian order, to `b` and return the result.

```go
func (Hash32) Sum(b []byte) []byte
```

### Hash32.Sum32()

Return the current 32-bit hash value.

```go
func (Hash32) Sum32() uint32
```

### Hash32.Reset()

Reset the hash to its initial state, keeping the seed.

```go
func (Hash32) Reset()
```

### Hash32.Size()

Return the number of bytes the hash produces (4).

```go
func (Hash32) Size() int
```

### Hash32.BlockSize()

Return the hash block size in bytes (4).

```go
func (Hash32) BlockSize() int
```

## Hash64 Digest Type

### New64()

Returns a `hash.Hash64` using seeds zero and one.

```go
func New64() hash.Hash64
```

### NewWithSeed64(seed1, seed2)

Returns a `hash.Hash64` with the given seeds.

```go
func NewWithSeed64(seed1, seed2 uint32) hash.Hash64
```

### Sum64(data)

One-shot 64-bit hash using seeds zero and one.

```go
func Sum64(data []byte) uint64
```

### Sum64WithSeed(data, seed1, seed2)

One-shot 64-bit hash with the given seeds.

```go
func Sum64WithSeed(data []byte, seed1, seed2 uint32) uint64
```

### Hash64.Write(data)

Add `data` to the running hash (never returns an error).

```go
func (Hash64) Write(data []byte) (int, error)
```

### Hash64.Sum(b)

Append the hash, in little-endian order, to `b` and return the result.

```go
func (Hash64) Sum(b []byte) []byte
```

### Hash64.Sum64()

Return the current 64-bit hash value.

```go
func (Hash64) Sum64() uint64
```

### Hash64.Reset()

Reset the hash to its initial state, keeping the seeds.

```go
func (Hash64) Reset()
```

### Hash64.Size()

Return the number of bytes the hash produces (8).

```go
func (Hash64) Size() int
```

### Hash64.BlockSize()

Return the hash block size in bytes (4).

```go
func (Hash64) BlockSize() int
```

## Encoding

### EncodeToString(sum)

Returns the hexadecimal encoding of a hash value.

```go
func EncodeToString(sum uint64) string
```
