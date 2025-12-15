package blog

import (
	"strings"
	"time"

	pblog "gno.land/p/jeronimoalbi/blog"
	"gno.land/p/nt/ownable"
)

// TODO: Support tags, basic search, sort by date
// TODO: Support datasource to integrate with home realm

var (
	blog  = pblog.Blog{Title: "A Blog of a Gnome"}
	owner = ownable.NewWithOrigin()
)

func Publish(_ realm, slug, title, content string) {
	owner.AssertOwnedByPrevious()

	content = strings.TrimSpace(content)
	if content == "" {
		panic("content is empty")
	}

	blog.Post(&pblog.Post{
		Slug:      slug,
		Title:     title,
		Status:    pblog.StatusPublished,
		Content:   strings.TrimSpace(content),
		CreatedAt: time.Now(),
	})
}

func Update(_ realm, slug, title, content string) {
	owner.AssertOwnedByPrevious()

	content = strings.TrimSpace(content)
	if content == "" {
		panic("content is empty")
	}

	p, found := blog.Get(slug)
	if !found {
		panic("post not found")
	}

	title = strings.TrimSpace(title)
	if title != "" {
		p.Title = title
	}

	p.Content = content
	p.UpdatedAt = time.Now()
}

func Delete(_ realm, slug string) {
	owner.AssertOwnedByPrevious()

	if _, found := blog.Remove(slug); !found {
		panic("post not found")
	}
}
