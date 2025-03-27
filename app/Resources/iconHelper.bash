#!/bin/bash

# helper.bash
# grok
# Created by Stephen M. Walker II on 2/18/25

# Function to resize icons

resize_icon() {
    local size=$1
    local scale=$2
    local output=$3
    sips -z $size $size "Original.png" --out "$output"
}

# Run all resizing operations
resize_icon 16 16 "Icon-macOS-16x16@1x.png"
resize_icon 32 32 "Icon-macOS-16x16@2x.png"
resize_icon 32 32 "Icon-macOS-32x32@1x.png"
resize_icon 64 64 "Icon-macOS-32x32@2x.png"
resize_icon 128 128 "Icon-macOS-128x128@1x.png"
resize_icon 256 256 "Icon-macOS-128x128@2x.png"
resize_icon 256 256 "Icon-macOS-256x256@1x.png"
resize_icon 512 512 "Icon-macOS-256x256@2x.png"
resize_icon 512 512 "Icon-macOS-512x512@1x.png"
resize_icon 1024 1024 "Icon-macOS-512x512@2x.png"
