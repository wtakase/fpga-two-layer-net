#   Copyright (c) 2016, Xilinx, Inc.
#   All rights reserved.
# 
#   Redistribution and use in source and binary forms, with or without 
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its 
#       contributors may be used to endorse or promote products derived from 
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from collections import OrderedDict
from dataset.mnist import load_mnist
import numpy as np
import cffi
import os
import tempfile
import time

TLN_ROOT_DIR = os.path.dirname(os.path.realpath(__file__))
TLN_LIB_DIR = os.path.join(TLN_ROOT_DIR, 'libraries')

RUNTIME_HW = "python_hw"
RUNTIME_SW = "python_sw"

NETWORK_TLN = "two-layer-net"

TLN_INPUT_SIZE = 784;
TLN_HIDDEN1_SIZE = 25;
TLN_OUTPUT_SIZE = 10;
TLN_BATCH_SIZE = 40;
TLN_TRAIN_SIZE = 60000;
TLN_TEST_SIZE = 10000;
TLN_W1_SIZE = TLN_INPUT_SIZE * TLN_HIDDEN1_SIZE;
TLN_B1_SIZE = TLN_HIDDEN1_SIZE;
TLN_W2_SIZE = TLN_HIDDEN1_SIZE * TLN_OUTPUT_SIZE;
TLN_B2_SIZE = TLN_OUTPUT_SIZE;
TLN_W_B_SIZE = TLN_W1_SIZE + TLN_B1_SIZE + TLN_W2_SIZE + TLN_B2_SIZE;

_ffi = cffi.FFI()
_ffi.cdef("""
void load_images(const char* path);
void init_param(float *param, unsigned int rowNum, unsigned int colNum, double weightInitStd);
void init_params();
float *train(unsigned int imageNum, float *usecPerMul);
void free_results(float *result);
void free_images();
void free_params();
void deinit();
"""
)

_libraries = {}

class TwoLayerNet:
    def __init__(self, runtime=RUNTIME_HW, network=NETWORK_TLN):
        dllname = "{0}-{1}.so".format(runtime, network)
        if dllname not in _libraries:
            _libraries[dllname] = _ffi.dlopen(
                os.path.join(TLN_LIB_DIR, dllname))
        self.interface = _libraries[dllname]
        self.num_classes = 0
        
    def __del__(self):
        self.interface.deinit()

    def train(self, path="/root/wtakase/mnist",
              image_num=TLN_BATCH_SIZE, epoch_num=None,
              get_accuracy=True):
        self.interface.load_images(path.encode())
        self.interface.init_params()
        usecpermult = _ffi.new("float *")
        if epoch_num is None:
            if image_num > TLN_TRAIN_SIZE:
                image_num = TLN_TRAIN_SIZE
            loop_per_image_num = TLN_BATCH_SIZE
            loop_num = int(image_num / TLN_BATCH_SIZE)
            if image_num % TLN_BATCH_SIZE != 0:
                loop_num += 1
        else:
            loop_per_image_num = TLN_TRAIN_SIZE
            loop_num = epoch_num
            if loop_num <= 0:
                loop_num = 1

        result_arrays = []
        total_start_time = time.time()
        for i in range(loop_num):
            sub_start_time = time.time()
            result_ptr = self.interface.train(loop_per_image_num, usecpermult)
            sub_end_time = time.time()
            #print(" %d-images training took %.2f sec" % (loop_per_image_num,
            #                                            sub_end_time - sub_start_time))
            result_buffer = _ffi.buffer(result_ptr, TLN_W_B_SIZE * 4)
            result_array = np.copy(np.frombuffer(result_buffer, dtype=np.float32))
            result_arrays.append({"image_num": (i + 1) * loop_per_image_num,
                                  "result": result_array})
            self.interface.free_results(result_ptr)
        total_end_time = time.time()
        print("%d-images training took %.2f sec" % (loop_num * loop_per_image_num,
                                                    total_end_time - total_start_time))
        self.interface.free_images()
        self.interface.free_params()

        w_bs = []
        for result in result_arrays:
            w1 = result["result"][0:TLN_W1_SIZE]
            b1 = result["result"][TLN_W1_SIZE:TLN_W1_SIZE+TLN_B1_SIZE]
            w2 = result["result"][TLN_W1_SIZE+TLN_B1_SIZE:TLN_W1_SIZE+TLN_B1_SIZE+TLN_W2_SIZE]
            b2 = result["result"][TLN_W1_SIZE+TLN_B1_SIZE+TLN_W2_SIZE:TLN_W1_SIZE+TLN_B1_SIZE+TLN_W2_SIZE+TLN_B2_SIZE]
            w_bs.append({"image_num": result["image_num"],
                         "w1": w1, "b1": b1, "w2": w2, "b2": b2})

        if get_accuracy:
            return self.get_accuracy(w_bs)
        else:
            return w_bs

    def get_accuracy(self, w_bs):
        (x_train, t_train), (x_test, t_test) = load_mnist(normalize=False, one_hot_label=True)
        #iter_num = int(TLN_TEST_SIZE / TLN_BATCH_SIZE)
        iter_num = 10
        accuracies = []
        for w_b in w_bs:
            network = TrainedTwoLayerNet(w_b["w1"], w_b["b1"], w_b["w2"], w_b["b2"])
            accuracy = 0.0
            for i in range(iter_num):
                batch_mask = np.random.choice(TLN_TEST_SIZE, TLN_BATCH_SIZE)
                x_batch = x_test[batch_mask] / 255.0
                t_batch = t_test[batch_mask]
                accuracy += network.accuracy(x_batch, t_batch)
            accuracies.append({"image_num": w_b["image_num"],
                               "accuracy": accuracy / iter_num})
        return accuracies


class Affine:
    def __init__(self, W, b):
        self.W = W
        self.b = b

    def forward(self, x):
        self.x = x
        return np.dot(x, self.W) + self.b


class Relu:
    def __init__(self):
        self.mask = None

    def forward(self, x):
        # If x = [1, 2, 0, -1], (x <= 0) returns [False, False, True, True].
        self.mask = (x <= 0)
        # Necessary to avoid overriding original x values.
        out = x.copy()
        # Set 0, if out[i] == True
        out[self.mask] = 0

        return out


class TrainedTwoLayerNet:
    def __init__(self, w1, b1, w2, b2,
                 input_size=TLN_INPUT_SIZE,
                 hidden_size=TLN_HIDDEN1_SIZE,
                 output_size=TLN_OUTPUT_SIZE):
        self.params = {}
        self.params['W1'] = w1.reshape((input_size,hidden_size))
        self.params['b1'] = b1
        self.params['W2'] = w2.reshape((hidden_size, output_size))
        self.params['b2'] = b2

        self.layers = OrderedDict()
        self.layers['Affine1'] = Affine(self.params['W1'], self.params['b1'])
        self.layers['Relu1'] = Relu()
        self.layers['Affine2'] = Affine(self.params['W2'], self.params['b2'])

    def predict(self, x):
        for layer in self.layers.values():
            x = layer.forward(x)
        return x

    def accuracy(self, x, t):
        y = self.predict(x)
        y = np.argmax(y, axis=1)
        if t.ndim != 1 : t = np.argmax(t, axis=1)
        return  np.sum(y == t) / float(x.shape[0])
