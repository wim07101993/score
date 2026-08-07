//go:build integration

package integration_test

import (
	"score/test/integration_test/helpers"
)

// harness is built by TestMain before any test runs.
var harness *helpers.Harness
