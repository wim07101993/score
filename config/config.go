package config

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"os"
	"score/internal/oidc"
	"score/internal/server"
	"score/internal/storage"

	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	HttpServerPort                 int    `envconfig:"HTTP_SERVER_PORT" json:"httpServerPort" default:"7001"`
	DbConnectionString             string `envconfig:"DB_CONNECTION_STRING" json:"dbConnectionString"`
	TokenIntrospectionUrl          string `envconfig:"TOKEN_INTROSPECTION_URL" json:"tokenIntrospectionUrl"`
	TokenIntrospectionClientId     string `envconfig:"TOKEN_INTROSPECTION_CLIENT_ID" json:"tokenIntrospectionClientId"`
	TokenIntrospectionClientSecret string `envconfig:"TOKEN_INTROSPECTION_CLIENT_SECRET" json:"tokenIntrospectionClientSecret"`
	UserInfoUrl                    string `envconfig:"USER_INFO_URL" json:"userInfoUrl"`
	RolesKey                       string `envconfig:"ROLES_KEY" json:"rolesKey"`
	MaxRequestBodyBytes            int64  `envconfig:"MAX_REQUEST_BODY_BYTES" json:"maxRequestBodyBytes" default:"33554432"`
}

func FromFile(configPath string) (*Config, error) {
	f, err := os.Open(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open config file: %w", err)
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
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}
	return cfg, nil
}

func FromEnv() (*Config, error) {
	cfg := &Config{}
	err := envconfig.Process("", cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to parse environment variables: %w", err)
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
	if other.UserInfoUrl != "" {
		cfg.UserInfoUrl = other.UserInfoUrl
	}
	if other.RolesKey != "" {
		cfg.RolesKey = other.RolesKey
	}
	if other.MaxRequestBodyBytes != 0 {
		cfg.MaxRequestBodyBytes = other.MaxRequestBodyBytes
	}
}

func (cfg *Config) Validate() error {
	var errs []error

	if cfg.HttpServerPort < 80 {
		errs = append(errs, errors.New("cannot listen on a port lower than 80 for listening for http requests"))
	}

	if cfg.DbConnectionString == "" {
		errs = append(errs, errors.New("no database connection string specified in configuration"))
	}

	if cfg.TokenIntrospectionUrl == "" {
		errs = append(errs, errors.New("no token introspection endpoint specified in configuration"))
	} else if _, err := url.ParseRequestURI(cfg.TokenIntrospectionUrl); err != nil {
		errs = append(errs, fmt.Errorf("the given token introspection url is not a valid url: %w", err))
	}

	if cfg.TokenIntrospectionClientId == "" {
		errs = append(errs, errors.New("no client id to use as auth for token introspection"))
	}

	if cfg.TokenIntrospectionClientSecret == "" {
		errs = append(errs, errors.New("no client secret to use as auth for token introspection"))
	}

	if cfg.UserInfoUrl == "" {
		errs = append(errs, errors.New("no user info url"))
	} else if _, err := url.ParseRequestURI(cfg.UserInfoUrl); err != nil {
		errs = append(errs, errors.New("the given user info url is not a valid url"))
	}

	if cfg.RolesKey == "" {
		errs = append(errs, errors.New("no roles key"))
	}

	if cfg.MaxRequestBodyBytes <= 0 {
		errs = append(errs, errors.New("the maximum request body size must be a positive number of bytes"))
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
		UserInfoUrl:                    cfg.UserInfoUrl,
		RolesKey:                       cfg.RolesKey,
		MaxRequestBodyBytes:            cfg.MaxRequestBodyBytes,
	}
}

func (cfg *Config) ServerConfig() server.Config {
	return server.Config{
		Port:                cfg.HttpServerPort,
		MaxRequestBodyBytes: cfg.MaxRequestBodyBytes,
	}
}

func (cfg *Config) OidcClientConfig() oidc.ClientConfig {
	return oidc.ClientConfig{
		IntrospectionUrl: cfg.TokenIntrospectionUrl,
		UserInfoUrl:      cfg.UserInfoUrl,
		ClientId:         cfg.TokenIntrospectionClientId,
		ClientSecret:     cfg.TokenIntrospectionClientSecret,
		RolesKey:         cfg.RolesKey,
	}
}

func (cfg *Config) DatabaseConfig() storage.DatabaseConfig {
	return storage.DatabaseConfig{
		ConnectionString: cfg.DbConnectionString,
	}
}
