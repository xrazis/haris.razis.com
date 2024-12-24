#!/bin/bash

# Directory where the images are located
image_dir="../static/blog"

# Directory where the replacement should be done
content_dir="../content/posts"

# Loop through both .jpg and .png images in the directory and its subdirectories
for ext in jpg png HEIC; do
    find "$image_dir" -type f -name "*.$ext" | while read -r file; do
        # Get the filename without extension
        filename="${file%.*}"

        # Convert the image to WebP format with specified quality
        convert "$file" -quality 90 "${filename}.webp"
    done

    echo "Conversion of .$ext files complete."

    # Remove original images
    find "$image_dir" -type f -name "*.$ext" -delete
done

echo "All original images removed."

# Replace code references of .jpg and .png with .webp in the content directory and its subdirectories
find "$content_dir" -type f -exec sed -i 's/\.jpg/\.webp/g' {} +
find "$content_dir" -type f -exec sed -i 's/\.png/\.webp/g' {} +

echo "Replacement complete."