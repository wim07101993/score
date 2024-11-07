package main

import (
	"encoding/json"
	"errors"
	"github.com/kelseyhightower/envconfig"
	"golang.org/x/exp/maps"
	"os"
	"score/backend/pkgs/auth"
	"strings"
)

var knownAuthConfigs = map[string]auth.Config{
	"google":   auth.GoogleConfig,
	"facebook": auth.FacebookConfig,
}

type Config struct {
	ScoresRepository             string   `envconfig:"SCORES_REPOSITORY" json:"scoresRepository"`
	GrpcServerPort               int      `envconfig:"GRPC_SERVER_PORT" json:"grpcServerPort" default:"7000"`
	HttpServerPort               int      `envconfig:"HTTP_SERVER_PORT" json:"httpServerPort" default:"7001"`
	AuthProviders                []string `envconfig:"AUTH_PROVIDERS" json:"authProviders"`
	InitialUserAdminEmailAddress string   `envconfig:"INITIAL_USER_ADMIN_EMAIL_ADDRESS" json:"initialUserAdminEmailAddress"`
}

func (cfg *Config) FromFile() error {
	f, err := os.Open("config.json")
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	defer func(f *os.File) {
		err := f.Close()
		if err != nil {
			panic(err)
		}
	}(f)

	decoder := json.NewDecoder(f)
	err = decoder.Decode(cfg)
	if err != nil {
		return err
	}
	return nil
}

func (cfg *Config) FromEnv() error {
	return envconfig.Process("", cfg)
}

func (cfg *Config) AuthConfigs() ([]auth.Config, error) {
	configs := make([]auth.Config, len(cfg.AuthProviders))
	for i, p := range cfg.AuthProviders {
		if c, ok := knownAuthConfigs[p]; ok {
			configs[i] = c
			continue
		}
		return nil, errors.New("unknown auth provider: " + p + "known auth providers" + strings.Join(maps.Keys(knownAuthConfigs), ", "))
	}
	return configs, nil
}

func (cfg *Config) Validate() error {
	logger.Info("validating config")

	var errs []string

	if cfg.ScoresRepository == "" {
		errs = append(errs, "No ScoresRepository specified in configuration.")
	}
	if cfg.GrpcServerPort < 80 {
		errs = append(errs, "Cannot listen on a port lower than 80 for listening for gRPC requests.")
	}
	if cfg.HttpServerPort < 80 {
		errs = append(errs, "Cannot listen on a port lower than 80 for listening for http requests.")
	}
	if cfg.GrpcServerPort == cfg.HttpServerPort {
		errs = append(errs, "Cannot for both http and gRPC requests on the same port.")
	}
	if len(cfg.AuthProviders) == 0 {
		errs = append(errs, "no auth providers specified. Use --auth google,facebook")
	}
	if cfg.InitialUserAdminEmailAddress == "" {
		logger.Warn("No initial admin email address specified. If there is no admin in the database, it will be impossible to perform operations which require admin rights")
	}

	for _, p := range cfg.AuthProviders {
		if _, ok := knownAuthConfigs[p]; !ok {
			errs = append(errs, "unknown auth provider: "+p+"known auth providers"+strings.Join(maps.Keys(knownAuthConfigs), ", "))
		}
	}

	if len(errs) > 0 {
		return errors.New(strings.Join(errs, "; "))
	}
	return nil
}
