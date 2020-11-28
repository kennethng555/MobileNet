using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading;

namespace mobileNetV2_weight_scripts
{
	class Program
	{
		static void Main(string[] args)
		{


			string weightsPath ="";
            double maxNum=double.NegativeInfinity;
            double minNum = double.PositiveInfinity;
            string minLocation = "error";
            string MaxLocation = "error";

            double average = 0;
            int total = 0; ;
            int numBelow11 = 0;
            int totalParams = 0; ;
            try
            {
                // Get the current directory.
                string path = Directory.GetCurrentDirectory();
                string target = @"c:\temp";
                Console.WriteLine("The current directory is {0}", path);
                Console.WriteLine("List of directories:");
                foreach (string subdirectory in Directory.GetDirectories(path)) 
                {
                    Console.Write("\t");
                    Console.WriteLine(subdirectory.ToString());
                }

                Directory.SetCurrentDirectory(Directory.GetDirectories(path)[0]);
                path = Directory.GetCurrentDirectory();
                Console.WriteLine("The current directory is {0}", path);

                string line;

                int layerNum = 1;
                /*Traverse every file in the directory*/
                foreach (string dirFile in Directory.GetFiles(path))
                {
                    /*Traverse Every line*/
                    System.IO.StreamReader file =new System.IO.StreamReader(dirFile);
                    Println("File opened:\t" + Path.GetFileName(dirFile)+"\n");
                    if (Path.GetFileName(dirFile).Contains("running_mean")||
                        Path.GetFileName(dirFile).Contains("num_batches_tracked")||
                        Path.GetFileName(dirFile).Contains("running_var")) 
                    {
                        //Println("\tIGNORED");
                        file.Close();
                        continue;
                    }

                    string quantized_fileName = "FPGA_" + Path.GetFileName(dirFile) + ".h";
                    // Check if file already exists. If yes, delete it.     
                    if (File.Exists(quantized_fileName))
                    {
                        File.Delete(quantized_fileName);
                    }

                    // Create a new file     
                    using (FileStream fs = File.Create(quantized_fileName)) 
                    {
                    
                    }


                    using (System.IO.StreamWriter FPGAFile = new System.IO.StreamWriter(quantized_fileName, true))
                    {
                        FPGAFile.WriteLine("int Layer" +layerNum+" [] = {");
                    }
                    layerNum++;

                    line = file.ReadLine();

                    bool breakout = false;
                    while (breakout == false )
                    //while ((line = file.ReadLine()) != null) 
                    {

                        //Println("File opened");
                        //Console.WriteLine(line);                                                
                        float value;
                        //int decimals = 0;
                        if (line.IndexOf(',') == -1)
                        {
                            breakout = true;
                            value= float.Parse(line);
                            using (System.IO.StreamWriter FPGAFile = new System.IO.StreamWriter(quantized_fileName, true))
                            {
                                int quantized_Val = Convert.ToInt32(value * 2147483648);
                                FPGAFile.WriteLine(quantized_Val.ToString());
                            }
                        }
                        else 
                        {
                            string value_s = line.Substring(0, line.IndexOf(','));

                             value = float.Parse(value_s);

                            int index = line.IndexOf(',');
                            int length = line.Length;

                            line = line.Substring(line.IndexOf(',') + 1, line.Length - 1 - line.IndexOf(','));

                            using (System.IO.StreamWriter FPGAFile = new System.IO.StreamWriter(quantized_fileName, true))
                            {
                                int quantized_Val = Convert.ToInt32(value * 2147483648);
                                FPGAFile.WriteLine(quantized_Val.ToString() + ',');
                            }
                        }



                        //Used for finding minimum and maximum values
                        /*
                        if (value < 0.00000000001) 
                        {
                            numBelow11++;
                        }
                        average += value;
                        total++;
                        totalParams++;
                        if (value < 0) 
                        {
                            value *= -1;
                        }
                        //Find Min - Max
                        if (value > maxNum)
                        {
                            maxNum = value;
                            MaxLocation = Path.GetFileName(dirFile);
                        }
                        if (value < minNum)
                        {
                            minNum = value;
                            minLocation = Path.GetFileName(dirFile);
                        }
                        */


                        //Println("Writing...\n");


                    }//Finished traversingline


                    using (System.IO.StreamWriter FPGAFile = new System.IO.StreamWriter(quantized_fileName, true))
                    {
                        FPGAFile.WriteLine("}");
                    }

                    file.Close();
                    //Println("Amount below e-11:" + numBelow11.ToString());
                } //Finished traversing files in this subdirectory

                Println("*********************************************************************");

                average = average / total;
                Println("Total Params:" + totalParams.ToString());
                Println("Amount below e-11:" + numBelow11.ToString());
                double percent = ((double)(double)numBelow11 / (double)totalParams) * 100;
                Println("Percent too smal: = " + percent);

                Println("Average value: " + average.ToString());
                Println("Min Location: " + minLocation);
                Println("Min: " + minNum);
                Println("\n");
                Println("Max: " + maxNum);
                Println("Max Location: " + MaxLocation);

                Console.WriteLine("\n\nEnd of program\n");
            }
            catch (Exception e)
            {
                Console.WriteLine("The process failed: {0}", e.ToString());
            }
        }//End main
	}
}
