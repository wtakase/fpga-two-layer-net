#!/bin/bash
###############################################################################
 #  Copyright (c) 2016, Xilinx, Inc.
 #  All rights reserved.
 #
 #  Redistribution and use in source and binary forms, with or without
 #  modification, are permitted provided that the following conditions are met:
 #
 #  1.  Redistributions of source code must retain the above copyright notice,
 #     this list of conditions and the following disclaimer.
 #
 #  2.  Redistributions in binary form must reproduce the above copyright
 #      notice, this list of conditions and the following disclaimer in the
 #      documentation and/or other materials provided with the distribution.
 #
 #  3.  Neither the name of the copyright holder nor the names of its
 #      contributors may be used to endorse or promote products derived from
 #      this software without specific prior written permission.
 #
 #  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 #  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 #  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 #  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 #  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 #  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 #  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 #  OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 #  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 #  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 #  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 #
###############################################################################
###############################################################################
 #
 #
 # @file make-sw.sh
 #
 # Bash script for host code compiling into a shared object used by the TLN 
 # python class. This script should be launched on the PYNQ board. 
 #
 #
###############################################################################

NETWORKS=$(ls -d *-*/ | cut -f1 -d'/' | tr "\n" " ")

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <network> <platform>" >&2
  echo "where <network> = $NETWORKS" >&2
  echo "<platform> = python_sw python_hw" >&2
  exit 1
fi

NETWORK=$1
PLATFORM=$2

if [ -z "$XILINX_TLN_ROOT" ]; then
  export XILINX_TLN_ROOT="$( ( cd "$(dirname "$0")/.."; pwd) )"
fi

if [ -z "$VIVADOHLS_INCLUDE_PATH" ]; then
  export VIVADOHLS_INCLUDE_PATH="../../../vivado_hls/include"
fi  

ADMXRC3_API="../../../admxrc3/api-v1_4_16b9"
ADMXRC3_APP_FRAMEWORK="../../../admxrc3/app_framework-v1_0_0"

OLD_DIR=$(pwd)
cd $XILINX_TLN_ROOT
if [ -d "${XILINX_TLN_ROOT}/xilinx-tiny-cnn/" ]; then
	echo "xilinx-tiny-cnn already cloned"
else
	git clone https://github.com/Xilinx/xilinx-tiny-cnn.git
fi
cd $OLD_DIR

TINYCNN_PATH=$XILINX_TLN_ROOT/xilinx-tiny-cnn
TLN_PATH=$XILINX_TLN_ROOT/network
TLNLIB=$XILINX_TLN_ROOT/library
HOSTLIB=$TLNLIB/host
HLSLIB=$TLNLIB/hls
HLSTOP=$TLN_PATH/$NETWORK/hw
DRIVER_PATH=$TLNLIB/driver

if [ "$PLATFORM" = "python_sw" ]; then
  SRCS_HOSTLIB="$HOSTLIB/offload.cpp $HLSLIB/*.cpp"
  SRCS_HLSLIB="$HLSLIB/*.cpp"
else
  SRCS_HOSTLIB="$HOSTLIB/offload.cpp"
  SRCS_HLSLIB="$HLSLIB/*.cpp"
fi
SRCS_HLSTOP=$HLSTOP/top.cpp
SRCS_HOST=$TLN_PATH/$NETWORK/sw/main.cpp

OUTPUT_DIR=$XILINX_TLN_ROOT/network/output/sw
mkdir -p $OUTPUT_DIR
OUTPUT_FILE="$OUTPUT_DIR/$PLATFORM-$NETWORK"

if [[ ("$PLATFORM" == "python_sw") ]]; then
  SRCS_HOST=$TLN_PATH/$NETWORK/sw/main_python.cpp
  SRCS_ALL="$SRCS_HOSTLIB $SRCS_HLSTOP $SRCS_HOST"
  #g++ -g -DHLS_NO_XIL_FPO_LIB -DOFFLOAD -DRAWHLS -std=c++11 -pthread -O2 -fPIC -shared $SRCS_ALL -I$VIVADOHLS_INCLUDE_PATH -I$TINYCNN_PATH -I$HOSTLIB -I$HLSLIB -I$HLSTOP -o $OUTPUT_FILE.so
  g++ -g -DHLS_NO_XIL_FPO_LIB -DHLSFIXED -DOFFLOAD -DRAWHLS -std=c++11 -pthread -O2 -fPIC -shared $SRCS_ALL -I$VIVADOHLS_INCLUDE_PATH -I$TINYCNN_PATH -I$HOSTLIB -I$HLSLIB -I$HLSTOP -o $OUTPUT_FILE.so
elif [[ ("$PLATFORM" == "python_hw") ]]; then
  SRCS_HOST=$TLN_PATH/$NETWORK/sw/main_python.cpp
  SRCS_ALL="$DRIVER_PATH/admxrc3_driver.cpp $ADMXRC3_APP_FRAMEWORK/src/admxrc3ut/*.c $SRCS_HOSTLIB $SRCS_HOST"
  #g++ -g -DHLS_NO_XIL_FPO_LIB -DOFFLOAD -std=c++11 -pthread -O3 -fPIC -shared $SRCS_ALL -I$ADMXRC3_API/include -I$ADMXRC3_APP_FRAMEWORK/include -I$DRIVER_PATH -I$VIVADOHLS_INCLUDE_PATH -I$TINYCNN_PATH -I$HOSTLIB -I$HLSLIB -I$HLSTOP -o $OUTPUT_FILE.so -ladmxrc3
  #g++ -g -DHLS_NO_XIL_FPO_LIB -DHLSHALF -DOFFLOAD -std=c++11 -pthread -O3 -fPIC -shared $SRCS_ALL -I$ADMXRC3_API/include -I$ADMXRC3_APP_FRAMEWORK/include -I$DRIVER_PATH -I$VIVADOHLS_INCLUDE_PATH -I$TINYCNN_PATH -I$HOSTLIB -I$HLSLIB -I$HLSTOP -o $OUTPUT_FILE.so -ladmxrc3
  g++ -g -DHLS_NO_XIL_FPO_LIB -DHLSFIXED -DOFFLOAD -std=c++11 -pthread -O3 -fPIC -shared $SRCS_ALL -I$ADMXRC3_API/include -I$ADMXRC3_APP_FRAMEWORK/include -I$DRIVER_PATH -I$VIVADOHLS_INCLUDE_PATH -I$TINYCNN_PATH -I$HOSTLIB -I$HLSLIB -I$HLSTOP -o $OUTPUT_FILE.so -ladmxrc3
fi

echo "Output at $OUTPUT_FILE"

cp output/sw/python_*-$NETWORK.so ../../libraries/
cp output/sw/python_sw-$NETWORK.so output/sw/libpython_sw-$NETWORK.so
