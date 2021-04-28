package space

import (
	"fmt"
	"io/ioutil"
	"log"
	"strings"
)

func SpaceIds() []string {
	// a := []string{"Pascal", "Elizabeth"}
	// return a
	files, err := ioutil.ReadDir("/Users/pascal/Galaxy/Documents/NyxSpace")
	if err != nil {
		log.Fatal(err)
	}
	var filenames []string
	for _, f := range files {
		if strings.HasSuffix(f.Name(), ".marble") {
			filenames = append(filenames, f.Name()[0:15])
		}
	}
	return filenames
}

func SpaceId2MarbleFilepath(id string) string {
	return fmt.Sprintf("/Users/pascal/Galaxy/Documents/NyxSpace/%s.marble", id)
}
