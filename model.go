package main

const (
	ProvidersV1Value = "/terraform/providers/v1/"
)

type ProvidersProtocol struct {
	ProvidersV1 string `json:"providers.v1"`
}
