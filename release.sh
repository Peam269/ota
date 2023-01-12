#!/bin/bash
if [[ ($1 == -y) ]]; then set -- "" "$1"; fi
if [ -z "$1" ]; then
echo "Where is your ROM source-code located at? (please type the full path)"
read ROMPATH
else ROMPATH=$1; fi
REPO=https://github.com/Peam269/ota
BUILDS=~/ota
ZIPPATH="$ROMPATH"/out/target/product/raphael
if [ ! -d "$BUILDS/old/" ]; then mkdir "$BUILDS"/old; fi
if [ -n "$(ls -A "$BUILDS"/*/*/*.zip)" ]; then mv "$BUILDS"/*/*/*.zip "$BUILDS"/old/ && mv "$BUILDS"/*/*/*.sha256 "$BUILDS"/old/; fi
FILENAME=$(ls "$ZIPPATH"/Bliss-*.zip | tail -n1 | xargs -n1 basename)
METADATA=$(unzip -p "$ZIPPATH"/$FILENAME META-INF/com/android/metadata)
DEVICE=$(echo "$METADATA" | grep pre-device | cut -f2 -d '=' | cut -f1 -d ',')
DATETIME=$(echo "$METADATA" | grep post-timestamp | cut -f2 -d '=')
ID=$(cut -f1 -d ' ' "$ZIPPATH"/${FILENAME}.sha256)
ROMTYPE=$(echo "$ZIPPATH"/$FILENAME | cut -f4 -d '-')
ROMNAME=$(echo "$ZIPPATH"/$FILENAME | cut -f1 -d '-')
JSON="$BUILDS/$ROMNAME/$ROMTYPE/${DEVICE}.json"
SIZE=$(du -b "$ZIPPATH"/$FILENAME | cut -f1 -d '	')
VERSION=$(echo "$ZIPPATH"/$FILENAME | cut -f2 -d '-')
DATE=$(echo "$ZIPPATH"/${FILENAME%.*} | cut -f6 -d '-')
TAG=BlissROM_$VERSION-$DATE
URL="$REPO/releases/download/$TAG/$FILENAME"

echo "datetime": $DATETIME,
echo "filename": "$FILENAME",
echo "id": "$ID",
echo "romtype": "${ROMTYPE,,}",
echo "size": $SIZE,
echo "url": "$URL",
echo "version": "$VERSION"

mv "$ZIPPATH"/$FILENAME "$BUILDS"/$ROMNAME/$ROMTYPE/ && mv "$ZIPPATH"/${FILENAME}.sha256 "$BUILDS"/$ROMNAME/$ROMTYPE/
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
uploadbuild(){
  git -C "$BUILDS" add $ROMNAME/$ROMTYPE/raphael.json $ROMNAME/$ROMTYPE/changelog.md
  git -C "$BUILDS" commit -m raphael_$DATE
  cd "$BUILDS"/ && gh release create $TAG -F $ROMNAME/$ROMTYPE/changelog.md $ROMNAME/$ROMTYPE/$FILENAME --target master && git -C "$BUILDS" push origin master
  echo "Build is released!"
}
releaseprompt(){
  echo "============================================"
  read -r -p "Do you want to upload the build? [y/N] " response
  case "$response" in
      [yY][eE][sS]|[yY])
          nano "$BUILDS"/$ROMNAME/$ROMTYPE/changelog.md
          uploadbuild
          ;;
      *)
          echo "Build not released."
          ;;
  esac
}
if [[ ($2 == -y) ]]; then uploadbuild; else releaseprompt; fi
