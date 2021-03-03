package main

import spew "github.com/davecgh/go-spew/spew"

// Analogous to PrettyPrint in Python or print_r() in PHP.
func getSpew() spew.ConfigState {
	return spew.ConfigState{
		Indent:   "    ",
		SortKeys: true,
		SpewKeys: true,
	}
}
