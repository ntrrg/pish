// +build mage

package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"os/user"
	"path"
	"path/filepath"
	"strings"

	hc "github.com/gohugoio/hugo/config"
	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
	ntos "nt.web.ve/go/ntgo/os"
)

var (
	Default = Build

	hugoVersion = "0.65.2"
	hugoPort    = "1313"
	hugoConfig  = "config.yaml"

	cfg hc.Provider
)

func Build() error {
	return sh.RunV("hugo")
}

type BumpVersion mg.Namespace

func (BumpVersion) Hugo() error {
	fn := func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if path == ".git" || path == "assets" || path == "content" ||
			path == ".mage/output" || strings.HasSuffix(path, "vendor") {
			return filepath.SkipDir
		}

		if info.IsDir() || strings.HasSuffix(path, ".swp") {
			return nil
		}

		if path == "mage" || path == ".mage/go.sum" {
			return nil
		}

		fd, err := os.Open(path)
		if err != nil {
			return err
		}

		s := bufio.NewScanner(fd)

		for s.Scan() {
			if bytes.Contains(s.Bytes(), []byte(hugoVersion)) {
				fmt.Println(path)
			}
		}

		if err := s.Err(); err != nil {
			return fmt.Errorf("%s: %w", path, err)
		}

		return nil
	}

	return filepath.Walk(".", fn)
}

func Clean() error {
	mg.Deps(Challenges.Clean)

	for _, dst := range []string{gitRepos, "public", "resources"} {
		if err := sh.Rm(dst); err != nil {
			return err
		}
	}

	return nil
}

type Lint mg.Namespace

func (Lint) Default() {
	mg.Deps(Lint.Mage, Challenges.Lint)
}

func (Lint) Mage() error {
	return sh.RunV("gofmt", "-d", "-e", "-s", ".mage/magefile.go")
}

func Run() error {
	return sh.RunV(
		"hugo", "server", "-D", "-E", "-F", "--noHTTPCache", "--i18n-warnings",
		"--disableFastRender", "--bind", "0.0.0.0", "--port", hugoPort,
		"--baseUrl", "/", "--appendPort=false",
	)
}

// Helpers

func cloneRepo(dst, src string) error {
	if dst == "" {
		dst = path.Base(src)
	}

	if _, err := os.Stat(dst); err == nil {
		return sh.Run("git", "-C", dst, "pull", "origin", "master")
	}

	if err := sh.Run("git", "clone", src, dst); err != nil {
		if err := sh.Rm(dst); err != nil {
			return err
		}

		return err
	}

	return nil
}

func getHugoConfig(cfgFile string) (hc.Provider, error) {
	f, err := os.Open(cfgFile)
	if err != nil {
		return nil, err
	}

	defer f.Close()

	cfgData, err := ioutil.ReadAll(f)
	if err != nil {
		return nil, err
	}

	return hc.FromConfigString(string(cfgData), filepath.Ext(cfgFile))
}

func writeMultiLangFile(path string, content map[string][]byte, mode os.FileMode) error {
	i := strings.LastIndex(path, ".")
	if i < 0 {
		i = len(path) - 1
	}

	ext := filepath.Ext(path)

	for lang, content := range content {
		path := path[:i] + "." + lang + ext

		err := ioutil.WriteFile(path, content, mode)
		if err != nil {
			return err
		}
	}

	return nil
}

func init() {
	var err error

	cfg, err = getHugoConfig(hugoConfig)
	if err != nil {
		panic(err)
	}
}

////////////
// Docker //
////////////

var (
	dockerOpts []string
)

type Docker mg.Namespace

func (Docker) Build() error {
	return runHugoDocker()
}

func (Docker) Run() error {
	dockerOpts = append(dockerOpts, "-p", hugoPort + ":" + hugoPort)

	return runHugoDocker(
		"server", "-D", "-E", "-F", "--noHTTPCache", "--i18n-warnings",
		"--disableFastRender", "--bind", "0.0.0.0", "--port", hugoPort,
		"--baseUrl", "/", "--appendPort=false",
	)
}

func (Docker) Shell() error {
	dockerOpts = append(dockerOpts, "--entrypoint", "sh")

	return runHugoDocker()
}

func runHugoDocker(args ...string) error {
	opts := append(dockerOpts, "ntrrg/hugo:"+hugoVersion)

	return sh.RunV("docker", append(opts, args...)...)
}

func init() {
	u, err := user.Current()
	if err != nil {
		panic(err)
	}

	wd, err := os.Getwd()
	if err != nil {
		panic(err)
	}

	dockerOpts = []string{
		"run", "--rm", "-i", "-t",
		"-u", u.Uid,
		"-v", wd + ":/site/",
	}
}

////////////////////////
// Content generation //
////////////////////////

var (
	gitRepos = filepath.Join(os.TempDir(), "ntweb-git-repos")
)

type Gen mg.Namespace

func (Gen) Default() {
	mg.SerialDeps(Gen.GoPkgs, Gen.Projects)
}

// Go packages

var (
	goPkgsDir = filepath.Clean("content/go")
)

func (Gen) GoPkgs() error {
	if err := os.MkdirAll(gitRepos, 0755); err != nil {
		return err
	}

	for _, repoUrl := range cfg.GetStringSlice("params.goPackages") {
		name := path.Base(repoUrl)
		dst := filepath.Join(gitRepos, name)

		if err := cloneRepo(dst, repoUrl); err != nil {
			return err
		}

		c := exec.Command("go", "list", "-m")
		c.Dir = dst
		output, err := c.Output()
		if err != nil {
			return err
		}

		mod := string(bytes.TrimSpace(output))
		if err := writeGoPkgPage(repoUrl, mod, mod, ""); err != nil {
			return err
		}

		c = exec.Command(
			"go", "list",
			"-f", "{{ .ImportPath }} {{ .Doc }}",
			"./...",
		)

		c.Dir = dst
		output, err = c.Output()
		if err != nil {
			return err
		}

		for _, entry := range bytes.Split(bytes.TrimSpace(output), []byte{'\n'}) {
			elms := bytes.SplitN(entry, []byte{' '}, 2)
			pkg, doc := string(elms[0]), string(elms[1])

			if err := writeGoPkgPage(repoUrl, mod, pkg, doc); err != nil {
				return err
			}
		}
	}

	return nil
}

func genGoPkgPage(src, mod, pkg, doc string) string {
	prefix := path.Dir(mod) + "/"
	pkg = strings.TrimPrefix(string(pkg), prefix)

	content := `
---
title: %s
source-code: %s
module: %s
description: %s
url: /go/%s
---
`[1:]

	return fmt.Sprintf(content, pkg, src, mod, doc, pkg)
}

func writeGoPkgPage(src, mod, pkg, doc string) error {
	content := []byte(genGoPkgPage(src, mod, pkg, doc))

	return writeMultiLangFile(
		filepath.Join(goPkgsDir, strings.ReplaceAll(pkg, "/", "-")+".md"),
		map[string][]byte{"en": content, "es": content}, 0644,
	)
}

// Projects

var (
	prjsDir = filepath.Clean("content/projects")
)

func (Gen) Projects() error {
	if err := os.MkdirAll(gitRepos, 0755); err != nil {
		return err
	}

	for _, repoUrl := range cfg.GetStringSlice("params.projects") {
		name := path.Base(repoUrl)
		prjRepo := filepath.Join(gitRepos, name)
		if err := cloneRepo(prjRepo, repoUrl); err != nil {
			return err
		}

		src := filepath.Join(prjRepo, ".ntweb")
		dst := filepath.Join(prjsDir, name)

		if err := sh.Rm(dst); err != nil {
			return err
		}

		if err := ntos.Cp(dst, src); err != nil {
			return err
		}

		output, err := sh.Output("git", "-C", prjRepo, "log", "--format=%cI")
		if err != nil {
			return err
		}

		dates := strings.Split(output, "\n")
		publishedAt := dates[len(dates)-1]
		modifiedAt := dates[0]

		license, err := getLincense(filepath.Join(prjRepo, "LICENSE"))
		if err != nil {
			return err
		}

		metadata := []byte(`---
publishdate: ` + publishedAt + `
date: ` + modifiedAt + `
metadata:
  source-code: ` + repoUrl + `
  license: ` + license + `
`)

		indexes, err := filepath.Glob(dst + "/index.*.md")
		if err != nil {
			return err
		}

		for _, index := range indexes {
			var (
				f       *os.File
				content []byte
				err     error
			)

			f, err = os.Open(index)
			if err != nil {
				goto finish
			}

			content, err = ioutil.ReadAll(f)
			if err != nil {
				goto finish
			}

			f.Close()
			f, err = os.Create(index)
			if err != nil {
				goto finish
			}

			content = append(
				metadata,
				content[bytes.IndexByte(content, '\n')+1:]...,
			)
			_, err = f.Write(content)

		finish:
			f.Close()
			if err != nil {
				return err
			}
		}
	}

	return nil
}

func getLincense(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}

	defer f.Close()

	s := bufio.NewScanner(f)

	for s.Scan() {
		switch {
		case bytes.Contains(s.Bytes(), []byte("The MIT License")):
			return "MIT", nil
		case bytes.Contains(s.Bytes(), []byte("DO WHAT THE FUCK YOU WANT TO")):
			return "WTFPL", nil
		}
	}

	return "", s.Err()
}

////////////////
// Challenges //
////////////////

var (
	challengesDir = filepath.Clean("content/challenges")
)

type Challenges mg.Namespace

func (Challenges) Default() {
	mg.SerialDeps(Challenges.Lint, Challenges.Run)
}

func (Challenges) Clean() error {
	fn := func(path string, info os.FileInfo, err error) error {
		if filepath.Base(path) != "solution" {
			return nil
		}

		return sh.Rm(path)
	}

	return filepath.Walk(challengesDir, fn)
}

func (Challenges) Lint() error {
	var files []string

	fn := func(path string, info os.FileInfo, err error) error {
		if !strings.HasSuffix(path, ".go") {
			return nil
		}

		files = append(files, path)
		return nil
	}

	if err := filepath.Walk(challengesDir, fn); err != nil {
		return err
	}

	args := []string{"-d", "-e", "-s"}
	args = append(args, files...)
	return sh.RunV("gofmt", args...)
}

func (Challenges) Run() error {
	c := exec.Command("./run.sh")
	c.Stdout = os.Stdout
	c.Dir = challengesDir

	return c.Run()
}
