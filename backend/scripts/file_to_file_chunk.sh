#!/bin/bash

CONTENT=$(base64 -w 0 "$1")
echo "{ \"content\": \"${CONTENT}\" }"