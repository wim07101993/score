package logging

import (
	"context"
	"google.golang.org/grpc"
	"log/slog"
)

func LoggingUnaryInterceptor(logger *slog.Logger) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
		logger.Info("rpc",
			slog.Any("server", info.Server),
			slog.String("method", info.FullMethod))

		resp, err := handler(ctx, req)

		if err != nil {
			logger.Error("rpc failed",
				slog.Any("server", info.Server),
				slog.String("method", info.FullMethod),
				slog.Any("error", err))
		}

		return resp, err
	}
}
func LoggingStreamInterceptor(logger *slog.Logger) grpc.StreamServerInterceptor {
	return func(srv interface{}, stream grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
		logger.Info("rpc",
			slog.String("method", info.FullMethod))

		err := handler(srv, stream)

		if err != nil {
			logger.Error("rpc failed",
				slog.String("method", info.FullMethod),
				slog.Any("error", err))
		}

		return err
	}
}
