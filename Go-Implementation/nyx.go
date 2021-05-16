package main

import (
	"fmt"

	"github.com/shtukas/nyx/space"
)

type Nx19 struct {
	announce string
	uuid     string
}

func main() {
	fmt.Println("Hello World!")
	for _, id := range space.SpaceIds() {
		fmt.Println(space.SpaceId2MarbleFilepath(id))
	}
	fmt.Println("Pascal")
	fmt.Println(Nx19{"announce", "6c249256-2379-4683-bc31-23bbcce4fd39"})
}
