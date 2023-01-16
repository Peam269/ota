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
ROMTYPE=$(echo $FILENAME | cut -f4 -d '-')
ROMVARIANT=$(echo $FILENAME | cut -f5 -d '-')
ROMNAME=$(echo $FILENAME | cut -f1 -d '-')
JSON="$BUILDS/${ROMNAME,,}/$ROMVARIANT/${DEVICE}.json"
SIZE=$(du -b "$ZIPPATH"/$FILENAME | cut -f1 -d '	')
VERSION=$(echo $FILENAME | cut -f2 -d '-')
DATE=$(echo ${FILENAME%.*} | cut -f6 -d '-')
TAG=BlissROM_$VERSION-$ROMVARIANT-$DATE
URL="$REPO/releases/download/$TAG/$FILENAME"

echo "datetime": $DATETIME,
echo "filename": "$FILENAME",
echo "id": "$ID",
echo "romtype": "${ROMTYPE,,}",
echo "size": $SIZE,
echo "url": "$URL",
echo "version": "$VERSION"

if [ ! -d "$BUILDS"/${ROMNAME,,} ]; then mkdir "$BUILDS"/${ROMNAME,,}; fi
if [ ! -d "$BUILDS"/${ROMNAME,,}/$ROMVARIANT ]; then mkdir "$BUILDS"/${ROMNAME,,}/$ROMVARIANT; fi
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
  mv "$ZIPPATH"/$FILENAME "$BUILDS"/${ROMNAME,,}/$ROMVARIANT/ && mv "$ZIPPATH"/${FILENAME}.sha256 "$BUILDS"/${ROMNAME,,}/$ROMVARIANT/

  git -C "$BUILDS" add ${ROMNAME,,}/$ROMVARIANT/raphael.json ${ROMNAME,,}/$ROMVARIANT/changelog.md
  git -C "$BUILDS" commit -m raphael_$DATE-$ROMVARIANT
  cd "$BUILDS"/ && gh release create $TAG -F ${ROMNAME,,}/$ROMVARIANT/changelog.md ${ROMNAME,,}/$ROMVARIANT/$FILENAME --target master && git -C "$BUILDS" push origin master
  echo "Build is released!"
}
releaseprompt(){
  echo "============================================"
  read -r -p "Do you want to upload the build? [y/N] " response
  case "$response" in
      [yY][eE][sS]|[yY])
          nano "$BUILDS"/${ROMNAME,,}/$ROMVARIANT/changelog.md
          uploadbuild
          ;;
      *)
          echo "Build not released."
          ;;
  esac
}
if [[ ($2 == -y) ]]; then uploadbuild; else releaseprompt; fi
