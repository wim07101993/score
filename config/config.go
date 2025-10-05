package config

import (
	"encoding/json"
	"errors"
	"net/url"
	"os"

	"github.com/kelseyhightower/envconfig"
	errorspkg "github.com/pkg/errors"
)

type Config struct {
	HttpServerPort                 int    `envconfig:"HTTP_SERVER_PORT" json:"httpServerPort" default:"7001"`
	DbConnectionString             string `envconfig:"DB_CONNECTION_STRING" json:"dbConnectionString"`
	TokenIntrospectionUrl          string `envconfig:"TOKEN_INTROSPECTION_URL" json:"tokenIntrospectionUrl"`
	TokenIntrospectionClientId     string `envconfig:"TOKEN_INTROSPECTION_CLIENT_ID" json:"tokenIntrospectionClientId"`
	TokenIntrospectionClientSecret string `envconfig:"TOKEN_INTROSPECTION_CLIENT_SECRET" json:"tokenIntrospectionClientSecret"`
}

func FromFile(configPath string) (*Config, error) {
	f, err := os.Open(configPath)
	if err != nil {
		return nil, errorspkg.Wrap(err, "failed to open config file")
	}
	defer func(f *os.File) {
		err := f.Close()
		if err != nil {
			panic(err)
		}
	}(f)

	cfg := &Config{}
	decoder := json.NewDecoder(f)
	err = decoder.Decode(cfg)
	if err != nil {
		return nil, errorspkg.Wrap(err, "failed to parse config file")
	}
	return cfg, nil
}

func FromEnv() (*Config, error) {
	cfg := &Config{}
	err := envconfig.Process("", cfg)
	if err != nil {
		return nil, errorspkg.Wrap(err, "failed to parse environment variables")
	}
	return cfg, nil
}

func (cfg *Config) CopyFrom(other *Config) {
	if other.DbConnectionString != "" {
		cfg.DbConnectionString = other.DbConnectionString
	}
	if other.HttpServerPort != 0 {
		cfg.HttpServerPort = other.HttpServerPort
	}
	if other.TokenIntrospectionClientId != "" {
		cfg.TokenIntrospectionClientId = other.TokenIntrospectionClientId
	}
	if other.TokenIntrospectionClientSecret != "" {
		cfg.TokenIntrospectionClientSecret = other.TokenIntrospectionClientSecret
	}
	if other.TokenIntrospectionUrl != "" {
		cfg.TokenIntrospectionUrl = other.TokenIntrospectionUrl
	}
}

func (cfg *Config) Validate() error {
	var errs []error

	if cfg.HttpServerPort < 80 {
		errs = append(errs, errors.New("cannot listen on a port lower than 80 for listening for http requests"))
	}
	if cfg.TokenIntrospectionUrl == "" {
		errs = append(errs, errors.New("no token introspection endpoint specified in configuration"))
	} else if _, err := url.ParseRequestURI(cfg.TokenIntrospectionUrl); err != nil {
		errs = append(errs, errorspkg.Wrap(err, "the given token introspection url is not a valid url"))
	}

	if cfg.TokenIntrospectionClientId == "" {
		errs = append(errs, errors.New("no client id to use as auth for token introspection"))
	}
	if cfg.TokenIntrospectionClientSecret == "" {
		errs = append(errs, errors.New("no client secret to use as auth for token introspection"))
	}

	if len(errs) > 0 {
		return errors.Join(errs...)
	}
	return nil
}

func (cfg *Config) Redacted() Config {
	return Config{
		HttpServerPort:                 cfg.HttpServerPort,
		DbConnectionString:             "********",
		TokenIntrospectionUrl:          cfg.TokenIntrospectionUrl,
		TokenIntrospectionClientId:     cfg.TokenIntrospectionClientId,
		TokenIntrospectionClientSecret: "********",
	}
}
