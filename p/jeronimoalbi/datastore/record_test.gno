package datastore

import (
	"testing"

	"gno.land/p/jeronimoalbi/expect"
)

var (
	_ Record    = (*record)(nil)
	_ Recordset = (*recordset)(nil)
)

func TestRecordDefaults(t *testing.T) {
	// Arrange
	storage := NewStorage("foo")

	// Act
	r := storage.NewRecord()

	// Assert
	expect.Value(t, r.ID()).AsUint().ToEqual(0)
	expect.Value(t, r.Key()).AsString().ToEqual("0000000")
	expect.Value(t, r.Type()).AsString().ToEqual("Foo")
	expect.Value(t, len(r.Fields())).AsInt().ToEqual(0)
	expect.Value(t, r.IsEmpty()).AsBoolean().ToBeTruthy()
}

func TestRecordHasField(t *testing.T) {
	storage := NewStorage("foo")
	storage.Schema().AddField("foo", nil)

	r := storage.NewRecord()

	expect.Value(t, r.HasField("foo")).AsBoolean().ToBeTruthy()
	expect.Value(t, r.HasField("undefined")).AsBoolean().ToBeFalsy()
}

func TestRecordSet(t *testing.T) {
	cases := []struct {
		name        string
		options     []SchemaOption
		field       string
		fieldsCount int
		value       int
		err         error
	}{
		{
			name:        "first new field",
			field:       "test",
			fieldsCount: 1,
			value:       42,
		},
		{
			name: "new extra field",
			options: []SchemaOption{
				WithField("foo"),
				WithField("bar"),
			},
			field:       "test",
			fieldsCount: 3,
			value:       42,
		},
		{
			name: "existing field",
			options: []SchemaOption{
				WithField("test"),
			},
			field:       "test",
			fieldsCount: 1,
			value:       42,
		},
		{
			name:        "undefined field",
			options:     []SchemaOption{Strict()},
			field:       "test",
			fieldsCount: 1,
			value:       42,
			err:         ErrUndefinedField,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			s := NewSchema("Foo", tc.options...)
			storage := NewStorage("foo", WithSchema(s))
			r := storage.NewRecord()

			// Act
			err := r.Set(tc.field, tc.value)

			// Assert
			if tc.err != nil {
				expect.
					Func(t, func() error { return err }).
					WithFailPrefix("expect a set error").
					ToFail().
					WithError(tc.err)
				return
			}

			expect.
				Value(t, err).
				WithFailPrefix("expect no set error").
				ToBeNil()
			expect.
				Value(t, r.HasField("test")).
				AsBoolean().
				ToBeTruthy()
			expect.
				Value(t, r.IsEmpty()).
				AsBoolean().
				ToBeFalsy()
			expect.
				Value(t, len(r.Fields())).
				WithFailPrefix("expect fields count to match").
				AsInt().
				ToEqual(int64(tc.fieldsCount))
		})
	}
}

func TestRecordGet(t *testing.T) {
	storage := NewStorage("foo")
	r := storage.NewRecord()
	r.Set("foo", "bar")
	r.Set("test", 42)

	v, found := r.Get("test")
	expect.
		Value(t, found).
		WithFailPrefix("expect value to be found").
		AsBoolean().
		ToBeTruthy()

	got, ok := v.(int)
	expect.
		Value(t, ok).
		WithFailPrefix("expect value type to match").
		AsBoolean().
		ToBeTruthy()
	expect.
		Value(t, got).
		AsInt().
		ToEqual(42)

	_, found = r.Get("unknown")
	expect.
		Value(t, found).
		WithFailPrefix("expect unknown value not to be found").
		AsBoolean().
		ToBeFalsy()
}

func TestRecordSave(t *testing.T) {
	index := NewIndex("name", func(r Record) string {
		return r.MustGet("name").(string)
	}).Unique().CaseInsensitive()

	storage := NewStorage("foo", WithIndex(index))
	cases := []struct {
		name            string
		id              uint64
		fieldValue, key string
		storageSize     int
		setup           func(Storage) Record
	}{
		{
			name:        "create first record",
			id:          1,
			key:         "0000001",
			fieldValue:  "foo",
			storageSize: 1,
			setup:       func(s Storage) Record { return s.NewRecord() },
		},
		{
			name:        "create second record",
			id:          2,
			key:         "0000002",
			fieldValue:  "bar",
			storageSize: 2,
			setup:       func(s Storage) Record { return s.NewRecord() },
		},
		{
			name:        "update second record",
			id:          2,
			key:         "0000002",
			fieldValue:  "baz",
			storageSize: 2,
			setup: func(s Storage) Record {
				r, _ := storage.Get(index.Name(), "bar")
				return r
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			r := tc.setup(storage)
			r.Set("name", tc.fieldValue)

			_, found := storage.Get(index.Name(), tc.fieldValue)
			expect.
				Value(t, found).
				WithFailPrefix("expect record not to be found").
				AsBoolean().
				ToBeFalsy()
			expect.
				Value(t, r.Save()).
				WithFailPrefix("expect save to succeed").
				AsBoolean().
				ToBeTruthy()
			expect.
				Value(t, storage.Size()).
				WithFailPrefix("expect storage size to match").
				AsInt().
				ToEqual(int64(tc.storageSize))

			r, found = storage.Get(index.Name(), tc.fieldValue)
			expect.
				Value(t, found).
				WithFailPrefix("expect record to be found").
				AsBoolean().
				ToBeTruthy()
			expect.
				Value(t, r.ID()).
				WithFailPrefix("expect ID to match").
				AsUint().
				ToEqual(tc.id)
			expect.
				Value(t, r.Key()).
				WithFailPrefix("expect key to match").
				AsString().
				ToEqual(tc.key)
			expect.
				Value(t, r.MustGet("name")).
				WithFailPrefix("expect field value to match").
				AsString().
				ToEqual(tc.fieldValue)
		})
	}
}

func TestRecordsetIterate(t *testing.T) {
	cases := []struct {
		name      string
		recordIDs []uint64
		setup     func(*Storage)
	}{
		{
			name:      "single record",
			recordIDs: []uint64{1},
			setup: func(s *Storage) {
				s.NewRecord().Save()
			},
		},
		{
			name:      "two records",
			recordIDs: []uint64{1, 2},
			setup: func(s *Storage) {
				s.NewRecord().Save()
				s.NewRecord().Save()
			},
		},
		{
			name: "empty recordset",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			storage := NewStorage("foo")
			if tc.setup != nil {
				tc.setup(&storage)
			}

			var (
				records []Record
				rs      = storage.MustQuery()
			)

			// Act
			rs.Iterate(func(r Record) bool {
				records = append(records, r)
				return false
			})

			// Assert
			expect.
				Value(t, len(records)).
				WithFailPrefix("expect results count to match").
				AsInt().
				ToEqual(int64(len(tc.recordIDs)))

			for i, r := range records {
				expect.
					Value(t, r.ID()).
					AsUint().
					ToEqual(tc.recordIDs[i])
			}
		})
	}
}

func TestRecordsetReverseIterate(t *testing.T) {
	cases := []struct {
		name      string
		recordIDs []uint64
		setup     func(*Storage)
	}{
		{
			name:      "single record",
			recordIDs: []uint64{1},
			setup: func(s *Storage) {
				s.NewRecord().Save()
			},
		},
		{
			name:      "two records",
			recordIDs: []uint64{2, 1},
			setup: func(s *Storage) {
				s.NewRecord().Save()
				s.NewRecord().Save()
			},
		},
		{
			name: "empty recordser",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			storage := NewStorage("foo")
			if tc.setup != nil {
				tc.setup(&storage)
			}

			var (
				records []Record
				rs      = storage.MustQuery()
			)

			// Act
			rs.ReverseIterate(func(r Record) bool {
				records = append(records, r)
				return false
			})

			// Assert
			expect.
				Value(t, len(records)).
				WithFailPrefix("expect results count to match").
				AsInt().
				ToEqual(int64(len(tc.recordIDs)))

			for i, r := range records {
				expect.
					Value(t, r.ID()).
					AsUint().
					ToEqual(tc.recordIDs[i])
			}
		})
	}
}

func TestRecordsetSize(t *testing.T) {
	cases := []struct {
		name  string
		size  int
		setup func(*Storage)
	}{
		{
			name: "single record",
			size: 1,
			setup: func(s *Storage) {
				s.NewRecord().Save()
			},
		},
		{
			name: "two records",
			size: 2,
			setup: func(s *Storage) {
				s.NewRecord().Save()
				s.NewRecord().Save()
			},
		},
		{
			name: "empty recordser",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			storage := NewStorage("foo")
			if tc.setup != nil {
				tc.setup(&storage)
			}

			rs := storage.MustQuery()

			// Act
			size := rs.Size()

			// Assert
			expect.
				Value(t, size).
				AsInt().
				ToEqual(int64(tc.size))
		})
	}
}
