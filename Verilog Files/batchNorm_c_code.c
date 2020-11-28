
/******************************************************************************

                            Online C Compiler.
                Code, Compile, Run and Debug C program online.
Write your code in this editor and press "Run" button to compile and execute it.

*******************************************************************************/

#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include <inttypes.h>
#include <time.h>

#define N 16

int main()
{
    int64_t average = 0;
    int64_t variance = 0;
    int batchnorm = 0;
    
    
    int iFM[N] = 
    {
        //112,223,113,423,577,631,7,822,9,1022,1165,2212,134453,15544,133315,5216
        //2,4,6,8,10,12,14,16,18,19,20,22,24,26,28,30
        //16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
        //        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
        112,-223,113,-423,577,631,7,-822,9,1022,1165,2212,-134453,15544,133315,-5216
    };
    
    srand(34); 
    
    /*Input numbers*/
    printf("iFM array values\n");
    for (int i = 0; i< N; i++)
    {
        iFM[i] = rand();
        printf("iFM [ %d]: %d\n", i,iFM[i]);
    }

    /*Find average*/
    printf("\nAverage accumulation:\n");
    for(int i = 0; i<N;i++)
    {
        average += (int64_t)iFM[i];
        //printf("accumulation step %" PRId64 ": %d\n", i,average);
    }
    average /= N;
  
    /*Find Variance*/
    printf("\nVariance accumulation:\n");
    for(int i =0;i<N;i++)
    {
        int64_t result = (   ((int64_t)iFM[i] - (int64_t)average)
                           * ((int64_t)iFM[i] - average)
                         );
        variance += result;
        if ((iFM[i] - average) > 4294967296)
        {
            printf("overflow\n");
        }
        //printf("var accumulation step %d: %" PRId64 "\n", i,variance);
    }
    
    variance/= N;
    
    printf("\n\naverage: %d\n",average);
    printf("variance: %" PRId64 "\n",variance);
    variance = sqrt(variance);
    printf("sqrt_var: %" PRId64 "\n\n\n",variance);
    

    /*Find batch norm for each number*/
    for( int i = 0; i < N; i++)
    {
        batchnorm = ((iFM[i] - average) / variance);
        printf("batchnorm [%d]: %d\n",i,batchnorm);
    }


    /*Copy paste this into memory block*/
    printf("\n\nVerilog statements :)\n");
    for (int i = 0; i<N;i++)
    {
        printf("mem[%d] = %d;\n",i,iFM[i]);
    }
    

    return 0;
}
