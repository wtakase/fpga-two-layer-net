#include <algorithm>
#include "softmax.hpp"

#if defined(FPGA)

#include "hls_math.h"

float expWrapper(float in) {
  return hls::exp(in);
}

float logWrapper(float in) {
  return hls::log(in);
}


#else

float expWrapper(float in) {
  return std::exp(in);
}

float logWrapper(float in) {
  return std::log(in);
}

#endif

DlSoftmaxWithLoss::DlSoftmaxWithLoss()
{
}

void DlSoftmaxWithLoss::SoftmaxWithLoss(IntMemWord x[BATCH_SIZE * SIZE])
{
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    IntMemWord xMax = x[i * SIZE];
    for (unsigned int j = 1; j < SIZE; j++) {
//#pragma HLS PIPELINE II=1
      if (x[i * SIZE + j] > xMax) {
        xMax = x[i * SIZE + j];
      }
    }
    IntMemWord expXSubXmaxSum = 0;
    for (unsigned int j = 0; j < SIZE; j++) {
//#pragma HLS PIPELINE II=1
      float xSubXMaxFloat = static_cast<float>(x[i * SIZE + j] - xMax);
      IntMemWord expXSubXmax = expWrapper(xSubXMaxFloat);
      out[i * SIZE + j] = expXSubXmax;
      expXSubXmaxSum += expXSubXmax;
    }
    for (unsigned int j = 0; j < SIZE; j++) {
//#pragma HLS PIPELINE II=1
#if defined(HLSFIXED) && !defined(HLSNOCAST)
      mulBox = static_cast<MulMemWord>(out[i * SIZE + j]) / static_cast<MulMemWord>(expXSubXmaxSum);
      out[i * SIZE + j] = static_cast<IntMemWord>(mulBox);
#else
      out[i * SIZE + j] /= expXSubXmaxSum;
#endif
    }
  }
}

IntMemWord DlSoftmaxWithLoss::CrossEntropyError(IntMemWord t[BATCH_SIZE * SIZE])
{
  IntMemWord sum = 0;
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
//#pragma HLS PIPELINE II=1
    for (unsigned int j = 0; j < SIZE; j++) {
      float outFloat = static_cast<float>(out[i * SIZE + j]);
      outFloat += 1e-7;
#if defined(HLSFIXED) && !defined(HLSNOCAST)
      mulBox = static_cast<MulMemWord>(t[i * SIZE + j]) * static_cast<MulMemWord>(logWrapper(outFloat));
      sum += static_cast<IntMemWord>(mulBox);
#else
      sum += t[i * SIZE + j] * static_cast<IntMemWord>(logWrapper(outFloat));
#endif
    }
  }
#if defined(HLSFIXED) && !defined(HLSNOCAST)
  mulBox = static_cast<MulMemWord>(-sum) / static_cast<MulMemWord>(BATCH_SIZE);
  return static_cast<IntMemWord>(mulBox);
#else
  return -sum / BATCH_SIZE;
#endif
}

IntMemWord DlSoftmaxWithLoss::Forward(IntMemWord x[BATCH_SIZE * SIZE], IntMemWord t[BATCH_SIZE * SIZE])
{
  DlSoftmaxWithLoss::SoftmaxWithLoss(x);
  return 0;
  //return DlSoftmaxWithLoss::CrossEntropyError(t);
}

void DlSoftmaxWithLoss::Backward(IntMemWord t[BATCH_SIZE * SIZE])
{
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
//#pragma HLS PIPELINE II=1
    for (unsigned int j = 0; j < SIZE; j++) {
#if defined(HLSFIXED) && !defined(HLSNOCAST)
      mulBox = static_cast<MulMemWord>(out[i * SIZE + j] - t[i * SIZE + j]);
      mulBox = mulBox / static_cast<MulMemWord>(BATCH_SIZE);
      dx[i * SIZE + j] = static_cast<IntMemWord>(mulBox);
#else
      dx[i * SIZE + j] = (out[i * SIZE + j] - t[i * SIZE + j]) / static_cast<IntMemWord>(BATCH_SIZE);
#endif
    }
  }
}
