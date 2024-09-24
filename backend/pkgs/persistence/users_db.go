package persistence

import (
	"log/slog"
)

type UsersDb interface {
	AddUser(user *User) error
	RemoveUser(email string) error
}

type User struct {
	Email    string
	Name     string
	googleId string
}

func (db *SqlTables) AddUser(user *User) error {
	db.logger.Info("adding user", slog.String("email", user.Email))

	const query = `
		INSERT INTO users (email,name,google_id,facebook_id) 
		VALUES (:email,:name,:googleId,:facebookId)`

	doc := map[string]interface{}{
		"email":    user.Email,
		"name":     user.Name,
		"googleId": user.googleId,
	}

	_, err := db.db.NamedExec(query, doc)
	if err != nil {
		return err
	}
	return nil
}

func (db *SqlTables) RemoveUser(email string) error {
	db.logger.Info("remove user", slog.String("email", email))

	const query = `
		DELETE FROM users
		WHERE email=:email`

	_, err := db.db.NamedExec(query, map[string]interface{}{"email": email})
	if err != nil {
		return err
	}
	return nil
}
