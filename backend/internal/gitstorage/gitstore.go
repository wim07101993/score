package gitstorage

import (
	"errors"
	"path/filepath"
	"strings"
)

var NoIdDelimiterFound = errors.New("no '---' found in file-name which indicate the start of the id of the score")
var MultipleIdDelimitersFound = errors.New("multiple '---' found in filename which indicate the start of the id of the score")

func ScoreIdFromPath(path string) (id string, err error) {
	ext := filepath.Ext(path)
	split := strings.Split(filepath.Base(path[:len(path)-len(ext)]), "---")
	switch len(split) {
	case 0:
		return "", NoIdDelimiterFound
	case 1:
		break
	default:
		return "", MultipleIdDelimitersFound
	}

	return split[1], nil
}
