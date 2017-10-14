#!/bin/bash

set -e
set -u

rm -rf build/
mkdir build/

rsync -vax DBD-SQLite/* build/

pushd sqlcipher
git clean -f -x
git reset --hard HEAD
git pull


# Build options and such stolen from debian's source package for SQLcipher
export CFLAGS="-O2 -fno-strict-aliasing -DSQLITE_SECURE_DELETE -DSQLITE_ENABLE_COLUMN_METADATA -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_SOUNDEX=1 -DSQLITE_ENABLE_UNLOCK_NOTIFY -DSQLITE_OMIT_LOOKASIDE=1 -DSQLITE_ENABLE_UPDATE_DELETE_LIMIT=1 -DSQLITE_MAX_SCHEMA_RETRY=25 -DSQLITE_HAS_CODEC -DHAVE_USLEEP=1"

patch -p1 < ../debianpatches/20-change-name-to-sqlcipher.patch
patch -p1 < ../debianpatches/33-add-have-usleep.patch

./configure --enable-threadsafe --enable-load-extension --enable-tempstore --disable-tcl --disable-fts3 --disable-fts4 --disable-fts5


make sqlite3.c

cp -av sqlite* ../build
popd
find build/ -iname \*.pm -or -iname \*.pl -or -iname \*.pod -exec perl -i.bak -E 's/DBD(::|-)SQLite/DBD$1SQLcipher/g;' {} +
