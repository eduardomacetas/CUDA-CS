#include <iostream>
#include <stdlib.h>     /* srand, rand */
#include <time.h>       /* time */

using namespace std;

#define row 4
#define column 4

#define threadsPB 16


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
     
     //printf("asdfas ");
     int i= threadIdx.x  + blockIdx.x * blockDim.x;
     int j = threadIdx.y + blockIdx.y * blockDim.y;

     if (i <row && j <column){
	C[i][j]= A[i][j] + B[i][j];

//       printf("i: %i\t j: %i\n" ,i,j );
       printf("1: %f \n " ,C[i][j] );
//       printf("2: %f \n" ,A[i][j] );
     
	
     }
     
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


