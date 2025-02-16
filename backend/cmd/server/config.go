package main

import (
	"encoding/json"
	"errors"
	"github.com/kelseyhightower/envconfig"
	"os"
)

type Config struct {
	ScoresRepository   string `envconfig:"SCORES_REPOSITORY" json:"scoresRepository"`
	GrpcServerPort     int    `envconfig:"GRPC_SERVER_PORT" json:"grpcServerPort" default:"7000"`
	HttpServerPort     int    `envconfig:"HTTP_SERVER_PORT" json:"httpServerPort" default:"7001"`
	JwtIssuer          string `envconfig:"JWT_ISSUER" json:"jwtIssuer"`
	DbConnectionString string `envconfig:"DB_CONNECTION_STRING" json:"dbConnectionString"`
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

func (cfg *Config) Validate() error {
	logger.Info("validating config")

	var errs []error

	if cfg.ScoresRepository == "" {
		errs = append(errs, errors.New("no ScoresRepository specified in configuration"))
	}
	if cfg.GrpcServerPort < 80 {
		errs = append(errs, errors.New("cannot listen on a port lower than 80 for listening for gRPC requests"))
	}
	if cfg.HttpServerPort < 80 {
		errs = append(errs, errors.New("cannot listen on a port lower than 80 for listening for http requests"))
	}
	if cfg.GrpcServerPort == cfg.HttpServerPort {
		errs = append(errs, errors.New("cannot for both http and gRPC requests on the same port"))
	}
	if cfg.JwtIssuer == "" {
		errs = append(errs, errors.New("no jwt issuer specified in configuration"))
	}

	if len(errs) > 0 {
		return errors.Join(errs...)
	}
	return nil
}
