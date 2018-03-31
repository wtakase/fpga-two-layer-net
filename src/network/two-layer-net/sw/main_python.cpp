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
 * @file main_python.c
 *
 * Host code for TLN, overlay Two-layer-net, to manage parameter loading, 
 * classification (training) of single and multiple images
 * 
 *
 *****************************************************************************/
#include <iostream>
#include <stdlib.h>
#include <string.h>
#include "offload.hpp"
#include <random>
#include <ctime>

static std::vector<tiny_cnn::label_t> trainLabels;
static std::vector<tiny_cnn::vec_t> trainImages;

static float *params = new float[W_B_SIZE];
static unsigned int countLoopBase;

extern "C" void load_images(const char *path)
//void load_images(const char *path)
{
  std::string trainLabelPath(path);
  trainLabelPath.append("/train-labels-idx1-ubyte");
  std::string trainImagePath(path);
  trainImagePath.append("/train-images-idx3-ubyte");
  tiny_cnn::parse_mnist_labels(trainLabelPath, &trainLabels);
  tiny_cnn::parse_mnist_images(trainImagePath, &trainImages, 0.0, 1.0, 0, 0);
}

extern "C" void init_param(float *param, unsigned int rowNum, unsigned int colNum, double weightInitStd)
//void init_param(float *param, unsigned int rowNum, unsigned int colNum, double weightInitStd)
{
  //std::random_device seed_gen;
  ////std::default_random_engine engine(seed_gen());
  //std::default_random_engine engine(1);
  //std::normal_distribution<> dist(0.0, weightInitStd);

  //std::mt19937 engine;
  //engine.seed(time(0));
  //std::mt19937 engine;
  //engine.seed(1);

  srand(1);
  for (int i = 0; i < rowNum; ++i) {
    for (int j = 0; j < colNum; ++j) {
      if (weightInitStd == 0) {
        param[i * colNum + j] = 0.0;
      } else {
        //param[i * colNum + j] = (float)dist(engine);
        //param[i * colNum + j] = (float)std::uniform_real_distribution<float>(0.0, weightInitStd)(engine);
          param[i * colNum + j] = (((float)rand() + 1.0) / ((float)RAND_MAX + 2.0)) * weightInitStd;
      }
    }
  }
}

extern "C" void init_params()
//void init_params()
{
  // initialize weights and biases and pack them
  unsigned int in_offset = 0;
  init_param(&params[in_offset], INPUT_SIZE, HIDDEN1_SIZE, WEIGHT_INIT_STD);
  in_offset += W1_SIZE;
  init_param(&params[in_offset], 1, HIDDEN1_SIZE, 0.0);
  in_offset += B1_SIZE;
  init_param(&params[in_offset], HIDDEN1_SIZE, OUTPUT_SIZE, WEIGHT_INIT_STD);
  in_offset += W2_SIZE;
  init_param(&params[in_offset], 1, OUTPUT_SIZE, 0.0);
  countLoopBase = 0;
}

extern "C" float *train(unsigned int imageNum, float *usecPerImage)
//float *train(unsigned int imageNum, float *usecPerImage)
{
  two_layer_net::PlatformInit();
  std::vector<float> wBResult;
  float usecPerImage_int;
  //std::cout << "0: params[0]: " << params[0] << std::endl;
  wBResult = two_layer_net::trainMNIST(trainImages, trainLabels, imageNum, usecPerImage_int, params, countLoopBase);
  countLoopBase += 1;
  float *result = new float[W_B_SIZE];
  std::copy(wBResult.begin(), wBResult.end(), result);
  if (usecPerImage) {
    *usecPerImage = usecPerImage_int;
  }
  std::copy(wBResult.begin(), wBResult.end(), params);
  //std::cout << "1: params[0]: " << params[0] << std::endl;
  return result;
}

extern "C" void free_results(float *result)
//void free_results(float *result)
{
  delete result;
  result = 0;
}

extern "C" void free_images()
//void free_images()
{
  std::vector<tiny_cnn::label_t>().swap(trainLabels);
  std::vector<tiny_cnn::vec_t>().swap(trainImages);
}

extern "C" void free_params()
//void free_params()
{
  //delete params;
  //params = 0;
  countLoopBase = 0;
}

extern "C" void deinit() {
//void deinit() {
  two_layer_net::PlatformDeinit();
}
