package grpc

import "score/backend/api/generated/github.com/wim07101993/score"

type FileChunkStreamWriter interface {
	Send(chunk *score.FileChunk) error
}

type FileChunkWriter struct {
	stream FileChunkStreamWriter
}

func NewFileChunkWriter(stream FileChunkStreamWriter) *FileChunkWriter {
	return &FileChunkWriter{
		stream: stream,
	}
}

func (r *FileChunkWriter) Write(p []byte) (n int, err error) {
	err = r.stream.Send(&score.FileChunk{Content: p})
	return len(p), err
}
