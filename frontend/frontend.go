package main

import (
	"log"
	"log/slog"
	"net/http"
	"os"
	"time"
)

var logger = slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))

func main() {
	fs := http.FileServer(http.Dir("./src"))
	http.Handle("/", NoCache(fs))

	logger.Info("listening on :3000")
	err := http.ListenAndServe(":3000", nil)
	if err != nil {
		log.Fatal(err)
	}
}

func NoCache(h http.Handler) http.Handler {
	var noCacheHeaders = map[string]string{
		"Expires":         time.Unix(0, 0).Format(time.RFC3339),
		"Cache-Control":   "no-cache, private, max-age=0",
		"Pragma":          "no-cache",
		"X-Accel-Expires": "0",
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		logger.Info("request", slog.Any("requestUri", r.RequestURI))
		for k, v := range noCacheHeaders {
			w.Header().Set(k, v)
		}
		h.ServeHTTP(w, r)
	})
}
