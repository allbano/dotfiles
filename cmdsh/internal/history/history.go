// Package history contains the rules for counting and deduplicating command
// history lines. File paths and operating-system concerns stay with main.
package history

import (
	"bufio"
	"errors"
	"io"
	"sort"
	"strings"
)

var lineBreaks = strings.NewReplacer(
	"\r\n", " ",
	"\r", " ",
	"\n", " ",
	"\v", " ",
	"\f", " ",
	"\u2028", " ",
	"\u2029", " ",
)

// Counts maps each history line to the occurrences observed while reading.
// Write persists only the lines, so these values are not historical counters.
type Counts map[string]int

// Count reads, normalizes, and counts physical history records.
func Count(input io.Reader) (Counts, error) {
	counts := make(Counts)
	reader := bufio.NewReader(input)

	for {
		line, err := reader.ReadString('\n')
		if err != nil && !errors.Is(err, io.EOF) {
			return nil, err
		}

		if len(line) > 0 {
			line = trimRecordDelimiter(line)
			if line, ok := normalize(line); ok {
				counts[line]++
			}
		}

		if errors.Is(err, io.EOF) {
			return counts, nil
		}
	}
}

// Merge adds the occurrences from other and reports how many distinct lines
// did not exist in counts before the merge.
func (counts Counts) Merge(other Counts) int {
	added := 0
	for line, occurrences := range other {
		if _, exists := counts[line]; !exists {
			added++
		}
		counts[line] += occurrences
	}
	return added
}

// Lines returns one copy of each line in deterministic order.
func (counts Counts) Lines() []string {
	lines := make([]string, 0, len(counts))
	for line := range counts {
		lines = append(lines, line)
	}
	sort.Strings(lines)
	return lines
}

// Write writes each distinct line once, sorted and followed by a line break.
func Write(output io.Writer, counts Counts) error {
	writer := bufio.NewWriter(output)
	for _, line := range counts.Lines() {
		if _, err := writer.WriteString(line + "\n"); err != nil {
			return err
		}
	}
	return writer.Flush()
}

func trimRecordDelimiter(line string) string {
	if !strings.HasSuffix(line, "\n") {
		return line
	}

	line = strings.TrimSuffix(line, "\n")
	return strings.TrimSuffix(line, "\r")
}

func normalize(line string) (string, bool) {
	line = lineBreaks.Replace(line)
	if strings.TrimSpace(line) == "" || isTimestamp(line) {
		return "", false
	}
	return line, true
}

func isTimestamp(line string) bool {
	if len(line) < 2 || line[0] != '#' {
		return false
	}
	for _, character := range line[1:] {
		if character < '0' || character > '9' {
			return false
		}
	}
	return true
}
