package datasource

import (
	"fmt"
	"testing"

	"gno.land/p/jeronimoalbi/expect"
)

func TestNewQuery(t *testing.T) {
	cases := []struct {
		name    string
		options []QueryOption
		setup   func() Query
	}{
		{
			name: "default",
			setup: func() Query {
				return Query{Count: DefaultQueryRecords}
			},
		},
		{
			name:    "with offset",
			options: []QueryOption{WithOffset(100)},
			setup: func() Query {
				return Query{
					Offset: 100,
					Count:  DefaultQueryRecords,
				}
			},
		},
		{
			name:    "with count",
			options: []QueryOption{WithCount(10)},
			setup: func() Query {
				return Query{Count: 10}
			},
		},
		{
			name:    "with invalid count",
			options: []QueryOption{WithCount(0)},
			setup: func() Query {
				return Query{Count: DefaultQueryRecords}
			},
		},
		{
			name:    "by tag",
			options: []QueryOption{ByTag("foo")},
			setup: func() Query {
				return Query{
					Tag:   "foo",
					Count: DefaultQueryRecords,
				}
			},
		},
		{
			name:    "with filter",
			options: []QueryOption{WithFilter("foo", 42)},
			setup: func() Query {
				q := Query{Count: DefaultQueryRecords}
				q.Filters.Set("foo", 42)
				return q
			},
		},
		{
			name: "with multiple filters",
			options: []QueryOption{
				WithFilter("foo", 42),
				WithFilter("bar", "baz"),
			},
			setup: func() Query {
				q := Query{Count: DefaultQueryRecords}
				q.Filters.Set("foo", 42)
				q.Filters.Set("bar", "baz")
				return q
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			want := tc.setup()

			// Act
			q := NewQuery(tc.options...)

			// Assert
			expect.
				Value(t, q.Offset).
				WithFailPrefix("Expect offset to match").
				AsInt().
				ToEqual(int64(want.Offset))
			expect.
				Value(t, q.Count).
				WithFailPrefix("Expect count to match").
				AsInt().
				ToEqual(int64(want.Count))
			expect.
				Value(t, q.Tag).
				WithFailPrefix("Expect tag to match").
				AsString().
				ToEqual(want.Tag)
			expect.
				Value(t, q.Filters.Size()).
				WithFailPrefix("Expect filters count to match").
				AsInt().
				ToEqual(int64(want.Filters.Size()))

			want.Filters.Iterate("", "", func(k string, v any) bool {
				expect.
					Value(t, q.Filters.Has(k)).
					WithFailPrefix("Expect filter to exist: " + k).
					AsBoolean().
					ToBeTruthy()

				got := q.Filters.Get(k)
				expect.
					Value(t, fmt.Sprint(got)).
					WithFailPrefix("Expect filter value to match: " + k).
					AsString().
					ToEqual(fmt.Sprint(v))
				return false
			})
		})
	}
}
