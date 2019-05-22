#define IMAGE_W 128
#define IMAGE_H 128
#define LENGTH IMAGE_W*IMAGE_H
#define FILTER_SIZE 5
#define HALF_FILTER_SIZE (FILTER_SIZE-1)/2

#define data_t float

#include <stdio.h>

void convolve_sw(data_t* input, data_t* output, data_t* filter);
data_t get(data_t* arr, int row, int col);

int main(int argc, char** argv)
{
	int errors=0, i;
	data_t hw_c[LENGTH] = {0};
	data_t sw_c[LENGTH];
	data_t filter[5*5];


	for (i=0; i<25; i++){
		filter[i] = (data_t)1/25;
	}

	data_t input[] = {
        #include "lena128pad.txt"
    };
	data_t sw_input[] = {
        #include "lena128.txt"
    };
	// Create input stimuli and compute the expected result
	convolve_sw(sw_input, sw_c, filter);

	// Call the OpenCL C simulation run kernel
	//
	hls_run_kernel("convolve", input, 132*132, hw_c, LENGTH, filter, FILTER_SIZE*FILTER_SIZE);
	// Check the results against the expected results
	for (i=0; i<LENGTH; i++) {
        if(-2 > hw_c[i] - sw_c[i] || hw_c[i] - sw_c[i] > 2)
            errors+=1;
	}
	printf("There are %d error(s) -> test %s\n", errors, errors ? "FAILED" : "PASSED");
	// Return a 0 if the results are correct
	return errors;
}

void convolve_sw(data_t* input, data_t* output, data_t* filter){
	for(int row = 0; row < IMAGE_H; row++){
		for(int col = 0; col < IMAGE_W; col++){
			int my = col + row*IMAGE_W;
			float sum = 0.0;
			for (int r = -HALF_FILTER_SIZE; r <= HALF_FILTER_SIZE; r++){
				int filter_row_offset = (r + HALF_FILTER_SIZE)*FILTER_SIZE + HALF_FILTER_SIZE;

				for (int c = -HALF_FILTER_SIZE; c <= HALF_FILTER_SIZE; c++)
				{
					int filt_ind = filter_row_offset + c;

					sum += get(input, row+r, col+c) * filter[ filt_ind ];
				}
			}
			output[my] = sum;
		}
	}

}
data_t get(data_t* arr, int row, int col){
	if(row < 0 || row >= IMAGE_H || col < 0 || col >= IMAGE_W)
		return 0.0;
	else
		return arr[row*IMAGE_W + col];
}
