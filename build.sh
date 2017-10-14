#!/bin/bash

set -e
set -u

rm -rf build/
mkdir build/

rsync -vax DBD-SQLite/* build/

pushd sqlcipher
git clean -f
git reset --hard HEAD
git pull
make sqlite3.c

cp -av sqlite* ../build
popd
find build/ -iname \*.pm -or -iname \*.pl -or -iname \*.pod -exec perl -i.bak -E 's/DBD(::|-)SQLite/DBD$1SQLcipher/g;' {} +
