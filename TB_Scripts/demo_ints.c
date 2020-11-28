// Peter Milder
// ESE 587 Hardware Architectures for Deep Learning
// Reference code for "CLP-Nano" design

// Description:
// This C code will serve as a demonstration of the function of the "CLP-Nano" design
// presented as part of Topic 11. Please see Topic 11 slides for more information.

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

void CV(int height,int M, int N);
void PW(int height, int M, int N);

int main()
{
	
    //CV(int height,int M, int N);
    CV(30, 4, 4);
    PW( 3,  2,  4);
	
	return 0;
}

void CV(int height,int M, int N)
{
    
	// -----------------------------------------------------------
	// Arguments

	//int N = 4;  //iFM depth
	//int M = 16;  //oFM depth
	int R;// = 3;  //oFM dimension
	int C;// = 3;  //oFM dimension
	int S = 1;
	int K = 3;  //Kernel square dimension
    

    int r = height + 2;// iFM Rows
    int c = height + 2;// iFM columns
    
    //I got sick of working backwards and defined output by first defining inputs
    // like how i do in the verilog code
    R = r - K + 1;
    C = c - K + 1;
    
	int RPrime = (R-1)*S+K;
	int CPrime = (C-1)*S+K;

	if ((N<=0) || (M<=0) || (R<=0) || (C<=0) || (S<=0) || (K<=0)) {
		printf("ERROR: 0 or negative parameter\n");
		return(1);
	}
		
	// ------------------------------------------------------------
	// Declare data structures that will reside in off chip memory.
	// Note: if these get too large, you will eventually run out of space
	// on your stack, and this will cause a segmentation fault. A more flexible
	// approach would be to use malloc and store this data on the heap.
	int I[N][RPrime][CPrime];
	int O[M][R][C];
	int B[M];
	int W[M][N][K][K];

	// -----------------------------------------------------------
	// Declare data structures that will reside in BRAM in your hardware
	// design. These will be accessible to your CLP-Lite hardware system
	int Ibuf[RPrime][CPrime];
	int Wbuf[K][K];
	int Obuf[R][C];
	int Bbuf;


	// -----------------------------------------------------------
	// As an example, we will generate random inputs, weights, and bias.
	// We will also store these and the parameters to a text file (to
	// make it easy to later verify the correctness of this design)
	FILE *ip, *op;
	ip = fopen("ip_cv.txt", "w");

	fprintf(ip, "N %d\nM %d\nR %d\nC %d\nS %d\nK %d\n", N, M, R, C, S, K);

	// Init. RNG
	srand((unsigned int)time(NULL));
    int temp = 2;
	// Generate random test inputs
	for (int n=0; n<N; n++) {
		for (int r=0; r<RPrime; r++) {
			for (int c=0; c<CPrime; c++) {
				I[n][r][c] = (float)temp;
				fprintf(ip, "iFM %.20f\n", I[n][r][c]);
				temp++;
			}
		}
	}
	
	temp = 1;
	// Generate random weights
	for (int m=0; m<M; m++)
		for (int n=0; n<N; n++)
			for (int i=0; i<K; i++)
				for (int j=0; j<K; j++) {
					W[m][n][i][j] =  (float)temp;
					fprintf(ip, "weight %.20f\n", W[m][n][i][j]);
					temp++;
				}
		
	// Generate random biases
	for (int m=0; m<M; m++) {
		B[m] = 0;
		fprintf(ip, "BIAS %.20f\n", B[m]);
	}

	fclose(ip);

	// --------------------------------------------------------------
	// Main loops
	for (int m=0; m<M; m++) {

		// Copy this output's bias value to bias buffer
		Bbuf = B[m];
		
		for (int n=0; n<N; n++) {

			// Copy the current input feature map to the
			// input buffer. 
			for (int rr=0; rr<RPrime; rr++) {     
				for (int cc=0; cc<CPrime; cc++) {
					Ibuf[rr][cc] = I[n][rr][cc];
				}
			}

			// Copy this feature map's weights into Wbuf
			for (int i=0; i<K; i++) {
				for (int j=0; j<K; j++) {
					Wbuf[i][j] = W[m][n][i][j];
				}
			}

			// -------------------------------------------------
			// Begin hardware functionality. Your HW system should do
			// do the following operations
			for (int i=0; i<K; i++) {
				for (int j=0; j<K; j++) {
					for (int rr=0; rr<R; rr++) {
						for (int cc=0; cc<C; cc++) {
							float t1 = Wbuf[i][j] * Ibuf[S*rr+i][S*cc+j];

							// mux: if i==0, j==0, and n==0 we need to add bias.
							// otherwise, we accumulate
							float t2 = (i==0 && j==0 && n==0) ? Bbuf : Obuf[rr][cc];
							Obuf[rr][cc] = t1 + t2;	
							//printf("%f + %f = %f\n",t1,t2, Obuf[rr][cc]);
						}				
					}
				}
			}
			// End hardware functionality
			// ---------------------------------------------------
		}

		// Read data from Obuf and store it into main memory O buffer
		// Note again we have to check that we don't go past the end of
		// the O buffer
		for (int rr=0; rr < R; rr++) {
			for (int cc=0; cc < C; cc++) {
				O[m][rr][cc] = Obuf[rr][cc];
			}
		}
	}
    int  i = 0;
	// ---------------------------------------------------
	// Store results to text file for easy checking.
	// Write the results to op.txt
	op = fopen("op_cv.txt", "w");
	for (int m=0; m<M; m++)
		for (int r=0; r<R; r++)
			for (int c=0; c<C; c++)
			    {
				    fprintf(op,"%d: %d\n",i , O[m][r][c]);
				    i++;
                }

	fclose(op);
}

void PW(int height, int M, int N)
{
    
	// -----------------------------------------------------------
	// Arguments

	//int N = 4;  //iFM depth
	//int M = 16;  //oFM depth
	int R;// = 3;  //oFM dimension
	int C;// = 3;  //oFM dimension
	int S = 1;
	int K = 1;  //Kernel square dimension
    

    int r = height;// iFM Rows
    int c = height;// iFM columns
    
    //I got sick of working backwards and defined output by first defining inputs
    // like how i do in the verilog code
    R = r - K + 1;
    C = c - K + 1;
    
	int RPrime = (R-1)*S+K;
	int CPrime = (C-1)*S+K;

	if ((N<=0) || (M<=0) || (R<=0) || (C<=0) || (S<=0) || (K<=0)) {
		printf("ERROR: 0 or negative parameter\n");
		return(1);
	}
		
	// ------------------------------------------------------------
	// Declare data structures that will reside in off chip memory.
	// Note: if these get too large, you will eventually run out of space
	// on your stack, and this will cause a segmentation fault. A more flexible
	// approach would be to use malloc and store this data on the heap.
	int I[N][RPrime][CPrime];
	int O[M][R][C];
	int B[M];
	int W[M][N][K][K];

	// -----------------------------------------------------------
	// Declare data structures that will reside in BRAM in your hardware
	// design. These will be accessible to your CLP-Lite hardware system
	int Ibuf[RPrime][CPrime];
	int Wbuf[K][K];
	int Obuf[R][C];
	int Bbuf;


	// -----------------------------------------------------------
	// As an example, we will generate random inputs, weights, and bias.
	// We will also store these and the parameters to a text file (to
	// make it easy to later verify the correctness of this design)
	FILE *ip, *op;
	ip = fopen("ip_pw.txt", "w");

	fprintf(ip, "N %d\nM %d\nR %d\nC %d\nS %d\nK %d\n", N, M, R, C, S, K);

	// Init. RNG
	srand((unsigned int)time(NULL));
    int temp = 2;
	// Generate random test inputs
	for (int n=0; n<N; n++) {
		for (int r=0; r<RPrime; r++) {
			for (int c=0; c<CPrime; c++) {
				I[n][r][c] = (float)temp;
				fprintf(ip, "iFM %.20f\n", I[n][r][c]);
				temp++;
			}
		}
	}
	
	temp = 1;
	// Generate random weights
	for (int m=0; m<M; m++)
		for (int n=0; n<N; n++)
			for (int i=0; i<K; i++)
				for (int j=0; j<K; j++) {
					W[m][n][i][j] =  (float)temp;
					fprintf(ip, "weight %.20f\n", W[m][n][i][j]);
					temp++;
				}
		
	// Generate random biases
	for (int m=0; m<M; m++) {
		B[m] = 0;
		fprintf(ip, "BIAS %.20f\n", B[m]);
	}

	fclose(ip);

	// --------------------------------------------------------------
	// Main loops
	for (int m=0; m<M; m++) {

		// Copy this output's bias value to bias buffer
		Bbuf = B[m];
		
		for (int n=0; n<N; n++) {

			// Copy the current input feature map to the
			// input buffer. 
			for (int rr=0; rr<RPrime; rr++) {     
				for (int cc=0; cc<CPrime; cc++) {
					Ibuf[rr][cc] = I[n][rr][cc];
				}
			}

			// Copy this feature map's weights into Wbuf
			for (int i=0; i<K; i++) {
				for (int j=0; j<K; j++) {
					Wbuf[i][j] = W[m][n][i][j];
				}
			}

			// -------------------------------------------------
			// Begin hardware functionality. Your HW system should do
			// do the following operations
			for (int i=0; i<K; i++) {
				for (int j=0; j<K; j++) {
					for (int rr=0; rr<R; rr++) {
						for (int cc=0; cc<C; cc++) {
							float t1 = Wbuf[i][j] * Ibuf[S*rr+i][S*cc+j];

							// mux: if i==0, j==0, and n==0 we need to add bias.
							// otherwise, we accumulate
							float t2 = (i==0 && j==0 && n==0) ? Bbuf : Obuf[rr][cc];
							Obuf[rr][cc] = t1 + t2;	
							//printf("%f + %f = %f\n",t1,t2, Obuf[rr][cc]);
						}				
					}
				}
			}
			// End hardware functionality
			// ---------------------------------------------------
		}

		// Read data from Obuf and store it into main memory O buffer
		// Note again we have to check that we don't go past the end of
		// the O buffer
		for (int rr=0; rr < R; rr++) {
			for (int cc=0; cc < C; cc++) {
				O[m][rr][cc] = Obuf[rr][cc];
			}
		}
	}

	// ---------------------------------------------------
	// Store results to text file for easy checking.
	// Write the results to op.txt
	int i = 0;
	op = fopen("op_pw.txt", "w");
	for (int m=0; m<M; m++)
		for (int r=0; r<R; r++)
			for (int c=0; c<C; c++)
			    {
				    fprintf(op,"%d: %d\n",i , O[m][r][c]);
				    i++;
                }
	fclose(op);
}






