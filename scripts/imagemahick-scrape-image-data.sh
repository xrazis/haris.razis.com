#!/bin/bash

# Assign the input folder path
image_dir="../static/upload"

# Get the current date in YYYYMMDD format
date=$(date +%Y%m%d)

# Specify the directory where the output file will be saved
output_dir="../data/images"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Output TOML file (named based on the current date)
output_file="${output_dir}/${date}.toml"

# If the file does not exist, create it; otherwise, overwrite it at the start of the script
if [ ! -f "$output_file" ]; then
    touch "$output_file"
fi

# Clear or initialize the TOML file
echo "images = [" > "${output_file}"

# Check for matching files
shopt -s nullglob
image_files=("$image_dir"/*.{jpg,jpeg,png,tiff,gif})
shopt -u nullglob

if [ ${#image_files[@]} -eq 0 ]; then
    echo "No image files found in the specified directory: $image_dir"
    echo "]" >> "${output_file}" # Close the TOML array
    exit 0
fi

# Loop through all image files in the folder
for image in "${image_files[@]}"; do
    # Extract EXIF data using ImageMagick's identify command
    if [ -f "$image" ]; then
        {
            echo -n "  { "
            echo -n "filename = \"$(basename $image)\","
#            if ["$(basename "$image")" == *"film"*] then
#              echo -n "film = "true""
#            fi
            identify -verbose "$image" | grep -E "exif:" | sed 's/^\s*//; s/: /=/; s/=/ = "/; s/://g; s/$/",/; $ s/,$/ },/' | tr '\n' ' '
            echo
        } >> "${output_file}"
    fi
done

# Close the TOML array
echo "]" >> "${output_file}"

echo "EXIF data has been written to ${output_file}"