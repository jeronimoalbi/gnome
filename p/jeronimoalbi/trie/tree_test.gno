package trie_test

import (
	"testing"

	"gno.land/p/jeronimoalbi/trie"
)

func TestNewTree(t *testing.T) {
	tree := trie.NewTree()
	if tree.Size() != 0 {
		t.Error("Expected new tree size to be 0")
	}
}

func TestZeroValueTree(t *testing.T) {
	var tree trie.Tree
	if tree.Size() != 0 {
		t.Error("Expected zero-value tree size to be 0")
	}

	if tree.Has("key") {
		t.Error("Expected zero-value tree to have no keys")
	}

	if updated := tree.Set("key", "value"); updated {
		t.Error("Expected Set on empty tree to insert, not update")
	}

	if !tree.Has("key") {
		t.Error("Expected zero-value tree to be usable after Set")
	}
}

func TestTreeSize(t *testing.T) {
	tree := trie.NewTree()
	if tree.Size() != 0 {
		t.Error("Expected empty tree size to be 0")
	}

	tree.Set("key1", "value1")
	tree.Set("key2", "value2")
	if tree.Size() != 2 {
		t.Error("Expected tree size to be 2")
	}

	// Updating an existing key must not change the size.
	if updated := tree.Set("key1", "updated"); !updated {
		t.Error("Expected Set on existing key to report updated=true")
	}

	if tree.Size() != 2 {
		t.Error("Expected tree size to remain 2 after update")
	}
}

func TestTreeHas(t *testing.T) {
	tree := trie.NewTree()
	tree.Set("key1", "value1")

	if !tree.Has("key1") {
		t.Error("Expected tree to have key1")
	}

	if tree.Has("key2") {
		t.Error("Expected tree to not have key2")
	}
}

func TestTreeGet(t *testing.T) {
	tree := trie.NewTree()
	tree.Set("key1", "value1")

	value, exists := tree.Get("key1")
	if !exists || value != "value1" {
		t.Error("Expected Get to return value1 and true")
	}

	_, exists = tree.Get("key2")
	if exists {
		t.Error("Expected Get to return false for non-existent key")
	}
}

func TestTreeGetByIndex(t *testing.T) {
	tree := trie.NewTree()
	tree.Set("key1", "value1")
	tree.Set("key2", "value2")

	key, value := tree.GetByIndex(0)
	if key != "key1" || value != "value1" {
		t.Error("Expected GetByIndex(0) to return key1 and value1")
	}

	key, value = tree.GetByIndex(1)
	if key != "key2" || value != "value2" {
		t.Error("Expected GetByIndex(1) to return key2 and value2")
	}

	defer func() {
		if r := recover(); r == nil {
			t.Error("Expected GetByIndex to panic for out-of-range index")
		}
	}()
	tree.GetByIndex(2)
}

func TestTreeRemove(t *testing.T) {
	tree := trie.NewTree()
	tree.Set("key1", "value1")

	value, removed := tree.Remove("key1")
	if !removed || value != "value1" || tree.Size() != 0 {
		t.Error("Expected Remove to remove key-value pair")
	}

	_, removed = tree.Remove("key2")
	if removed {
		t.Error("Expected Remove to return false for non-existent key")
	}
}

func TestTreeIterate(t *testing.T) {
	tree := trie.NewTree()
	tree.Set("key1", "value1")
	tree.Set("key2", "value2")
	tree.Set("key3", "value3")

	var keys []string
	tree.Iterate("", "", func(key string, value any) bool {
		keys = append(keys, key)
		return false
	})

	expectedKeys := []string{"key1", "key2", "key3"}
	if !slicesEqual(keys, expectedKeys) {
		t.Errorf("Expected keys %v, got %v", expectedKeys, keys)
	}
}

func TestTreeIterateRange(t *testing.T) {
	tree := trie.NewTree()
	for _, k := range []string{"a", "b", "c", "d", "e"} {
		tree.Set(k, k)
	}

	// Ascending: start inclusive, end exclusive.
	var keys []string
	tree.Iterate("b", "d", func(key string, value any) bool {
		keys = append(keys, key)
		return false
	})

	if want := []string{"b", "c"}; !slicesEqual(keys, want) {
		t.Errorf("Iterate range: got %v, want %v", keys, want)
	}

	// Early termination stops the walk and is reported.
	keys = nil
	stopped := tree.Iterate("", "", func(key string, value any) bool {
		keys = append(keys, key)
		return key == "b"
	})

	if !stopped {
		t.Error("Expected Iterate to report early termination")
	}

	if want := []string{"a", "b"}; !slicesEqual(keys, want) {
		t.Errorf("Iterate early stop: got %v, want %v", keys, want)
	}
}

func TestTreeReverseIterate(t *testing.T) {
	tree := trie.NewTree()
	tree.Set("key1", "value1")
	tree.Set("key2", "value2")
	tree.Set("key3", "value3")

	var keys []string
	tree.ReverseIterate("", "", func(key string, value any) bool {
		keys = append(keys, key)
		return false
	})

	expectedKeys := []string{"key3", "key2", "key1"}
	if !slicesEqual(keys, expectedKeys) {
		t.Errorf("Expected keys %v, got %v", expectedKeys, keys)
	}
}

func TestTreeReverseIterateRange(t *testing.T) {
	tree := trie.NewTree()
	for _, k := range []string{"a", "b", "c", "d", "e"} {
		tree.Set(k, k)
	}

	// Descending: both start and end are inclusive.
	var keys []string
	tree.ReverseIterate("b", "d", func(key string, value any) bool {
		keys = append(keys, key)
		return false
	})

	if want := []string{"d", "c", "b"}; !slicesEqual(keys, want) {
		t.Errorf("ReverseIterate range: got %v, want %v", keys, want)
	}
}

func TestTreeIterateByOffset(t *testing.T) {
	tree := trie.NewTree()
	tree.Set("key1", "value1")
	tree.Set("key2", "value2")
	tree.Set("key3", "value3")

	var keys []string
	tree.IterateByOffset(1, 2, func(key string, value any) bool {
		keys = append(keys, key)
		return false
	})

	expectedKeys := []string{"key2", "key3"}
	if !slicesEqual(keys, expectedKeys) {
		t.Errorf("Expected keys %v, got %v", expectedKeys, keys)
	}
}

func TestTreeReverseIterateByOffset(t *testing.T) {
	tree := trie.NewTree()
	tree.Set("key1", "value1")
	tree.Set("key2", "value2")
	tree.Set("key3", "value3")

	var keys []string
	tree.ReverseIterateByOffset(1, 2, func(key string, value any) bool {
		keys = append(keys, key)
		return false
	})

	expectedKeys := []string{"key2", "key1"}
	if !slicesEqual(keys, expectedKeys) {
		t.Errorf("Expected keys %v, got %v", expectedKeys, keys)
	}
}

func TestTreeReverseIterateByOffsetVaried(t *testing.T) {
	tree := trie.NewTree()
	tree.Set("a", 1)
	tree.Set("b", 2)
	tree.Set("c", 3)
	tree.Set("d", 4)
	tree.Set("e", 5)

	// All keys in reverse: e d c b a
	cases := []struct {
		offset int
		limit  int
		want   []string
	}{
		{0, 5, []string{"e", "d", "c", "b", "a"}},
		{0, 1, []string{"e"}},
		{0, 3, []string{"e", "d", "c"}},
		{1, 2, []string{"d", "c"}},
		{2, 2, []string{"c", "b"}},
		{3, 5, []string{"b", "a"}},
		{4, 1, []string{"a"}},
		{4, 10, []string{"a"}},
		{5, 1, nil},
		{0, 0, nil},
		{10, 1, nil},
	}

	for _, tc := range cases {
		var got []string
		tree.ReverseIterateByOffset(tc.offset, tc.limit, func(key string, value any) bool {
			got = append(got, key)
			return false
		})

		if !slicesEqual(got, tc.want) {
			t.Errorf("ReverseIterateByOffset(%d, %d): got %v, want %v", tc.offset, tc.limit, got, tc.want)
		}
	}

	// Early termination: stop after 2 items from offset 1.
	var got []string
	tree.ReverseIterateByOffset(1, 5, func(key string, value any) bool {
		got = append(got, key)
		return len(got) >= 2
	})

	want := []string{"d", "c"}
	if !slicesEqual(got, want) {
		t.Errorf("ReverseIterateByOffset early stop: got %v, want %v", got, want)
	}
}

// --- trie-specific behaviour: shared prefixes ---

func TestTreePrefixKeys(t *testing.T) {
	tree := trie.NewTree()
	// Keys where some keys are prefixes of others.
	tree.Set("a", 1)
	tree.Set("ab", 2)
	tree.Set("abc", 3)
	tree.Set("abd", 4)
	tree.Set("b", 5)

	if tree.Size() != 5 {
		t.Errorf("Expected size 5, got %d", tree.Size())
	}

	// Every key resolves to its own value.
	for k, want := range map[string]int{"a": 1, "ab": 2, "abc": 3, "abd": 4, "b": 5} {
		if v, ok := tree.Get(k); !ok || v != want {
			t.Errorf("Get(%q) = %v, %v; want %d, true", k, v, ok, want)
		}
	}

	// A prefix that was never stored must not be reported as a key.
	if tree.Has("") {
		t.Error("Expected empty string to be absent")
	}

	// In-order traversal yields lexicographic order, with prefixes first.
	var keys []string
	tree.Iterate("", "", func(key string, value any) bool {
		keys = append(keys, key)
		return false
	})

	want := []string{"a", "ab", "abc", "abd", "b"}
	if !slicesEqual(keys, want) {
		t.Errorf("Iterate order: got %v, want %v", keys, want)
	}
}

func TestTreeRemovePrefix(t *testing.T) {
	tree := trie.NewTree()
	tree.Set("ab", 1)
	tree.Set("abc", 2)

	// Removing a key that is a prefix must keep the longer key intact.
	if _, removed := tree.Remove("ab"); !removed {
		t.Error("Expected to remove ab")
	}

	if tree.Has("ab") {
		t.Error("Expected ab to be gone")
	}

	if v, ok := tree.Get("abc"); !ok || v != 2 {
		t.Errorf("Expected abc to remain, got %v, %v", v, ok)
	}

	// Removing the longer key prunes the now-empty branch; re-adding works.
	if _, removed := tree.Remove("abc"); !removed {
		t.Error("Expected to remove abc")
	}

	if tree.Size() != 0 {
		t.Errorf("Expected empty tree, got size %d", tree.Size())
	}

	tree.Set("abc", 9)
	if v, ok := tree.Get("abc"); !ok || v != 9 {
		t.Errorf("Expected abc=9 after re-insert, got %v, %v", v, ok)
	}
}

func TestTreeEmptyKey(t *testing.T) {
	tree := trie.NewTree()
	if updated := tree.Set("", "root"); updated {
		t.Error("Expected empty key insert to report updated=false")
	}

	tree.Set("a", "a")

	if v, ok := tree.Get(""); !ok || v != "root" {
		t.Errorf("Expected empty key to store a value, got %v, %v", v, ok)
	}

	// The empty key is the smallest key: first ascending, last descending.
	var keys []string
	tree.Iterate("", "", func(key string, value any) bool {
		keys = append(keys, key)
		return false
	})

	if want := []string{"", "a"}; !slicesEqual(keys, want) {
		t.Errorf("Iterate with empty key: got %v, want %v", keys, want)
	}

	if v, removed := tree.Remove(""); !removed || v != "root" {
		t.Errorf("Expected to remove empty key, got %v, %v", v, removed)
	}

	if tree.Has("") {
		t.Error("Expected empty key to be gone")
	}
}

func slicesEqual(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}

	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}
