#!/usr/bin/python3.4

import sys
import os

TLN_ROOT_DIR = os.path.dirname(os.path.realpath(__file__))
sys.path.append(TLN_ROOT_DIR)

import two_layer_net

tln = two_layer_net.TwoLayerNet(runtime=two_layer_net.RUNTIME_HW,
                                network=two_layer_net.NETWORK_TLN)
#print(tln.train(image_num=40))
#print(tln.train(image_num=80))
#print(tln.train(image_num=800))
print(tln.train(epoch_num=1))
