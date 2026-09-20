package datastore

import (
	"testing"

	"gno.land/p/jeronimoalbi/expect/v0"
)

func TestSchemaNew(t *testing.T) {
	cases := []struct {
		name    string
		options []SchemaOption
		fields  []string
		strict  bool
	}{
		{
			name: "default",
		},
		{
			name:    "strict",
			options: []SchemaOption{Strict()},
			strict:  true,
		},
		{
			name: "with fields",
			options: []SchemaOption{
				WithField("foo"),
				WithField("bar"),
				WithDefaultField("baz", 42),
			},
			fields: []string{"foo", "bar", "baz"},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			s := NewSchema("Foo", tc.options...)

			expect.
				Value(t, s.Name()).
				AsString().
				ToEqual("Foo")
			expect.
				Value(t, s.IsStrict()).
				AsBoolean().
				ToEqual(tc.strict)
			expect.
				Value(t, s.Size()).
				WithFailPrefix("expect field count to match").
				AsInt().
				ToEqual(int64(len(tc.fields)))

			for i, name := range s.Fields() {
				expect.
					Value(t, name).
					AsString().
					ToEqual(tc.fields[i])
				expect.
					Value(t, s.HasField(name)).
					AsBoolean().
					ToBeTruthy()
			}
		})
	}
}

func TestSchemaAddField(t *testing.T) {
	cases := []struct {
		name       string
		options    []SchemaOption
		fieldName  string
		fieldIndex int
		fields     []string
		success    bool
	}{
		{
			name:       "new only field",
			fieldName:  "foo",
			fieldIndex: 0,
			fields:     []string{"foo"},
			success:    true,
		},
		{
			name: "new existing fields",
			options: []SchemaOption{
				WithField("foo"),
				WithField("bar"),
			},
			fieldName:  "baz",
			fieldIndex: 2,
			fields:     []string{"foo", "bar", "baz"},
			success:    true,
		},
		{
			name:       "duplicated field",
			options:    []SchemaOption{WithField("foo")},
			fieldName:  "foo",
			fieldIndex: -1,
			fields:     []string{"foo"},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			s := NewSchema("Foo", tc.options...)

			index, added := s.AddField(tc.fieldName, nil)

			if tc.success {
				expect.
					Value(t, index).
					AsInt().
					ToEqual(int64(tc.fieldIndex))
				expect.
					Value(t, added).
					AsBoolean().
					ToBeTruthy()
			} else {
				expect.
					Value(t, index).
					AsInt().
					ToEqual(-1)
				expect.
					Value(t, added).
					AsBoolean().
					ToBeFalsy()
			}

			expect.
				Value(t, s.Size()).
				WithFailPrefix("expect field count to match").
				AsInt().
				ToEqual(int64(len(tc.fields)))

			for i, name := range s.Fields() {
				expect.
					Value(t, name).
					AsString().
					ToEqual(tc.fields[i])
				expect.
					Value(t, s.HasField(name)).
					AsBoolean().
					ToBeTruthy()
			}
		})
	}
}

func TestSchemaGetFieldIndex(t *testing.T) {
	s := NewSchema("Foo")
	s.AddField("foo", nil)
	s.AddField("bar", nil)
	s.AddField("baz", nil)

	expect.Value(t, s.GetFieldIndex("foo")).AsInt().ToEqual(0)
	expect.Value(t, s.GetFieldIndex("bar")).AsInt().ToEqual(1)
	expect.Value(t, s.GetFieldIndex("baz")).AsInt().ToEqual(2)

	expect.Value(t, s.GetFieldIndex("")).AsInt().ToEqual(-1)
	expect.Value(t, s.GetFieldIndex("unknown")).AsInt().ToEqual(-1)
}

func TestSchemaGetFieldName(t *testing.T) {
	s := NewSchema("Foo")
	s.AddField("foo", nil)
	s.AddField("bar", nil)
	s.AddField("baz", nil)

	name, found := s.GetFieldName(0)
	expect.Value(t, name).AsString().ToEqual("foo")
	expect.Value(t, found).AsBoolean().ToBeTruthy()

	name, found = s.GetFieldName(1)
	expect.Value(t, name).AsString().ToEqual("bar")
	expect.Value(t, found).AsBoolean().ToBeTruthy()

	name, found = s.GetFieldName(2)
	expect.Value(t, name).AsString().ToEqual("baz")
	expect.Value(t, found).AsBoolean().ToBeTruthy()

	name, found = s.GetFieldName(404)
	expect.Value(t, name).AsString().ToBeEmpty()
	expect.Value(t, found).AsBoolean().ToBeFalsy()
}

func TestSchemaGetDefault(t *testing.T) {
	s := NewSchema("Foo")
	s.AddField("foo", nil)
	s.AddField("bar", 42)

	_, found := s.GetDefault("foo")
	expect.Value(t, found).AsBoolean().ToBeFalsy()

	v, found := s.GetDefault("bar")
	expect.Value(t, found).AsBoolean().ToBeTruthy()

	got, ok := v.(int)
	expect.
		Value(t, ok).
		WithFailPrefix("expect default field value type to match").
		AsBoolean().
		ToBeTruthy()
	expect.Value(t, got).AsInt().ToEqual(42)
}

func TestSchemaGetDefaultByIndex(t *testing.T) {
	s := NewSchema("Foo")
	s.AddField("foo", nil)
	s.AddField("bar", 42)

	_, found := s.GetDefaultByIndex(0)
	expect.Value(t, found).AsBoolean().ToBeFalsy()

	_, found = s.GetDefaultByIndex(404)
	expect.Value(t, found).AsBoolean().ToBeFalsy()

	v, found := s.GetDefaultByIndex(1)
	expect.Value(t, found).AsBoolean().ToBeTruthy()

	got, ok := v.(int)
	expect.
		Value(t, ok).
		WithFailPrefix("expect default field value type to match").
		AsBoolean().
		ToBeTruthy()
	expect.Value(t, got).AsInt().ToEqual(42)
}

func TestSchemaRenameField(t *testing.T) {
	s := NewSchema("Foo")
	s.AddField("foo", nil)
	s.AddField("bar", nil)

	renamed := s.RenameField("foo", "bar")
	expect.Value(t, renamed).AsBoolean().ToBeFalsy()

	renamed = s.RenameField("", "baz")
	expect.Value(t, renamed).AsBoolean().ToBeFalsy()

	renamed = s.RenameField("foo", "")
	expect.Value(t, renamed).AsBoolean().ToBeTruthy()

	renamed = s.RenameField("", "foo")
	expect.Value(t, renamed).AsBoolean().ToBeTruthy()

	renamed = s.RenameField("foo", "foobar")
	expect.Value(t, renamed).AsBoolean().ToBeTruthy()

	expect.
		Value(t, s.Size()).
		WithFailPrefix("expect field count to match").
		AsInt().
		ToEqual(2)

	fields := []string{"foobar", "bar"}
	for i, name := range s.Fields() {
		expect.
			Value(t, name).
			AsString().
			ToEqual(fields[i])
		expect.
			Value(t, s.HasField(name)).
			AsBoolean().
			ToBeTruthy()
	}
}
