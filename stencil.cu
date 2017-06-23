#include <iostream>
#include <stdlib.h>     /* srand, rand */
#include <time.h>       /* time */

using namespace std;

#define N 100000

#define BLOCK_SIZE 32

#define RADIUS 3


void randomsInt(int *f)
{
    for(int i=0;i<N;++i)
        f[i]=rand() % 10 + 1;
}


__global__ void stencil_1d(int *in, int *out) {
     __shared__ int temp[BLOCK_SIZE + 2 * RADIUS];
     int gindex = threadIdx.x + blockIdx.x * blockDim.x;
     int lindex = threadIdx.x + RADIUS;
     // Read input elements into shared memory
     temp[lindex] = in[gindex];
     if (threadIdx.x < RADIUS) {
     	temp[lindex - RADIUS] = in[gindex - RADIUS];
     	temp[lindex + BLOCK_SIZE] = in[gindex + BLOCK_SIZE];
     }

    // Synchronize (ensure all the data is available)
    __syncthreads();

    // Apply the stencil
    int result = 0;
    for (int offset = -RADIUS ; offset <= RADIUS ; offset++)
     result += temp[lindex + offset];
    // Store the result
    out[gindex] = result;
}

void serial (int *in, int *out){
	
	for(int i=RADIUS;i<N-RADIUS;++i){
	     int suma=0;
	     for(int j=i-RADIUS;j<=i+RADIUS;++j)
		 suma+=in[j];
	    out[i]=suma;
	}

}


void print(int * a){
	for (int i=0;i<N;++i){
	    cout<<a[i]<<"\t";
        }
	cout<<endl;
}


int main()
{
	srand (time(NULL));
	int *a, *c, *outserial;

	int *d_a, *d_c;

	int size = N * sizeof(int);
	
	cudaMalloc((void **)&d_a,size);

	cudaMalloc((void **)&d_c,size);


	a = (int *)malloc(size); randomsInt(a);
	c = (int *)malloc(size);
	outserial=(int *)malloc(size);


	cudaMemcpy(d_a, a, size, cudaMemcpyHostToDevice);


	cudaEvent_t start,stop;

	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	
	cudaEventRecord(start);
        stencil_1d<<<(N + BLOCK_SIZE-1) / BLOCK_SIZE,BLOCK_SIZE>>>(d_a,d_c);

	cudaEventRecord(stop);

	float timeCUDA;
	cudaEventElapsedTime(&timeCUDA, start,stop);
	cout<<timeCUDA<<endl;


	cudaMemcpy(c,d_c, size, cudaMemcpyDeviceToHost);

	
        cudaFree(d_a);cudaFree(d_c);


	clock_t tSerial=clock();

	
	serial(a,outserial);

	tSerial=clock()-tSerial;
	cout<<"serial: "<< (double) tSerial/CLOCKS_PER_SEC <<endl;


        /*cout<<"----A----"<<endl;
	print (a);
	cout<<"----c----"<<endl;
	print(c);


	cout<<"----SERIAL----"<<endl;
	print(outserial);
*/
	free(a); free(c);


	return 0;
}
