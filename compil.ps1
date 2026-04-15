.\fennel --require-as-include --compile src/main.fnl > bundle.lua
.\tic80 --skip --fs . --cmd="import code bundle.lua"