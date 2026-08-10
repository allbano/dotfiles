package main

import (
	"errors"
	"io"
	"os"
	"path/filepath"
	"testing"

	"cmdsh/internal/history"
)

func TestProcessHistoryCreatesDestination(t *testing.T) {
	dir := t.TempDir()
	sourcePath := filepath.Join(dir, ".bash_history")
	destinationPath := filepath.Join(dir, "nested", "commands_history")
	writeTestFile(t, sourcePath, "pwd\nls\npwd\ngit status\r\n#1700000000\n\n", 0o600)

	counts, added, err := processHistory(sourcePath, destinationPath)
	if err != nil {
		t.Fatalf("processHistory() error = %v", err)
	}
	if added != 3 {
		t.Fatalf("processHistory() added = %d, want 3", added)
	}
	if counts["pwd"] != 2 {
		t.Fatalf("processHistory()[pwd] = %d, want 2", counts["pwd"])
	}
	assertFileContents(t, destinationPath, "git status\nls\npwd\n")
	assertFileMode(t, destinationPath, 0o600)
	assertNoTemporaryFiles(t, filepath.Dir(destinationPath))
}

func TestProcessHistoryMergesExistingDestination(t *testing.T) {
	dir := t.TempDir()
	sourcePath := filepath.Join(dir, ".bash_history")
	destinationPath := filepath.Join(dir, "commands_history")
	writeTestFile(t, sourcePath, "shared\nnew\nnew\n", 0o600)
	writeTestFile(t, destinationPath, "old\nshared\nold\n", 0o644)

	counts, added, err := processHistory(sourcePath, destinationPath)
	if err != nil {
		t.Fatalf("processHistory() error = %v", err)
	}
	if added != 1 {
		t.Fatalf("processHistory() added = %d, want 1", added)
	}
	if counts["old"] != 2 || counts["shared"] != 2 || counts["new"] != 2 {
		t.Fatalf("processHistory() counts = %#v", counts)
	}
	assertFileContents(t, destinationPath, "new\nold\nshared\n")
	assertFileMode(t, destinationPath, 0o600)

	_, added, err = processHistory(sourcePath, destinationPath)
	if err != nil {
		t.Fatalf("second processHistory() error = %v", err)
	}
	if added != 0 {
		t.Fatalf("second processHistory() added = %d, want 0", added)
	}
	assertFileContents(t, destinationPath, "new\nold\nshared\n")
}

func TestProcessHistoryNormalizesExistingDestination(t *testing.T) {
	dir := t.TempDir()
	sourcePath := filepath.Join(dir, ".bash_history")
	destinationPath := filepath.Join(dir, "commands_history")
	writeTestFile(t, sourcePath, "\n#999\n \t \n", 0o600)
	writeTestFile(t, destinationPath, "z\r\n\n#123\nx\r\nx\n", 0o600)

	_, added, err := processHistory(sourcePath, destinationPath)
	if err != nil {
		t.Fatalf("processHistory() error = %v", err)
	}
	if added != 0 {
		t.Fatalf("processHistory() added = %d, want 0", added)
	}
	assertFileContents(t, destinationPath, "x\nz\n")
}

func TestProcessHistoryCreatesEmptyDestination(t *testing.T) {
	dir := t.TempDir()
	sourcePath := filepath.Join(dir, ".bash_history")
	destinationPath := filepath.Join(dir, "commands_history")
	writeTestFile(t, sourcePath, "\n#123\n", 0o600)

	counts, added, err := processHistory(sourcePath, destinationPath)
	if err != nil {
		t.Fatalf("processHistory() error = %v", err)
	}
	if len(counts) != 0 || added != 0 {
		t.Fatalf("processHistory() counts = %#v, added = %d; want empty and 0", counts, added)
	}
	assertFileContents(t, destinationPath, "")
	assertFileMode(t, destinationPath, 0o600)
}

func TestProcessHistoryMissingSourcePreservesDestination(t *testing.T) {
	dir := t.TempDir()
	sourcePath := filepath.Join(dir, "missing")
	destinationPath := filepath.Join(dir, "commands_history")
	writeTestFile(t, destinationPath, "do not touch\n", 0o600)

	_, _, err := processHistory(sourcePath, destinationPath)
	if err == nil {
		t.Fatal("processHistory() error = nil, want an error")
	}
	if !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("processHistory() error = %v, want os.ErrNotExist", err)
	}
	assertFileContents(t, destinationPath, "do not touch\n")
	assertNoTemporaryFiles(t, dir)
}

func TestProcessHistoryReturnsDestinationReadError(t *testing.T) {
	dir := t.TempDir()
	sourcePath := filepath.Join(dir, ".bash_history")
	destinationPath := filepath.Join(dir, "commands_history")
	writeTestFile(t, sourcePath, "ls\n", 0o600)
	if err := os.Mkdir(destinationPath, 0o700); err != nil {
		t.Fatal(err)
	}

	_, _, err := processHistory(sourcePath, destinationPath)
	if err == nil {
		t.Fatal("processHistory() error = nil, want a destination read error")
	}
	if errors.Is(err, os.ErrNotExist) {
		t.Fatalf("processHistory() error = %v, want an error other than os.ErrNotExist", err)
	}
	info, statErr := os.Stat(destinationPath)
	if statErr != nil {
		t.Fatal(statErr)
	}
	if !info.IsDir() {
		t.Fatalf("destination was modified after read error: mode = %v", info.Mode())
	}
	assertNoTemporaryFiles(t, dir)
}

func TestWriteHistoryFailurePreservesDestination(t *testing.T) {
	dir := t.TempDir()
	destinationPath := filepath.Join(dir, "commands_history")
	writeTestFile(t, destinationPath, "original\n", 0o600)
	wantErr := errors.New("write failed")

	err := writeHistoryAtomically(
		destinationPath,
		history.Counts{"replacement": 1},
		func(output io.Writer, _ history.Counts) error {
			_, _ = io.WriteString(output, "partial")
			return wantErr
		},
		os.Rename,
	)
	if !errors.Is(err, wantErr) {
		t.Fatalf("writeHistoryAtomically() error = %v, want %v", err, wantErr)
	}
	assertFileContents(t, destinationPath, "original\n")
	assertNoTemporaryFiles(t, dir)
}

func TestWriteHistoryRenameFailurePreservesDestination(t *testing.T) {
	dir := t.TempDir()
	destinationPath := filepath.Join(dir, "commands_history")
	writeTestFile(t, destinationPath, "original\n", 0o600)
	wantErr := errors.New("rename failed")

	err := writeHistoryAtomically(
		destinationPath,
		history.Counts{"replacement": 1},
		history.Write,
		func(string, string) error { return wantErr },
	)
	if !errors.Is(err, wantErr) {
		t.Fatalf("writeHistoryAtomically() error = %v, want %v", err, wantErr)
	}
	assertFileContents(t, destinationPath, "original\n")
	assertNoTemporaryFiles(t, dir)
}

func writeTestFile(t *testing.T, path, contents string, mode os.FileMode) {
	t.Helper()
	if err := os.WriteFile(path, []byte(contents), mode); err != nil {
		t.Fatal(err)
	}
}

func assertFileContents(t *testing.T, path, want string) {
	t.Helper()
	got, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != want {
		t.Fatalf("%s contents = %q, want %q", path, got, want)
	}
}

func assertFileMode(t *testing.T, path string, want os.FileMode) {
	t.Helper()
	info, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if got := info.Mode().Perm(); got != want {
		t.Fatalf("%s permissions = %o, want %o", path, got, want)
	}
}

func assertNoTemporaryFiles(t *testing.T, dir string) {
	t.Helper()
	matches, err := filepath.Glob(filepath.Join(dir, ".cmdsh-*"))
	if err != nil {
		t.Fatal(err)
	}
	if len(matches) != 0 {
		t.Fatalf("temporary files left behind: %v", matches)
	}
}
