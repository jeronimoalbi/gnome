package blog

import (
	"strings"
	"time"

	"gno.land/p/jeronimoalbi/blog"
	"gno.land/p/nt/ownable"
)

// TODO: Support tags, basic search, sort by date
// TODO: Support datasource to integrate with home realm

var auth = ownable.NewWithOrigin()

var Blog = blog.Blog{Title: "El Blog de Jerónimo"}

func Publish(_ realm, slug, title, content string) {
	auth.AssertOwnedByPrevious()

	content = strings.TrimSpace(content)
	if content == "" {
		panic("content is empty")
	}

	Blog.Post(&blog.Post{
		Slug:      slug,
		Title:     title,
		Status:    blog.StatusPublished,
		Content:   strings.TrimSpace(content),
		CreatedAt: time.Now(),
	})
}

func Update(_ realm, slug, title, content string) {
	auth.AssertOwnedByPrevious()

	content = strings.TrimSpace(content)
	if content == "" {
		panic("content is empty")
	}

	p, found := Blog.Get(slug)
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
	auth.AssertOwnedByPrevious()

	if _, found := Blog.Remove(slug); !found {
		panic("post not found")
	}
}
