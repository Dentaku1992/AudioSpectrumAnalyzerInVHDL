----------------------------------------------------------------------------------
-- Engineer:    Gert-Jan Andries <info@gertjanandries.com>
-- Project:     VHDL Audio Spectrum Analyzer - Zynq 7000 Zedboard
-- Description: Hamming window for 2 channel 24 bit audio signal
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hamming_window is
    Port ( data_in : in STD_LOGIC_VECTOR (31 downto 0);
           data_out_left : out STD_LOGIC_VECTOR (23 downto 0);
           data_out_right : out STD_LOGIC_VECTOR (23 downto 0);
           hamming_value : in STD_LOGIC_VECTOR (7 downto 0);
           clk : in STD_LOGIC);
end hamming_window;

architecture Behavioral of hamming_window is
    signal s_data_out_left : std_logic_vector(15 downto 0);    
    signal s_data_out_right : std_logic_vector(15 downto 0); 
    
    begin    
    process(clk) is
    begin
        if rising_edge(clk) then
             s_data_out_left <= std_logic_vector(to_unsigned((conv_integer((to_unsigned(data_in(15 downto 0),16)))*(conv_integer((to_unsigned(hamming_value,16)))/10000),16)));   --data_in * (hamming_value/10000)
             s_data_out_right <= std_logic_vector(to_unsigned((conv_integer((to_unsigned(data_in(31 downto 16),16)))*(conv_integer((to_unsigned(hamming_value,16)))/10000),16)));
        else
             s_data_out_left <=  s_data_out_left;
             s_data_out_right <= s_data_out_right;    
        end if;
    end process;
    data_out_left <= s_data_out_left; 
    data_out_right <= s_data_out_right;
end Behavioral;
