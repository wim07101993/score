package oidc

import (
	"net/http"
	"time"
)

// requestTimeout is how long one call to the provider may take, from dialling
// to the last byte of the answer.
//
// Every request the API serves waits on the provider twice before it does
// anything — once to ask whether the token is still good and once to learn who
// it belongs to — so a provider that stalls stalls the API with it. The
// request's own context does not save us either: a PUT whose caller has hung
// up is not cancelled while its body is still unread, and one was seen waiting
// on a stalled provider for well over two minutes. A provider that has not
// answered in this long is not going to, and answering the caller with an
// error they can retry is better than holding their connection and a
// goroutine until something else times out.
const requestTimeout = 10 * time.Second

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
		httpClient: &http.Client{Timeout: requestTimeout},
	}
}
