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
#pragma HLS DATAFLOW
  const unsigned int SIZE_PER_IMAGE = INPUT_SIZE + 1;

  hls::stream<ExtMemWord> memInStrm("DoCompute.memInStrm");
  hls::stream<ExtMemWord> memOutStrm("DoCompute.memOutStrm");

  unsigned int offset = 0;
  // TODO(wtakase): Need to sophisticate
  two_layer_net::Mem2Stream_Batch<bitsPerExtMemWord, (W_B_SIZE + SIZE_PER_IMAGE * BATCH_SIZE) * bytesPerExtMemWord>(&in[offset], memInStrm, 1);

  StreamingTrain_Batch(memInStrm, memOutStrm);

  offset = 0;
  // TODO(wtakase): Need to sophisticate
  two_layer_net::Stream2Mem_Batch<bitsPerExtMemWord, W_B_SIZE * bytesPerExtMemWord>(memOutStrm, &out[offset], 1);
}

// This is needed for RUNTIME_SW
void BlackBoxJam(ExtMemWord *in, ExtMemWord *out) {
// pragmas for MLBP jam interface
// signals to be mapped to the AXI Lite slave port
#pragma HLS INTERFACE s_axilite port=return bundle=control
// signals to be mapped to the AXI master port (hostmem)
#pragma HLS INTERFACE m_axi offset=slave port=in bundle=hostmem depth=256
#pragma HLS INTERFACE s_axilite port=in bundle=control
#pragma HLS INTERFACE m_axi offset=slave port=out bundle=hostmem depth=256
#pragma HLS INTERFACE s_axilite port=out bundle=control

  //DoCompute(in, out);
  Train_Batch(in, out);
}

} // namespace two_layer_net

// This is needed for RUNTIME_HW
void BlackBoxJam(two_layer_net::ExtMemWord *in, two_layer_net::ExtMemWord *out) {
// pragmas for MLBP jam interface
// signals to be mapped to the AXI Lite slave port
#pragma HLS INTERFACE s_axilite port=return bundle=control
// signals to be mapped to the AXI master port (hostmem)
#pragma HLS INTERFACE m_axi offset=slave port=in bundle=hostmem depth=256
#pragma HLS INTERFACE s_axilite port=in bundle=control
#pragma HLS INTERFACE m_axi offset=slave port=out bundle=hostmem depth=256
#pragma HLS INTERFACE s_axilite port=out bundle=control

  //two_layer_net::DoCompute(in, out);
  two_layer_net::Train_Batch(in, out);
}
