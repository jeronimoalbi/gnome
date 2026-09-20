package main

import (
	"errors"
	"strings"

	"gno.land/p/jeronimoalbi/datasource/v0"
)

func main() {
	var ds datasource.Datasource = posts{
		{"1", "Hello Gno", []string{"gno"}},
		{"2", "Realms 101", []string{"gno", "realms"}},
		{"3", "Cooking pasta", []string{"food"}},
		{"4", "Testing in Gno", []string{"gno", "testing"}},
	}

	// Get the first two records tagged with "gno"
	records, err := datasource.QueryRecords(
		ds,
		datasource.ByTag("gno"),
		datasource.WithCount(2),
	)
	if err != nil {
		panic(err)
	}

	for _, r := range records {
		println(r.ID(), r.String())
	}

	// Get the next page of records tagged with "gno"
	records, err = datasource.QueryRecords(
		ds,
		datasource.ByTag("gno"),
		datasource.WithOffset(2),
		datasource.WithCount(2),
	)
	if err != nil {
		panic(err)
	}

	for _, r := range records {
		println(r.ID(), r.String())
	}

	// Get a single record, and use its optional interfaces
	r, err := ds.Record("2")
	if err != nil {
		panic(err)
	}

	if t, ok := r.(datasource.TaggableRecord); ok {
		println("Tags:", strings.Join(t.Tags(), ", "))
	}

	fields, err := r.Fields()
	if err != nil {
		panic(err)
	}

	title, _ := fields.Get("title")
	println("Title:", title.(string))
}

// Datasource: A list of posts
type posts []post

func (ps posts) Size() int { return len(ps) }

func (ps posts) Record(id string) (datasource.Record, error) {
	for _, p := range ps {
		if p.id == id {
			return p, nil
		}
	}
	return nil, errors.New("record not found")
}

func (ps posts) Records(q datasource.Query) datasource.Iterator {
	var records []datasource.Record
	for _, p := range ps {
		if q.Tag == "" || p.hasTag(q.Tag) {
			records = append(records, p)
		}
	}

	if q.Offset >= len(records) {
		return datasource.NewRecordIterator(nil)
	}
	return datasource.NewRecordIterator(records[q.Offset:])
}

// TaggableRecord: A post
type post struct {
	id    string
	title string
	tags  []string
}

func (p post) ID() string     { return p.id }
func (p post) String() string { return p.title }
func (p post) Tags() []string { return p.tags }

func (p post) Fields() (datasource.Fields, error) {
	return datasource.NewFieldsFromMap(map[string]any{
		"title": p.title,
	}), nil
}

func (p post) hasTag(tag string) bool {
	for _, t := range p.tags {
		if t == tag {
			return true
		}
	}
	return false
}

// Output:
// 1 Hello Gno
// 2 Realms 101
// 4 Testing in Gno
// Tags: gno, realms
// Title: Realms 101
