# Provider Registry Protocol

Acts as an "overlay" between GitHub Enterprise and Terraform by implementing a Lambda function which sits in front of GitHub Enterprise, queries its API, and responds to requests for private provider installation.

Completely event-driven. No infrastructure to run.

## How it works

In the world of GitHub and Go packages, there are some fairly common patterns in the world.

1. Tags are semantically-versioned.
1. Proper releases are prepared.
1. Binaries for supported platforms are compiled and attached as assets to the release.

These patterns are expected by this software. A LOT of people are using GoReleaser to streamline this process.

Additionally, because they are light-touch, we can derive certain metadata about a provider by leveraging specially-formatted repository topics.

## Provider Configuration

* `terraform-provider` is required.
* `provider-type-{NAME}` is required, where `{NAME}` is a lowercase (e.g., `aws`, `google`, `azurerm`, `scout`).
* `provider-ns-{NAME}` is optional, where `{NAME}` is a lowercase namespace. If omitted, the default value will be defined in the `DEFAULT_PROVIDER_NS` environment variable of the Lambda environment.

To avoid confusion, only ONE of each of these topics/tags is permitted. (Any behavior stemming from multiple copies of a tag being set is _undefined behavior_ and therefore has no service contract.)

## Lambda Configuration

| Environment           | Description |
|-----------------------|-------------|
| `DEFAULT_PROVIDER_NS` |             |
| `GHE_TOKEN`           |             |
| `GHE_BASE_URL`        |             |
