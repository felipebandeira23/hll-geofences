FROM golang:1.24-alpine
WORKDIR /app
COPY . .
RUN go build -mod=vendor -o hll-geofences ./cmd/cmd.go
CMD ["./hll-geofences"]
