#!/bin/sh -e

default_user=ocaml
default_branch=master
default_distro=alpine
default_ocaml_version=4.03.0

fork_user=${FORK_USER:-$default_user}
fork_branch=${FORK_BRANCH:-$default_branch}
distro=${DISTRO:-$default_distro}
ocaml_version=${OCAML_VERSION:-$default_ocaml_version}

cat >env.list <<-EOF
    MIRAGE_BACKEND="$MIRAGE_BACKEND"
    DEPLOY="$DEPLOY"
    UPDATE_GCC_BINUTILS="$UPDATE_GCC_BINUTILS"
    XENIMG="$XENIMG"
    FLAGS="$FLAGS"
EOF
echo "* env.list:"
cat env.list

cat >Dockerfile <<-EOF
    FROM ocaml/opam:${DISTRO}_ocaml-${OCAML_VERSION}
    WORKDIR /home/opam/opam-repository
    RUN git pull origin master
    RUN opam pin add travis-opam \
             https://github.com/$fork_user/ocaml-ci-scripts.git#$fork_branch
    RUN opam update -uy && opam install mirage
    VOLUME /repo
    WORKDIR /repo
EOF
echo "* Dockerfile:"
cat Dockerfile

docker build -t local-build .

OS=~/build/$TRAVIS_REPO_SLUG
chmod -R a+w $OS

CMD=docker run --env-file=env.list -v ${OS}:/repo local-build travis-mirage
echo "* Command:"
echo $CMD

$CMD
