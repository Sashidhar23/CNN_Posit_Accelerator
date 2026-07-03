`timescale 1ns / 1ps

// Parallel quire accuracy-style testbench for tb_reduced_vgg16_mnist_accuracy.
`define REDUCED_VGG_DUT reduced_vgg16_mnist_quire
`define REDUCED_VGG_TB_MODULE tb_reduced_vgg16_mnist_quire_accuracy
`include "tb_reduced_vgg16_mnist_accuracy.v"
