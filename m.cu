#include <iostream>
#include <stdlib.h>     /* srand, rand */
#include <time.h>       /* time */

using namespace std;

#define filas 10

#define columnas 10

#define N filas*columnas

#define M filas*columnas


void randomsInt(int *f)
{
    for(int i=0;i<filas;++i)
	for(int j=0;j<columnas;++j)
            f[(i*filas)+j]=rand() % 10 + 1;
}


__global__ void add(int* a, int* b, int* c)
{
    int index = threadIdx.x + blockIdx.x * blockDim.x;
    //int index = threadIdx.x + blockIdx.x * blockDim.x;
    if (index < N){
	int count=0;
	for (int i=0;i<filas;++i){
        	count += a[(((int)(index/filas))*filas)+i] * b[(i*filas)+(index%filas)];
	}
	c[index]=count;
   }
}

void printMatrix(int * a){

	for (int i=0;i<filas;++i){
	    for (int j=0;j<columnas;++j)
  	          cout<<a[(i*filas)+j]<<"\t";
//            cout<<b[i]<<"\t";
            //cout<<c[i]<<"\n";
	    cout<<endl;
        }
}



int main()
{
	cout<<(int)(5/filas)<<endl;
	srand (time(NULL));
	int *a, *b, *c;

	int *d_a, *d_b, *d_c;

	int size = filas*columnas * sizeof(int);
	
	cudaMalloc((void **)&d_a,size);
	cudaMalloc((void **)&d_b,size);
	cudaMalloc((void **)&d_c,size);


	a = (int *)malloc(size); randomsInt(a);
	b = (int *)malloc(size); randomsInt(b);
	c = (int *)malloc(size);


	cudaMemcpy(d_a, a, size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, b, size, cudaMemcpyHostToDevice);

        add<<<(N + M-1) / M,M>>>(d_a,d_b,d_c);

	cudaMemcpy(c,d_c, size, cudaMemcpyDeviceToHost);

	
        cudaFree(d_a);cudaFree(d_b);cudaFree(d_c);

        cout<<"----A----"<<endl;
	printMatrix (a);
cout<<"----B----"<<endl;

	printMatrix (b);
cout<<"----c----"<<endl;
	printMatrix (c);

	//free(a); free(b); free(c);


	return 0;
}
