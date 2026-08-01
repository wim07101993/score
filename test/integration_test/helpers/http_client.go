package helpers

import (
	"net/http"
	"testing"
	"time"
)

func (h *Harness) EnsureHttpClient(t *testing.T) *http.Client {
	t.Helper()
	h.httpClient.mutex.Lock()
	defer h.httpClient.mutex.Unlock()

	if h.httpClient.value == nil {
		h.httpClient.value = &http.Client{
			Timeout: 30 * time.Second,
			// Redirects would hide the status code the API actually returned.
			CheckRedirect: func(req *http.Request, via []*http.Request) error {
				return http.ErrUseLastResponse
			},
		}
	}
	return h.httpClient.value
}
