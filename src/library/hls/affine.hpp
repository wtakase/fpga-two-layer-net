#ifndef _AFFINE_HPP
#define _AFFINE_HPP

#include "two_layer_net_define.hpp"

using namespace two_layer_net;

class DlAffine1
{
public:
  static const unsigned int IN_SIZE = INPUT_SIZE;
  static const unsigned int OUT_SIZE = HIDDEN1_SIZE;
  IntMemWord out[BATCH_SIZE * OUT_SIZE];
#if defined(HLSFIXED) && !defined(HLSNOCAST)
  MulMemWord mulBox;
#endif
  IntMemWord sumBox1;
  IntMemWord sumBox2;

  DlAffine1();

  void Forward(IntMemWord x[BATCH_SIZE * IN_SIZE], IntMemWord w[W1_SIZE], IntMemWord b[B1_SIZE]);

  void Backward(IntMemWord dout[BATCH_SIZE * OUT_SIZE], IntMemWord x[BATCH_SIZE * IN_SIZE], IntMemWord w[W1_SIZE], IntMemWord b[B1_SIZE]);
};

class DlAffine2
{
public:
  static const unsigned int IN_SIZE = HIDDEN1_SIZE;
  static const unsigned int OUT_SIZE = OUTPUT_SIZE;
  IntMemWord out[BATCH_SIZE * OUT_SIZE];
  IntMemWord dx[BATCH_SIZE * IN_SIZE];
#if defined(HLSFIXED) && !defined(HLSNOCAST)
  MulMemWord mulBox;
#endif
  IntMemWord sumBox1;
  IntMemWord sumBox2;

  DlAffine2();

  void Forward(IntMemWord x[BATCH_SIZE * IN_SIZE], IntMemWord w[W2_SIZE], IntMemWord b[B2_SIZE]);

  void Backward(IntMemWord dout[BATCH_SIZE * OUT_SIZE], IntMemWord x[BATCH_SIZE * IN_SIZE], IntMemWord w[W2_SIZE], IntMemWord b[B2_SIZE]);
};

#endif
