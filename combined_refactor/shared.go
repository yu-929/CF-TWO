package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"
)

var webUser, webPassword string
var webSessionMinutes int

type latestReleaseInfo struct {
	TagName string `json:"tag_name"`
	HTMLURL string `json:"html_url"`
}

func versionIsOlder(current, latest string) bool {
	current = strings.TrimPrefix(strings.TrimSpace(current), "v")
	latest = strings.TrimPrefix(strings.TrimSpace(latest), "v")
	if current == "" || latest == "" || current == "dev" {
		return false
	}
	cParts := strings.FieldsFunc(current, func(r rune) bool { return r == '.' || r == '-' || r == '_' })
	lParts := strings.FieldsFunc(latest, func(r rune) bool { return r == '.' || r == '-' || r == '_' })
	for i := 0; i < len(cParts) || i < len(lParts); i++ {
		c, l := 0, 0
		if i < len(cParts) {
			c, _ = strconv.Atoi(cParts[i])
		}
		if i < len(lParts) {
			l, _ = strconv.Atoi(lParts[i])
		}
		if c != l {
			return c < l
		}
	}
	return false
}

func getLatestRelease(ctx context.Context) (latestReleaseInfo, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://api.github.com/repos/PoemMisty/CFData-WEB/releases/latest", nil)
	if err != nil {
		return latestReleaseInfo{}, err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("User-Agent", "CFData-WEB/"+appVersion)
	ctx, cancel := context.WithTimeout(ctx, 6*time.Second)
	defer cancel()
	resp, err := upstreamHTTPClient.Do(req.WithContext(ctx))
	if err != nil {
		return latestReleaseInfo{}, err
	}
	defer resp.Body.Close()
	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
		return latestReleaseInfo{}, fmt.Errorf("GitHub 返回状态 %d", resp.StatusCode)
	}
	var info latestReleaseInfo
	if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
		return latestReleaseInfo{}, err
	}
	if info.HTMLURL == "" {
		info.HTMLURL = releaseLatestURL
	}
	return info, nil
}

func checkAndPrintUpdate(prefix string) {
	ctx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
	defer cancel()
	info, err := getLatestRelease(ctx)
	if err != nil {
		recordDebugError("release_check", err.Error())
		return
	}
	if info.TagName != "" && versionIsOlder(appVersion, info.TagName) {
		if prefix == "" {
			fmt.Printf("新版本可用: %s → %s  下载地址: %s\n", appVersion, info.TagName, info.HTMLURL)
		} else {
			fmt.Printf("%s 新版本: %s → %s\n", prefix, appVersion, info.TagName)
		}
	}
}