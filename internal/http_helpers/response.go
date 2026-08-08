package http_helpers

import (
	"encoding/json"
	"fmt"
	"net/http"
)

func RespondJson(res http.ResponseWriter, body any) error {
	bs, err := json.Marshal(body)
	if err != nil {
		http.Error(res, "failed to serialize the response", http.StatusInternalServerError)
		return fmt.Errorf("failed to serialize response: %v", err)
	}

	res.Header().Set("Content-Type", "application/json")
	res.WriteHeader(http.StatusOK)
	if _, err = res.Write(bs); err != nil {
		return fmt.Errorf("failed to respond: %v", err)
	}
	return nil
}
