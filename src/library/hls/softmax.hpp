#ifndef _SOFTMAX_HPP
#define _SOFTMAX_HPP

#include "two_layer_net_define.hpp"

using namespace two_layer_net;

class DlSoftmaxWithLoss
{
public:
  static const unsigned int SIZE = OUTPUT_SIZE;
  IntMemWord out[BATCH_SIZE * SIZE];
  IntMemWord dx[BATCH_SIZE * SIZE];
  IntMemWord loss;
#if defined(HLSFIXED) && !defined(HLSNOCAST)
  MulMemWord mulBox;
#endif

  DlSoftmaxWithLoss();

  void SoftmaxWithLoss(IntMemWord x[BATCH_SIZE * SIZE]);

  IntMemWord CrossEntropyError(IntMemWord t[BATCH_SIZE * SIZE]);

  IntMemWord Forward(IntMemWord x[BATCH_SIZE * SIZE], IntMemWord t[BATCH_SIZE * SIZE]);

  void Backward(IntMemWord t[BATCH_SIZE * SIZE]);
};

#endif
