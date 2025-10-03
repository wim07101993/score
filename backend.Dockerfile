FROM golang:1.24 AS build

WORKDIR /
COPY go.mod go.sum ./

RUN go mod download

COPY . ./

# diable dependency on glibc
RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/score-backend .

FROM scratch
COPY db/migrations /db/migrations
COPY --from=build /bin/score-backend /bin/score-backend
CMD ["/bin/score-backend"]
