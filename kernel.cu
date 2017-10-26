#include "cuda.h"
#include "../common/book.h"
#include "../common/cpu_anim.h"

#define DIM 1024
#define PI 3.1415926535897932f

__global__ void kernel(int* dev_init, int* dev_output) {

		int alive = 0;
		if (blockIdx.y - 1 >= 0)
		{
			if (dev_init[(blockIdx.y - 1)*(DIM / 16) + blockIdx.x] == 1) alive++;

			if (blockIdx.x + 1 < (DIM / 16))
			{
				if (dev_init[(blockIdx.y - 1)*(DIM / 16) + blockIdx.x + 1] == 1) alive++;
			}
		}
		if (blockIdx.y + 1 < (DIM / 16))
		{
			if (dev_init[(blockIdx.y + 1)*(DIM / 16) + blockIdx.x] == 1) alive++;

			if (blockIdx.x - 1 >= 0)
			{
				if (dev_init[(blockIdx.y + 1)*(DIM / 16) + blockIdx.x - 1] == 1) alive++;
			}
		}
		if (blockIdx.x - 1 >= 0)
		{
			if (dev_init[blockIdx.y*(DIM / 16) + blockIdx.x - 1] == 1) alive++;

			if (blockIdx.y - 1 >= 0)
			{
				if (dev_init[(blockIdx.y - 1)*(DIM / 16) + blockIdx.x - 1] == 1) alive++;
			}
		}
		if (blockIdx.x + 1 < (DIM / 16))
		{
			if (dev_init[blockIdx.y*(DIM / 16) + blockIdx.x + 1] == 1) alive++;

			if (blockIdx.y + 1 < (DIM / 16))
			{
				if (dev_init[(blockIdx.y + 1)*(DIM / 16) + blockIdx.x + 1] == 1) alive++;
			}
		}

		//判断alive个数
		if (dev_output[blockIdx.y*(DIM / 16) + blockIdx.x] == 1) {
			if (alive < 2)
			{
				dev_output[blockIdx.y*(DIM / 16) + blockIdx.x] = 0;
			}
			else if (alive < 4)
			{
				dev_output[blockIdx.y*(DIM / 16) + blockIdx.x] = 1;
			}
			else
			{
				dev_output[blockIdx.y*(DIM / 16) + blockIdx.x] = 0;
			}
		}
		else if (dev_output[blockIdx.y*(DIM / 16) + blockIdx.x] == 0)
		{
			if (alive == 3)
			{
				dev_output[blockIdx.y*(DIM / 16) + blockIdx.x] = 1;
			}
		}
	

}

__global__ void kernelShow(unsigned char *ptr, int ticks, int* dev_init)
{
	//计算像素点坐标
	int x = threadIdx.x + blockIdx.x * blockDim.x;
	int y = threadIdx.y + blockIdx.y * blockDim.y;
	int offset = x + y * blockDim.x * gridDim.x;

	__shared__ int  shared[16][16];

	//绘制当前图形
	if (dev_init[blockIdx.y*(DIM / 16) + blockIdx.x] == 1)
		shared[threadIdx.x][threadIdx.y] = 1;
	else
		shared[threadIdx.x][threadIdx.y] = 0;
	__syncthreads();

	//方块边框
	if (threadIdx.x == 0 || threadIdx.y == 0 || threadIdx.x == 15 || threadIdx.y == 15)
		shared[threadIdx.x][threadIdx.y] = 0;

	//绘制方块波纹动态
	float fx = x - DIM / 2;
	float fy = y - DIM / 2;
	float d = sqrtf(fx * fx + fy * fy);
	unsigned char grey = (unsigned char)(128.0f + 127.0f *
		cos(d / 10.0f - ticks / 7.0f) /
		(d / 10.0f + 1.0f));
	
	//输出
	ptr[offset * 4 + 0] = shared[15 - threadIdx.x][15 - threadIdx.y] * 255;
	ptr[offset * 4 + 1] = shared[15 - threadIdx.x][15 - threadIdx.y] * grey;
	ptr[offset * 4 + 2] = 0;
	ptr[offset * 4 + 3] = 255;


}


struct DataBlock {
	unsigned char   *dev_bitmap;
	CPUAnimBitmap  *bitmap;
	int* dev_init;
	int* dev_output;
};

void generate_frame(DataBlock *d, int ticks) {

	dim3    blocks(DIM / 16, DIM / 16);
	dim3    threads(16, 16);

	//绘制图形
	kernelShow << <blocks, threads >> >(d->dev_bitmap, ticks, d->dev_init);

	HANDLE_ERROR(cudaMemcpy(d->bitmap->get_ptr(),
		d->dev_bitmap,
		d->bitmap->image_size(),
		cudaMemcpyDeviceToHost));

	if (ticks > 100) {
		if (ticks % 10 == 0)
		{
			kernel << <blocks, 1 >> > (d->dev_init, d->dev_output);
			HANDLE_ERROR(cudaMemcpy(d->dev_init, d->dev_output, DIM / 16 * DIM / 16 * sizeof(int), cudaMemcpyDeviceToDevice));
		}
	}

}

// clean up memory allocated on the GPU
void cleanup(DataBlock *d) {
	HANDLE_ERROR(cudaFree(d->dev_bitmap));
	HANDLE_ERROR(cudaFree(d->dev_init));
	HANDLE_ERROR(cudaFree(d->dev_output));
}

int main(void) {
	DataBlock   data;
	CPUAnimBitmap  bitmap(DIM, DIM, &data);
	data.bitmap = &bitmap;

	int  *initdata;
	initdata = new int[(DIM / 16) *(DIM / 16)];
	memset(initdata, 0, (DIM / 16) * (DIM / 16) * sizeof(int));
	HANDLE_ERROR(cudaMalloc((void**)&data.dev_bitmap, bitmap.image_size()));


	//初始化数组
	/*initdata[(16)*(DIM / 16) + (16)] = 1;
	initdata[(16)*(DIM / 16) + (15)] = 1;
	initdata[(16)*(DIM / 16) + (17)] = 1;
	initdata[(15)*(DIM / 16) + (16)] = 1;
	initdata[(17)*(DIM / 16) + (16)] = 1;
	initdata[(17)*(DIM / 16) + (17)] = 1;
	initdata[(15)*(DIM / 16) + (15)] = 1;
	initdata[(15)*(DIM / 16) + (17)] = 1;
	initdata[(17)*(DIM / 16) + (15)] = 1;*/   //9X9正方形

	/*initdata[(16)*(DIM / 16) + (16)] = 1;
	initdata[(16)*(DIM / 16) + (15)] = 1;
	initdata[(16)*(DIM / 16) + (17)] = 1;
	initdata[(15)*(DIM / 16) + (16)] = 1;
	initdata[(17)*(DIM / 16) + (16)] = 1;*/     //十字


	initdata[(32)*(DIM / 16) + (16)] = 1;
	initdata[(32)*(DIM / 16) + (17)] = 1;
	initdata[(32)*(DIM / 16) + (18)] = 1;
	initdata[(32)*(DIM / 16) + (19)] = 1;
	initdata[(32)*(DIM / 16) + (20)] = 1;
	initdata[(32)*(DIM / 16) + (21)] = 1;
	initdata[(32)*(DIM / 16) + (22)] = 1;
	initdata[(32)*(DIM / 16) + (23)] = 1;
	initdata[(32)*(DIM / 16) + (24)] = 1;

	initdata[(32)*(DIM / 16) + (29)] = 1;
	initdata[(32)*(DIM / 16) + (30)] = 1;
	initdata[(32)*(DIM / 16) + (31)] = 1;
	initdata[(32)*(DIM / 16) + (32)] = 1;
	initdata[(32)*(DIM / 16) + (33)] = 1;
	initdata[(32)*(DIM / 16) + (34)] = 1;
	initdata[(32)*(DIM / 16) + (35)] = 1;
	initdata[(32)*(DIM / 16) + (36)] = 1;
	initdata[(32)*(DIM / 16) + (37)] = 1;
	initdata[(32)*(DIM / 16) + (38)] = 1;

	initdata[(32)*(DIM / 16) + (44)] = 1;
	initdata[(32)*(DIM / 16) + (45)] = 1;
	initdata[(32)*(DIM / 16) + (46)] = 1;


	HANDLE_ERROR(cudaMalloc((void**)&data.dev_init, DIM / 16 * DIM / 16 * sizeof(int)));
	HANDLE_ERROR(cudaMalloc((void**)&data.dev_output, DIM / 16 * DIM / 16 * sizeof(int)));

	HANDLE_ERROR(cudaMemcpy(data.dev_init, initdata, DIM / 16 * DIM / 16 * sizeof(int), cudaMemcpyHostToDevice));
	HANDLE_ERROR(cudaMemcpy(data.dev_output, initdata, DIM / 16 * DIM / 16 * sizeof(int), cudaMemcpyHostToDevice));

	bitmap.anim_and_exit((void(*)(void*, int))generate_frame,
		(void(*)(void*))cleanup);
}
