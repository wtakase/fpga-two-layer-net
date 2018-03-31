#!/bin/sh

rm -rf output/hls-syn/two-layer-net
rm -rf output/vivado/two-layer-net-admxrc3
#./make-hw.sh two-layer-net admxrc3 a
./make-hw.sh two-layer-net admxrc3 h
