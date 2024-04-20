#!/bin/sh

pcscd && node -r source-map-support/register lib/server.js
