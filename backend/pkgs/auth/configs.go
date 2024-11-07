package auth

var GoogleConfig = Config{
	JwksUrl: `https://www.googleapis.com/oauth2/v3/certs`,
	Issuer:  "https://accounts.google.com",
}

var FacebookConfig = Config{
	JwksUrl: "https://www.facebook.com/.well-known/oauth/openid/jwks/",
	Issuer:  "https://accounts.facebook.com",
}

type Config struct {
	JwksUrl string
	Issuer  string
}
