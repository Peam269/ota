#!/bin/bash
echo "Where is your ROM source-code located at? (please type the full path)"
read ROMPATH
REPO=https://github.com/Peam269/bliss-ota
BUILDS=~/bliss-ota
ZIPPATH="$ROMPATH"/out/target/product/raphael
if [ ! -d "$BUILDS/old/" ]; then mkdir "$BUILDS"/old; fi
if [ -e "$BUILDS"/*.zip ]; then mv "$BUILDS"/*.zip "$BUILDS"/old/ && mv "$BUILDS"/*.sha256 "$BUILDS"/old/; fi
FILENAME=$(ls "$ZIPPATH"/Bliss-*.zip | tail -n1 | xargs -n1 basename)
METADATA=$(unzip -p "$ZIPPATH"/$FILENAME META-INF/com/android/metadata)
DEVICE=$(echo "$METADATA" | grep pre-device | cut -f2 -d '=' | cut -f1 -d ',')
JSON="$BUILDS/${DEVICE}.json"
DATETIME=$(echo "$METADATA" | grep post-timestamp | cut -f2 -d '=')
ID=$(cut -f1 -d ' ' "$ZIPPATH"/${FILENAME}.sha256)
ROMTYPE=$(echo "$ZIPPATH"/$FILENAME | cut -f4 -d '-')
SIZE=$(du -b "$ZIPPATH"/$FILENAME | cut -f1 -d '	')
VERSION=$(echo "$ZIPPATH"/$FILENAME | cut -f2 -d '-')
DATE=$(echo "$ZIPPATH"/${FILENAME%.*} | cut -f6 -d '-')
TAG=BlissROM_${VERSION}-${DATE}
URL="$REPO/releases/download/${TAG}/${FILENAME}"

echo "datetime": $DATETIME,
echo "filename": "$FILENAME",
echo "id": "$ID",
echo "romtype": "${ROMTYPE,,}",
echo "size": $SIZE,
echo "url": "$URL",
echo "version": "$VERSION"

mv "$ZIPPATH"/$FILENAME "$BUILDS"/ && mv "$ZIPPATH"/${FILENAME}.sha256 "$BUILDS"/
/bin/cat <<EOM >$JSON
{
  "response": [
    {
      "datetime": $DATETIME,
      "filename": "$FILENAME",
      "id": "$ID",
      "romtype": "${ROMTYPE,,}",
      "size": $SIZE,
      "url": "$URL",
      "version": "$VERSION"
    }
  ]
}
EOM

# Push update to GitHub
echo "============================================"
read -r -p "Do you want to upload the build? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) 
	nano "$BUILDS"/changelog.md
	git -C "$BUILDS" add raphael.json changelog.md
	git -C "$BUILDS" commit -m raphael_${DATE}
	cd "$BUILDS"/ && gh release create $TAG -F changelog.md "$BUILDS"/$FILENAME --target master && git -C "$BUILDS" push
	echo "Build is released!"
        ;;
    *)
        echo "Build not released."
        ;;
esac
