#include <clc.h>
#define IMAGE_W 128
#define IMAGE_H 128

#define WKGRP_W 128
#define WKGRP_H 128

#define BUFFER_W (WKGRP_W+FILTER_SIZE-1)
#define BUFFER_H (WKGRP_H+FILTER_SIZE-1)

#define FILTER_SIZE 5
#define HALF_FILTER_SIZE (FILTER_SIZE-1)/2

#define data_t float

void load_buffer(
		global data_t *input,
		const int x_group,
		const int y_group,
		local data_t (*img_buffer)[BUFFER_W])
{
	#ifdef __xilinx__
	__attribute__ ((xcl_pipeline_loop))
	#endif
	for (int i = (y_group-1)*WKGRP_H; i < (y_group-1)*WKGRP_H+BUFFER_H; i++){
		for (int j = (x_group-1)*WKGRP_W; j < (x_group-1)*WKGRP_W+BUFFER_W; j++){
			img_buffer[i][j] = input[j+i*BUFFER_W];
		}
	}
}

void filter(
		const local data_t (*buffer)[BUFFER_W],
		constant data_t* filter,
		const int x,
		const int y,
		global data_t *output)
{
	data_t sum = 0.0;

	#ifdef __xilinx__
	__attribute__ ((xcl_pipeline_loop))
	#endif
	for (int r = 0; r < FILTER_SIZE; r++){
		for (int c = 0; c < FILTER_SIZE; c++)
		{
			int filt_ind = r*FILTER_SIZE+c;
			sum += buffer[y%WKGRP_H+r][x%WKGRP_W+c] * filter[filt_ind];
		}
	}

	output[x+y*IMAGE_W] = sum;
}


__kernel void  __attribute__ ((reqd_work_group_size(WKGRP_W, WKGRP_H, 1)))
convolve(
	const __global data_t* input,
	__global data_t* output,
	__constant data_t* filter_params
){
	__local int x_group, y_group;
	__local data_t img_buffer[BUFFER_H][BUFFER_W];

	if (x_group != get_global_id(0)/WKGRP_W+1 || y_group != get_global_id(1)/WKGRP_H+1){
		int x_group = get_global_id(0)/WKGRP_W+1;
		int y_group = get_global_id(1)/WKGRP_H+1;

		load_buffer(input, x_group, y_group, img_buffer);
	}

	barrier(CLK_LOCAL_MEM_FENCE);

	__attribute__((xcl_pipeline_workitems)){
	filter(img_buffer, filter_params, get_global_id(0), get_global_id(1), output);
	}
}

