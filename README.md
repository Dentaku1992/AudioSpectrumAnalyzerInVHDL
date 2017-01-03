#Spectrum Analyzer in VHDL

This project contains an audio spectrum analyzer written in VHDL and synthesizable for a Xilinx Zynq 7000. The development board used to build this project is a [ZedBoard](http://zedboard.org/product/zedboard). 

The audio spectrum analyzer takes a stereo audio as input than calculates the spectrum trough a fast Fourrier transform (FFT). This spectrum is than shown on a HDMI or VGA compatible  screen.

The user has the possibility to make some preferences (different themes, averaging...) by using the buttons on te ZedBoard. 

#General workflow

1. An audio signal is applied to the line input of the ZedBoard

2. The audio signal is sampled trough an audio codec (ADAU1761)

3. The audio signal is decoded by an I2S decoder

4. A RAM memory is filled with 1024 audio samples. Each sample consists out of 16-bit audio data per channel.

5. When the audio sample memory is completely filled, the samples will d multiplied with a hamming window. This is done separately for each channel.

6. The audio samples are then supplied to the FFT engine. This engine reads 1024 samples in before the transformation begins.

7. When the transformation is finished, the samples are stored in a (block) RAM. The 512 samples are scaled to a width of 1280 pixels to fit on a HD screen.

8. Finally, the Image generation logic will generate an image depending on the switches. This picture is than send to the HDMI and VGA interface of the ZedBoard.

9. On the ZedBoard OLED screen some aditional data about the user settings is shown. This project contains also a driver for the ZedBoard OLED screen completely writting in VHDL. 

#Authors
Gert-Jan Andries (Audio Interface, FFT, Memory, OLED interface, Toplevel)
Nick Steen (VHDL tools)
Xavier Dejager (Display Output, HDMI, VGA)