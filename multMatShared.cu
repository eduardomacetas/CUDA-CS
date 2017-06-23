#include <iostream>
#include <stdlib.h>     /* srand, rand */
#include <time.h>       /* time */

using namespace std;

#define row 5
#define column 5

#define threadsPB 4


void randomsInt(double **& matrix)
{
    for(int i=0;i<row;++i){
	for(int j=0;j<column;++j)
            matrix[i][j]=rand() % 10 + 1;
    }
}

void createMatrixHostCUDA(double**& host, double**& device, double **& aux, int size, int r, int c ){
    host = (double **)malloc(r*sizeof(double*));
    host[0]=(double *)malloc(size);


    aux =(double **)malloc(r*sizeof(double*));
    cudaMalloc((void **)&aux[0],size);
 
    cudaMalloc((void **)&device,r*sizeof(double*));
//    cudaMalloc((void **)&(device[0]),size);

    for (int i=1; i<r;++i){
	host[i]=host[i-1]+c;
	aux[i]=aux[i-1]+c;

    }

    cudaMemcpy(device, aux, r*sizeof(double*), cudaMemcpyHostToDevice);
    

}


__global__ void MatAdd(double ** A, double ** B,double ** C) {
     

     int gIndexX= threadIdx.x  + blockIdx.x * blockDim.x;
     int gIndexY = threadIdx.y + blockIdx.y * blockDim.y;
     
     

     int lIndexX= threadIdx.x;
     int lIndexY = threadIdx.y;


     __shared__ int tempA[threadsPB][threadsPB], tempB[threadsPB][threadsPB];
   

     // Read input elements into shared memory

     if (gIndexX < row && gIndexY < column) {

	    tempA[lIndexX][lIndexY] = A[gIndexX][gIndexY];
	    tempB[lIndexX][lIndexY] = B[gIndexX][gIndexY];

	
     }

    // Synchronize (ensure all the data is available)
    __syncthreads();


    // Apply the stencil
  

    if (gIndexX <row && gIndexY <column){
	double count=0;
	for (int i=0;i<threadsPB;++i){
	    count+= tempA[lIndexX][i] * tempB[i][lIndexY];
	}

	C[lIndexX][lIndexY]= count;
	
    }



    /*if (gIndexX <row && gIndexY <column){
	double count=0;
	for (int i=0;i<row;++i){
	    count+= A[gIndexX][i] * B[i][gIndexY];
	}

	C[gIndexX][gIndexY]= count;
	
    }*/

}


void print(double ** a){
	for(int i=0;i<row;++i){
	    for(int j=0;j<column;++j)
            cout<<a[i][j]<<'\t';
	cout<<endl;
    }
	cout<<endl;
}


int main()
{
	srand (time(NULL));
	double **a, **b, **c;

	double **d_a, **d_b, **d_c;


	double **a_aux, **b_aux, **c_aux;
	

	
	int size = row* column * sizeof(double*);

	
	createMatrixHostCUDA(a,d_a,a_aux,size,row,column);
	createMatrixHostCUDA(b,d_b,b_aux,size,row,column);
	createMatrixHostCUDA(c,d_c,c_aux,size,row,column);


	randomsInt(a);randomsInt(b);
	

	cudaMemcpy(a_aux[0], a[0], size, cudaMemcpyHostToDevice);
	cudaMemcpy(b_aux[0], b[0], size, cudaMemcpyHostToDevice);
	
	dim3 threadPerBlock(threadsPB, threadsPB);
	dim3 blockPerGrid((row+threadPerBlock.x-1)/threadPerBlock.x,(column+threadPerBlock.y-1)/threadPerBlock.y);
        
        MatAdd<<<blockPerGrid,threadPerBlock>>>(d_a,d_b,d_c);

	
	cudaMemcpy(c[0],c_aux[0], size, cudaMemcpyDeviceToHost);
	

	cudaFree(d_a);cudaFree(d_b);cudaFree(d_c);
	cudaFree(a_aux[0]);cudaFree(b_aux[0]);cudaFree(c_aux[0]);


        cout<<"----A----"<<endl;
	print (a);

        cout<<"----B----"<<endl;
	print (b);

	cout<<"----c----"<<endl;
	print(c);


	free(a); free(b); free(c);


	return 0;
}


