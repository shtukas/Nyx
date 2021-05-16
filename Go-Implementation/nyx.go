package main

import (
	"fmt"

	"github.com/shtukas/nyx/space"
)

type Nx19 struct {
	announce string
	uuid     string
}

type Nx27 struct {
	uuid     string
	datetime string
	type_    string
	payload  string
}

type NxEntity struct {
	uuid       string
	entityType string
	datetime   string
}

func main() {
	fmt.Println("Hello World!")
	for _, id := range space.SpaceIds() {
		fmt.Println(space.SpaceId2MarbleFilepath(id))
	}
	fmt.Println("Pascal")
	fmt.Println("Nx19", Nx19{"announce", "6c249256-2379-4683-bc31-23bbcce4fd39"})
	fmt.Println("Nx27", Nx27{"e1cec0c2-f1ad-4411-9f59-d25cf6bdfa4b", "2021-05-16T17:41:45Z", "unique-string", "a301c45a-e0d1"})
}
