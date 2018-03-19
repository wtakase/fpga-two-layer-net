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
 * @file offload.hpp
 *
 * Library of functions for host code and managing SW/HW offload
 * 
 *
 *****************************************************************************/

#ifndef _OFFLOAD_HPP
#define _OFFLOAD_HPP

#pragma once
#include <stdlib.h>
#include <vector>
#include "tiny_cnn/tiny_cnn.h"
#include "two_layer_net_define.hpp"

#if defined(OFFLOAD) && !defined(RAWHLS)
#include "admxrc3_driver.hpp"
#else
#include "two_layer_net_library.hpp"
#endif

namespace two_layer_net
{

#ifndef VIRTUAL
#define INPUT_BUF_ENTRIES       3840000
#define OUTPUT_BUF_ENTRIES      160000
#else
#define INPUT_BUF_ENTRIES	8192
#define OUTPUT_BUF_ENTRIES	1024
#endif

extern ExtMemWord *bufIn, *bufOut;

void PlatformInit();

void PlatformDeinit();

std::vector<float> trainMNIST(std::vector<tiny_cnn::vec_t> &trainImages, std::vector<tiny_cnn::label_t> &trainLabels, const unsigned int imageNum, float &usecPerImage, float *params); 

std::vector<float> add(const unsigned int imageNum, float &usecPerImage);

#if defined(OFFLOAD) && !defined(RAWHLS)
extern Admxrc3Driver* thePlatform;
void ExecAccel();
#else
void BlackBoxJam(ExtMemWord *in, ExtMemWord *out);
#endif

} // namespace two_layer_net

#endif
