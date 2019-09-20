# Contributing Guide

## Requirements

* [GNU make](https://www.gnu.org/software/make/) >= 4.2

* [Shellcheck](https://shellcheck.org/dl/) >= 0.7

## Guidelines

* **Git commit messages:** <https://chris.beams.io/posts/git-commit/>;
  additionally any commit must be scoped to the component where changes were
  made, which is prefixing the message with the component name, e.g.
  `targets/debian-10-x86_64: Do something`.

## Instructions

1. Create a new branch with a short name that describes the changes that you
   intend to do. If you don't have permissions to create branches, fork the
   project and do the same in your forked copy.

2. Do any change you need to do.

3. **(Optional)** Run `make ci` in the project root folder to verify that
   everything is working.

4. Create a [pull request](https://github.com/ntrrg/pish/compare) to the
   `master` branch.

