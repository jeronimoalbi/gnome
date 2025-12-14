package blog

import (
	"errors"
	"strings"
	"time"

	"gno.land/p/moul/addrset"
)

const (
	StatusDraft PostStatus = iota
	StatusApproved
	StatusPublished
	StatusRevised
	StatusArchived
)

type (
	// PostStatus defines a type for blog post states.
	PostStatus uint8

	// Post defines a blog post.
	Post struct {
		// Slug contains the URL path slug for the post.
		Slug string

		// Title is the post's title.
		Title string

		// Summary is the post's summary.
		Summary string

		// Status is the current post's state.
		Status PostStatus

		// Content contains the post's content.
		Content string

		// ContentHash contains the hash of the post's content.
		ContentHash string

		// Authors contains the list of post authors.
		Authors addrset.Set

		// Editors contains the list of post editors.
		// Each account belongs to an editor that significantly improved the content.
		Editors addrset.Set

		// Contributors contains the list of post contributors.
		// Each account belongs to a contributor that submitted small content changes.
		Contributors addrset.Set

		// Publishers contains the accounts that published the content.
		Publishers addrset.Set

		// Tags contains a list of tags for the post.
		// These tags can be used to build the blog content taxonomy.
		Tags []string

		// CreatedAt is the block time when the post has been created.
		CreatedAt time.Time

		// UpdatedAt is the block time when the post has been updated for the last time.
		UpdatedAt time.Time

		// PublishAt is the block time when the post should be published.
		PublishAt time.Time

		// ExpireAt is the block time when the post should be archived.
		ExpireAt time.Time
	}
)

// String returns the post status name.
func (s PostStatus) String() string {
	switch s {
	case StatusDraft:
		return "draft"
	case StatusApproved:
		return "approved"
	case StatusPublished:
		return "published"
	case StatusRevised:
		return "revised"
	case StatusArchived:
		return "archived"
	default:
		return "unknown"
	}
}

// IsExpired checks if the expiration date was reached.
func (p Post) IsExpired() bool {
	return !p.ExpireAt.IsZero() && p.ExpireAt.Before(time.Now())
}

// ParseStringToAddresses parses a string addresses.
// String should have one or more lines where each line should contain an address.
// Addresses are validated after being parsed.
func ParseStringToAddresses(s string) (addrset.Set, error) {
	var addresses addrset.Set
	for _, line := range strings.Split(s, "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			// Skip empty lines
			continue
		}

		addr := address(strings.TrimSpace(line))
		if !addr.IsValid() {
			return addrset.Set{}, errors.New("invalid address: " + addr.String())
		}

		addresses.Add(addr)
	}
	return addresses, nil
}

// MustParseStringToAddresses parses a string addresses.
// String should have one or more lines where each line should contain an address.
// Addresses are validated after being parsed.
func MustParseStringToAddresses(s string) addrset.Set {
	addresses, err := ParseStringToAddresses(s)
	if err != nil {
		panic(err.Error())
	}
	return addresses
}

// EscapeHTML escapes special characters like "<" to become "&lt;".
// It escapes only five such characters: <, >, &, ' and ".
func EscapeHTML(s string) string {
	s = strings.ReplaceAll(s, `&`, "&amp;")
	s = strings.ReplaceAll(s, `"`, "&#34;")
	s = strings.ReplaceAll(s, `'`, "&#39;")
	s = strings.ReplaceAll(s, `<`, "&lt;")
	return strings.ReplaceAll(s, `>`, "&gt;")
}
