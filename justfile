run_tiled:
    /Applications/love.app/Contents/MacOS/love .
    aerospace layout --window-id "$(aerospace list-windows --all | grep LÖVE | cut -d"|" -f1)" tiling tiles

dev:
    wgo -file .lua just run_tiled
