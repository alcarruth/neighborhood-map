#!/bin/bash

function clean() {
    echo "clean()"
    rm -rf dist/ build/
    mkdir -p dist/css dist/js dist/images
    mkdir -p build/css build/js build/coffee build/images
}

function mk_neighborhood_map_coffee() {
    echo "mk_neighborhood_map_coffee()"
    pushd src/coffee >/dev/null
    cat \
        jsonp_controller.coffee \
        google_maps_api.coffee \
        wikipedia_api.coffee \
        neighborhood_map.coffee \
        > ../../build/coffee/neighborhood-map.coffee
    popd >/dev/null
}

function mk_neighborhood_map_js() {
    mk_neighborhood_map_coffee
    echo "mk_neighborhood_map_js()"
    pushd build >/dev/null
    coffee -c -o js/ coffee/neighborhood-map.coffee
    popd >/dev/null
}

function mk_build() {
    mk_neighborhood_map_js
    echo "mk_build()"
    pushd build >/dev/null
    cp -r ../src/css .
    cp -r ../src/images .
    cp ../node_modules/knockout/build/output/knockout-latest.js js/knockout.js
    popd >/dev/null
}

function mk_dist() {
    clean
    mk_build
    echo "mk_dist()"
    pushd build >/dev/null
    cp -r js/ ../dist/
    cp -r css/ ../dist/
    cp -r images/ ../dist/
    popd >/dev/null
}

