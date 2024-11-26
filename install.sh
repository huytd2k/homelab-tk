#!/bin/bash

set -e  # Exit on errors

LOGFILE="install_from_archive.log"
exec > >(tee -a "$LOGFILE") 2>&1  # Log everything

echo "=== Script started at $(date) ==="

# Function to detect compression type and decompress
extract_archive() {
    local archive="$1"
    local dest_dir="$2"
    echo "Detecting compression type for $archive..."

    case "$archive" in
        *.tar.gz | *.tgz)
            echo "Detected gzip compression."
            tar -xzf "$archive" -C "$dest_dir"
            ;;
        *.tar.bz2 | *.tbz)
            echo "Detected bzip2 compression."
            tar -xjf "$archive" -C "$dest_dir"
            ;;
        *.tar.xz)
            echo "Detected xz compression."
            tar -xJf "$archive" -C "$dest_dir"
            ;;
        *.zip)
            echo "Detected zip compression."
            unzip -d "$dest_dir" "$archive"
            ;;
        *.tar)
            echo "Detected uncompressed tar."
            tar -xf "$archive" -C "$dest_dir"
            ;;
        *)
            echo "Error: Unsupported compression type."
            exit 1
            ;;
    esac
    echo "Extraction completed."
}

# Main script starts here
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <url-to-download>"
    exit 1
fi

URL="$1"
ARCHIVE_NAME=$(basename "$URL")
DOWNLOAD_DIR="$HOME/.binaries"
INSTALL_DIR="/usr/local/bin"

echo "Downloading file from $URL..."
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

wget "$URL" -O "$ARCHIVE_NAME"

echo "Downloaded file saved as $ARCHIVE_NAME."

# Create a temporary directory for extraction
EXTRACT_DIR="$DOWNLOAD_DIR/extracted"
mkdir -p "$EXTRACT_DIR"

# Extract the downloaded archive
extract_archive "$ARCHIVE_NAME" "$EXTRACT_DIR"

# Find and link binaries
echo "Searching for 'bin' directories recursively..."
BIN_DIRS=$(find "$EXTRACT_DIR" -type d -name "bin")

if [ -z "$BIN_DIRS" ]; then
    echo "No 'bin' directories found. Exiting."
    exit 0
fi

for BIN_DIR in $BIN_DIRS; do
    echo "Found 'bin' directory: $BIN_DIR"
    for BINARY in "$BIN_DIR"/*; do
        if [ -x "$BINARY" ]; then
            echo "Linking binary $BINARY to $INSTALL_DIR"
            sudo ln -sf "$BINARY" "$INSTALL_DIR/"
        fi
    done
done

echo "Binaries have been successfully linked to $INSTALL_DIR."

# Cleanup
echo "Cleaning up temporary files..."
# rm -rf "$DOWNLOAD_DIR"

echo "=== Script completed successfully at $(date) ==="
