#!/bin/bash

set -e
set -u

rm -rf build/
mkdir build/

pushd DBD-SQLite
git checkout master # TODO make env variable
git clean -f -x
git reset --hard HEAD
git pull
popd

rsync -vax DBD-SQLite/* build/

pushd build
patch -p1 -F10 < ../patches/01-add-sqlcihper-defines.patch
patch -p1 -F10 < ../patches/02-add-ext-includes.patch
popd

pushd sqlcipher
git checkout master # TODO make env variable
git clean -f -x
git reset --hard HEAD
git pull


# Build options and such stolen from debian's source package for SQLcipher
export CFLAGS="-O2 -fno-strict-aliasing -DSQLITE_SECURE_DELETE -DSQLITE_ENABLE_COLUMN_METADATA -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_SOUNDEX=1 -DSQLITE_ENABLE_UNLOCK_NOTIFY -DSQLITE_OMIT_LOOKASIDE=1 -DSQLITE_ENABLE_UPDATE_DELETE_LIMIT=1 -DSQLITE_MAX_SCHEMA_RETRY=25 -DSQLITE_HAS_CODEC -DHAVE_USLEEP=1"

patch -p1 < ../debianpatches/20-change-name-to-sqlcipher.patch
patch -p1 < ../debianpatches/33-add-have-usleep.patch

./configure --enable-threadsafe --enable-load-extension --enable-tempstore --disable-tcl --enable-fts3 --enable-fts4


make sqlite3.c

cp -av sqlite* fts* ext ../build
popd
find build/ -iname \*.pm -or -iname \*.pl -or -iname \*.pod -or -iname \*.t -exec perl -i.bak -E 's/DBD(::|-)SQLite/DBD$1SQLcipher/g;' {} +

pushd build/
perl Makefile.PL
make
make test
