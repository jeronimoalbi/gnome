package datasource

import (
	"testing"

	"gno.land/p/jeronimoalbi/expect"
)

func TestNewRecordIterator(t *testing.T) {
	cases := []struct {
		name    string
		records []Record
	}{
		{
			name: "multiple records",
			records: []Record{
				testRecord{id: "1"},
				testRecord{id: "2"},
				testRecord{id: "3"},
			},
		},
		{
			name:    "single record",
			records: []Record{testRecord{id: "1"}},
		},
		{
			name:    "empty records",
			records: []Record{},
		},
		{
			name: "nil records",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			iter := NewRecordIterator(tc.records)

			// Assert
			expect.
				Value(t, iter.Record()).
				WithFailPrefix("Expect no record before the first call to next").
				ToBeNil()

			count := 0
			for iter.Next() {
				expect.
					Value(t, count < len(tc.records)).
					WithFailPrefix("Expect iteration count to be within records count").
					AsBoolean().
					ToBeTruthy()
				expect.
					Value(t, iter.Record().ID()).
					WithFailPrefix("Expect record ID to match").
					AsString().
					ToEqual(tc.records[count].ID())

				count++
			}

			expect.
				Value(t, count).
				WithFailPrefix("Expect all records to be iterated").
				AsInt().
				ToEqual(int64(len(tc.records)))
			expect.
				Value(t, iter.Next()).
				WithFailPrefix("Expect iterator to remain exhausted").
				AsBoolean().
				ToBeFalsy()
			expect.
				Value(t, iter.Err()).
				WithFailPrefix("Expect no iterator error").
				ToBeNil()
		})
	}
}

func TestNewRecordIteratorKeepsRecords(t *testing.T) {
	// Arrange
	records := []Record{
		testRecord{id: "1"},
		testRecord{id: "2"},
	}
	iter := NewRecordIterator(records)

	// Act
	for iter.Next() {
	}

	// Assert
	expect.
		Value(t, len(records)).
		WithFailPrefix("Expect the records slice to not be modified").
		AsInt().
		ToEqual(2)
	expect.
		Value(t, records[0].ID()).
		WithFailPrefix("Expect the first record to not be modified").
		AsString().
		ToEqual("1")
}
