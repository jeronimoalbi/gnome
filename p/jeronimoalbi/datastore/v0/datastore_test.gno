package datastore

import (
	"testing"

	"gno.land/p/jeronimoalbi/expect/v0"
)

func TestDatastoreCreateStorage(t *testing.T) {
	cases := []struct {
		name        string
		storageName string
		mustFail    bool
		setup       func(*Datastore)
	}{
		{
			name:        "success",
			storageName: "users",
		},
		{
			name:        "storage exists",
			storageName: "users",
			mustFail:    true,
			setup: func(db *Datastore) {
				db.CreateStorage("users")
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			db := NewDatastore()
			if tc.setup != nil {
				tc.setup(db)
			}

			storage := db.CreateStorage(tc.storageName)

			if tc.mustFail {
				expect.
					Value(t, storage).
					WithFailPrefix("expect no storage").
					ToBeNil()
				return
			}

			expect.
				Value(t, storage).
				WithFailPrefix("expect storage to be created").
				Not().ToBeNil()
			expect.
				Value(t, storage.Name()).
				AsString().
				ToEqual(tc.storageName)
			expect.
				Value(t, db.HasStorage(tc.storageName)).
				AsBoolean().
				ToBeTruthy()
		})
	}
}

func TestDatastoreHasStorage(t *testing.T) {
	db := NewDatastore()
	name := "users"

	expect.
		Value(t, db.HasStorage(name)).
		AsBoolean().
		ToBeFalsy()

	db.CreateStorage(name)

	expect.
		Value(t, db.HasStorage(name)).
		AsBoolean().
		ToBeTruthy()
}

func TestDatastoreGetStorage(t *testing.T) {
	db := NewDatastore()
	name := "users"

	storage := db.GetStorage(name)
	expect.
		Value(t, storage).
		ToBeNil()

	db.CreateStorage(name)

	storage = db.GetStorage(name)
	expect.
		Value(t, storage).
		WithFailPrefix("expect storage to be found").
		Not().ToBeNil()
	expect.
		Value(t, storage.Name()).
		AsString().
		ToEqual(name)
}
