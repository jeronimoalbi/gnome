package blog

import (
	"chain/runtime"
	"strings"

	pblog "gno.land/p/jeronimoalbi/blog"
	"gno.land/p/jeronimoalbi/pager"
	"gno.land/p/moul/md"
	"gno.land/p/nt/mux"
)

const (
	dateFormat      = "2006-01-02 15:04 MST"
	itemsPerPage    = 50
	shortDateFormat = "Jan 2, 2006"
)

func Render(path string) string {
	router := mux.NewRouter()
	router.NotFoundHandler = func(res *mux.ResponseWriter, _ *mux.Request) {
		res.Write("Path not found")
	}

	router.HandleFunc("", renderBlog)
	router.HandleFunc("posts", renderBlog)
	router.HandleFunc("posts/{slug}", renderPost)

	return router.Render(path)
}

func renderBlog(res *mux.ResponseWriter, req *mux.Request) {
	pages, err := pager.New(req.RawPath, blog.Size(), pager.WithPageSize(itemsPerPage))
	if err != nil {
		res.Write(err.Error())
		return
	}

	res.Write(md.H1(blog.Title))
	if blog.Description != "" {
		res.Write(md.Paragraph(blog.Description))
	}

	realmPath := strings.TrimPrefix(runtime.CurrentRealm().PkgPath(), "gno.land")

	blog.Iterate(pages.Offset(), pages.PageSize(), func(p *pblog.Post) bool {
		path := realmPath + ":posts/" + p.Slug
		res.Write(md.Bold(md.Link(p.Title, path)) + "  \n")
		res.Write(md.Italic("Published on " + p.PublishAt.UTC().Format(shortDateFormat)))
		res.Write("\n\n")
		return false
	})

	if pages.HasPages() {
		res.Write("\nPages " + pager.Picker(pages))
	}
}

func renderPost(res *mux.ResponseWriter, req *mux.Request) {
	slug := req.GetVar("slug")
	p, found := blog.Get(slug)
	if !found {
		res.Write("Post not found")
		return
	}

	res.Write(md.H1(p.Title))
	res.Write("- Created: " + p.CreatedAt.UTC().Format(dateFormat) + "\n")

	if !p.UpdatedAt.IsZero() {
		res.Write("- Updated: " + p.UpdatedAt.UTC().Format(dateFormat) + "\n")
	}

	res.Write("\n")
	res.Write(p.Content)
}
