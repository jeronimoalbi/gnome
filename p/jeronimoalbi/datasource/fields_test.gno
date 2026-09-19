package datasource

import (
	"testing"

	"gno.land/p/jeronimoalbi/expect"
)

func TestNewFieldsFromMap(t *testing.T) {
	cases := []struct {
		name  string
		input map[string]any
		field string
		found bool
	}{
		{
			name:  "existing field",
			input: map[string]any{"foo": "bar"},
			field: "foo",
			found: true,
		},
		{
			name:  "existing field with nil value",
			input: map[string]any{"foo": nil},
			field: "foo",
			found: true,
		},
		{
			name:  "missing field",
			input: map[string]any{"foo": "bar"},
			field: "baz",
		},
		{
			name:  "empty map",
			input: map[string]any{},
			field: "foo",
		},
		{
			name:  "nil map",
			field: "foo",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			fields := NewFieldsFromMap(tc.input)

			// Act
			has := fields.Has(tc.field)
			value, found := fields.Get(tc.field)

			// Assert
			expect.
				Value(t, has).
				WithFailPrefix("Expect field existence to match").
				AsBoolean().
				ToEqual(tc.found)
			expect.
				Value(t, found).
				WithFailPrefix("Expect found flag to match").
				AsBoolean().
				ToEqual(tc.found)

			// Assert: Missing fields and fields assigned to nil both have a nil value
			want := tc.input[tc.field]
			if want == nil {
				expect.
					Value(t, value).
					WithFailPrefix("Expect a nil field value").
					ToBeNil()
				return
			}

			expect.
				Value(t, value).
				WithFailPrefix("Expect field value to match").
				ToEqual(want)
		})
	}
}

func TestNewFieldsFromMapWrapsMap(t *testing.T) {
	// Arrange
	m := map[string]any{}
	fields := NewFieldsFromMap(m)

	expect.
		Value(t, fields.Has("foo")).
		WithFailPrefix("Expect field to not exist before it is added to the map").
		AsBoolean().
		ToBeFalsy()

	// Act
	m["foo"] = "bar"

	// Assert
	expect.
		Value(t, fields.Has("foo")).
		WithFailPrefix("Expect field to exist after it is added to the map").
		AsBoolean().
		ToBeTruthy()

	value, found := fields.Get("foo")
	expect.
		Value(t, found).
		WithFailPrefix("Expect field to be found").
		AsBoolean().
		ToBeTruthy()
	expect.
		Value(t, value).
		WithFailPrefix("Expect field value to match").
		ToEqual("bar")
}
