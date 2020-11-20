#!/bin/bash

mkdir build
cd build
cmake ..
make
cd ..
mv build/edgeSubPix.mex* ./
rm -rf build