package server

import (
	"encoding/xml"
	"errors"
	"io"
	"score/backend/api/generated/github.com/wim07101993/score"
	"score/backend/internal/grpc"
	"score/backend/pkgs/musicxml"
)

type ScoreManager struct {
	score.ScoreManagerServer
}

func (s *ScoreManager) CreateScoreFromMusicXml(stream score.ScoreManager_CreateScoreFromMusicXmlServer) error {
	reader := grpc.NewFileChunkReader(stream)
	musicDoc, err := musicxml.NewParser(xml.NewDecoder(reader)).Parse()
	if err != nil {
		if err == io.EOF {
			return errors.New("no file to parse")
		}
		return err
	}

	_ = musicDoc // TODO save the doc to the database

	var id int32 = 0 // TODO actually create the score
	return stream.SendAndClose(&score.CreatedReply{Id: id})
}
