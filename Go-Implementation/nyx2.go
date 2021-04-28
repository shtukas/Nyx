package main

import (
	"fmt"

	"github.com/shtukas/nyx2/space"
)

func main() {
	fmt.Println("Hello world Nyx2")
	for _, id := range space.SpaceIds() {
		fmt.Println(space.SpaceId2MarbleFilepath(id))
	}
}
