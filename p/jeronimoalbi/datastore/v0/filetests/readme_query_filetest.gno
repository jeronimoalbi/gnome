package main

import "gno.land/p/jeronimoalbi/datastore/v0"

func main() {
	db := datastore.NewDatastore()

	// Define a multi value index to search posts by tag
	tagsIdx := datastore.NewMultiValueIndex("tags", func(r datastore.Record) []string {
		return r.MustGet("tags").([]string)
	})

	posts := db.CreateStorage("posts", datastore.WithIndex(tagsIdx))
	for _, title := range []string{"Post 1", "Post 2", "Post 3"} {
		post := posts.NewRecord()
		post.Set("title", title)
		post.Set("tags", []string{"gno", title})
		post.Save()
	}

	// Get two records starting from the second one
	recordset, err := posts.Query(datastore.WithOffset(1), datastore.WithSize(2))
	if err != nil {
		panic(err)
	}

	recordset.Iterate(func(r datastore.Record) bool {
		println("Post:", r.MustGet("title"))
		return false // Continue iterating
	})

	// Get all the records that have the "gno" tag using the custom index
	recordset = posts.MustQuery(datastore.UseIndex("tags", "gno"))
	println("Tagged posts:", recordset.Size())
}

// Output:
// Post: Post 2
// Post: Post 3
// Tagged posts: 3
