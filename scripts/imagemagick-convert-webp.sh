#!/bin/bash

# Set the desired quality (adjust as needed)
quality=90

# Loop through each image in the current directory
for file in *.jpg; do
    # Check if the file is a regular file
    if [ -f "$file" ]; then
        # Get the filename without extension
        filename="${file%.*}"

        # Convert the image to WebP format with specified quality
        convert "$file" -quality $quality "${filename}.webp"
    fi
done

echo "Conversion complete."

for file in *.jpg; do
    # Check if the file is a regular file
    rm "$file"
done