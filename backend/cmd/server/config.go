package main

import (
	"flag"
	"golang.org/x/exp/maps"
	auth2 "score/backend/pkgs/auth"
	"strings"
)

const (
	scoresRepositoryEnvVar         = "SCORES_REPOSITORY"
	scorePortEnvVar                = "SCORE_PORT"
	authProvidersEnvVars           = "AUTH_PROVIDERS"
	initialAdminEmailAddressEnvVar = "INITIAL_ADMIN_EMAIL_ADDRESS"
)

var scoresRepository string
var serverPort int
var authProviderCsvList string
var authConfigs []auth2.Config
var knownAuthConfigs = map[string]auth2.Config{
	"google":   auth2.GoogleConfig,
	"facebook": auth2.FacebookConfig,
}
var initialUserAdminEmailAddress string

func init() {
	flag.StringVar(&scoresRepository, "repo", "",
		"The git repository on which the scores are stored. Ensure this server has read access to that repo.")
	flag.IntVar(&serverPort, "port", 7700,
		"The port on which the server should listen. If omitted, stdin is used.")
	flag.StringVar(&initialUserAdminEmailAddress, "initialUserAdminEmailAddress", "",
		"The email address of the initial administrator. This email address will be added to the users table in the database (with admin access rights) if no admins are present.")

	knownAuthProviders := make([]string, 0, len(knownAuthConfigs))
	for k := range knownAuthConfigs {
		knownAuthProviders = append(knownAuthProviders, k)
	}

	flag.StringVar(&authProviderCsvList, "auth", "google",
		"The allowed auth providers. Should be a comma separated list without spaces. E.g.: google,facebook "+
			"Implemented providers are: "+strings.Join(maps.Keys(knownAuthConfigs), ", "))
}
