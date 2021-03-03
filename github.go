package main

import (
	"context"
	"log"
	"os"

	"github.com/google/go-github/v32/github"
	"golang.org/x/oauth2"
)

var ()

func gheClient() (*github.Client, context.Context, error) {
	token := os.Getenv("GHE_TOKEN")
	gheBaseURL := os.Getenv("GHE_BASE_URL")

	if token == "" {
		log.Fatal("GHE_TOKEN is undefined")
		os.Exit(1)
	}

	ctx := context.Background()
	transportClient := oauth2.NewClient(ctx, oauth2.StaticTokenSource(
		&oauth2.Token{
			AccessToken: token,
		},
	))

	client, err := github.NewEnterpriseClient(gheBaseURL, gheBaseURL, transportClient)

	return client, ctx, err
}
