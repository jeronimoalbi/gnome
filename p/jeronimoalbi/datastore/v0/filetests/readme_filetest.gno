package main

import "gno.land/p/jeronimoalbi/datastore/v0"

func main() {
	db := datastore.NewDatastore()

	// Define a unique case insensitive index for user emails
	emailIdx := datastore.NewIndex("email", func(r datastore.Record) string {
		return r.MustGet("email").(string)
	}).Unique().CaseInsensitive()

	// Create a new storage for user records
	users := db.CreateStorage("users", datastore.WithIndex(emailIdx))

	// Add a user with a single "email" field
	user := users.NewRecord()
	user.Set("email", "foo@bar.org")

	// Save to assign the user ID and update indexes
	user.Save()

	// Find user by email using the custom index
	user, _ = users.Get(emailIdx.Name(), "FOO@bar.org")
	println("Found by email:", user.MustGet("email"))

	// Find user by ID
	user, _ = users.GetByID(user.ID())
	println("Found by ID:", user.ID())

	// Delete the user from the storage and update indexes
	users.Delete(user.ID())
	println("Users:", users.Size())
}

// Output:
// Found by email: foo@bar.org
// Found by ID: 1
// Users: 0
