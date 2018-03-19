#include "affine.hpp"

DlAffine1::DlAffine1()
{
}

void DlAffine1::Forward(IntMemWord x[BATCH_SIZE * IN_SIZE], IntMemWord w[W1_SIZE], IntMemWord b[B1_SIZE])
{
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    for (unsigned int j = 0; j < OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      for (unsigned int k = 0; k < IN_SIZE; k++) {
//#pragma HLS PIPELINE II=1
        if (k == 0) {
          sumBox1 = b[j];
        }
#if defined(HLSFIXED) && !defined(HLSNOCAST)
        mulBox = static_cast<MulMemWord>(x[i * IN_SIZE + k]) * static_cast<MulMemWord>(w[k * OUT_SIZE + j]);
        sumBox1 += static_cast<IntMemWord>(mulBox);
#else
        sumBox1 += x[i * IN_SIZE + k] * w[k * OUT_SIZE + j];
#endif
        if (k == IN_SIZE - 1) {
          // ReLU forward
          if (sumBox1 <= 0) {
            out[i * OUT_SIZE + j] = 0;
          } else {
            out[i * OUT_SIZE + j] = sumBox1;
          }
        }
      }
    }
  }
}

void DlAffine1::Backward(IntMemWord dout[BATCH_SIZE * OUT_SIZE], IntMemWord x[BATCH_SIZE * IN_SIZE], IntMemWord w[W1_SIZE], IntMemWord b[B1_SIZE])
{
  for (unsigned int i = 0; i < IN_SIZE; i++) {
    for (unsigned int j = 0; j < OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      for (unsigned int k = 0; k < BATCH_SIZE; k++) {
        if (k == 0) {
          sumBox1 = 0;
        }
        // ReLU backward
        if (out[k * OUT_SIZE + j] != 0) {
#if defined(HLSFIXED) && !defined(HLSNOCAST)
          mulBox = static_cast<MulMemWord>(x[k * IN_SIZE + i]) * static_cast<MulMemWord>(dout[k * OUT_SIZE + j]);
          sumBox1 += static_cast<IntMemWord>(mulBox);
#else
          sumBox1 += x[k * IN_SIZE + i] * dout[k * OUT_SIZE + j];
#endif
        }
        if (k == BATCH_SIZE - 1) {
          w[i * OUT_SIZE + j] -= sumBox1 * LEARNING_RATE;
        }
      }
    }
  }

  for (unsigned int j = 0; j < OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
    for (unsigned int k = 0; k < BATCH_SIZE; k++) {
      if (k == 0) {
        sumBox2 = 0;
      }
      // ReLU backward
      if (out[k * OUT_SIZE + j] != 0) {
        sumBox2 += dout[k * OUT_SIZE + j];
      }
      if (k == BATCH_SIZE - 1) {
        b[j] -= sumBox2 * LEARNING_RATE;
      }
    }
  }
}


DlAffine2::DlAffine2()
{
}

void DlAffine2::Forward(IntMemWord x[BATCH_SIZE * IN_SIZE], IntMemWord w[W2_SIZE], IntMemWord b[B2_SIZE])
{
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    for (unsigned int j = 0; j < OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      for (unsigned int k = 0; k < IN_SIZE; k++) {
        if (k == 0) {
          sumBox1 = b[j];
        }
#if defined(HLSFIXED) && !defined(HLSNOCAST)
        mulBox = static_cast<MulMemWord>(x[i * IN_SIZE + k]) * static_cast<MulMemWord>(w[k * OUT_SIZE + j]);
        sumBox1 += static_cast<IntMemWord>(mulBox);
#else
        sumBox1 += x[i * IN_SIZE + k] * w[k * OUT_SIZE + j];
#endif
        if (k == IN_SIZE - 1) {
          out[i * OUT_SIZE + j] = sumBox1;
        }
      }
    }
  }
}

void DlAffine2::Backward(IntMemWord dout[BATCH_SIZE * OUT_SIZE], IntMemWord x[BATCH_SIZE * IN_SIZE], IntMemWord w[W2_SIZE], IntMemWord b[B2_SIZE])
{
  for (unsigned int i = 0; i < BATCH_SIZE; i++) {
    for (unsigned int j = 0; j < IN_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      for (unsigned int k = 0; k < OUT_SIZE; k++) {
        if (k == 0) {
          sumBox1 = 0;
        }
#if defined(HLSFIXED) && !defined(HLSNOCAST)
        mulBox = static_cast<MulMemWord>(dout[i * OUT_SIZE + k]) * static_cast<MulMemWord>(w[j * OUT_SIZE + k]);
        sumBox1 += static_cast<IntMemWord>(mulBox);
#else
        sumBox1 += dout[i * OUT_SIZE + k] * w[j * OUT_SIZE + k];
#endif
        if (k == OUT_SIZE -1) {
          dx[i * IN_SIZE + j] = sumBox1;
        }
      }
    }
  }

  for (unsigned int i = 0; i < IN_SIZE; i++) {
    for (unsigned int j = 0; j < OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
      for (unsigned int k = 0; k < BATCH_SIZE; k++) {
        if (k == 0) {
          sumBox1 = 0;
        }
#if defined(HLSFIXED) && !defined(HLSNOCAST)
        mulBox = static_cast<MulMemWord>(x[k * IN_SIZE + i]) * static_cast<MulMemWord>(dout[k * OUT_SIZE + j]);
        sumBox1 += static_cast<IntMemWord>(mulBox);
#else
        sumBox1 += x[k * IN_SIZE + i] * dout[k * OUT_SIZE + j];
#endif
        if (k == BATCH_SIZE - 1) {
          w[i * OUT_SIZE + j] -= sumBox1 * LEARNING_RATE;
        }
      }
    }
  }

  for (unsigned int j = 0; j < OUT_SIZE; j++) {
//#pragma HLS PIPELINE II=1
    for (unsigned int k = 0; k < BATCH_SIZE; k++) {
      if (k == 0) {
        sumBox2 = 0;
      }
      sumBox2 += dout[k * OUT_SIZE + j];
      if (k == BATCH_SIZE - 1) {
        b[j] -= sumBox2 * LEARNING_RATE;
      }
    }
  }
}
