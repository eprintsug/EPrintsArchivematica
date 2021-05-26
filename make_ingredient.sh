#!/bin/bash

# Copy the contents into the structure used by an EPrints 3.4 ingredient.

# run ./make_ingredient.sh
# then place ingredients/archivematica under your EPrints 3.4 ingredients directory
# update your flavours/pub_lib/inc file to include ingredients/archivematica
# run epadmin update REPO
# apachectl graceful

I=ingredients/archivematica
mkdir -p $I

cp -r bin $I
cp -r cgi $I

cp -r cfg/cfg.d $I
# cp -r cfg/citations $I # unused?

cp -r lib/citations $I
cp -r lib/static $I
cp -r lib/lang $I
cp -r lib/plugins $I
cp -r lib/workflows $I
