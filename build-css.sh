#!/usr/bin/env bash

[ -s __site ] || { echo "__site needs to point to the built site directory"; exit 1; }

mkdir -p ./dist
rm -f ./dist/*.css

vite build
rm __site/dist -rf
mv dist/bundle*.css _css/
