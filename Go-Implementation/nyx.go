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
type NxEvent struct {
	uuid        string
	datetime    string
	date        string
	description string
}

type NxListing struct {
	uuid        string
	datetime    string
	description string
}

// NxEntity is representing a super type of Nx27 and NxEvent
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
	fmt.Println("NxEvent", NxEvent{"6c249256-2379-4683-bc31-23bbcce4fd39", "2021-05-16T18:14:12Z", "2021-05-16", "description"})
	fmt.Println("NxListing", NxListing{"6c249256-2379-4683-bc31-23bbcce4fd39", "2021-05-16T18:14:12Z", "description"})
	fmt.Println("NxEntity", NxEntity{"6c249256-2379-4683-bc31-23bbcce4fd39", "Nx27", "2021-05-16T18:14:12Z"})
}
