package datastore

import (
	"strings"
	"testing"

	"gno.land/p/jeronimoalbi/expect/v0"
)

func TestStorageDefaults(t *testing.T) {
	name := "foo"
	storage := NewStorage(name)

	expect.
		Value(t, storage.Name()).
		AsString().
		ToEqual(name)
	expect.
		Value(t, storage.Collection()).
		WithFailPrefix("Expect a collection").
		Not().ToBeNil()
	expect.
		Value(t, storage.Size()).
		AsInt().
		ToEqual(0)

	s := storage.Schema()
	expect.
		Value(t, s).
		WithFailPrefix("Expect a schema").
		Not().ToBeNil()
	expect.
		Value(t, s.Name()).
		AsString().
		ToEqual(strings.Title(name))
}

func TestStorageNewRecord(t *testing.T) {
	field := "status"
	defaultValue := "testing"
	s := NewSchema("Foo", WithDefaultField(field, defaultValue))
	storage := NewStorage("foo", WithSchema(s))

	r := storage.NewRecord()
	expect.
		Value(t, r).
		WithFailPrefix("Expect new record not to be nil").
		Not().ToBeNil()
	expect.
		Value(t, r.ID()).
		AsUint().
		ToEqual(0)
	expect.
		Value(t, r.Type()).
		AsString().
		ToEqual(storage.Schema().Name())

	v, found := r.Get(field)
	expect.
		Value(t, found).
		WithFailPrefix("Expect default value to be found").
		AsBoolean().
		ToBeTruthy()

	got, ok := v.(string)
	expect.
		Value(t, ok).
		WithFailPrefix("Expect default value type to match").
		AsBoolean().
		ToBeTruthy()
	expect.
		Value(t, got).
		AsString().
		ToEqual(defaultValue)
}

func TestStorageQuery(t *testing.T) {
	index := NewIndex("tag", func(r Record) string {
		if v, found := r.Get("tag"); found {
			return v.(string)
		}
		return ""
	})

	cases := []struct {
		name    string
		options []QueryOption
		results []uint64
		setup   func() *Storage
		errMsg  string
	}{
		{
			name:    "default query",
			results: []uint64{1, 2},
			setup: func() *Storage {
				s := NewStorage("foo")
				s.NewRecord().Save()
				s.NewRecord().Save()
				return &s
			},
		},
		{
			name:    "with size",
			results: []uint64{1},
			options: []QueryOption{WithSize(1)},
			setup: func() *Storage {
				s := NewStorage("foo")
				s.NewRecord().Save()
				s.NewRecord().Save()
				return &s
			},
		},
		{
			name:    "with offset",
			results: []uint64{2},
			options: []QueryOption{WithOffset(1)},
			setup: func() *Storage {
				s := NewStorage("foo")
				s.NewRecord().Save()
				s.NewRecord().Save()
				return &s
			},
		},
		{
			name:    "with offset overflow",
			options: []QueryOption{WithOffset(4)},
			setup: func() *Storage {
				s := NewStorage("foo")
				s.NewRecord().Save()
				return &s
			},
		},
		{
			name:    "with size and offset",
			results: []uint64{2, 3},
			options: []QueryOption{WithSize(2), WithOffset(1)},
			setup: func() *Storage {
				s := NewStorage("foo")
				s.NewRecord().Save()
				s.NewRecord().Save()
				s.NewRecord().Save()
				s.NewRecord().Save()
				return &s
			},
		},
		{
			name:    "custom index",
			options: []QueryOption{UseIndex("tag", "A")},
			results: []uint64{1, 3},
			setup: func() *Storage {
				s := NewStorage("foo", WithIndex(index))

				r := s.NewRecord()
				r.Set("tag", "A")
				r.Save()

				r = s.NewRecord()
				r.Set("tag", "B")
				r.Save()

				r = s.NewRecord()
				r.Set("tag", "A")
				r.Save()

				return &s
			},
		},
		{
			name:    "custom index with offset",
			options: []QueryOption{UseIndex("tag", "B"), WithOffset(1)},
			results: []uint64{3, 4},
			setup: func() *Storage {
				s := NewStorage("foo", WithIndex(index))

				r := s.NewRecord()
				r.Set("tag", "B")
				r.Save()

				r = s.NewRecord()
				r.Set("tag", "A")
				r.Save()

				r = s.NewRecord()
				r.Set("tag", "B")
				r.Save()

				r = s.NewRecord()
				r.Set("tag", "B")
				r.Save()

				return &s
			},
		},
		{
			name:    "custom index with offset and size",
			options: []QueryOption{UseIndex("tag", "B"), WithOffset(1), WithSize(1)},
			results: []uint64{3},
			setup: func() *Storage {
				s := NewStorage("foo", WithIndex(index))

				r := s.NewRecord()
				r.Set("tag", "B")
				r.Save()

				r = s.NewRecord()
				r.Set("tag", "A")
				r.Save()

				r = s.NewRecord()
				r.Set("tag", "B")
				r.Save()

				r = s.NewRecord()
				r.Set("tag", "B")
				r.Save()

				return &s
			},
		},
		{
			name:    "custom index not found",
			options: []QueryOption{UseIndex("foo", "B")},
			setup: func() *Storage {
				s := NewStorage("foo")
				return &s
			},
			errMsg: "storage index for query not found: foo",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			storage := tc.setup()

			// Act
			rs, err := storage.Query(tc.options...)

			// Assert
			if tc.errMsg != "" {
				expect.
					Value(t, err).
					WithFailPrefix("Expect a query error").
					ToContainErrorString(tc.errMsg)
				return
			}

			expect.
				Value(t, err).
				WithFailPrefix("Expect no query error").
				ToBeNil()
			expect.
				Value(t, rs).
				WithFailPrefix("Expect recordset not to be nil").
				Not().ToBeNil()
			expect.
				Value(t, rs.Size()).
				WithFailPrefix("Expect query results count to match").
				AsInt().
				ToEqual(int64(len(tc.results)))

			var i int
			rs.Iterate(func(r Record) bool {
				expect.
					Value(t, r.ID()).
					WithFailPrefix("Expect result IDs to match").
					AsUint().
					ToEqual(tc.results[i])
				i++
				return false
			})
		})
	}
}

func TestStorageGet(t *testing.T) {
	index := NewIndex("name", func(r Record) string {
		if v, found := r.Get("name"); found {
			return v.(string)
		}
		return ""
	})

	cases := []struct {
		name     string
		key      string
		recordID uint64
		setup    func(*Storage)
	}{
		{
			name:     "single record",
			key:      "foobar",
			recordID: 1,
			setup: func(s *Storage) {
				r := s.NewRecord()
				r.Set("name", "foobar")
				r.Save()
			},
		},
		{
			name:     "two records",
			key:      "foobar",
			recordID: 1,
			setup: func(s *Storage) {
				r := s.NewRecord()
				r.Set("name", "foobar")
				r.Save()

				r = s.NewRecord()
				r.Set("name", "foobar")
				r.Save()

				r = s.NewRecord()
				r.Set("name", "extra")
				r.Save()
			},
		},
		{
			name: "record not found",
			key:  "unknown",
			setup: func(s *Storage) {
				r := s.NewRecord()
				r.Set("name", "foobar")
				r.Save()
			},
		},
		{
			name: "empty storage",
			key:  "foobar",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			storage := NewStorage("foo", WithIndex(index))
			if tc.setup != nil {
				tc.setup(&storage)
			}

			r, found := storage.Get(index.Name(), tc.key)

			if tc.recordID == 0 {
				expect.
					Value(t, r).
					WithFailPrefix("Expect no record").
					ToBeNil()
				expect.
					Value(t, found).
					WithFailPrefix("Expect record not found").
					AsBoolean().
					ToBeFalsy()
				return
			}

			expect.
				Value(t, found).
				WithFailPrefix("Expect record found").
				AsBoolean().
				ToBeTruthy()
			expect.
				Value(t, r).
				WithFailPrefix("Expect record to be found").
				Not().ToBeNil()
			expect.
				Value(t, r.ID()).
				WithFailPrefix("Expect ID to match").
				AsUint().
				ToEqual(tc.recordID)
		})
	}
}

func TestStorageGetByID(t *testing.T) {
	cases := []struct {
		name     string
		recordID uint64
		found    bool
		setup    func(*Storage)
	}{
		{
			name:     "single record",
			recordID: 1,
			found:    true,
			setup: func(s *Storage) {
				s.NewRecord().Save()
			},
		},
		{
			name:     "multiple records",
			recordID: 2,
			found:    true,
			setup: func(s *Storage) {
				s.NewRecord().Save()
				s.NewRecord().Save()
				s.NewRecord().Save()
			},
		},
		{
			name:     "record not found",
			recordID: 3,
			setup: func(s *Storage) {
				s.NewRecord().Save()
				s.NewRecord().Save()
			},
		},
		{
			name:     "empty storage",
			recordID: 1,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			storage := NewStorage("foo")
			if tc.setup != nil {
				tc.setup(&storage)
			}

			r, found := storage.GetByID(tc.recordID)

			if !tc.found {
				expect.
					Value(t, r).
					WithFailPrefix("Expect no record").
					ToBeNil()
				expect.
					Value(t, found).
					WithFailPrefix("Expect record not found").
					AsBoolean().
					ToBeFalsy()
				return
			}

			expect.
				Value(t, found).
				WithFailPrefix("Expect record found").
				AsBoolean().
				ToBeTruthy()
			expect.
				Value(t, r).
				WithFailPrefix("Expect record to be found").
				Not().ToBeNil()
			expect.
				Value(t, r.ID()).
				WithFailPrefix("Expect ID to match").
				AsUint().
				ToEqual(tc.recordID)
		})
	}
}

func TestStorageDelete(t *testing.T) {
	storage := NewStorage("foo")
	r := storage.NewRecord()
	r.Save()

	deleted := storage.Delete(r.ID())
	expect.
		Value(t, deleted).
		WithFailPrefix("Expect record to be deleted").
		AsBoolean().
		ToBeTruthy()

	deleted = storage.Delete(r.ID())
	expect.
		Value(t, deleted).
		WithFailPrefix("Expect record not to be deleted twice").
		AsBoolean().
		ToBeFalsy()
}
