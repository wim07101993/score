package main

import (
	"context"
	"flag"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"io"
	"log"
	"os"
	"score/backend/api/generated/github.com/wim07101993/score"
	"score/backend/internal/closer"
	grpc2 "score/backend/internal/grpc"
	"time"
)

var address = flag.String("address", "localhost:8012", "the address to connect to")
var filePath = flag.String("file", "", "the file path of th emusic xml to upload")

func main() {
	flag.Parse()

	client := createGrpcClient()
	createScoreFromMusicXml(client)
}

func createScoreFromMusicXml(client score.ScoreManagerClient) {
	if *filePath == "" {
		log.Fatal("no file specified. Please specify a file to upload using the -file flag")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	file, err := os.Open(*filePath)
	if err != nil {
		log.Fatalf("error while opening file: %v", err)
	}
	defer closer.CloseAndLogError(file)

	stream, err := client.CreateScoreFromMusicXml(ctx)
	if err != nil {
		log.Fatalf("error while creating score from music xml: %v", err)
	}

	writer := grpc2.NewFileChunkWriter(stream)
	size, err := io.Copy(writer, file)
	if err != nil {
		log.Fatalf("error while sending file: %v", err)
	}
	log.Printf("sent %d bytes", size)
	log.Printf("created score with id %v", stream)
}

func createGrpcClient() score.ScoreManagerClient {
	opts := []grpc.DialOption{
		// todo set credentials
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	}
	conn, err := grpc.Dial(*address, opts...)

	if err != nil {
		log.Fatalf("failed to connect to %v: %v", address, err)
	}
	defer closer.CloseAndLogError(conn)

	return score.NewScoreManagerClient(conn)
}
