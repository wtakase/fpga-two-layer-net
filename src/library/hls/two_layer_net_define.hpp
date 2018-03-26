#ifndef _TWO_LAYER_NET_DEFINE_HPP
#define _TWO_LAYER_NET_DEFINE_HPP

#if defined(HLSFIXED)

#include "ap_fixed.h"

namespace two_layer_net

{
//typedef ap_fixed<32, 8, AP_RND, AP_SAT> IntMemWord;
//typedef ap_fixed<24, 4, AP_RND, AP_SAT> IntMemWord;
//typedef ap_fixed<16, 2, AP_RND, AP_SAT> IntMemWord;
//typedef ap_fixed<20, 4, AP_RND, AP_SAT> IntMemWord;
//typedef ap_fixed<20, 4, AP_RND, AP_SAT> IntMemWord;
//typedef ap_fixed<32, 8> IntMemWord;
//typedef ap_fixed<24, 4> IntMemWord;
//typedef ap_fixed<24, 2> IntMemWord;
//typedef ap_fixed<31, 7> IntMemWord;
//typedef ap_fixed<20, 4, AP_TRN, AP_SAT> IntMemWord;
//typedef ap_fixed<16, 2, AP_TRN, AP_SAT> IntMemWord;
//typedef ap_fixed<16, 4, AP_TRN, AP_SAT> IntMemWord;
//typedef ap_fixed<14, 4, AP_TRN, AP_SAT> IntMemWord;
//typedef ap_fixed<12, 4, AP_TRN, AP_SAT> IntMemWord;
typedef ap_fixed<32, 8, AP_TRN, AP_SAT> IntMemWord;

//typedef ap_fixed<32, 8, AP_RND, AP_SAT> ExtMemWord;
typedef ap_fixed<32, 8, AP_TRN, AP_SAT> ExtMemWord;
const unsigned int bytesPerExtMemWord = sizeof(ExtMemWord);
const unsigned int bitsPerExtMemWord = sizeof(ExtMemWord) * 8;

#if !defined(HLSNOCAST)
//typedef float MulMemWord;
typedef ap_fixed<32, 8, AP_RND, AP_SAT> MulMemWord;
#endif

#if !defined(HLSNOSHIFT)
typedef ap_fixed<32, 8, AP_RND, AP_SAT> ShiftMemWord;
#endif

} // namespace two_layer_net

#elif defined(HLSHALF)

#include "hls_half.h"

namespace two_layer_net
{

typedef half IntMemWord;
typedef IntMemWord ExtMemWord;
const unsigned int bytesPerExtMemWord = sizeof(ExtMemWord);
const unsigned int bitsPerExtMemWord = sizeof(ExtMemWord) * 8;

} // namespace two_layer_net

#else

namespace two_layer_net
{

typedef float IntMemWord;
typedef IntMemWord ExtMemWord;
const unsigned int bytesPerExtMemWord = sizeof(ExtMemWord);
const unsigned int bitsPerExtMemWord = sizeof(ExtMemWord) * 8;

} // namespace two_layer_net

#endif

#define DEF_INPUT_SIZE 784
#define DEF_BATCH_SIZE 40
#define PRAGMA_SUB(x) _Pragma (#x)
#define DO_PRAGMA(x) PRAGMA_SUB(x)

static const unsigned int INPUT_SIZE = DEF_INPUT_SIZE;
static const unsigned int HIDDEN_LAYER_NUM = 1;
static const unsigned int HIDDEN1_SIZE = 25;
static const unsigned int OUTPUT_SIZE = 10;
static const unsigned int BATCH_SIZE = DEF_BATCH_SIZE;
static const unsigned int MAX_SIZE = INPUT_SIZE;
static const double WEIGHT_INIT_STD = 0.01;
static const two_layer_net::ExtMemWord LEARNING_RATE = 0.01;
static const unsigned int TRAIN_SIZE = 60000;
static const unsigned int TEST_SIZE = 10000;
static const unsigned int STEPS_PER_EPOCH = TRAIN_SIZE / BATCH_SIZE;
static const unsigned int MAX_EPOCHS = 3;
static const unsigned int MAX_ITERATIONS = STEPS_PER_EPOCH * MAX_EPOCHS;
static const unsigned int W1_SIZE = INPUT_SIZE * HIDDEN1_SIZE;
static const unsigned int B1_SIZE = HIDDEN1_SIZE;
static const unsigned int W2_SIZE = HIDDEN1_SIZE * OUTPUT_SIZE;
static const unsigned int B2_SIZE = OUTPUT_SIZE;
static const unsigned int W_B_SIZE = W1_SIZE + B1_SIZE + W2_SIZE + B2_SIZE;

#endif
