#!/bin/sh -e

default_user=ocaml
default_branch=master
default_distro=alpine
default_ocaml_version=4.03.0

fork_user=${FORK_USER:-$default_user}
fork_branch=${FORK_BRANCH:-$default_branch}
distro=${DISTRO:-$default_distro}
ocaml_version=${OCAML_VERSION:-$default_ocaml_version}

# prep environment for export to container
cat >env.list <<-EOF
	distro="$distro"
	fork_branch="$fork_branch"
	fork_user="$fork_user"
	ocaml_version="$ocaml_version"

	DEPLOY="$DEPLOY"
	DEPLOYD="$DEPLOYD"
	EXTRA_REMOTES="$EXTRA_REMOTES"
	FLAGS="$FLAGS"

	MIRAGE_BACKEND="$MIRAGE_BACKEND"
	MIRAGE_CONFIG_DIR="$MIRAGE_CONFIG_DIR"
	MIRDIR="$MIRDIR"

	TRAVIS_BRANCH="$TRAVIS_BRANCH"
	TRAVIS_COMMIT="$TRAVIS_COMMIT"
	TRAVIS_PULL_REQUEST="$TRAVIS_PULL_REQUEST"
	TRAVIS_REPO_SLUG="$TRAVIS_REPO_SLUG"

	XENIMG="$XENIMG"
EOF
cat env.list

# construct Dockerfile for this particular unikernel
cat >Dockerfile <<-EOF
	FROM ocaml/opam:${distro}_ocaml-${ocaml_version}

	RUN opam update -uy
	RUN opam pin add -n travis-opam \
	         https://github.com/${fork_user}/ocaml-ci-scripts.git#${fork_branch}

	USER root
	RUN opam depext -u travis-opam mirage

	USER opam
	RUN opam install travis-opam mirage

	VOLUME /repo
	WORKDIR /repo
EOF
cat Dockerfile

# build container for building this unikernel
docker build -t local-build .

# invoke the build!
OS=~/build/$TRAVIS_REPO_SLUG
chmod -R a+w $OS
docker run --env-file=env.list -v ${OS}:/repo local-build travis-mirage
