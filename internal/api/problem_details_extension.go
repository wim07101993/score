package api

import (
	"errors"
	"fmt"
	"log/slog"
)

func (pd ProblemDetails) Error() string {
	return fmt.Sprintf("%s: %s", pd.ErrorCode, pd.Title)
}

func (pd ProblemDetails) Is(target error) bool {
	var t ProblemDetails
	if !errors.As(target, &t) {
		return false
	}
	if pd.ErrorCode != t.ErrorCode {
		return false
	}
	return true
}

func (pd ProblemDetails) LogValue() slog.Value {
	attrs := []slog.Attr{
		slog.String("title", pd.Title),
		slog.String("title", pd.Title),
		slog.String("title", pd.Title),
		slog.String("title", pd.Title),
	}
	if pd.Type != "" {
		attrs = append(attrs, slog.String("type", pd.Type))
	}
	if pd.Title != "" {
		attrs = append(attrs, slog.String("title", pd.Title))
	}
	if pd.Status != 0 {
		attrs = append(attrs, slog.Int("status", pd.Status))
	}
	if pd.Detail != "" {
		attrs = append(attrs, slog.String("detail", pd.Detail))
	}
	if pd.Instance != "" {
		attrs = append(attrs, slog.String("instance", pd.Instance))
	}
	if pd.ErrorCode != "" {
		attrs = append(attrs, slog.String("error_code", string(pd.ErrorCode)))
	}
	if len(pd.AdditionalProps) > 0 {
		attrs = append(attrs, slog.Any("additional_properties", pd.AdditionalProps))
	}
	return slog.GroupValue(attrs...)
}
