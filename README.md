# 2020-CVSD
Computer-aided Vlsi System Design


## hw1
Introduction
---
The Arithmetic logic unit (ALU) is one of the components of a computer processor.
The ALU has math, logic, and some designed operations in the computer. In this
homework, you are going to design an ALU with some special instructions, and use the
ALU to compute input data to get the correct results.


## hw2
Introduction
---
Central Processing Unit (CPU) is the important core in the computer system. In
this homework, you are asked to design a simple MIPS CPU, which contains the basic
module of program counter, ALU and register files. The instruction set of the simple
CPU is similar to MIPS structure. Since the files of testbench (testbed.v, inst_mem.v,
data_mem.v) are protected, you also need to design the testbench to test your design.

## hw3
Introduction
---
Image display is a useful feature for the consumer electronics. In this homework,
you are going to implement an image display controller with some simple functions.
An 8×8 image will be loaded first, and it will be processed with several functions.
| Operation Mode | Meaning | Need to display?|
|---------|---------|--------|
|3’b000 |Input image loading| No|
|3’b001 |Origin right shift |Yes|
|3’b010 |Origin down shift |Yes|
|3’b011 |Default origin |Yes|
|3’b100 |Zoom-in |Yes|
|3’b101 |Median filter operation |No|
|3’b110 |YCbCr display |No|
|3’b111 |RGB display |No|
