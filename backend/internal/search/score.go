package search

import "score/backend/pkgs/models"

func ScoreToDocument(score *models.Score, id string) map[string]interface{} {
	if score == nil {
		return nil
	}
	return map[string]interface{}{
		"id":          id,
		"title":       score.Title,
		"composers":   score.Composers,
		"lyricists":   score.Lyricists,
		"instruments": score.Instruments(),
	}
}
