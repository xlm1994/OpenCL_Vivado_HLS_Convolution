#include <clc.h>
#define IMAGE_W 128
#define IMAGE_H 128

#define WKGRP_W 128
#define WKGRP_H 128

#define FILTER_SIZE 5
#define HALF_FILTER_SIZE (FILTER_SIZE-1)/2

#define BUFFER_W (WKGRP_W+FILTER_SIZE-1)
#define BUFFER_H (WKGRP_H+FILTER_SIZE-1)

#define data_t float

void get_row(const global data_t* arr, data_t* out, int line){
	#ifdef __xilinx__
	__attribute__ ((xcl_pipeline_loop))
	#endif
	for (int i = 0; i < BUFFER_W; i++){
		out[i] = arr[line*BUFFER_W+i];
	}
}

void filter(const global data_t* input, global data_t* output, constant data_t* filter, int row)
{
	data_t buffer[FILTER_SIZE][BUFFER_W] = {};

	#ifdef __xilinx__
	__attribute__ ((xcl_pipeline_loop))
	#endif
	for (int i = 0; i < FILTER_SIZE; i++){
		get_row(input, buffer[i], row+i);
	}

	data_t output_buf[IMAGE_W];
	#ifdef __xilinx__
	__attribute__ ((xcl_pipeline_loop))
	#endif
	for (int col = 0; col < IMAGE_W; col++){
		data_t sum = 0.0;

		for (int r = 0; r < FILTER_SIZE; r++){
			for (int c = 0; c < FILTER_SIZE; c++)
			{
				int filt_ind = r*FILTER_SIZE+c;
//				sum_arr[filt_ind+1] = buffer[r][col+c] * filter[filt_ind] + sum_arr[filt_ind];
				sum += buffer[r][col+c] * filter[filt_ind];
			}
		}

//		output_buf[col] = sum_arr[FILTER_SIZE*FILTER_SIZE];
		output_buf[col] = sum;
	}

	#ifdef __xilinx__
	__attribute__ ((xcl_pipeline_loop))
	#endif
	for (int col = 0; col < IMAGE_W; col++){
		output[col+row*IMAGE_W] = output_buf[col];
	}
}


__kernel void  __attribute__ ((reqd_work_group_size(128, 1, 1)))
convolve(
	const __global data_t* input,
	__global data_t* output,
	__constant data_t* filter_params
){
	int ind = get_global_id(0);
	filter(input, output, filter_params, ind);
}

