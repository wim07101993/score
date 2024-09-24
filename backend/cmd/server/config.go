package main

import (
	"flag"
	meili "github.com/meilisearch/meilisearch-go"
	"golang.org/x/exp/maps"
	auth2 "score/backend/pkgs/auth"
	"strings"
)

const (
	meiliHostEnvVar        = "MEILI_HOST"
	meiliApiKeyEnvVar      = "MEILI_API_KEY"
	scoresRepositoryEnvVar = "SCORES_REPOSITORY"
	scorePortEnvVar        = "SCORE_PORT"
	authProvidersEnvVars   = "AUTH_PROVIDERS"
)

var scoresRepository string
var meiliConfig meili.ClientConfig
var serverPort int
var authProviderCsvList string
var authConfigs []auth2.Config
var knownAuthConfigs = map[string]auth2.Config{
	"google":   auth2.GoogleConfig,
	"facebook": auth2.FacebookConfig,
}

func init() {
	flag.StringVar(&scoresRepository, "repo", "",
		"The git repository on which the scores are stored. Ensure this server has read access to that repo.")
	flag.StringVar(&meiliConfig.Host, "host", "http://localhost:7700",
		"The meili search server on which to index the score.")
	flag.StringVar(&meiliConfig.APIKey, "apikey", "",
		"The api key with which to connect to the meili server.")
	flag.IntVar(&serverPort, "port", 7700,
		"The port on which the server should listen. If omitted, stdin is used.")

	knownAuthProviders := make([]string, 0, len(knownAuthConfigs))
	for k := range knownAuthConfigs {
		knownAuthProviders = append(knownAuthProviders, k)
	}

	flag.StringVar(&authProviderCsvList, "auth", "google",
		"The allowed auth providers. Should be a comma separated list without spaces. E.g.: google,facebook "+
			"Implemented providers are: "+strings.Join(maps.Keys(knownAuthConfigs), ", "))
}
