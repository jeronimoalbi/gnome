package blog

import (
	"strings"

	"gno.land/p/nt/avl"
)

type (
	// Blog defines a blog.
	Blog struct {
		posts avl.Tree // string(slug) -> *Post

		// Title is blog's title.
		Title string

		// Description is the blog's description.
		Description string
	}

	// PostIterFn defines the a callback to iterate blog posts.
	PostIterFn func(*Post) bool
)

// Size returns the number of posts in the blog.
func (b Blog) Size() int {
	return b.posts.Size()
}

// Has checks if a post with a URL slug exists.
func (b Blog) Has(slug string) bool {
	return b.posts.Has(slug)
}

// Get returns a blog's post.
func (b Blog) Get(slug string) (_ *Post, found bool) {
	if v, found := b.posts.Get(slug); found {
		return v.(*Post), true
	}
	return nil, false
}

// Post adds a new post to the blog.
func (b *Blog) Post(p *Post) bool {
	slug := strings.TrimSpace(p.Slug)
	if slug == "" {
		panic("post has an empty slug")
	}

	return b.posts.Set(slug, p)
}

// Remove removes a post from the blog.
// The removed post is returned after being removed if it exists.
func (b *Blog) Remove(slug string) (_ *Post, removed bool) {
	if v, removed := b.posts.Remove(slug); removed {
		return v.(*Post), true
	}
	return nil, false
}

// Iterate iterates posts by slug.
func (b Blog) Iterate(offset, count int, fn PostIterFn) bool {
	return b.posts.IterateByOffset(offset, count, func(_ string, value interface{}) bool {
		return fn(value.(*Post))
	})
}
