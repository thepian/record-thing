import json
import os
import shutil
import sys

# Configuration
SOURCE_DIR = "/Volumes/Projects/Evidently/record-thing/assets/Icons/PNG/ThepiaApp"
DEST_DIR = "/Volumes/Projects/Evidently/record-thing/apps/ThepiaApp/Shared/Resources/Assets.xcassets/AppIcon.appiconset"
CONTENTS_FILE = os.path.join(DEST_DIR, "Contents.json")


def main():
    if not os.path.exists(SOURCE_DIR):
        print(f"Error: Source directory not found: {SOURCE_DIR}")
        sys.exit(1)

    if not os.path.exists(CONTENTS_FILE):
        print(f"Error: Contents.json not found: {CONTENTS_FILE}")
        sys.exit(1)

    with open(CONTENTS_FILE, "r") as f:
        contents = json.load(f)

    images = contents.get("images", [])
    updated_images = []

    print(f"Processing {len(images)} icon entries...")

    for image in images:
        size = image.get("size")
        scale = image.get("scale")
        idiom = image.get("idiom")

        if not size or not scale:
            updated_images.append(image)
            continue

        # Determine expected source filename
        source_filename = ""

        if idiom == "mac":
            # Mac icon naming convention in source
            if size == "512x512" and scale == "2x":
                source_filename = "Mac-App512x512@2x.png"
            elif size == "256x256" and scale == "1x":
                # Maps to 128@2x (256px)
                source_filename = "Mac-App-128x128@2x.png"
            elif size == "256x256" and scale == "2x":
                # Maps to 512@1x (512px)
                source_filename = "Mac-App-512x512@1x.png"
            elif scale == "1x" and size in ["16x16", "32x32"]:
                source_filename = f"Mac-App-{size}.png"
            else:
                source_filename = f"Mac-App-{size}@{scale}.png"
        else:
            # iOS/iPad icon naming convention
            # Pattern: Icon-App-{size}@{scale}.png
            source_filename = f"Icon-App-{size}@{scale}.png"

            # Special cases
            if size == "1024x1024" and scale == "1x":
                # Marketing icon often maps to 512@2x or specific marketing name
                source_filename = "Icon-App512x512@2x.png"
            elif idiom == "ipad" and size == "40x40" and scale == "1x":
                # 40pt iPad Spotlight 1x -> Use iPad Notifications 20pt 2x (40px)
                source_filename = "Icon-App-20x20@2x.png"

        # Check if file exists in source
        source_path = os.path.join(SOURCE_DIR, source_filename)

        if not os.path.exists(source_path):
            # Try alternative naming for Mac or other cases if needed
            # For now, just warn and keep existing entry if not found
            # print(f"Warning: Source file not found for {idiom} {size} {scale}: {source_filename}")
            updated_images.append(image)
            continue

        # Construct new clean filename for destination
        # Pattern: AppIcon-{idiom}-{size}@{scale}.png
        new_filename = f"AppIcon-{idiom}-{size}@{scale}.png"
        dest_path = os.path.join(DEST_DIR, new_filename)

        # Copy file
        print(f"Updating {idiom} {size} {scale} -> {new_filename}")
        shutil.copy2(source_path, dest_path)

        # Update entry
        image["filename"] = new_filename
        updated_images.append(image)

    # Write back Contents.json
    contents["images"] = updated_images
    with open(CONTENTS_FILE, "w") as f:
        json.dump(contents, f, indent=2)

    print("Icon update complete.")


if __name__ == "__main__":
    main()
