package main

import (
	"bytes"
	"log"
	"strings"
	"testing"
)

func TestMain(t *testing.T) {
	// Redirect stdout to buffer
	var buf bytes.Buffer
	log.SetOutput(&buf)

	// Call main function
	main()

	// Check output
	expected := "[" + version + "]"

	if strings.Contains(buf.String(), expected) {
		t.Errorf("Unexpected output: got %q, want %q", buf.String(), expected)
	}
}
