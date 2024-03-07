package main

import (
	"fmt"
	"github.com/go-git/go-billy/v5/osfs"
	"os"
	"time"

	"github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/plumbing/cache"
	"github.com/go-git/go-git/v5/plumbing/object"
	"github.com/go-git/go-git/v5/storage/filesystem"
)

func main() {
	const path = "/home/wim/source/repos/score"

	fs := osfs.New(path)
	if _, err := fs.Stat(git.GitDirName); err == nil {
		fs, err = fs.Chroot(git.GitDirName)
		CheckIfError(err)
	}

	s := filesystem.NewStorageWithOptions(fs, cache.NewObjectLRUDefault(), filesystem.Options{KeepDescriptors: true})
	r, err := git.Open(s, fs)
	CheckIfError(err)
	defer s.Close()

	//ref, err := r.Head()
	CheckIfError(err)

	since := time.Date(2024, 01, 01, 0, 0, 0, 0, time.UTC)
	//until := time.Now().UTC()
	var first *object.Commit
	var last *object.Commit
	log, err := r.Log(&git.LogOptions{
		Since: &since,
		//Until: &until,
		//From: ref.Hash(),
	})
	CheckIfError(err)

	err = log.ForEach(func(commit *object.Commit) error {
		if first == nil {
			first = commit
		} else {
			last = commit
		}
		return nil
	})
	CheckIfError(err)

	fTree, err := first.Tree()
	CheckIfError(err)
	lTree, err := last.Tree()
	CheckIfError(err)

	changes, err := lTree.Diff(fTree)
	CheckIfError(err)

	paths := make(map[string]struct{})
	for _, change := range changes {
		_, to, err := change.Files()
		CheckIfError(err)
		if to != nil {
			paths[to.Name] = struct{}{}
		}
	}

	fmt.Println(paths)
}

// CheckIfError should be used to naively panics if an error is not nil.
func CheckIfError(err error) {
	if err == nil {
		return
	}

	fmt.Printf("\x1b[31;1m%s\x1b[0m\n", fmt.Sprintf("error: %s", err))
	os.Exit(1)
}
