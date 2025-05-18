package blob

import (
	"context"
	"fmt"
	"github.com/minio/minio-go/v7"
	"io"
	"log/slog"
)

type MinioBlobStoreFactory func(ctx context.Context) (*MinioScoreBlobStore, error)

type MinioScoreBlobStore struct {
	bucketName string
	logger     *slog.Logger
	minio      *minio.Client
}

func (store *MinioScoreBlobStore) Put(
	ctx context.Context,
	scoreId string,
	title string,
	file io.Reader,
	fileSize int64) error {
	_, err := store.minio.PutObject(
		ctx, store.bucketName,
		scoreId, file, fileSize,
		minio.PutObjectOptions{
			ContentType:        "application/vnd.recordstore.musicxml+xml",
			ContentDisposition: fmt.Sprintf("attachment; filename=\"%s.pdf\"", title),
		})
	return err
}

func (store *MinioScoreBlobStore) Remove(ctx context.Context, scoreId string) error {
	return store.minio.RemoveObject(
		ctx, store.bucketName,
		scoreId,
		minio.RemoveObjectOptions{})
}

func (store *MinioScoreBlobStore) Get(ctx context.Context, scoreId string) (size int64, file io.ReadCloser, err error) {
	obj, err := store.minio.GetObject(
		ctx, store.bucketName,
		scoreId,
		minio.GetObjectOptions{})
	if err != nil {
		return 0, nil, err
	}

	stats, err := obj.Stat()
	if err != nil {
		return 0, nil, err
	}

	return stats.Size, obj, err
}
