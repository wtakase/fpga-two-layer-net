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
 * @file two_layer_net.cpp
 *
 * Library of templated HLS functions for Two-layer-net deployment. 
 * 
 *
 *****************************************************************************/

#include "two_layer_net.hpp"

#if defined(FPGA)
#include "hls_math.h"
#else
#include "cmath"
#endif

namespace two_layer_net
{

void StreamingTrain_Batch(hls::stream<ExtMemWord> &in, hls::stream<ExtMemWord> &out) {
  IntMemWord w1[W1_SIZE];
  IntMemWord b1[B1_SIZE];
  IntMemWord w2[W2_SIZE];
  IntMemWord b2[B2_SIZE];

  for (unsigned int i = 0; i < W1_SIZE; i++) {
    w1[i] = static_cast<IntMemWord>(in.read());
  }
  for (unsigned int i = 0; i < B1_SIZE; i++) {
    b1[i] = static_cast<IntMemWord>(in.read());
  }
  for (unsigned int i = 0; i < W2_SIZE; i++) {
    w2[i] = static_cast<IntMemWord>(in.read());
  }
  for (unsigned int i = 0; i < B2_SIZE; i++) {
    b2[i] = static_cast<IntMemWord>(in.read());
  }

  IntMemWord xTrain[INPUT_SIZE * BATCH_SIZE];
  IntMemWord tTrain[BATCH_SIZE];

  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    for (unsigned int j = 0; j < INPUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      xTrain[i * INPUT_SIZE + j] = static_cast<IntMemWord>(in.read());
    }
    tTrain[i] = in.read();
  }

  // Train
  // affine1 forward
  IntMemWord affine1Out[BATCH_SIZE * AFFINE1_OUT_SIZE];
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    for (unsigned int j = 0; j < AFFINE1_OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      IntMemWord sumBox = b1[j];
      for (unsigned int k = 0; k < AFFINE1_IN_SIZE; k++) {
//#pragma HLS PIPELINE II=1
#if defined(HLSFIXED) && !defined(HLSNOCAST)
        MulMemWord mulBox = static_cast<MulMemWord>(xTrain[i * AFFINE1_IN_SIZE + k]) * static_cast<MulMemWord>(w1[k * AFFINE1_OUT_SIZE + j]);
        sumBox += static_cast<IntMemWord>(mulBox);
#else
        sumBox += xTrain[i * AFFINE1_IN_SIZE + k] * w1[k * AFFINE1_OUT_SIZE + j];
#endif
      }
      // ReLU forward
      if (sumBox <= 0) {
        affine1Out[i * AFFINE1_OUT_SIZE + j] = 0;
      } else {
        affine1Out[i * AFFINE1_OUT_SIZE + j] = sumBox;
      }
    }
  }

  // affine2 forward
  IntMemWord affine2Out[BATCH_SIZE * AFFINE2_OUT_SIZE];
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    for (unsigned int j = 0; j < AFFINE2_OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      IntMemWord sumBox = b2[j];
      for (unsigned int k = 0; k < AFFINE2_IN_SIZE; k++) {
#if defined(HLSFIXED) && !defined(HLSNOCAST)
        MulMemWord mulBox = static_cast<MulMemWord>(affine1Out[i * AFFINE2_IN_SIZE + k]) * static_cast<MulMemWord>(w2[k * AFFINE2_OUT_SIZE + j]);
        sumBox += static_cast<IntMemWord>(mulBox);
#else
        sumBox += affine1Out[i * AFFINE2_IN_SIZE + k] * w2[k * AFFINE2_OUT_SIZE + j];
#endif
      }
      affine2Out[i * AFFINE2_OUT_SIZE + j] = sumBox;
    }
  }

  // softmax forward and backward
  IntMemWord softmaxOut[SOFTMAX_SIZE];
  IntMemWord softmaxDx[BATCH_SIZE * SOFTMAX_SIZE];
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    // forward
    IntMemWord xMax = affine2Out[i * SOFTMAX_SIZE];
    for (unsigned int j = 1; j < SOFTMAX_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      if (affine2Out[i * SOFTMAX_SIZE + j] > xMax) {
        xMax = affine2Out[i * SOFTMAX_SIZE + j];
      }
    }
    IntMemWord expXSubXmaxSum = 0;
    for (unsigned int j = 0; j < SOFTMAX_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      float xSubXMaxFloat = static_cast<float>(affine2Out[i * SOFTMAX_SIZE + j] - xMax);
#if defined(FPGA)
      IntMemWord expXSubXmax = hls::expf(xSubXMaxFloat);
#else
      IntMemWord expXSubXmax = std::exp(xSubXMaxFloat);
#endif
      softmaxOut[j] = expXSubXmax;
      expXSubXmaxSum += softmaxOut[j];
    }
    // backward
    IntMemWord label = tTrain[i];
    for (unsigned int j = 0; j < SOFTMAX_SIZE; j++) {
//#pragma HLS PIPELINE II=1
#if defined(HLSFIXED) && !defined(HLSNOCAST)
      MulMemWord mulBox = static_cast<MulMemWord>(softmaxOut[j]) / static_cast<MulMemWord>(expXSubXmaxSum);
      if (j == label) {
        mulBox -= 1;
      }
      mulBox /= static_cast<MulMemWord>(BATCH_SIZE);
      softmaxDx[i * SOFTMAX_SIZE + j] = static_cast<IntMemWord>(mulBox);
#else
      softmaxOut[j] /= expXSubXmaxSum;
      if (j == label) {
        softmaxOut[j] -= 1;
      }
      softmaxDx[i * SOFTMAX_SIZE + j] = softmaxOut[j] / static_cast<IntMemWord>(BATCH_SIZE);
#endif
    }
  }

  // affine2 backward
  IntMemWord affine2Dx[BATCH_SIZE * AFFINE2_IN_SIZE];
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    for (unsigned int j = 0; j < AFFINE2_IN_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      IntMemWord sumBox = 0;
      for (unsigned int k = 0; k < AFFINE2_OUT_SIZE; k++) {
#if defined(HLSFIXED) && !defined(HLSNOCAST)
        MulMemWord mulBox = static_cast<MulMemWord>(softmaxDx[i * AFFINE2_OUT_SIZE + k]) * static_cast<MulMemWord>(w2[j * AFFINE2_OUT_SIZE + k]);
        sumBox += static_cast<IntMemWord>(mulBox);
#else
        sumBox += softmaxDx[i * AFFINE2_OUT_SIZE + k] * w2[j * AFFINE2_OUT_SIZE + k];
#endif
      }
      affine2Dx[i * AFFINE2_IN_SIZE + j] = sumBox;
    }
  }
  for (unsigned int i = 0; i < AFFINE2_IN_SIZE; i++) {
    for (unsigned int j = 0; j < AFFINE2_OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      IntMemWord sumBox = 0;
      for (unsigned int k = 0; k < BATCH_SIZE; k++) {
#if defined(HLSFIXED) && !defined(HLSNOCAST)
        MulMemWord mulBox = static_cast<MulMemWord>(affine1Out[k * AFFINE2_IN_SIZE + i]) * static_cast<MulMemWord>(softmaxDx[k * AFFINE2_OUT_SIZE + j]);
        sumBox += static_cast<IntMemWord>(mulBox);
#else
        sumBox += affine1Out[k * AFFINE2_IN_SIZE + i] * softmaxDx[k * AFFINE2_OUT_SIZE + j];
#endif
      }
      w2[i * AFFINE2_OUT_SIZE + j] -= sumBox * LEARNING_RATE;
    }
  }
  for (unsigned int j = 0; j < AFFINE2_OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
    IntMemWord sumBox = 0;
    for (unsigned int k = 0; k < BATCH_SIZE; k++) {
      sumBox += softmaxDx[k * AFFINE2_OUT_SIZE + j];
    }
    b2[j] -= sumBox * LEARNING_RATE;
  }

  // affine1 backward
  for (unsigned int i = 0; i < AFFINE1_IN_SIZE; i++) {
    for (unsigned int j = 0; j < AFFINE1_OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      IntMemWord sumBox = 0;
      for (unsigned int k = 0; k < BATCH_SIZE; k++) {
        // ReLU backward
        if (affine1Out[k * AFFINE1_OUT_SIZE + j] != 0) {
#if defined(HLSFIXED) && !defined(HLSNOCAST)
          MulMemWord mulBox = static_cast<MulMemWord>(xTrain[k * AFFINE1_IN_SIZE + i]) * static_cast<MulMemWord>(affile2Dx[k * AFFINE1_OUT_SIZE + j]);
          sumBox += static_cast<IntMemWord>(mulBox);
#else
          sumBox += xTrain[k * AFFINE1_IN_SIZE + i] * affine2Dx[k * AFFINE1_OUT_SIZE + j];
#endif
        }
      }
      w1[i * AFFINE1_OUT_SIZE + j] -= sumBox * LEARNING_RATE;
    }
  }
  for (unsigned int j = 0; j < AFFINE1_OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
    IntMemWord sumBox = 0;
    for (unsigned int k = 0; k < BATCH_SIZE; k++) {
      // ReLU backward
      if (affine1Out[k * AFFINE1_OUT_SIZE + j] != 0) {
        sumBox += affine2Dx[k * AFFINE1_OUT_SIZE + j];
      }
    }
    b1[j] -= sumBox * LEARNING_RATE;
  }

  for (unsigned int i = 0; i < W1_SIZE; i++) {
    out.write(static_cast<ExtMemWord>(w1[i]));
  }
  for (unsigned int i = 0; i < B1_SIZE; i++) {
    out.write(static_cast<ExtMemWord>(b1[i]));
  }
  for (unsigned int i = 0; i < W2_SIZE; i++) {
    out.write(static_cast<ExtMemWord>(w2[i]));
  }
  for (unsigned int i = 0; i < B2_SIZE; i++) {
    out.write(static_cast<ExtMemWord>(b2[i]));
  }
}

void Train_Batch(ExtMemWord *in, ExtMemWord *out) {
  IntMemWord w1[W1_SIZE];
  IntMemWord b1[B1_SIZE];
  IntMemWord w2[W2_SIZE];
  IntMemWord b2[B2_SIZE];

  volatile unsigned int offset = 0;
  for (unsigned int i = 0; i < W1_SIZE; i++) {
    w1[i] = static_cast<IntMemWord>(in[offset + i]);
  }
  offset += W1_SIZE;
  for (unsigned int i = 0; i < B1_SIZE; i++) {
    b1[i] = static_cast<IntMemWord>(in[offset + i]);
  }
  offset += B1_SIZE;
  for (unsigned int i = 0; i < W2_SIZE; i++) {
    w2[i] = static_cast<IntMemWord>(in[offset + i]);
  }
  offset += W2_SIZE;
  for (unsigned int i = 0; i < B2_SIZE; i++) {
    b2[i] = static_cast<IntMemWord>(in[offset + i]);
  }
  offset += B2_SIZE;

  IntMemWord xTrain[INPUT_SIZE * BATCH_SIZE];
  IntMemWord tTrain[BATCH_SIZE];

  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    for (unsigned int j = 0; j < INPUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      xTrain[i * INPUT_SIZE + j] = static_cast<IntMemWord>(in[offset + j]);
    }
    offset += INPUT_SIZE;
    tTrain[i] = in[offset];
    offset += 1;
  }

  // Train
  // affine1 forward
  IntMemWord affine1Out[BATCH_SIZE * AFFINE1_OUT_SIZE];
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    for (unsigned int j = 0; j < AFFINE1_OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      IntMemWord sumBox = b1[j];
      for (unsigned int k = 0; k < AFFINE1_IN_SIZE; k++) {
//#pragma HLS PIPELINE II=1
#if defined(HLSFIXED) && !defined(HLSNOCAST)
        MulMemWord mulBox = static_cast<MulMemWord>(xTrain[i * AFFINE1_IN_SIZE + k]) * static_cast<MulMemWord>(w1[k * AFFINE1_OUT_SIZE + j]);
        sumBox += static_cast<IntMemWord>(mulBox);
#else
        sumBox += xTrain[i * AFFINE1_IN_SIZE + k] * w1[k * AFFINE1_OUT_SIZE + j];
#endif
      }
      // ReLU forward
      if (sumBox <= 0) {
        affine1Out[i * AFFINE1_OUT_SIZE + j] = 0;
      } else {
        affine1Out[i * AFFINE1_OUT_SIZE + j] = sumBox;
      }
    }
  }

  // affine2 forward
  IntMemWord affine2Out[BATCH_SIZE * AFFINE2_OUT_SIZE];
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    for (unsigned int j = 0; j < AFFINE2_OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      IntMemWord sumBox = b2[j];
      for (unsigned int k = 0; k < AFFINE2_IN_SIZE; k++) {
#if defined(HLSFIXED) && !defined(HLSNOCAST)
        MulMemWord mulBox = static_cast<MulMemWord>(affine1Out[i * AFFINE2_IN_SIZE + k]) * static_cast<MulMemWord>(w2[k * AFFINE2_OUT_SIZE + j]);
        sumBox += static_cast<IntMemWord>(mulBox);
#else
        sumBox += affine1Out[i * AFFINE2_IN_SIZE + k] * w2[k * AFFINE2_OUT_SIZE + j];
#endif
      }
      affine2Out[i * AFFINE2_OUT_SIZE + j] = sumBox;
    }
  }

  // softmax forward and backward
  IntMemWord softmaxOut[SOFTMAX_SIZE];
  IntMemWord softmaxDx[BATCH_SIZE * SOFTMAX_SIZE];
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    // forward
    IntMemWord xMax = affine2Out[i * SOFTMAX_SIZE];
    for (unsigned int j = 1; j < SOFTMAX_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      if (affine2Out[i * SOFTMAX_SIZE + j] > xMax) {
        xMax = affine2Out[i * SOFTMAX_SIZE + j];
      }
    }
    IntMemWord expXSubXmaxSum = 0;
    for (unsigned int j = 0; j < SOFTMAX_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      float xSubXMaxFloat = static_cast<float>(affine2Out[i * SOFTMAX_SIZE + j] - xMax);
#if defined(FPGA)
      IntMemWord expXSubXmax = hls::expf(xSubXMaxFloat);
#else
      IntMemWord expXSubXmax = std::exp(xSubXMaxFloat);
#endif
      softmaxOut[j] = expXSubXmax;
      expXSubXmaxSum += expXSubXmax;
    }
    // backward
    IntMemWord denominator = static_cast<IntMemWord>(BATCH_SIZE) * expXSubXmaxSum;
    volatile unsigned int label = static_cast<unsigned int>(tTrain[i]);
    for (unsigned int j = 0; j < SOFTMAX_SIZE; j++) {
//#pragma HLS PIPELINE II=1
#if defined(HLSFIXED) && !defined(HLSNOCAST)
      MulMemWord mulBox = static_cast<MulMemWord>(softmaxOut[j]) / static_cast<MulMemWord>(expXSubXmaxSum);
      if (j == label) {
        mulBox -= 1;
      }
      mulBox /= static_cast<MulMemWord>(BATCH_SIZE);
      softmaxDx[i * SOFTMAX_SIZE + j] = static_cast<IntMemWord>(mulBox);
#else
      //IntMemWord softmaxOutEach = softmaxOut[j] / expXSubXmaxSum;
      //IntMemWord softmaxOutEach = softmaxOut[j];
      if (j == label) {
        softmaxDx[i * SOFTMAX_SIZE + j] = (softmaxOut[j] - expXSubXmaxSum) / denominator;
      } else {
        softmaxDx[i * SOFTMAX_SIZE + j] = softmaxOut[j] / denominator;
      }
      //softmaxDx[i * SOFTMAX_SIZE + j] = softmaxOutEach / static_cast<IntMemWord>(BATCH_SIZE);
      //softmaxDx[i * SOFTMAX_SIZE + j] = softmaxOutEach / denominator;

      //softmaxOut[i * SOFTMAX_SIZE + j] = preOut[j] / expXSubXmaxSum;

      // NG:
      //float softmaxOutFloat = outFloat[j] / expXSubXmaxSumFloat;
      //softmaxDx[i * SOFTMAX_SIZE + j] = static_cast<IntMemWord>((softmaxOutFloat - tTrainFloat[i * SOFTMAX_SIZE + j]) / static_cast<float>(BATCH_SIZE));

      // NG:
      //IntMemWord softmaxOutEach = preOut[j] / expXSubXmaxSum;
      //IntMemWord tTrainEach = tTrain[i * SOFTMAX_SIZE + j];
      //softmaxDx[i * SOFTMAX_SIZE + j] = (softmaxOutEach - tTrainEach) / static_cast<IntMemWord>(BATCH_SIZE);

      // NG:
      //eachOut[j] /= expXSubXmaxSum;
      //softmaxDx[i * SOFTMAX_SIZE + j] = (eachOut[j] - eachTTrain[j]) / static_cast<IntMemWord>(BATCH_SIZE);

      // NG:
      //float floatTTrain = static_cast<float>(eachTTrain[j]);
      //float floatOut = static_cast<float>(eachOut[j]);
      //float floatSoftmaxOut = floatOut / static_cast<float>(expXSubXmaxSum);
      //softmaxDx[i * SOFTMAX_SIZE + j] = static_cast<IntMemWord>(floatSoftmaxOut - floatTTrain) / static_cast<IntMemWord>(BATCH_SIZE);
/*
      IntMemWord eachSoftmaxOut = eachOut[j];
      if (j == eachTTrain) {
        eachSoftmaxOut -= expXSubXmaxSum;
      }
*/
      // NG: softmaxDx[i * SOFTMAX_SIZE + j] = softmaxOutEach / denominator;
      // NG: softmaxDx[i * SOFTMAX_SIZE + j] = softmaxOutEach;

      // OK(//expXSubXmaxSum += expXSubXmax;): softmaxDx[i * SOFTMAX_SIZE + j] = eachOut[j];
      //softmaxDx[i * SOFTMAX_SIZE + j] = eachSoftmaxOut / denominator;

      // OK: softmaxDx[i * SOFTMAX_SIZE + j] = static_cast<IntMemWord>(expXSubXmaxSum) / static_cast<IntMemWord>(BATCH_SIZE);

      // OK: softmaxDx[i * SOFTMAX_SIZE + j] = static_cast<IntMemWord>(i * SOFTMAX_SIZE + j) / static_cast<IntMemWord>(BATCH_SIZE);
#endif
    }
  }

  // affine2 backward
  IntMemWord affine2Dx[BATCH_SIZE * AFFINE2_IN_SIZE];
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    for (unsigned int j = 0; j < AFFINE2_IN_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      IntMemWord sumBox = 0;
      for (unsigned int k = 0; k < AFFINE2_OUT_SIZE; k++) {
#if defined(HLSFIXED) && !defined(HLSNOCAST)
        MulMemWord mulBox = static_cast<MulMemWord>(softmaxDx[i * AFFINE2_OUT_SIZE + k]) * static_cast<MulMemWord>(w2[j * AFFINE2_OUT_SIZE + k]);
        sumBox += static_cast<IntMemWord>(mulBox);
#else
        sumBox += softmaxDx[i * AFFINE2_OUT_SIZE + k] * w2[j * AFFINE2_OUT_SIZE + k];
#endif
      }
      affine2Dx[i * AFFINE2_IN_SIZE + j] = sumBox;
    }
  }
  for (unsigned int i = 0; i < AFFINE2_IN_SIZE; i++) {
    for (unsigned int j = 0; j < AFFINE2_OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      IntMemWord sumBox = 0;
      for (unsigned int k = 0; k < BATCH_SIZE; k++) {
#if defined(HLSFIXED) && !defined(HLSNOCAST)
        MulMemWord mulBox = static_cast<MulMemWord>(affine1Out[k * AFFINE2_IN_SIZE + i]) * static_cast<MulMemWord>(softmaxDx[k * AFFINE2_OUT_SIZE + j]);
        sumBox += static_cast<IntMemWord>(mulBox);
#else
        sumBox += affine1Out[k * AFFINE2_IN_SIZE + i] * softmaxDx[k * AFFINE2_OUT_SIZE + j];
#endif
      }
      w2[i * AFFINE2_OUT_SIZE + j] -= sumBox * LEARNING_RATE;
    }
  }
  for (unsigned int j = 0; j < AFFINE2_OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
    IntMemWord sumBox = 0;
    for (unsigned int k = 0; k < BATCH_SIZE; k++) {
      sumBox += softmaxDx[k * AFFINE2_OUT_SIZE + j];
    }
    b2[j] -= sumBox * LEARNING_RATE;
  }

  // affine1 backward
  for (unsigned int i = 0; i < AFFINE1_IN_SIZE; i++) {
    for (unsigned int j = 0; j < AFFINE1_OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      IntMemWord sumBox = 0;
      for (unsigned int k = 0; k < BATCH_SIZE; k++) {
        // ReLU backward
        if (affine1Out[k * AFFINE1_OUT_SIZE + j] != 0) {
#if defined(HLSFIXED) && !defined(HLSNOCAST)
          MulMemWord mulBox = static_cast<MulMemWord>(xTrain[k * AFFINE1_IN_SIZE + i]) * static_cast<MulMemWord>(affile2Dx[k * AFFINE1_OUT_SIZE + j]);
          sumBox += static_cast<IntMemWord>(mulBox);
#else
          sumBox += xTrain[k * AFFINE1_IN_SIZE + i] * affine2Dx[k * AFFINE1_OUT_SIZE + j];
#endif
        }
      }
      w1[i * AFFINE1_OUT_SIZE + j] -= sumBox * LEARNING_RATE;
    }
  }
  for (unsigned int j = 0; j < AFFINE1_OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
    IntMemWord sumBox = 0;
    for (unsigned int k = 0; k < BATCH_SIZE; k++) {
      // ReLU backward
      if (affine1Out[k * AFFINE1_OUT_SIZE + j] != 0) {
        sumBox += affine2Dx[k * AFFINE1_OUT_SIZE + j];
      }
    }
    b1[j] -= sumBox * LEARNING_RATE;
  }

  offset = 0;
  for (unsigned int i = 0; i < W1_SIZE; i++) {
    out[offset + i] = static_cast<ExtMemWord>(w1[i]);
  }
  offset += W1_SIZE;
  for (unsigned int i = 0; i < B1_SIZE; i++) {
    out[offset + i] = static_cast<ExtMemWord>(b1[i]);
  }
  offset += B1_SIZE;
  for (unsigned int i = 0; i < W2_SIZE; i++) {
    out[offset + i] = static_cast<ExtMemWord>(w2[i]);
  }
  offset += W2_SIZE;
  for (unsigned int i = 0; i < B2_SIZE; i++) {
    out[offset + i] = static_cast<ExtMemWord>(b2[i]);
  }
}

} // namespace two_layer_net
