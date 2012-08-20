#!/bin/sh

source common.sh

section_print "Cleanup keychain"

KEYCHAIN_NAME=~/Library/Keychains/jenkins.keychain
security delete-keychain "$KEYCHAIN_NAME"
security default-keychain -s ~/Library/Keychains/login.keychain


rm ~/Library/MobileDevice/"Provisioning Profiles"/*

section_print "Cleanup finished"