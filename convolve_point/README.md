# convolution: point
Buffers all the pixels in and near the workgroup at once and convolve one pixel at a time in one work item.

Each loop takes 25 cycles, it might be possible to improve by pipelining the work item.
