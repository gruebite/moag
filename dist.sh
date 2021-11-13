#!/usr/bin/env sh

rm MOAG.love
zip -9 -r MOAG.love . -x "dist/**" -x dist.sh -x ".git/**" > /dev/null 2>&1

if [ "$1" = "win" ]; then
    cat dist/win/love.exe MOAG.love > MOAG.exe
    zip -9 -j MOAG-win.zip dist/win/* MOAG.exe
    rm MOAG.exe
elif [ "$1" = "macos" ]; then
    cp MOAG.love dist/macos/MOAG.app/Contents/Resources/
    (cd dist/macos; zip -9 -r ../../MOAG-macos.zip ./MOAG.app)
    rm dist/macos/MOAG.app/Contents/Resources/MOAG.love
elif [ "$1" = "linux" ]; then
    cat $(which love) MOAG.love > MOAG
    chmod +x MOAG
    tar -cvzf MOAG.tar.gz ./MOAG
    rm MOAG
else
    echo "usage: ./dist.sh [ win | macos | linux ]"
fi
