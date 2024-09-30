package auth

import (
	"github.com/gin-gonic/gin"
	"github.com/markbates/goth/gothic"
	"net/http"
)

type AuthorizerServer struct {
}

func NewAuthorizerServer() *AuthorizerServer {
	return &AuthorizerServer{}
}

func (server *AuthorizerServer) RegisterRoutesOnRouter(r *gin.Engine) {
	r.GET("/", server.home)
	r.GET("/auth/:provider", server.signInWithProvider)
	r.GET("/auth/:provider/callback", server.callback)
	r.GET("/success", server.success)
}

func (server *AuthorizerServer) home(c *gin.Context) {

}
func (server *AuthorizerServer) signInWithProvider(c *gin.Context) {
	provider := c.Param("provider")
	q := c.Request.URL.Query()
	q.Add("provider", provider)
	c.Request.URL.RawQuery = q.Encode()

	gothic.BeginAuthHandler(c.Writer, c.Request)
}
func (server *AuthorizerServer) callback(c *gin.Context) {
	provider := c.Param("provider")
	q := c.Request.URL.Query()
	q.Add("provider", provider)
	c.Request.URL.RawQuery = q.Encode()

	_, err := gothic.CompleteUserAuth(c.Writer, c.Request)
	if err != nil {
		_ = c.AbortWithError(http.StatusInternalServerError, err)
		return
	}

	c.Redirect(http.StatusTemporaryRedirect, "/success")
}
func (server *AuthorizerServer) success(c *gin.Context) {}
