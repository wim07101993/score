package server

import "net/http"

func LimitRequestBody(maxBytes int64, handler http.Handler) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		if req.Body != nil {
			req.Body = http.MaxBytesReader(res, req.Body, maxBytes)
		}
		handler.ServeHTTP(res, req)
	}
}
