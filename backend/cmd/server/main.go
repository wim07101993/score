package main

import (
	"flag"
	"fmt"
	"github.com/go-kit/log"
	"github.com/go-kit/log/level"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/auth"
	logging2 "github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/logging"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/selector"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"net"
	"os"
	"score/backend/api/generated/github.com/wim07101993/score"
	grpc2 "score/backend/internal/grpc"
	"score/backend/pkgs/server"
)

var port = flag.Int("port", 8012, "the port to serve on")

func main() {
	flag.Parse()
	logger := log.NewLogfmtLogger(os.Stderr)
	rpcLogger := grpc2.NewLogger(log.With(logger, "service", "gRPC/server"))

	fmt.Printf("server starting on port %d...\n", *port)

	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		_ = level.Error(logger).Log("failed to listen for requests: %v", err)
	}

	opts := []grpc.ServerOption{
		grpc.ChainUnaryInterceptor(
			logging2.UnaryServerInterceptor(rpcLogger),
			selector.UnaryServerInterceptor(
				auth.UnaryServerInterceptor(grpc2.IsContextAuthenticated),
				selector.MatchFunc(grpc2.ShouldAuthenticate),
			),
		),
		grpc.ChainStreamInterceptor(
			logging2.StreamServerInterceptor(rpcLogger),
			selector.StreamServerInterceptor(
				auth.StreamServerInterceptor(grpc2.IsContextAuthenticated),
				selector.MatchFunc(grpc2.ShouldAuthenticate),
			),
		),
	}
	s := grpc.NewServer(opts...)

	score.RegisterScoreManagerServer(s, &server.ScoreManager{})

	// register reflection service on gRPC server
	reflection.Register(s)

	if err := s.Serve(lis); err != nil {
		_ = logger.Log("ERROR: error while serving score manager", err)
	}
}
