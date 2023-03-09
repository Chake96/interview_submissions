package goshred

import (
	"bytes"
	"crypto/sha256"
	"io/ioutil"
	"math/rand"
	"os"
	"testing"
)

const testFileName = "test_file"

func TestShred(t *testing.T) {
	// Create a test file with random content
	fileContent := make([]byte, 1000)
	if _, err := rand.Read(fileContent); err != nil {
		t.Fatalf("Failed to generate random content: %v", err)
	}

	if err := ioutil.WriteFile(testFileName, fileContent, 0666); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}
	defer os.Remove(testFileName)

	// Test shredding a valid file path
	if err := Shred(testFileName); err != nil {
		t.Errorf("Shred failed for a valid file path: %v", err)
	}

	// Test shredding an invalid file path
	if err := Shred("invalid_file_path"); err == nil {
		t.Error("Shred succeeded for an invalid file path")
	}

	// Test shredding an empty file
	emptyFile, err := ioutil.TempFile("", "empty_file")
	if err != nil {
		t.Fatalf("Failed to create empty file: %v", err)
	}
	defer os.Remove(emptyFile.Name())

	if err := Shred(emptyFile.Name()); err != nil {
		t.Errorf("Shred failed for an empty file: %v", err)
	}

	hasher := sha256.New()
	// Compute the hash of the original content
	fileHash := sha256.Sum256(fileContent)

	// Test that the file has been overwritten with random data
	if bytes.Equal(fileHash[:], hasher.Sum(nil)) {
		t.Errorf("File has not been overwritten with random data")
	}

	// Test shredding a file with small size
	smallFileContent := []byte("Small file")
	if err := ioutil.WriteFile(testFileName, smallFileContent, 0666); err != nil {
		t.Fatalf("Failed to create small test file: %v", err)
	}

	if err := Shred(testFileName); err != nil {
		t.Errorf("Shred failed for a small file: %v", err)
	}

	// Test shredding a file with large size
	largeFileContent := bytes.Repeat([]byte("Large file"), 1000)
	if err := ioutil.WriteFile(testFileName, largeFileContent, 0666); err != nil {
		t.Fatalf("Failed to create large test file: %v", err)
	}

	if err := Shred(testFileName); err != nil {
		t.Errorf("Shred failed for a large file: %v", err)
	}

	// Test shredding a file with very large size
	var veryLargeFileContent []byte
	for i := 0; i < 1000; i++ {
		randomContent := make([]byte, 1024*1024)
		if _, err := rand.Read(randomContent); err != nil {
			t.Fatalf("Failed to generate random content: %v", err)
		}
		veryLargeFileContent = append(veryLargeFileContent, randomContent...)
	}

	if err := ioutil.WriteFile(testFileName, veryLargeFileContent, 0666); err != nil {
		t.Fatalf("Failed to create very large test file: %v", err)
	}

	if err := Shred(testFileName); err != nil {
		t.Errorf("Shred failed for a very large file: %v", err)
	}

	// Test shredding a file with special permissions
	// Test shredding a file with special permissions
	permsFile, err := ioutil.TempFile("", "perms_file")
	if err != nil {
		t.Fatalf("Failed to create file with special permissions: %v", err)
	}
	defer os.Remove(permsFile.Name())

	// Set write permissions for the test file
	if err := permsFile.Chmod(0666); err != nil {
		t.Fatalf("Failed to set write permissions for test file: %v", err)
	}

	if err := Shred(permsFile.Name()); err != nil {
		t.Errorf("Shred failed for a file with special permissions: %v", err)
	}

	file, err := os.OpenFile("to_shred.txt", os.O_WRONLY|os.O_CREATE, 0666)
	content := "The ships hung in the sky in much the same way that bricks don't. The Guide is definitive. Reality is frequently inaccurate. In the beginning the Universe was created. This has made a lot of people very angry and been widely regarded as a bad move. The Answer to the Ultimate Question of Life, The Universe, and Everything is...42! The impossible often has a kind of integrity to it which the merely improbable lacks. The major difference between a thing that might go wrong and a thing that cannot possibly go wrong is that when a thing that cannot possibly go wrong goes wrong, it usually turns out to be impossible to get at and repair. Time is an illusion. Lunchtime doubly so. The ships hung in the sky in much the same way that bricks don't. Human beings, who are almost unique in having the ability to learn from the experience of others, are also remarkable for their apparent disinclination to do so."
	_, err = file.WriteString(content)
	defer file.Close()
	if err := Shred(file.Name()); err != nil {
		t.Errorf("Shred failed for a file with special permissions: %v", err)
	}
}

func TestMain(m *testing.M) {
	// Run tests
	exitCode := m.Run()

	// Clean up test files
	os.Remove(testFileName)

	os.Exit(exitCode)
}
