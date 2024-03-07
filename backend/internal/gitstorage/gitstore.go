package gitstorage

import (
	"errors"
	"fmt"
	"github.com/go-git/go-billy/v5/memfs"
	"github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/plumbing/object"
	"github.com/go-git/go-git/v5/storage/memory"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"time"
)

var NoIdDelimiterFound = errors.New("no '---' found in file-name which indicate the start of the id of the score")
var MultipleIdDelimitersFound = errors.New("multiple '---' found in filename which indicate the start of the id of the score")

type GitFileStore struct {
	repo   *git.Repository
	logger *slog.Logger
}

func NewGitStore(logger *slog.Logger, url string) *GitFileStore {
	logger.Info("initializing git repo")

	repo, err := git.Clone(memory.NewStorage(), memfs.New(), &git.CloneOptions{
		URL: url,
	})
	if err != nil {
		logger.Error("failed to open git repository", slog.Any("error", err))
		os.Exit(1)
	}

	ref, err := repo.Head()
	if err != nil {
		panic(err)
	}

	cIter, err := repo.Log(&git.LogOptions{From: ref.Hash()})
	if err != nil {
		panic(err)
	}

	// ... just iterates over the commits, printing it
	err = cIter.ForEach(func(c *object.Commit) error {
		fmt.Println(c)
		return nil
	})
	return &GitFileStore{
		repo:   repo,
		logger: logger,
	}
}

func (gfs *GitFileStore) Pull() error {
	gfs.logger.Debug("pull repo")
	tree, err := gfs.repo.Worktree()
	if err != nil {
		return err
	}

	err = tree.Pull(&git.PullOptions{
		RemoteName: "origin",
	})
	if errors.Is(err, git.NoErrAlreadyUpToDate) {
		return nil
	}
	return err
}

func (gfs *GitFileStore) ChangedFiles(since *time.Time, until *time.Time) (files []string, err error) {
	gfs.logger.Debug("getting changed files", slog.Any("since", since), slog.Any("until", until))
	log, err := gfs.repo.Log(&git.LogOptions{
		Since: since,
		Until: until,
	})
	if err != nil {
		return nil, err
	}

	var first *object.Commit
	var last *object.Commit
	err = log.ForEach(func(commit *object.Commit) error {
		if first == nil {
			first = commit
		} else {
			last = commit
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	if first == nil {
		return make([]string, 0), nil
	}

	if last == nil {
		filesIter, err := first.Files()
		if err != nil {
			return nil, err
		}

		err = filesIter.ForEach(func(file *object.File) error {
			files = append(files, file.Name)
			return nil
		})
		if err != nil {
			return nil, err
		}

		return files, nil
	}

	fTree, err := first.Tree()
	if err != nil {
		return nil, err
	}
	lTree, err := last.Tree()
	if err != nil {
		return nil, err
	}

	changes, err := lTree.Diff(fTree)

	for _, change := range changes {
		_, to, err := change.Files()
		if err != nil {
			return nil, err
		}
		files = append(files, to.Name)
	}
	return files, nil
}

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
