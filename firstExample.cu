#include <iostream>
#include <stdlib.h>     /* srand, rand */
#include <time.h>       /* time */

using namespace std;

#define N 100

#define M 10

void randomsInt(int *f)
{
    for(int i=0;i<N;++i)
        f[i]=rand() % 100 + 1;
}

__global__ void add(int *a, int *b, int *c)
{
    int index = threadIdx.x + blockIdx.x * blockDim.x;
    if (index < N)
        c[index] = a[index] + b[index];
}

int main()
{
	srand (time(NULL));
	int *a, *b, *c;
	int *d_a, *d_b, *d_c;
	int size = N * sizeof(int);


	cudaMalloc((void **)&d_a,size);
	cudaMalloc((void **)&d_b,size);
	cudaMalloc((void **)&d_c,size);

	
	a = (int *)malloc(size); randomsInt(a);
	b = (int *)malloc(size); randomsInt(b);
	c = (int *)malloc(size); 


	cudaMemcpy(d_a,a, size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, b, size, cudaMemcpyHostToDevice);

        add<<<(N + M-1) / M,M>>>(d_a,d_b,d_c);

	cudaMemcpy(c,d_c, size, cudaMemcpyDeviceToHost);

	
        cudaFree(d_a);cudaFree(d_b);cudaFree(d_c);

        for (int i=0;i<N;++i){
            cout<<a[i]<<"\t";
            cout<<b[i]<<"\t";
            cout<<c[i]<<"\n";
        }


	free(a); free(b); free(c);


	return 0;
}
