package grpc

import "score/backend/api/generated/github.com/wim07101993/score"

type FileChunkStreamReader interface {
	Recv() (*score.FileChunk, error)
}

type FileChunkReader struct {
	buffer []byte
	stream FileChunkStreamReader
}

func NewFileChunkReader(stream FileChunkStreamReader) *FileChunkReader {
	return &FileChunkReader{
		buffer: []byte{},
		stream: stream,
	}
}

func (r *FileChunkReader) Read(p []byte) (n int, err error) {
	if len(r.buffer) == 0 {
		chunk, err := r.stream.Recv()
		if err != nil {
			return 0, err
		}
		r.buffer = chunk.Content
	}

	i := copy(p, r.buffer)
	r.buffer = r.buffer[i:]
	return i, nil
}
