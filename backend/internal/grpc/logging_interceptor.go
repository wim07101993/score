package grpc

import (
	"context"
	"fmt"
	"github.com/go-kit/log"
	"github.com/go-kit/log/level"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/logging"
)

func NewLogger(l log.Logger) logging.Logger {
	return logging.LoggerFunc(
		func(_ context.Context, lvl logging.Level, msg string, fields ...any) {
			largs := append([]any{"msg", msg}, fields...)
			switch lvl {
			case logging.LevelDebug:
				_ = level.Debug(l).Log(largs...)
			case logging.LevelInfo:
				_ = level.Info(l).Log(largs...)
			case logging.LevelWarn:
				_ = level.Warn(l).Log(largs...)
			case logging.LevelError:
				_ = level.Error(l).Log(largs...)
			default:
				panic(fmt.Sprintf("unknown level %v", lvl))
			}
		},
	)
}
