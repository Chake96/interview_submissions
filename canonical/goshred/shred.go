package goshred

import (
	"crypto/rand"
	"fmt"
	"os"
)

const bufferSize = 1024

func Shred(path string) error {
	// Check if the file exists
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return fmt.Errorf("file does not exist: %s", path)
	}

	file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE, 0666)
	if err != nil {
		return err
	}
	defer file.Close()

	buffer := make([]byte, bufferSize)

	for i := 0; i < 3; i++ {
		if _, err := rand.Read(buffer); err != nil {
			return err
		}

		if _, err := file.Write(buffer); err != nil {
			return err
		}

		if err := file.Sync(); err != nil {
			return err
		}
	}

	if err := os.Remove(path); err != nil {
		return err
	}

	return nil
}
