package space

import (
	"fmt"
	"io/ioutil"
	"log"
	"strings"
)

func pathToNyxNxQuarksFolder() string {
	return "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/quarks"
}

func SpaceIds() []string {
	// a := []string{"Pascal", "Elizabeth"}
	// return a
	files, err := ioutil.ReadDir(pathToNyxNxQuarksFolder())
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
	return fmt.Sprintf("%s/%s.marble", pathToNyxNxQuarksFolder(), id)
}
