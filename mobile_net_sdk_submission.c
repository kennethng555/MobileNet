

#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include <inttypes.h>
#include "platform.h"
#include "xil_printf.h"
#include "xtmrctr.h"    // timer
//#include "test_image.h"


#define TIMER_BASE 0x42800000  // change to match base address of your AXI timer if necessary
#define TIMER_FREQ 9         // in MHz
#define TMRCTR_DEVICE_ID        XPAR_TMRCTR_0_DEVICE_ID

//#define DEBUG
//#define TEST
#define SHOW_RESULTS
//#define SHOW_MID_RESULTS
#define FPGA_TIMER
//#define TOTAL_TIMER

#define CV 1
#define DW 2
#define MEM_SIZE 128*1024 / 4 //words


typedef struct
{
	int height;
	int M;
	int N;
	int Stride;
	int Padding;
	int Kernel;
	int mode;
	int sizeOfKernel;
	int sizeOfiFM;
	int sizeOfoiFM;

}ConfigReg;

/*Function Declarations*********************************************************************************************************************/
/*Stimulator Fuction*/
void calc( int configReg);

/*Top Layers*/
int bottleNeck_layer(int height1, int height2, int in_planes, int out_planes, int expansion, int stride,int shortcut);
int cv_tile_layer (ConfigReg configReg, int t); //Tr:Tc tile size

/*Wrapper Functions*/
int dw_layer(uint8_t height, uint16_t N);
int cv_layer(uint8_t height, uint16_t M, uint16_t N);
int ex_layer(uint8_t height, uint16_t M, uint16_t N);
int pw_layer(uint8_t height, uint16_t M, uint16_t N);
int shortcut_layer(uint8_t height, uint16_t M, uint16_t N);

/*Basic layer*/
uint32_t conv_layer(uint8_t height, uint16_t M, uint16_t N, uint8_t stride, uint8_t padding, uint8_t kernel, uint8_t mode);

/*Peripheral layers*/
void batchNorm( int height, int channels);

/*Helper Functions*/
void saveShortcutLayer   (int configReg);
void addFromShortcutLayer(int configReg);
int  getoFMStartAddress  (int configReg);
int  getoFMSize          (int configReg);
void oFM_to_iFM          (int configReg);
void convLayer_toString  (int configReg);

int  depthwiseSetup    (int HEIGHT, int CHANNELS);
int  convSetup         (int HEIGHT, int KERNEL, int PADDING, int OUT_CHANNELS, int IN_CHANNELS);

void clearMem(void);
int  PoST(void);

/*Timer Related*/
void initTimer(void);
void startTimer(void);
void stopTimer(void);
/*******************************************************************************************************************************************/

volatile  int* bram0 = ( int*)XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR;
volatile  int* hw = ( int*)XPAR_BRAM_MULT_ALT_0_S00_AXI_BASEADDR;

/*Largest output is only ever: 24 x 32 x 32 */
int shortcutStorage[24576]={0};
int shortcutConfig = 0;

int tick = 1;
int tock = 0;

int iFM_tile[147456]={0}; // For tiling, store the local input
int oFM_tile[147346]={0}; // For tiling, store the output as it's calculated

XTmrCtr TimerCounter;
int time0 = 0;
double accumulatedTime=0;


/*******************************************************************************************************************************************
				__  __       _
				|  \/  |     (_)
				| \  / | __ _ _ _ __
				| |\/| |/ _` | | '_ \
				| |  | | (_| | | | | |
				|_|  |_|\__,_|_|_| |_|

*******************************************************************************************************************************************/



int main()
{
    init_platform();

    PoST();
	printf("********************************************* \n");

	/*Depthwise
	depthwiseSetup (5,5);
    int layer1 = dw_layer(5,5);

    initTimer();
	startTimer();
    calc(layer1);
	int time1 = XTmrCtr_GetValue(&TimerCounter, 0);
	//printf("Meausured %d clock cycles == %f seconds\n", (time1-time0),((double)(time1-time0))/(TIMER_FREQ*1000000));
  	*/

	/*Std Convolution
	convSetup(5, 3, 1, 4, 4);

	ConfigReg configReg;
	configReg.height  = 5;
	configReg.M       = 4;
	configReg.N       = 4;
	configReg.Stride  = 1;
	configReg.Padding = 1;
	configReg.Kernel  = 3;
	configReg.mode    = CV;
	printf("********************************************* \n");
	initTimer();
	//startTimer();
	cv_tile_layer(configReg, 3);
	int time1 = XTmrCtr_GetValue(&TimerCounter, 0);
    //printf("Meausured %d clock cycles == %f seconds\n", (time1-time0),((double)(time1-time0))/(TIMER_FREQ*1000000));


    */

	/*	Pointwise

	convSetup(3, 1, 0, 2, 4);
	int layer3 = pw_layer(3,2,4);
	//calc(layer3);

	ConfigReg configReg;
	configReg.height  = 3;
	configReg.M       = 2;
	configReg.N       = 4;
	configReg.Stride  = 1;
	configReg.Padding = 0;
	configReg.Kernel  = 1;
	configReg.mode    = CV;

	initTimer();
	startTimer();
	cv_tile_layer(configReg, 3);
	int time1 = XTmrCtr_GetValue(&TimerCounter, 0);
    //printf("Meausured %d clock cycles == %f seconds\n", (time1-time0),((double)(time1-time0))/(TIMER_FREQ*1000000));
	*/
	
    printf("Meausured %d clock cycles == %f seconds\n", (time1-time0),accumulatedTime);

	//Mobile Net
	// bottleNeck_layer(height1, height2, in_planes,  out_planes,  expansion, stride)
	//convSetup(4, 1, 0, 16, 4);
    //int layer1Config = cv_layer(32,32,3);// 32x32, M =32, N =16
    //calc(layer1Config);

    //printf("Bottleneck Layer1\n");
    //BottleNeck 1
	//bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);
	//shortcut_layer(32,32,32);


/*
    printf("Bottleneck Layer2\n");
    //BottleNeck 2
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);
	shortcut_layer(32,32,32);
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);


    printf("Bottleneck Layer3\n");
    //BottleNeck 3
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);


    printf("Bottleneck Layer4\n");
    //BottleNeck 4
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);


    printf("Bottleneck Layer5\n");
    //BottleNeck 5
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);
	shortcut_layer(32,32,32);
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);


    printf("Bottleneck Layer6\n");
    //BottleNeck 6
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);
	bottleNeck_layer(32, 32, 32, 16, 1, 1, TRUE);


    printf("Bottleneck Layer7\n");
    //BottleNeck 7
	bottleNeck_layer(4, 4, 160, 160, 6, 1, TRUE);
	shortcut_layer(32,32,32);


    int lastLayerConfig = cv_layer(32,32,3);// 32x32, M =32, N =16

    //average ppool
    calc(lastLayerConfig);
    */


	printf("********************************************* \n");
	printf("***********End of program******************** \n");
	printf("********************************************* \n");

    cleanup_platform();

    return 0;
}



/*Stimulator Function*************************************************************************************************************************/
void calc( int configReg)
{

	#ifdef DEBUG
		convLayer_toString(configReg);
		printf("\nStarting calculation... \r\n");
	#endif

	#ifdef FPGA_TIMER
		XTmrCtr_Reset(&TimerCounter, 0);                     // reset timer
		time0 = XTmrCtr_GetValue(&TimerCounter, 0);      // read timer value
		XTmrCtr_Start(&TimerCounter, 0);                     // start timer
	#endif

	hw[0] = configReg;
	// Wait for done signal
	while ( (hw[1] & 0x1) == 0)
	{;
		//printf("%d\n",bram0[1]);
	}

	// Deassert start signal
	hw[0] = 0;

	#ifdef FPGA_TIMER
		int time1 = XTmrCtr_GetValue(&TimerCounter, 0);
		double elapsed = ((double)(time1-time0))/(TIMER_FREQ*1000000);
		accumulatedTime += elapsed;
	#endif

	printf("time elapsed: %f\n",elapsed);

	#ifdef DEBUG
		printf("Finished calculation! \r\n");
	#endif

	int r = ((configReg >> 26)  & 0x3F);
	int K = ((configReg >>  3)  & 0x01);
	int N = ((configReg >>  6)  & 0xFF);
	int M = ((configReg >> 16)  & 0xFF);
	int P = ((configReg >>  4)  & 0x01);
	if (K == 0)
	{
		K = 3;
	}

	#ifdef SHOW_MID_RESULTS

		/*Print results*/
		printf("\noFM:********************** \n");
		int startIndex = K * K * N * M + (r+2*P) * (r+2*P) * N;

		for(int i = startIndex; i <startIndex + getoFMSize(configReg) ; i++)
		{
			printf("bram0[%d]: %d\n",i, bram0[i]);
		}

	#endif
	//oFM_to_iFM(configReg);
	//batchNorm( ((r+2*P)-K+1), M);
}

void printoFM(int configReg)
{
	/*Print results*/
	printf("\noFM:********************** \n");

	int consecZ = 0;

	int r = ((configReg >> 26)  & 0x3F);
	int K = ((configReg >>  3)  & 0x01);
	int N = ((configReg >>  6)  & 0xFF);
	int M = ((configReg >> 16)  & 0xFF);
	int P = ((configReg >> 4)   & 0x01);
	if (K == 0)
	{
		K = 3;
	}

	int startIndex = K * K * N * M + (r+2*P) * (r+2*P) * N;

	printf("iFM[] = {");
	for(int i = startIndex; i <MEM_SIZE ; i++)
	{
		if (consecZ == 10)
			break;
		if (bram0[i] == 0)
			consecZ++;

		printf("%d,\n", bram0[i]);
		//printf("bram0[%d]: %d,\n",i bram0[i]);
	}

}

/*Top level layers***************************************************************************************************************************/
int bottleNeck_layer(int height1, int height2, int in_planes, int out_planes, int expansion, int stride, int shortcut)
{
	int planes = expansion * out_planes;
	int expLayerConfig = ex_layer(height1, planes,     in_planes);
	shortcutConfig = expLayerConfig;
	calc(expLayerConfig );

	if(shortcut == 1)
	{
		saveShortcutLayer(expLayerConfig);
	}


	calc( dw_layer(height1, planes               ));


	calc( pw_layer(height2, out_planes, planes   ));

	return 1;
}

int cv_tile_layer (ConfigReg configReg, int t) //Tr:Tc tile size
{
	int oFM_index = 0;

	int singleMapSize = (configReg.height+ (2*configReg.Padding)) * (configReg.height+ (2*configReg.Padding));

	configReg.sizeOfKernel = configReg.Kernel * configReg.Kernel * configReg.N * configReg.M;
	configReg.sizeOfoiFM = ((configReg.height+ (2*configReg.Padding)) - configReg.Kernel + 1) * ((configReg.height+ (2*configReg.Padding)) - configReg.Kernel + 1);

	//# of tiles
	for(int tr = 0; tr < configReg.height+ (2*configReg.Padding) - t+1; tr++) //Tile across rows
	{
		for(int tc = 0; tc < configReg.height+ (2*configReg.Padding) - t+1; tc++)//Tile across columns
		{
			int ti = 0; //tile index

			/*Import all channels*/
			for ( int n = 0; n < configReg.N; n++)//For each input channels
			{

				/*Operate on a tile*/
				for(int r = 0; r < t; r++)
				{
					for ( int c = 0; c <t; c++)
					{
						bram0[ti + configReg.sizeOfKernel] = iFM_tile[  (n * singleMapSize)  + ((tr+r)*(configReg.height+2*configReg.Padding) + (tc+c))];
						ti++;
					}
				}

			}

			/*Use the same parameters but tile the height*/
			ConfigReg tileReg = configReg;
			tileReg.height = t - configReg.Kernel + 1;
			tileReg.sizeOfKernel = tileReg.Kernel * tileReg.Kernel * tileReg.N * tileReg.M;
			tileReg.sizeOfiFM = (tileReg.height + 2 * tileReg.Padding) * (tileReg.height + 2 * tileReg.Padding) * tileReg.N;


			int tempLayer;
			if(configReg.mode == CV && configReg.Kernel ==1) // pointwise
			{
				tempLayer = pw_layer(tileReg.height,tileReg.M, tileReg.N);
			}
			else//depthwise and normal convolution
			{
				tempLayer = cv_layer(tileReg.height,tileReg.M, tileReg.N);
			}
			calc(tempLayer);

			#ifdef DEBUG
				for (int i = 0;i< 44+18; i++)
				{
					printf("bram0[%d]: %d\n", i, bram0[i]);
				}
				printf("********************************************* \n");
			#endif

			int sizeOfoFM_single = (tileReg.height + 2 * tileReg.Padding) - tileReg.Kernel +1;

			/*Save all outputs*/

			for ( int i = 0 ;i <sizeOfoFM_single * sizeOfoFM_single; i++) //Save results for an entire outmap
			{
				for (int m = 0; m< tileReg.M; m++) //Save results for each outmap
				{
					oFM_tile[oFM_index + m * (configReg.sizeOfoiFM)] = bram0[tileReg.sizeOfiFM + tileReg.sizeOfKernel + i + (m *sizeOfoFM_single*sizeOfoFM_single) ];

					bram0[tileReg.sizeOfiFM + tileReg.sizeOfKernel + i + (m *sizeOfoFM_single*sizeOfoFM_single)] = 0; //Reset for next tile
				}
				oFM_index++;
			}






		}
	}

	#ifdef SHOW_RESULTS
		/*Tiled results*/
		printf("tiled Results \n");
		for (int i =0;i < configReg.M * (configReg.sizeOfoiFM);i++)
		{
			printf("%d: %d\n",i,oFM_tile[i]);
		}
	#endif

	return 0;
}

/*Wrapper Functions**************************************************************************************************************************/
int dw_layer(uint8_t height, uint16_t N)
{
	// HEIGHT
	// M = 1
	// N
	// STRIDE
	// PADDING = 1
	// KERNEL = 3

	           //h,m,n,s,p,k,mode
	return conv_layer(height, 1, N, 1, 1, 0,DW);
}

int cv_layer(uint8_t height, uint16_t M, uint16_t N)
{
	// HEIGHT
	// M
	// N
	// STRIDE
	// PADDING = 1
	// KERNEL = 3
	          //h,m,n,s,p,k,mode
	return conv_layer(height, M, N, 1, 1, 0,CV);
}

int ex_layer(uint8_t height, uint16_t M, uint16_t N)
{
	// HEIGHT
	// M
	// N
	// STRIDE
	// PADDING = 0
	// KERNEL = 1
	   //h,m,n,s,p,k,mode
	return conv_layer(height, M, N, 1, 0, 1,CV);
}

int pw_layer(uint8_t height, uint16_t M, uint16_t N)
{
	// HEIGHT
	// M
	// N
	// STRIDE
	// PADDING = 0
	// KERNEL = 1
	   //h,m,n,s,p,k,mode
	return conv_layer(height, M, N, 1, 0, 1,CV);
}

int shortcut_layer(uint8_t height, uint16_t M, uint16_t N)
{
	int shortcutConfig = pw_layer(height, M, N);
	addFromShortcutLayer(shortcutConfig); // out = out of recent layer + shortcut layer

	return shortcutConfig;
}

/*Base Functions*****************************************************************************************************************************/
uint32_t conv_layer(uint8_t height, uint16_t M, uint16_t N, uint8_t stride, uint8_t padding, uint8_t kernel, uint8_t mode)
{
	if (M > 1023 || N > 1023 || stride > 2 || padding > 1||mode >4)
		return 0xFFFFFFFF;

	uint32_t result = 0;
	result += height  << 26;	//[31:26]
	result += M       << 16; //[25:16]
	result += N       << 6;  //[15:6]
	result += stride  << 5;  //[5]
	result += padding << 4; //[4]
	result += kernel  << 3;
	result += mode;		    //[3:0]

	return result;
}

/*Peripheral Functions***********************************************************************************************************************/
//TODO: add ReLU
void batchNorm( int height, int channels)
{
    int64_t average = 0;
    int64_t variance = 0;
    int batchnorm = 0;

	/*Find average*/
	for(int i = 0;i< height * height;i++)
	{
		average += bram0[i];
	}
	average = average/(height * height);

	/*Find Variance*/
	//printf("\nVariance accumulation:\n");
	for(int i = 0 ; i < height*height*channels  ;i++)
	{

		/*Variance = sigma((Xi - average)^2) / num elements */
		uint64_t result = (   ((uint64_t)bram0[i] - (uint64_t)average)
						   *  ((uint64_t)bram0[i] - (uint64_t)average)
						 );
		variance += result;
		if ((bram0[i] - average) > 4294967296)
		{
			printf("ERROR: overflow\n");
		}
		//printf("var accumulation step %d: %" PRId64 "\n", i,variance);
	}

	variance/= (height*height);
    int64_t sqrt_variance = sqrt(variance);

	//BatchNorm Yi = (Xi - average) / sqrt(Variance)
    /*Find batch norm for each number*/
    for( int i = 0; i < height * height * channels; i++)
    {
        batchnorm = ((bram0[i] - average) / sqrt_variance);
        //printf("batchnorm [%d]: %d\n",i,batchnorm);
        if(batchnorm <0)
        {
        	batchnorm = 0;
        }
        bram0[i] = batchnorm;
    }


}

/*Helper Functions***************************************************************************************************************************/

void saveShortcutLayer(int configReg)
{
	for(int i = 0; i < getoFMSize(configReg); i++)
	{
		shortcutStorage[i] = bram0[i + getoFMStartAddress(configReg)];
	}
}

void addFromShortcutLayer(int configReg)
{
	for ( int i = 0; i<getoFMSize(configReg); i++)
	{
		bram0[i] += shortcutStorage[i];
	}
}

int getoFMStartAddress(int configReg)
{
	int r = ((configReg >> 26)  & 0x3F);
	int K = ((configReg >>  3)  & 0x01);
	int N = ((configReg >>  6)  & 0xFF);
	int M = ((configReg >> 16)  & 0xFF);
	int P = ((configReg >> 4)   & 0x01);
	if (K == 0)
	{
		K = 3;
	}

	int startIndex = K * K * N * M + (r+2*P) * (r+2*P) * N;
	return startIndex;
}

int getoFMSize(int configReg)
{
	int r = ((configReg >> 26)  & 0x3F);
	int K = ((configReg >>  3)  & 0x01);
	int M = ((configReg >> 16)  & 0xFF);
	int P = ((configReg >> 4)   & 0x01);
    int N = ((configReg >> 6)  & 0xFF);
	if (K == 0)
	{
		K = 3;
	}
    int mode = configReg & 0x07;
	int size;

	if (mode == DW)
	{
		size = N * ((r + 2*P)-K+1)*((r + 2*P)-K+1);
	}
	else
	{
		size = M * ((r + 2*P)-K+1)*((r + 2*P)-K+1);
	}

	return size;
}

/*Shift oFM to iFM location*/
void oFM_to_iFM(int configReg)
{
	#ifdef DEBUG
		printf("\n\noFM sent to iFM location...\n\n");
	#endif

	int R = ((configReg >> 26)  & 0x3F);
	int M = ((configReg >> 16)  & 0xFF);

	int size = R * R * M;

	int indexOfoFM = getoFMStartAddress(configReg);

	for(int i = 0 ; i < size; i++)
	{
		bram0[i] = bram0[i + indexOfoFM];
	}
}

/*Load weights from an appropriate file*/
void loadWeights(int layerNumber)
{
	/*
	for(int i = 0; i<sizeof(layer1);i++)
	{
		bram0[i];

	}
	*/
}

/*Print this layer's metadata*/
void convLayer_toString(int configReg)
{
	printf("\nhex: %x\n", configReg);

    int P = ((configReg >> 4)  & 0x01);
    int K = ((configReg >> 3)  & 0x01);

    printf("iFM: %d\t", (configReg>> 26) & 0x3F);
    printf("M: %d\t",  (configReg >> 16) & 0xFF);

    printf("N: %d\t",  (configReg >> 6)  & 0xFF);
    printf("S: %d\t",  (configReg >> 5)  & 0x01);
    printf("P: %d\t",  (configReg >> 4)  & 0x01);

    if (K == 0)
    	K = 3;

    printf("K: %d\t",  K);

    int mode = configReg & 0x07;
    if(mode== 2)
    {
        printf("Mode: DepthWise\t");
    }
    else if (mode == 1 && P ==1)
    {
    	printf("Mode: Convolution\t");
    }
    else if (mode == 1 && P == 0 && K == 1)
    {
    	printf("Mode: Pointwise/Expansion\t");
    }
    else
    {
    	printf("Error");

    }
    printf("\n");


}

/*Depthwise Stimuli*/
int depthwiseSetup(int HEIGHT, int CHANNELS)
{
	int KERNEL = 3;
	int PADDING = 1;

	int iFM_size     = CHANNELS*KERNEL*KERNEL;
	int kernel_size  = (HEIGHT+2*PADDING)*(HEIGHT+2*PADDING)*CHANNELS;
	int oFM_size     = HEIGHT*HEIGHT*CHANNELS;
	int total_size   = iFM_size + kernel_size + oFM_size ;


	printf("Setting up inputs and clearing our output buffer\r\n");
	printf("KERNELS:********************* \n");
	//Load iFM

	for ( int i = 0; i < CHANNELS*KERNEL*KERNEL; i++)
	{
		bram0[i] = i+1;
		//printf("%d: %d\n",i, bram0[i]);
	}


	printf("\nIFM:****************** \n");

	int j = 2;
	//Load Kernels
	for ( int i = 0 ; i <  (HEIGHT+2*PADDING)*(HEIGHT+2*PADDING)*CHANNELS; i++)
	{
		bram0[i+CHANNELS*KERNEL*KERNEL] = j;
		j++;
		//printf("%d: %d\n",i+CHANNELS*KERNEL*KERNEL, bram0[i]);
	}

	printf("\noFM:********************** \n");
	/*Clear oFM*/
	for( int i = 0; i < HEIGHT*HEIGHT*CHANNELS; i++)
	{
		bram0[i+CHANNELS*KERNEL*KERNEL + (HEIGHT+2*PADDING)*(HEIGHT+2*PADDING)*CHANNELS] = 0;
		//printf("%d: %d\n",i, bram0[i]);
	}
	/*Print results*/
	for(int i = 0; i <total_size ; i++)
	{
		printf("%d: %d\n",i, bram0[i]);
	}

	return total_size;


}

/*Convolution Stimuli*/
int convSetup( int HEIGHT, int KERNEL, int PADDING, int OUT_CHANNELS, int IN_CHANNELS)
{

	int kernel_size  = IN_CHANNELS * KERNEL * KERNEL * OUT_CHANNELS;
	int iFM_size     = (HEIGHT+2*PADDING)*(HEIGHT+2*PADDING)*IN_CHANNELS;
	int oFM_size     = HEIGHT * HEIGHT * OUT_CHANNELS;
	int total_size   = iFM_size + kernel_size + oFM_size ;


	printf("Setting up inputs and clearing our output buffer\r\n");
	//printf("KERNELS:********************* \n");
	//Load Kernel
	for ( int i = 0; i < kernel_size; i++)
	{
		bram0[i] = i+1;
		//printf("%d: %d\n",i, bram0[i]);
	}

	//printf("\nIFM:****************** \n");
	int j = 2;
	//Load iFM
	for ( int i = 0 ; i <  iFM_size; i++)
	{
		iFM_tile[i] = j;
		j++;
		//printf("%d: %d\n",i+CHANNELS*KERNEL*KERNEL, bram0[i]);
	}

	//printf("\noFM:********************** \n");

	/*Clear oFM*/
	for( int i = 0; i < oFM_size; i++)
	{
		bram0[i + kernel_size + iFM_size] = 0;
        //bram0[i+IN_CHANNELS*OUT_CHANNELS*KERNEL*KERNEL + (HEIGHT+2*PADDING)*(HEIGHT+2*PADDING)*IN_CHANNELS] = 0;
		//printf("%d: %d\n",i, bram0[i]);
	}

	#ifdef TEST
		//Print results
		for(int i = 0; i <total_size; i++)
		{
			printf("%d: %d\n",i, bram0[i]);
		}
	#endif
	return total_size;
}

/*Memory setups*/
//Power on Self Test (PoST)
int PoST(void)
{
	clearMem();
	printf("Starting PoST\n\n");

	printf("MEM_SIZE: %d words\n",MEM_SIZE);

	printf("TestWriting values to bram[0] to bram[MEM_SIZE]\n");
	//Clear registers
	for ( int i = 0; i < MEM_SIZE; i++)
	{
		bram0[i] = i;
	}

	int errorFlag = 0;
	for ( int i = 0; i < MEM_SIZE; i++)
	{
		if(bram0[i] != i)
		{
			errorFlag = 1;
			printf("ERROR;CHECK YOUR SIZING\n");
			printf("\tbram0[%d]: %d\n",i,bram0[i]);
		}

	}
	clearMem();
	if (errorFlag == 0)
	{
		printf("No errors Found\n\n");

		return 0;
	}
	return -1;
}

void clearMem(void)
{
	#ifdef PRINT
		printf("\nClearing BRAM... \r\n");
	#endif

    //Clear registers
	for ( int i = 0; i < MEM_SIZE; i++)
	{
		bram0[i] = 0;
	}
}

void initTimer(void)
{
	printf("Initializing timer... \r\n");
	int Status = XTmrCtr_Initialize(&TimerCounter, TMRCTR_DEVICE_ID);
	if (Status != XST_SUCCESS) {
		   return XST_FAILURE;
	}

	// Set up timer. Clear it. Take the first reading; start the timer.
	XTmrCtr_SetOptions(&TimerCounter, 0, XTC_AUTO_RELOAD_OPTION);
	XTmrCtr_Reset(&TimerCounter, 0);                     // reset timer
	time0 = XTmrCtr_GetValue(&TimerCounter, 0);      // read timer value
	XTmrCtr_Start(&TimerCounter, 0);                     // start timer

}

void startTimer(void)
{
	XTmrCtr_Start(&TimerCounter, 0);                     // start timer
}

void stopTimer(void)
{
	XTmrCtr_Stop(&TimerCounter, 0);                     // start timer
}


