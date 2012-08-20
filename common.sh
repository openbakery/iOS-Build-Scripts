#!/bin/sh

function fail {
    echo "$*" >&2
    exit 1
}

function section_print {
    echo "\n=== $* ==="
}
