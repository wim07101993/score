# syntax=docker/dockerfile:1

FROM golang:1.24 AS build

WORKDIR /
COPY go.mod go.sum ./

RUN go mod download

COPY . ./

RUN go build -o bin/score-backend .


FROM scratch AS package
COPY --from=build bin/score-backend /bin/score-backend
CMD ["/bin/score-backend"]
