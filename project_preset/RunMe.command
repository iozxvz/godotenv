#!/bin/bash

set -e

git_clone() {
    path=$1
    name=`basename $1`
    git clone https://github.com/iozxvz/$path.git . \
    || (print_red "error: 找不到 $name 仓库" >&2; exit 1)
}

git_pull() {
    path=$1
    branch=$2
    git pull --ff-only https://github.com/iozxvz/$path.git $branch
}

DIDAENV_ROOT="$HOME/.godotenv"
if [ ! -d "$DIDAENV_ROOT" ]; then
    mkdir "$DIDAENV_ROOT"
    cd $DIDAENV_ROOT
    git_clone "godotenv"
else
    cd $DIDAENV_ROOT
    git_pull "godotenv" "main"
fi

cd $(dirname "$0")
$HOME/.godotenv/godotenv
