package main

import (
	"encoding/json"
	"fmt"
	"os"
)

var (
	jsonPrefix = ""
	jsonIndent = "  "
)

func main() {
	provider := ProvidersProtocol{
		ProvidersV1: ProvidersV1Value,
	}

	b, err := json.MarshalIndent(provider, jsonPrefix, jsonIndent)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	fmt.Println(string(b))
}
