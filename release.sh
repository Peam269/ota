#!/bin/bash
if [[ ($1 == -y) ]]; then set -- "" "$1"; fi
if [ -z "$1" ]; then
echo "Where is your ROM source-code located at? (please type the full path)"
read ROMPATH
else ROMPATH=$1; fi
REPO=https://github.com/Peam269/ota
UPLOAD=https://gitlab.com/Peam269/ota
BUILDS=~/ota
ZIPPATH="$ROMPATH"/out/target/product/raphael
if [ ! -d "$BUILDS/upload/" ]; then git clone $UPLOAD "$BUILDS"/upload; fi
if [ ! -d "$BUILDS/old/" ]; then mkdir "$BUILDS"/old; fi
if [ -n "$(ls -A "$BUILDS"/upload/*/*/*.zip)" ]; then mv "$BUILDS"/upload/*/*/*.zip "$BUILDS"/old/; fi > /dev/null 2>&1
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
URL="$UPLOAD/raw/master/${ROMNAME,,}/$ROMVARIANT/$FILENAME"

echo "datetime": $DATETIME,
echo "filename": "$FILENAME",
echo "id": "$ID",
echo "romtype": "${ROMTYPE,,}",
echo "size": $SIZE,
echo "url": "$URL",
echo "version": "$VERSION"

if [ ! -d "$BUILDS"/${ROMNAME,,} ]; then mkdir "$BUILDS"/${ROMNAME,,}; fi && if [ ! -d "$BUILDS"/upload/${ROMNAME,,} ]; then mkdir "$BUILDS"/upload/${ROMNAME,,}; fi
if [ ! -d "$BUILDS"/${ROMNAME,,}/$ROMVARIANT ]; then mkdir "$BUILDS"/${ROMNAME,,}/$ROMVARIANT; fi && if [ ! -d "$BUILDS"/upload/${ROMNAME,,}/$ROMVARIANT ]; then mkdir "$BUILDS"/upload/${ROMNAME,,}/$ROMVARIANT; fi
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
  mv "$ZIPPATH"/$FILENAME "$BUILDS"/upload/${ROMNAME,,}/$ROMVARIANT/

  git -C "$BUILDS" add ${ROMNAME,,}/$ROMVARIANT/raphael.json ${ROMNAME,,}/$ROMVARIANT/changelog.md
  git -C "$BUILDS" commit -m raphael_$DATE-$ROMVARIANT
  git -C "$BUILDS"/upload add ${ROMNAME,,}/$ROMVARIANT
  git -C "$BUILDS"/upload commit --amend --no-edit
  git -C "$BUILDS"/upload push -f origin master && git -C "$BUILDS" push origin master
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
