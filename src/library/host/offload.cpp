/******************************************************************************
 *  Copyright (c) 2016, Xilinx, Inc.
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *
 *  1.  Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *
 *  2.  Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *  3.  Neither the name of the copyright holder nor the names of its
 *      contributors may be used to endorse or promote products derived from
 *      this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 *  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 *  OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 *  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 *  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *****************************************************************************/
/******************************************************************************
 *
 *
 * @file offload.cpp
 *
 * Library of functions for host code and managing SW/HW offload
 * 
 *
 *****************************************************************************/

#include <string.h>
#include <vector>
#include <iostream>
#include <stdlib.h>
#include <unistd.h>
#include "offload.hpp"

namespace two_layer_net
{

ExtMemWord *bufIn, *bufOut;

#if defined(OFFLOAD) && !defined(RAWHLS)
Admxrc3Driver *thePlatform = 0;

void ExecAccel() {
  // invoke accelerator and wait for result
  thePlatform->writeJamRegAddr(0x00, 1);
  while((thePlatform->readJamRegAddr(0x00) & 0x2) == 0) usleep(1);
}
#endif

void PlatformInit() {
  // allocate input/output buffers
  // TODO should be dynamically sized based on the largest I/O
  if (!bufIn) {
    bufIn = new ExtMemWord[INPUT_BUF_ENTRIES];
    if (!bufIn) {
      throw "Failed to allocate host buffer";
    }
  }
  if (!bufOut) {
    bufOut = new ExtMemWord[OUTPUT_BUF_ENTRIES];
    if (!bufOut) {
      throw "Failed to allocate host buffer";
    }
  }
#if defined(OFFLOAD) && !defined(RAWHLS)
  thePlatform = initPlatform();
  // set up I/O buffer addresses for the accelerator
  thePlatform->writeJamRegAddr(0x10, thePlatform->inBaseAddr);
  thePlatform->writeJamRegAddr(0x18, thePlatform->outBaseAddr);
#endif
}

void PlatformDeinit() {
  // NOTE(wtakase): Not sure why these cause 'double free or corruption'
  //delete bufIn;
  //delete bufOut;
  //bufIn = 0;
  //bufOut = 0;
#if defined(OFFLOAD) && !defined(RAWHLS)
  //deinitPlatform(thePlatform);
  //thePlatform = 0;
#endif
}

std::vector<float> trainMNIST(std::vector<tiny_cnn::vec_t> &trainImages, std::vector<tiny_cnn::label_t> &trainLabels, const unsigned int imageNum, float &usecPerImage, float *params, unsigned int countLoopBase) {

  const unsigned int imageSize = trainImages[0].size();

  // allocate host-side buffers for packed input and outputs
  unsigned int imagesSize = BATCH_SIZE * imageSize;
  unsigned int labelsSize = BATCH_SIZE * 1;
  unsigned int packedInSize = W_B_SIZE + imagesSize + labelsSize;
  unsigned int packedOutSize = W_B_SIZE;

  if (INPUT_BUF_ENTRIES < packedInSize) {
    throw "Not enough space in accelBufIn";
  }
  if (OUTPUT_BUF_ENTRIES < packedOutSize) {
    throw "Not enough space in accelBufOut";
  }

  // NOTE(wtakase): Need comment out to prevent
  // 'application performed illegal memory access and is being terminated'
  //ExtMemWord *packedIn = new ExtMemWord[packedInSize];
  //ExtMemWord *packedOut = new ExtMemWord[packedOutSize];
  ExtMemWord packedIn[packedInSize];
  ExtMemWord packedOut[packedOutSize];

  for (unsigned int i = 0; i < W_B_SIZE; i++) {
    packedIn[i] = static_cast<ExtMemWord>(params[i]);
  }

  unsigned int countLoopNum = 1;
  if (imageNum > BATCH_SIZE) {
    countLoopNum = imageNum / BATCH_SIZE;
    if (imageNum % BATCH_SIZE > 0) {
      countLoopNum++;
    }
  }

  unsigned int inOffset;
  std::vector<float> result;
  for (unsigned int countLoop = countLoopBase; countLoop < countLoopNum + countLoopBase; countLoop++) {
    unsigned int countOffset = (countLoop * BATCH_SIZE) % TRAIN_SIZE;
    // pack images and labels
    inOffset = W_B_SIZE;
    for (unsigned int i = 0; i < BATCH_SIZE; i++) {
      for (unsigned int j = 0; j < imageSize + 1; j++) {
        if (j < imageSize) {
          packedIn[inOffset + i * (imageSize + 1) + j] = static_cast<ExtMemWord>(trainImages[countOffset + i][j]);
        } else {
          packedIn[inOffset + i * (imageSize + 1) + j] = static_cast<ExtMemWord>(trainLabels[countOffset + i]);
        }
      }
    }
#if defined(OFFLOAD) && !defined(RAWHLS)
    // copy inputs to accelerator
    thePlatform->copyBufferHostToAccel((void *)packedIn, sizeof(ExtMemWord) * packedInSize);
    // call the accelerator in compute mode
    ExecAccel();
    // copy results back to host
    thePlatform->copyBufferAccelToHost((void *)packedOut, sizeof(ExtMemWord) * packedOutSize);
#else
    two_layer_net::BlackBoxJam((ExtMemWord *)packedIn, (ExtMemWord *)packedOut);
#endif
    // get trained weights and biases
    memcpy(packedIn, packedOut, sizeof(ExtMemWord) * W_B_SIZE);
/////////////////////
/*
    std::cout << "ExtMemWord expected_out[19885] = {" << std::endl;
    for (unsigned int k = 0; k < W_B_SIZE-1; k++) {
      std::cout << packedOut[k] << "," << std::endl;
    }
    std::cout << packedOut[W_B_SIZE-1] << "};" << std::endl;
*/
/////////////////////
  }

  // put trained weights and biases
  for (unsigned int i = 0; i < W_B_SIZE; i++) {
    result.push_back(static_cast<float>(packedOut[i]));
  }

  // NOTE(wtakase): Need comment out to prevent
  // 'application performed illegal memory access and is being terminated'
  //delete packedIn;
  //delete packedOut;
  //packedIn = 0;
  //packedOut = 0;
  return (result);
}

} // namespace two_layer_net
