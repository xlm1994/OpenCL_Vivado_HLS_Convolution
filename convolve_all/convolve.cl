//#include <clc.h>
#define IMAGE_W 128
#define IMAGE_H 128

#define WKGRP_W 128
#define WKGRP_H 128

#define FILTER_SIZE 5
#define HALF_FILTER_SIZE (FILTER_SIZE-1)/2

#define BUFFER_W (WKGRP_W+FILTER_SIZE-1)
#define BUFFER_H (WKGRP_H+FILTER_SIZE-1)

#define data_t float

void get_row(const global data_t* arr, data_t out[BUFFER_W], int line){
	#ifdef __xilinx__
	__attribute__ ((xcl_pipeline_loop))
	#endif
	for (int i = 0; i < BUFFER_W; i++){
		out[i] = arr[line*BUFFER_W+i];
	}
}

int update(data_t buffer[FILTER_SIZE][BUFFER_W], int start_line, const global data_t* arr, int line){
	get_row(arr, buffer[start_line],line);
	return start_line+1 == FILTER_SIZE ? 0 : start_line+1;
}

data_t get_buffer(data_t buffer[FILTER_SIZE][BUFFER_W], int start_line, int r, int c){
	int row = r+start_line>=FILTER_SIZE ? r+start_line-FILTER_SIZE : r+start_line;

	return buffer[row][c];
}

void filter(const global data_t* input, global data_t* output, constant data_t* filter)
{
	data_t buffer[FILTER_SIZE][BUFFER_W] = {};
	int start_line = FILTER_SIZE-1;

	#ifdef __xilinx__
	__attribute__ ((xcl_pipeline_loop))
	#endif
	for (int i = 0; i < FILTER_SIZE-1; i++){
		get_row(input, buffer[i], i);
	}
	#ifdef __xilinx__
	__attribute__ ((xcl_pipeline_loop))
	#endif
	for (int row = 0; row < IMAGE_H; row++){
		start_line = update(buffer, start_line, input, row+FILTER_SIZE-1);

        data_t output_buf[IMAGE_W];
		data_t sum_arr[FILTER_SIZE*FILTER_SIZE+1]={};
		for (int col = 0; col < IMAGE_W; col++){
			for (int r = 0; r < FILTER_SIZE; r++){
				for (int c = 0; c < FILTER_SIZE; c++)
				{
					int filt_ind = r*FILTER_SIZE+c;
					sum_arr[filt_ind+1] = get_buffer(buffer, start_line, r, col+c) * filter[filt_ind] + sum_arr[filt_ind];
				}
			}

			output_buf[col] = sum_arr[FILTER_SIZE*FILTER_SIZE];
		}

		for (int col = 0; col < IMAGE_W; col++){
			output[col+row*IMAGE_W] = output_buf[col];
		}
	}
}


__kernel void  __attribute__ ((reqd_work_group_size(1, 1, 1)))
convolve(
	const __global data_t* input,
	__global data_t* output,
	__constant data_t* filter_params
){
	filter(input, output, filter_params);
}

