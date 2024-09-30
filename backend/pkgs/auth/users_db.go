package auth

import (
	"errors"
	"github.com/jmoiron/sqlx"
	"log/slog"
)

type User struct {
	Email    string
	Name     string
	googleId string
}

type UsersDb interface {
	AddUser(user *User) error
	RemoveUser(email string) error
	EnsureUserAdmin(initialAdminEmail string) error
}

type usersDb struct {
	logger *slog.Logger
	db     *sqlx.DB
}

func NewUsersDb(logger *slog.Logger, db *sqlx.DB) UsersDb {
	return &usersDb{
		logger: logger,
		db:     db,
	}
}

func (db *usersDb) AddUser(user *User) error {
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

func (db *usersDb) RemoveUser(email string) error {
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

func (db *usersDb) EnsureUserAdmin(initialAdminEmail string) error {
	db.logger.Info("ensuring user the administrator account exists",
		slog.String("email", initialAdminEmail))

	const existsQuery = `
		SELECT email
		FROM users
		WHERE email=:email AND is_user_admin`

	rows, err := db.db.NamedQuery(existsQuery, map[string]interface{}{"email": initialAdminEmail})
	if err != nil {
		return FailedToCheckWhetherUserAdminExistsError{InternalError: err}
	}
	defer func() { _ = rows.Close() }()

	if rows.Next() {
		cols, err := rows.SliceScan()
		if err != nil {
			return FailedToReadUserEmailRow{InternalError: err}
		}
		if len(cols) == 0 {
			return FailedToReadUserEmailRow{InternalError: errors.New("no columns returned")}
		}
		// a user admin exists
		db.logger.Info("found user admin", slog.Any("email", cols[0]))
		return nil
	}

	const createQuery = `
		INSERT INTO users (email)
		VALUES (:email)`

	_, err = db.db.NamedExec(createQuery, map[string]interface{}{"email": initialAdminEmail})
	if err != nil {
		return FailedToCreateUserAdmin{InternalError: err}
	}
	return nil
}
