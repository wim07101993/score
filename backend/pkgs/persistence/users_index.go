package persistence

import (
	"log/slog"
	"time"
)

const UsersIndexName = "users"

type UsersIndex interface {
	AddUser(user *User) error
	RemoveUser(email string) error
}

type User struct {
	Email    string
	Name     string
	googleId string
}

func (idx *MeiliIndexes) AddUser(user *User) error {
	idx.logger.Info("adding user", slog.String("email", user.Email))

	doc := userToDocument(user)
	resp, err := idx.meili.Index(UsersIndexName).AddDocuments(doc)
	if err != nil {
		return err
	}

	_, err = idx.waitForTask(resp.TaskUID, time.Duration(30)*time.Second)
	if err != nil {
		return err
	}
	return nil
}

func (idx *MeiliIndexes) RemoveUser(email string) error {
	idx.logger.Info("removing user", slog.String("email", email))
	_, err := idx.meili.Index(UsersIndexName).DeleteDocument(email)
	return err
}

func userToDocument(user *User) map[string]interface{} {
	return map[string]interface{}{
		"email":    user.Email,
		"name":     user.Name,
		"googleId": user.googleId,
	}
}
