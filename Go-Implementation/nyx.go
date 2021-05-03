package main

import (
	"fmt"

	"github.com/shtukas/nyx/space"
)

func main() {
	fmt.Println("Hello World!")
	for _, id := range space.SpaceIds() {
		fmt.Println(space.SpaceId2MarbleFilepath(id))
	}
}
