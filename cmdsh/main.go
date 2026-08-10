package main

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"cmdsh/internal/history"
)

const commandsHistoryRelativePath = "github/dotfiles/bash/history/commands_history"

func main() {
	home, err := os.UserHomeDir()
	if err != nil {
		exit(err)
	}

	counts, added, err := processHistory(
		filepath.Join(home, ".bash_history"),
		filepath.Join(home, commandsHistoryRelativePath),
	)
	if err != nil {
		exit(err)
	}

	fmt.Printf(
		"Histórico atualizado: %d comandos novos, %d comandos no total.\n",
		added, len(counts),
	)
}

func processHistory(sourcePath, destinationPath string) (history.Counts, int, error) {
	incoming, err := readHistory(sourcePath)
	if err != nil {
		return nil, 0, fmt.Errorf("ler histórico de entrada %q: %w", sourcePath, err)
	}

	counts, err := readHistory(destinationPath)
	if errors.Is(err, os.ErrNotExist) {
		counts = make(history.Counts)
	} else if err != nil {
		return nil, 0, fmt.Errorf("ler histórico de saída %q: %w", destinationPath, err)
	}

	added := counts.Merge(incoming)
	if err := writeHistory(destinationPath, counts); err != nil {
		return nil, 0, fmt.Errorf("gravar histórico de saída %q: %w", destinationPath, err)
	}

	return counts, added, nil
}

func readHistory(path string) (history.Counts, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}

	counts, readErr := history.Count(file)
	closeErr := file.Close()
	if readErr != nil {
		return nil, readErr
	}
	if closeErr != nil {
		return nil, closeErr
	}
	return counts, nil
}

// writeHistory troca o destino somente depois de concluir toda a escrita.
func writeHistory(path string, counts history.Counts) error {
	return writeHistoryAtomically(path, counts, history.Write, os.Rename)
}

func writeHistoryAtomically(
	path string,
	counts history.Counts,
	write func(io.Writer, history.Counts) error,
	rename func(string, string) error,
) error {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}

	temporary, err := os.CreateTemp(dir, ".cmdsh-*")
	if err != nil {
		return err
	}
	temporaryPath := temporary.Name()
	defer func() {
		_ = temporary.Close()
		_ = os.Remove(temporaryPath)
	}()

	if err := temporary.Chmod(0o600); err != nil {
		return err
	}
	if err := write(temporary, counts); err != nil {
		return err
	}
	if err := temporary.Sync(); err != nil {
		return err
	}
	if err := temporary.Close(); err != nil {
		return err
	}
	if err := rename(temporaryPath, path); err != nil {
		return err
	}

	return nil
}

func exit(err error) {
	fmt.Fprintf(os.Stderr, "cmdsh: %v\n", err)
	os.Exit(1)
}
