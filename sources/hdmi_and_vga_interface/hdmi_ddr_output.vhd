----------------------------------------------------------------------------------
-- Engineer:    Xavier Dejager
-- Project:     VHDL Audio Spectrum Analyzer - Zynq 7000 Zedboard
-- Description: HDMI output 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
    use UNISIM.VComponents.all;


entity hdmi_ddr_output is
    Port ( clk      : in  STD_LOGIC;
           clk90    : in  STD_LOGIC;
           y        : in  STD_LOGIC_VECTOR (7 downto 0);
           c        : in  STD_LOGIC_VECTOR (7 downto 0);
           hsync_in : in  STD_LOGIC;
           vsync_in : in  STD_LOGIC;
           de_in    : in  STD_LOGIC;
           
           hdmi_clk      : out   STD_LOGIC;
           hdmi_hsync    : out   STD_LOGIC;
           hdmi_vsync    : out   STD_LOGIC;
           hdmi_d        : out   STD_LOGIC_VECTOR (15 downto 0);
           hdmi_de       : out   STD_LOGIC;
           hdmi_scl      : out   STD_LOGIC;
           hdmi_sda      : inout STD_LOGIC;
           oled_data_in  : in STD_LOGIC
    );
end hdmi_ddr_output;

architecture Behavioral of hdmi_ddr_output is
   COMPONENT i2c_sender
   PORT(
      clk    : IN std_logic;
      resend : IN std_logic;    
      siod   : INOUT std_logic;      
      sioc   : OUT std_logic
   );
   END COMPONENT;
begin
clk_proc: process(clk)
   begin
      if rising_edge(clk) then
         hdmi_vsync <= vsync_in;
         hdmi_hsync <= hsync_in;
      end if;
   end process;

ODDR_hdmi_clk : ODDR 
   generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
   port map (C => clk90, Q => hdmi_clk,  D1 => '1', D2 => '0', CE => '1', R => '0', S => '0');

ODDR_hdmi_de : ODDR 
   generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
   port map (C => clk, Q => hdmi_de,  D1 => de_in, D2 => de_in, CE => '1', R => '0', S => '0');

--ddr_gen: for i in 0 to 7 generate
--   begin
--   ODDR_hdmi_d : ODDR 
--     generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
--     port map (C => clk, Q => hdmi_d(i+8),  D1 => y(i), D2 => c(i), CE => '1', R => '0', S => '0');
--   end generate;
   
       ODDR_hdmi_d0 : ODDR
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(0),  D1 => '0', D2 => '0', CE => '1', R => '0', S => '0');   
       ODDR_hdmi_d1 : ODDR 
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(1),  D1 => oled_data_in, D2 => oled_data_in, CE => '1', R => '0', S => '0');   
       ODDR_hdmi_d2 : ODDR
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(2),  D1 => '0', D2 => '0', CE => '1', R => '0', S => '0');               
       ODDR_hdmi_d3 : ODDR
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(3),  D1 => '0', D2 => '0', CE => '1', R => '0', S => '0');              
       ODDR_hdmi_d4 : ODDR
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(4),  D1 => '0', D2 => '0', CE => '1', R => '0', S => '0');                    
       ODDR_hdmi_d5 : ODDR
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(5),  D1 => '0', D2 => '0', CE => '1', R => '0', S => '0');           
       ODDR_hdmi_d6 : ODDR
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(6),  D1 => '0', D2 => '0', CE => '1', R => '0', S => '0');                 
       ODDR_hdmi_d7 : ODDR
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(7),  D1 => '0', D2 => '0', CE => '1', R => '0', S => '0');        
        ODDR_hdmi_d8 : ODDR 
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(8),  D1 => y(0), D2 => c(0), CE => '1', R => '0', S => '0');
        ODDR_hdmi_d9 : ODDR 
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(9),  D1 => y(1), D2 => c(1), CE => '1', R => '0', S => '0');
        ODDR_hdmi_d10 : ODDR 
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(10),  D1 => y(2), D2 => c(2), CE => '1', R => '0', S => '0');
        ODDR_hdmi_d11 : ODDR 
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(11),  D1 => y(3), D2 => c(3), CE => '1', R => '0', S => '0');
        ODDR_hdmi_d12 : ODDR 
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(12),  D1 => y(4), D2 => c(4), CE => '1', R => '0', S => '0');
        ODDR_hdmi_d13 : ODDR 
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(13),  D1 => y(5), D2 => c(5), CE => '1', R => '0', S => '0');
        ODDR_hdmi_d14 : ODDR 
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(14),  D1 => y(6), D2 => c(6), CE => '1', R => '0', S => '0');
        ODDR_hdmi_d15 : ODDR 
        generic map(DDR_CLK_EDGE => "SAME_EDGE", INIT => '0',SRTYPE => "SYNC") 
        port map (C => clk, Q => hdmi_d(15),  D1 => y(7), D2 => c(7), CE => '1', R => '0', S => '0');
   
   --hdmi_d(7 downto 2) <= "000000";
   --hdmi_d(0) <= '0';

   --hdmi_d(1) <= oled_data_in;


-----------------------------------------------------------------------   
-- This sends the configuration register values to the HDMI transmitter
-----------------------------------------------------------------------   
i_i2c_sender: i2c_sender PORT MAP(
      clk => clk,
      resend => '0',
      sioc => hdmi_scl,
      siod => hdmi_sda
   );
end Behavioral;

