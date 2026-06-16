package expect_test

import (
	"errors"
	"testing"

	"gno.land/p/jeronimoalbi/expect"
)

func TestReadmeValue(t *testing.T) {
	// Assert integer value
	score := 42
	expect.Value(t, score).ToEqual(42)
	expect.Value(t, score).Not().ToEqual(0)
	expect.Value(t, score).AsInt().ToBeLowerThan(100)

	// Assert string value
	name := "Alice"
	expect.Value(t, name).AsString().ToEqual("Alice")
	expect.Value(t, name).AsString().ToHaveLength(5)

	// Assert boolean value
	expect.Value(t, true).AsBoolean().ToBeTruthy()

	// Assert pointer value
	var v any
	expect.Value(t, v).ToBeNil()

	// Assert error value
	err := errors.New("foo bar")
	expect.Value(t, err).ToEqual(err)
	expect.Value(t, err).ToContainErrorString("foo")
}
