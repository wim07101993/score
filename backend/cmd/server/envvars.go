package main

import (
	"golang.org/x/exp/maps"
	"os"
	"score/backend/pkgs/auth"
	"strconv"
	"strings"
)

func parseEnvVars() {
	if scoresRepository == "" {
		scoresRepository = os.Getenv(scoresRepositoryEnvVar)
	}

	if serverPort == 0 {
		sport := os.Getenv(scorePortEnvVar)
		if sport != "" {
			p, err := strconv.Atoi(os.Getenv(scorePortEnvVar))
			if err != nil {
				panic(err)
			}
			serverPort = p
		}
	}

	if authProviderCsvList == "" {
		authProviderCsvList = os.Getenv(authProvidersEnvVars)
	}
	if initialUserAdminEmailAddress == "" {
		initialUserAdminEmailAddress = os.Getenv(initialAdminEmailAddressEnvVar)
	}
}

func validateConfig() {
	if scoresRepository == "" {
		panic("no git repo specified. e.g.: --repo git@SERVER.com:MY_USER/REPOSITORY.git or " + scoresRepositoryEnvVar + " environment variable")
	}
	if serverPort < 80 {
		panic("cannot listen on a port lower than 80. e.g.: --port 7701 or " + scorePortEnvVar + " environment variable")
	}
	if authProviderCsvList == "" {
		panic("no auth providers specified. e.g.: --auth google,facebook")
	}

	if authProviderCsvList == "none" {
		// This should only be used for debugging purposes!
		auth.SkipJwtVerification = true
	} else {
		authProviders := strings.Split(authProviderCsvList, ",")
		if len(authProviders) == 0 {
			panic("no auth providers specified. e.g.: --auth google,facebook")
		}

		for _, provider := range authProviders {
			if c, ok := knownAuthConfigs[provider]; ok {
				authConfigs = append(authConfigs, c)
				continue
			}
			panic("unknown auth provider: " + provider + "known auth providers" + strings.Join(maps.Keys(knownAuthConfigs), ", "))
		}
	}

	if initialUserAdminEmailAddress == "" {
		logger.Warn("No initial admin email address specified. If there is no admin in the database, it will be impossible to perform operations which require admin rights")
	}
}
