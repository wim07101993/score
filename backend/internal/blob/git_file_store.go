package blob

import (
	"context"
	"errors"
	"github.com/go-git/go-billy/v5/memfs"
	"github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/plumbing/object"
	"github.com/go-git/go-git/v5/storage/memory"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"time"
)

var NoIdDelimiterFound = errors.New("no '---' found in file-name which indicate the start of the id of the score")
var MultipleIdDelimitersFound = errors.New("multiple '---' found in filename which indicate the start of the id of the score")
var NoSinceTimeSpecified = errors.New("no 'since' time specified")

type GitFileStoreFactory func(ctx context.Context) (*GitFileStore, error)

type GitFileStore struct {
	repo   *git.Repository
	logger *slog.Logger
}

func NewGitFileStore(ctx context.Context, logger *slog.Logger, url string) *GitFileStore {
	logger.Info("initializing git repo")

	repo, err := git.CloneContext(ctx, memory.NewStorage(), memfs.New(), &git.CloneOptions{
		URL: url,
	})
	if err != nil {
		logger.Error("failed to open git repository", slog.Any("error", err))
		os.Exit(1)
	}

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

func (gfs *GitFileStore) ChangedFiles(since *time.Time, until *time.Time) (
	new []*object.File, changed []*object.File, removed []*object.File, err error) {
	gfs.logger.Debug("getting changed files", slog.Any("since", since), slog.Any("until", until))

	if since == nil {
		return nil, nil, nil, NoSinceTimeSpecified
	}
	if until == nil {
		now := time.Now().UTC()
		until = &now
	}

	last, err := gfs.LastCommitBefore(*until)
	if err != nil {
		return nil, nil, nil, err
	}

	first, err := gfs.LastCommitBefore(*since)
	if err != nil {
		return nil, nil, nil, err
	}

	if first == nil {
		filesIter, err := last.Files()
		if err != nil {
			return nil, nil, nil, err
		}
		err = filesIter.ForEach(func(file *object.File) error {
			if strings.HasSuffix(file.Name, ".musicxml") {
				new = append(new, file)
			}
			return nil
		})
		return new, nil, nil, err
	}

	fTree, err := first.Tree()
	if err != nil {
		return nil, nil, nil, err
	}
	lTree, err := last.Tree()
	if err != nil {
		return nil, nil, nil, err
	}

	changes, err := fTree.Diff(lTree)

	for _, change := range changes {
		from, to, err := change.Files()
		if err != nil {
			return nil, nil, nil, err
		}
		if from != nil && to != nil && strings.HasSuffix(to.Name, ".musicxml") {
			changed = append(changed, to)
		} else if to != nil && strings.HasSuffix(to.Name, ".musicxml") {
			new = append(new, to)
		} else if from != nil && strings.HasSuffix(from.Name, ".musicxml") {
			removed = append(removed, from)
		}
	}
	return new, changed, removed, nil
}

func (gfs *GitFileStore) LastCommitBefore(until time.Time) (*object.Commit, error) {
	log, err := gfs.repo.Log(&git.LogOptions{
		Until: &until,
	})
	if err != nil {
		return nil, err
	}
	commit, err := log.Next()
	if err == nil || err == io.EOF {
		return commit, nil
	}
	return nil, err
}

func ScoreIdFromPath(path string) (id string, err error) {
	ext := filepath.Ext(path)
	split := strings.Split(filepath.Base(path[:len(path)-len(ext)]), "---")
	switch len(split) {
	case 0, 1:
		return "", NoIdDelimiterFound
	case 2:
		break
	default:
		return "", MultipleIdDelimitersFound
	}

	return split[1], nil
}
