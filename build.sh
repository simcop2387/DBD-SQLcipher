#!/bin/bash

set -e
set -u

: ${DBD_SQLITE_BRANCH:=master}
: ${SQLCIPHER_BRANCH:=master}

if [ -z ${BUILD_NUMBER+x} ]; then
  export BUILD_NUMBER
fi

read MODULE_VERSION < VERSION
export MODULE_VERSION

# Clear the build area
rm -rf build/
mkdir build/

# Prep the DBD-SQLite repo
pushd DBD-SQLite
git fetch --all
git checkout $DBD_SQLITE_BRANCH
git clean -f -x
git reset --hard HEAD
git pull || echo Not on branch
popd

# Prep the build area
cp -vax DBD-SQLite/* build/

pushd build
for patch in ../patches/*.patch; do
	echo applying $patch
	patch -p1 -F10 < $patch
done

find ./ \( -name MANIFEST -or -name constants.inc -or -iname \*.pm -or -iname \*.pl -or -iname \*.pod -or -iname \*.t -or -iname \*.xs \) -exec perl -pi -E 's{DBD(::|-|/)SQLite}{DBD$1SQLcipher}g; s/dbi:SQLite/dbi:SQLcipher/g; s/DBI:SQLite/DBI:SQLcipher/g' {} +
find ./lib -type f -iname \*sqlite\* -exec rename 's/SQLite/SQLcipher/g; s/sqlite/sqlcipher/g;' {} \;
mv lib/DBD/SQLite lib/DBD/SQLcipher
mv lib/DBD/SQLite.pm lib/DBD/SQLcipher.pm
mv SQLite.xs SQLcipher.xs
perl -i -pE 's/SQLite.xsi/SQLcipher.xsi/g;' SQLcipher.xs
perl -i -pE 's/.travis.yml\n//g; s/SQLite.xs/SQLcipher.xs/g' MANIFEST
find ./ -iname \*.pm -exec perl -i -p ../rewriteversion.pl {} + # TODO this needs to be handled somehow else
rm t/57_uri_filename.t

cp -avx ../t/* t
 	
popd


# Prep and configure the sqlcipher repo
pushd sqlcipher
git fetch --all
git checkout $SQLCIPHER_BRANCH
git clean -f -x
git reset --hard HEAD
git pull || echo Not on branch

patch -p1 < ../debianpatches/20-change-name-to-sqlcipher.patch
patch -p1 < ../debianpatches/33-add-have-usleep.patch

./configure --enable-threadsafe --enable-load-extension --enable-tempstore --disable-tcl --enable-fts3 --enable-fts4


make sqlite3.c

cp -av sqlite* ext ../build
popd

# Try to actually build and test

pushd build/

for patch in ../after_patches/*.patch; do
  patch -p1 -F30 < $patch
done

perl Makefile.PL
make
make test
make dist
