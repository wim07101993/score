package utils

import (
	"io"
	"score/backend/api/generated/github.com/wim07101993/score/api"
)

type GrpcChunkSender interface {
	Send(chunk *api.FileChunk) error
}

type grpcChunkWriter struct {
	totalFileSize uint64
	sender        GrpcChunkSender
}

func NewGrpcChunkWriter(sender GrpcChunkSender, totalFileSize uint64) io.Writer {
	return &grpcChunkWriter{
		totalFileSize: totalFileSize,
		sender:        sender,
	}
}

func (w *grpcChunkWriter) Write(p []byte) (n int, err error) {
	err = w.sender.Send(&api.FileChunk{
		TotalFileSize: w.totalFileSize,
		Data:          p,
	})
	return len(p), err
}

type GrpcChunkReceiver interface {
	Recv() (*api.FileChunk, error)
}

type grpcChunkReader struct {
	receiver GrpcChunkReceiver
}

func NewGrpcChunkReader(receiver GrpcChunkReceiver) io.Reader {
	return &grpcChunkReader{
		receiver: receiver,
	}
}

func (r *grpcChunkReader) Read(p []byte) (n int, err error) {

}
