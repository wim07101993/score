package interceptors

import (
	"context"
	"fmt"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/logging"
	"log/slog"
	"strings"
)

func NewLogger(logger *slog.Logger) logging.Logger {
	return logging.LoggerFunc(
		func(ctx context.Context, lvl logging.Level, msg string, fields ...any) {
			if len(fields) >= 6 {
				service := fmt.Sprint(fields[5])
				if strings.HasPrefix(service, "grpc.reflection") {
					return
				}
			}
			attrs := make([]slog.Attr, len(fields))
			for i := 0; i < len(fields)/2; i++ {
				attrs[i] = slog.Any(fmt.Sprint(fields[i*2]), fields[(i*2)+1])
			}

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
			logger.LogAttrs(ctx, level, msg, attrs...)
		},
	)
}
