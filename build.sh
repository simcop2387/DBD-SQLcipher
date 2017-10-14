#!/bin/bash

set -e
set -u

# Clear the build area
rm -rf build/
mkdir build/

# Prep the DBD-SQLite repo
pushd DBD-SQLite
git checkout master # TODO make env variable
git clean -f -x
git reset --hard HEAD
git pull
popd

# Prep the build area
rsync -vax DBD-SQLite/* build/

pushd build
patch -p1 -F10 < ../patches/01-add-sqlcihper-defines.patch
patch -p1 -F10 < ../patches/02-add-ext-includes.patch

# find ./ \( -name MANIFEST -or -iname \*.pm -or -iname \*.pl -or -iname \*.pod -or -iname \*.t \) -exec perl -pi -E 's{DBD(::|-|/)SQLite}{DBD$1SQLcipher}g;' {} +
#find ./lib -type f -iname \*sqlite\* -exec rename 's/SQLite/SQLcipher/g; s/sqlite/sqlcipher/g;' {} \;
#mv lib/DBD/SQLite lib/DBD/SQLcipher

popd


# Prep and configure the sqlcipher repo
pushd sqlcipher
git checkout master # TODO make env variable
git clean -f -x
git reset --hard HEAD
git pull

patch -p1 < ../debianpatches/20-change-name-to-sqlcipher.patch
patch -p1 < ../debianpatches/33-add-have-usleep.patch

./configure --enable-threadsafe --enable-load-extension --enable-tempstore --disable-tcl --enable-fts3 --enable-fts4


make sqlite3.c

cp -av sqlite* ext ../build
popd

# Try to actually build and test

pushd build/
perl Makefile.PL
make
make test
