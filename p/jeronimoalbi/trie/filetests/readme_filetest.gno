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
