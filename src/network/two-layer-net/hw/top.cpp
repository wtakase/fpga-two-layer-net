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
 * @file top.cpp
 *
 * HLS Description of the Two-layer-net, with axi-lite based parameter loading (DoMemInit) 
 * and  dataflow architecture of the image inference (DoCompute)
 * 
 *
 *****************************************************************************/
#include "two_layer_net_library.hpp"
#include "two_layer_net_define.hpp"
#include <iostream>

namespace two_layer_net
{

void DoCompute(ExtMemWord *in, ExtMemWord *out) {
  hls::stream<ExtMemWord> memInStrm("DoCompute.memInStrm");
  hls::stream<ExtMemWord> memOutStrm("DoCompute.memOutStrm");
#pragma HLS STREAM depth=51285 variable=memInStrm
#pragma HLS STREAM depth=19885 variable=memOutStrm

  const unsigned int SIZE_PER_IMAGE = INPUT_SIZE + 1;
  for (unsigned int i = 0; i < W_B_SIZE + SIZE_PER_IMAGE * BATCH_SIZE; i++) {
    ExtMemWord e = in[i];
    memInStrm.write(e);
  }
  StreamingTrain_Batch(memInStrm, memOutStrm);
  for (unsigned int i = 0; i < W_B_SIZE; i++) {
    ExtMemWord e = memOutStrm.read();
    out[i] = e;
  }
}

// This is needed for RUNTIME_SW
void BlackBoxJam(ExtMemWord *in, ExtMemWord *out) {
#pragma HLS INTERFACE m_axi offset=slave port=in bundle=hostmem0 depth=51285
#pragma HLS INTERFACE m_axi offset=slave port=out bundle=hostmem1 depth=19885
#pragma HLS INTERFACE s_axilite port=in bundle=control
#pragma HLS INTERFACE s_axilite port=out bundle=control
#pragma HLS INTERFACE s_axilite port=return bundle=control
  DoCompute(in, out);
}

} // namespace two_layer_net

// This is needed for RUNTIME_HW
void BlackBoxJam(two_layer_net::ExtMemWord *in, two_layer_net::ExtMemWord *out) {
#pragma HLS INTERFACE m_axi offset=slave port=in bundle=hostmem0 depth=51285
#pragma HLS INTERFACE m_axi offset=slave port=out bundle=hostmem1 depth=19885
#pragma HLS INTERFACE s_axilite port=in bundle=control
#pragma HLS INTERFACE s_axilite port=out bundle=control
#pragma HLS INTERFACE s_axilite port=return bundle=control
  two_layer_net::DoCompute(in, out);
}
