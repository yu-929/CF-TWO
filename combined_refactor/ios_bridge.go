//go:build ios

package main

/*
#include <stdlib.h>
*/
import "C"
import (
	"context"
	"fmt"
	"net/http"
	"time"
)

var iosServer *http.Server

//export StartIOSServer
func StartIOSServer() C.int {
	listenPort = 13335
	listenHost = "127.0.0.1"
	speedTestURL = "auto"
	skipGeoCheck = true

	configureHTTPClients()
	initLocations()
	webSessionTTL = 12 * time.Hour

	http.HandleFunc("/auth/login", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			handleLoginPost(w, r)
			return
		}
		handleLoginPage(w, r)
	})
	http.HandleFunc("/auth/logout", handleLogout)
	http.HandleFunc("/favicon.png", func(w http.ResponseWriter, r *http.Request) {
		data, err := staticFiles.ReadFile("favicon.png")
		if err != nil {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "image/png")
		_, _ = w.Write(data)
	})
	http.HandleFunc("/", requireAuth(func(w http.ResponseWriter, r *http.Request) {
		data, err := staticFiles.ReadFile("index.html")
		if err != nil {
			http.Error(w, "无法加载页面", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		_, _ = w.Write(data)
	}))
	http.HandleFunc("/ws", requireAuth(handleWebSocket))

	addr := fmt.Sprintf("127.0.0.1:%d", listenPort)
	go checkAndPrintUpdate("")

	iosServer = &http.Server{
		Addr:              addr,
		ReadHeaderTimeout: 10 * time.Second,
	}

	go func() {
		fmt.Printf("iOS server starting on %s\n", addr)
		if err := iosServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			fmt.Printf("iOS server error: %v\n", err)
		}
	}()

	return 0
}

//export StopIOSServer
func StopIOSServer() {
	if iosServer != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		iosServer.Shutdown(ctx)
		iosServer = nil
	}
}

func main() {}