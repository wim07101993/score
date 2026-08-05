package score

import (
	"net/http"
	"time"

	"score/internal/api"
	"score/internal/httperror"

	"github.com/google/uuid"
)

type Score struct {
	Id            string    `json:"id"`
	Work          Work      `json:"work"`
	Movement      Movement  `json:"movement"`
	Creators      Creators  `json:"creators"`
	Languages     []string  `json:"languages"`
	Instruments   []string  `json:"instruments"`
	LastChangedAt time.Time `json:"last_changed_at"`
	Tags          []string  `json:"tags"`
}

type Work struct {
	Title  string `json:"title"`
	Number string `json:"number"`
}

type Movement struct {
	Title  string `json:"title"`
	Number string `json:"number"`
}

type Creators struct {
	Composers []string `json:"composers"`
	Lyricists []string `json:"lyricists"`
}

// apiScore is a score the way api/endpoints/scores/by_id/get_score_response.yaml
// describes it.
func apiScore(score *Score) (*api.Score, error) {
	id, err := uuid.Parse(score.Id)
	if err != nil {
		return nil, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to get score")
	}

	return &api.Score{
		ID: id,
		Work: api.ScoreWork{
			Title:  score.Work.Title,
			Number: score.Work.Number,
		},
		Movement: api.ScoreMovement{
			Title:  score.Movement.Title,
			Number: score.Movement.Number,
		},
		Creators: api.ScoreCreators{
			Composers: score.Creators.Composers,
			Lyricists: score.Creators.Lyricists,
		},
		Languages:     score.Languages,
		Instruments:   score.Instruments,
		LastChangedAt: score.LastChangedAt,
		Tags:          score.Tags,
	}, nil
}
