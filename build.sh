#!/bin/bash

set -e
set -u

rm -rf build/
mkdir build/


pushd sqlcipher
git clean -f
git reset --hard HEAD
git pull
make sqlite3.c

cp -av sqlite* ../build
popd
pushd build

#rsync -vax DBD-SQLite/* build/
