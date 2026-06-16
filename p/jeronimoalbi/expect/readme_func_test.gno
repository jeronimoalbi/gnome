package expect_test

import (
	"errors"
	"testing"

	"gno.land/p/jeronimoalbi/expect"
)

func TestReadmeFunc(t *testing.T) {
	foo := func() int {
		return 42
	}

	fooPanic := func() {
		panic("boom!")
	}

	err := errors.New("boom!")
	fooError := func(err error) error {
		return err
	}

	// Assert that "fooError" function returns an error
	expect.Func(t, func() error {
		return fooError(err)
	}).ToFail().WithError(err)

	// Assert that "fooPanic" function panics with a message
	expect.Func(t, func() {
		fooPanic()
	}).ToPanic().WithMessage("boom!")

	// Assert that "foo" function returns 42
	expect.Func(t, func() any {
		return foo()
	}).ToReturn(42)
}
