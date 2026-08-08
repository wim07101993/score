package oidc

import (
	"net/http"
)

type ClientConfig struct {
	IntrospectionUrl string
	UserInfoUrl      string
	ClientId         string
	ClientSecret     string
	RolesKey         string
}

type Client struct {
	config     ClientConfig
	httpClient *http.Client
}

func NewClient(config ClientConfig) *Client {
	return &Client{
		config:     config,
		httpClient: &http.Client{},
	}
}
