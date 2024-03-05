package grpc

import (
	"context"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/logging"
	"log/slog"
)

func NewLogger(logger *slog.Logger) logging.Logger {
	return logging.LoggerFunc(
		func(ctx context.Context, lvl logging.Level, msg string, fields ...any) {
			var level slog.Level
			switch lvl {
			case logging.LevelDebug:
				level = slog.LevelDebug
			case logging.LevelInfo:
				level = slog.LevelInfo
			case logging.LevelWarn:
				level = slog.LevelWarn
			case logging.LevelError:
				level = slog.LevelError
			default:
				logger.Error("unknown log level",
					slog.Any("level", lvl),
					slog.String("message", msg),
					slog.Any("fields", fields))
				return
			}
			logger.Log(ctx, level, msg, fields)
		},
	)
}
