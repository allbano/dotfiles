package history

import (
	"errors"
	"reflect"
	"strings"
	"testing"
)

func TestCountNormalizesAndCounts(t *testing.T) {
	literalEscape := `printf '\n'`
	input := strings.NewReader(
		"git status\r\n" +
			"git status\n" +
			literalEscape + "\n" +
			"\tgo test\t\n" +
			"one\vtwo\n" +
			"one two\n" +
			"# comentário\n" +
			"#1700000000\n" +
			"\n" +
			" \t \n" +
			"sem newline",
	)

	got, err := Count(input)
	if err != nil {
		t.Fatalf("Count() error = %v", err)
	}

	want := Counts{
		"git status":   2,
		literalEscape:  1,
		"\tgo test\t":  1,
		"one two":      2,
		"# comentário": 1,
		"sem newline":  1,
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("Count() = %#v, want %#v", got, want)
	}
}

func TestNormalizeLineBreaks(t *testing.T) {
	input := "a\r\nb\rc\nd\ve\ff\u2028g\u2029h\ti"
	const want = "a b c d e f g h\ti"

	got, ok := normalize(input)
	if !ok {
		t.Fatal("normalize() rejected a valid command")
	}
	if got != want {
		t.Fatalf("normalize() = %q, want %q", got, want)
	}
}

func TestNormalizeRejectsOnlyBlankAndExactTimestamps(t *testing.T) {
	tests := []struct {
		name string
		line string
		want bool
	}{
		{name: "empty", line: "", want: false},
		{name: "whitespace", line: " \t ", want: false},
		{name: "timestamp", line: "#1700000000", want: false},
		{name: "zero timestamp", line: "#000", want: false},
		{name: "hash", line: "#", want: true},
		{name: "comment", line: "# comentário", want: true},
		{name: "timestamp with prefix", line: " #123", want: true},
		{name: "timestamp with suffix", line: "#123 ", want: true},
		{name: "non numeric", line: "#12x", want: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got, ok := normalize(test.line)
			if ok != test.want {
				t.Fatalf("normalize(%q) validity = %t, want %t", test.line, ok, test.want)
			}
			if ok && got != test.line {
				t.Fatalf("normalize(%q) = %q, want unchanged", test.line, got)
			}
		})
	}
}

func TestCountAcceptsLongLines(t *testing.T) {
	line := strings.Repeat("x", 2*1024*1024)

	got, err := Count(strings.NewReader(line + "\n" + line))
	if err != nil {
		t.Fatalf("Count() error = %v", err)
	}
	if got[line] != 2 {
		t.Fatalf("Count()[long line] = %d, want 2", got[line])
	}
}

func TestCountReturnsReadError(t *testing.T) {
	wantErr := errors.New("read failed")

	got, err := Count(errorReader{err: wantErr})
	if !errors.Is(err, wantErr) {
		t.Fatalf("Count() error = %v, want %v", err, wantErr)
	}
	if got != nil {
		t.Fatalf("Count() = %#v, want nil on error", got)
	}
}

func TestMerge(t *testing.T) {
	counts := Counts{"ls": 2, "pwd": 1}
	incoming := Counts{"git status": 2, "ls": 3}
	wantIncoming := Counts{"git status": 2, "ls": 3}

	if added := counts.Merge(incoming); added != 1 {
		t.Fatalf("Merge() added = %d, want 1", added)
	}

	want := Counts{"git status": 2, "ls": 5, "pwd": 1}
	if !reflect.DeepEqual(counts, want) {
		t.Fatalf("Merge() result = %#v, want %#v", counts, want)
	}
	if !reflect.DeepEqual(incoming, wantIncoming) {
		t.Fatalf("Merge() changed incoming = %#v, want %#v", incoming, wantIncoming)
	}
}

func TestLinesUsesLexicographicalOrder(t *testing.T) {
	counts := Counts{"z": 1, "a": 3, "A": 2, "á": 1}
	want := []string{"A", "a", "z", "á"}

	if got := counts.Lines(); !reflect.DeepEqual(got, want) {
		t.Fatalf("Lines() = %#v, want %#v", got, want)
	}
}

func TestWrite(t *testing.T) {
	counts := Counts{"pwd": 1, "git status": 2, "ls": 3}
	var output strings.Builder

	if err := Write(&output, counts); err != nil {
		t.Fatalf("Write() error = %v", err)
	}

	const want = "git status\nls\npwd\n"
	if got := output.String(); got != want {
		t.Fatalf("Write() = %q, want %q", got, want)
	}
}

func TestWriteEmptyCounts(t *testing.T) {
	var output strings.Builder

	if err := Write(&output, Counts{}); err != nil {
		t.Fatalf("Write() error = %v", err)
	}
	if output.Len() != 0 {
		t.Fatalf("Write() = %q, want empty output", output.String())
	}
}

func TestWriteReturnsWriterError(t *testing.T) {
	wantErr := errors.New("write failed")

	err := Write(errorWriter{err: wantErr}, Counts{"ls": 1})
	if !errors.Is(err, wantErr) {
		t.Fatalf("Write() error = %v, want %v", err, wantErr)
	}
}

type errorReader struct {
	err error
}

func (reader errorReader) Read([]byte) (int, error) {
	return 0, reader.err
}

type errorWriter struct {
	err error
}

func (writer errorWriter) Write([]byte) (int, error) {
	return 0, writer.err
}
