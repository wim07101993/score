package logging

import (
	"bytes"
	"encoding/json"
	"net/http"
)

type wireErrorCode struct {
	Code string `json:"errorCode"`
}

func extractWireErrorCode(body []byte) string {
	if len(body) == 0 {
		return ""
	}
	var envelope wireErrorCode
	if err := json.Unmarshal(body, &envelope); err != nil {
		return ""
	}
	return envelope.Code
}

type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int
	errorBody  *bytes.Buffer
}

func (w *loggingResponseWriter) WriteHeader(code int) {
	w.statusCode = code
	w.ResponseWriter.WriteHeader(code)
}

func (w *loggingResponseWriter) Write(b []byte) (int, error) {
	switch {
	case w.statusCode == 0:
		w.statusCode = http.StatusOK
	case w.statusCode >= http.StatusBadRequest:
		w.errorBody.Write(b)
	}
	return w.ResponseWriter.Write(b)
}
