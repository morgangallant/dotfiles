System setup:
```
sudo apt install curl git gnome-tweaks
```

Inside of `gnome-tweaks`, remap caps lock to escape (for vim)

Building Zig from scratch:
```
sudo apt install cmake clang libclang-dev lld liblld-dev libclang-cpp18-dev 
git clone git@github.com:ziglang/zig.git
mkdir zig/build
cd zig/build
cmake ..
make install
```

Then, add `./build/stage3/bin" to your path.
