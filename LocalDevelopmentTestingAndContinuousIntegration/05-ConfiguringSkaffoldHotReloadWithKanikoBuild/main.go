package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	msg := os.Getenv("APP_MESSAGE")
	if msg == "" {
		msg = "Hello from skaffold-demo-app"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		_, _ = fmt.Fprintf(w, "%s\n", msg)
	})

	log.Println("server listening on :8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}
