Refer to kuang liu's Github. By using pre-existing implementations of MobileNet, the weights were extracted using the modified main.py for our hardware model.
https://github.com/kuangliu/pytorch-cifar

The Github's model achieved 95% accuracy; however, we did our own run and got 92% (the code terminated
early)

The main.py and ./model/mobilenetv2.py file was edited to extract
1. Test image from the CIFAR-10 dataset (test.png)
2. The sizing information for each layer recorded in (mobileNet_layerBreakdown_V0.2.xlsx)
3. The raw weights for each layer (.\weights)
4. The weights formatted to a specified precision (.\weights_formatted)

Additional files
For testing purposes to verfiy that the simulation in Vivado and the Minized was operational, we had
made different test cases
Manually tested some small cases using Excel (.\Manual Testing)
Used python scripts to verify larger cases and did manual difference testing (.\Testing)
