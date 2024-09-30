package auth

import "fmt"

type FailedToCheckWhetherUserAdminExistsError struct {
	InternalError error
}

func (err FailedToCheckWhetherUserAdminExistsError) Error() string {
	return fmt.Sprintf("Failed to check if user admin exists: %v", err.InternalError.Error())
}

type FailedToAddUserError struct {
	InternalError error
}

func (err FailedToAddUserError) Error() string {
	return fmt.Sprintf("Failed to add user: %v", err.InternalError.Error())
}

type FailedToRemoveUserError struct {
	InternalError error
}

func (err FailedToRemoveUserError) Error() string {
	return fmt.Sprintf("Failed to remove user: %v", err.InternalError.Error())
}

type FailedToReadUserEmailRow struct {
	InternalError error
}

func (err FailedToReadUserEmailRow) Error() string {
	return fmt.Sprintf("Failed to read user email: %v", err.InternalError.Error())
}

type FailedToCreateUserAdmin struct {
	InternalError error
}

func (err FailedToCreateUserAdmin) Error() string {
	return fmt.Sprintf("Failed to create user admin: %v", err.InternalError.Error())
}
