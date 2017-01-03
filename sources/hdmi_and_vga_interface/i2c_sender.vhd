----------------------------------------------------------------------------------
-- Engineer:    Xavier Dejager
-- Project:     VHDL Audio Spectrum Analyzer - Zynq 7000 Zedboard
-- Description: I2C sender
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_sender is
    Port ( clk    : in    STD_LOGIC;    
           resend : in    STD_LOGIC;
           sioc   : out   STD_LOGIC;
           siod   : inout STD_LOGIC
    );
end i2c_sender;

architecture Behavioral of i2c_sender is
   signal   divider           : unsigned(8 downto 0)  := (others => '0'); 
   signal   initial_pause     : unsigned(7 downto 0) := (others => '0');
   signal   finished          : std_logic := '0';
   signal   address           : std_logic_vector(7 downto 0)  := (others => '0');
   signal   clk_first_quarter : std_logic_vector(28 downto 0) := (others => '1');
   signal   clk_last_quarter  : std_logic_vector(28 downto 0) := (others => '1');
   signal   busy_sr           : std_logic_vector(28 downto 0) := (others => '1');
   signal   data_sr           : std_logic_vector(28 downto 0) := (others => '1');
   signal   tristate_sr       : std_logic_vector(28 downto 0) := (others => '0');
   signal   reg_value         : std_logic_vector(15 downto 0)  := (others => '0');
   constant i2c_wr_addr       : std_logic_vector(7 downto 0)  := x"72";

   type reg_value_pair is ARRAY(0 TO 63) OF std_logic_vector(15 DOWNTO 0);    
   
   signal reg_value_pairs : reg_value_pair := (
            x"4110", 
            x"9803", x"9AE0", x"9C30", x"9D61", x"A2A4", x"A3A4", x"E0D0", x"5512", x"F900",
            -- Input mode
            x"1506", 
            x"4810",             
            x"1637", 
            x"1700", 
            x"D03C", 
            -- Output mode
            x"AF04",
            x"4c04",
            x"4000",
            -- (Cr * A1       +      Y * A2       +     Cb * A3)/4096 +     A4    =  Red
             x"18E7", x"1934",   x"1A04", x"1BAD",   x"1C00", x"1D00",   x"1E1C", x"1F1B",
            -- (Cr * B1       +      Y * B2       +     Cb * B3)/4096 +     B4    =  Green
            x"201D", x"21DC",   x"2204", x"23AD",   x"241F", x"2524",   x"2601", x"2735",
            -- (Cr * C1       +      Y * C2       +     Cb * C3)/4096 +     C4    =  Blue
            x"2800", x"2900",   x"2A04", x"2BAD",   x"2C08", x"2D7C",   x"2E1B", x"2F77",
            x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF",
            x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF",
            x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF"
   );
begin

registers: process(clk)
   begin
      if rising_edge(clk) then
         reg_value <= reg_value_pairs(to_integer(unsigned(address)));
      end if;
   end process;

i2c_tristate: process(data_sr, tristate_sr)
   begin
      if tristate_sr(tristate_sr'length-1) = '0' then
         siod <= data_sr(data_sr'length-1);
      else
         siod <= 'Z';
      end if;
   end process;
   
   with divider(divider'length-1 downto divider'length-2) 
      select sioc <= clk_first_quarter(clk_first_quarter'length -1) when "00",
                     clk_last_quarter(clk_last_quarter'length -1)   when "11",
                     '1' when others;
                     
i2c_send:   process(clk)
   begin
      if rising_edge(clk) then
         if resend = '1' then 
            address           <= (others => '0');
            clk_first_quarter <= (others => '1');
            clk_last_quarter  <= (others => '1');
            busy_sr           <= (others => '0');
            divider           <= (others => '0');
            initial_pause     <= (others => '0');
            finished <= '0';
         end if;

         if busy_sr(busy_sr'length-1) = '0' then
            if initial_pause(initial_pause'length-1) = '0' then
               initial_pause <= initial_pause+1;
            elsif finished = '0' then
               if divider = "11111111" then
                  divider <= (others =>'0');
                  if reg_value(15 downto 8) = "11111111" then
                     finished <= '1';
                  else
                     clk_first_quarter <= (others => '0'); clk_first_quarter(clk_first_quarter'length-1) <= '1';
                     clk_last_quarter <= (others => '0');  clk_last_quarter(0) <= '1';
                     tristate_sr <= "0" & "00000000"  & "1" & "00000000"             & "1" & "00000000"             & "1"  & "0";
                     data_sr     <= "0" & i2c_wr_addr & "1" & reg_value(15 downto 8) & "1" & reg_value( 7 downto 0) & "1"  & "0";
                     busy_sr     <= (others => '1');
                     address     <= std_logic_vector(unsigned(address)+1);
                  end if;
               else
                  divider <= divider+1; 
               end if;
            end if;
         else
            if divider = "11111111" then
               tristate_sr       <= tristate_sr(tristate_sr'length-2 downto 0) & '0';
               busy_sr           <= busy_sr(busy_sr'length-2 downto 0) & '0';
               data_sr           <= data_sr(data_sr'length-2 downto 0) & '1';
               clk_first_quarter <= clk_first_quarter(clk_first_quarter'length-2 downto 0) & '1';
               clk_last_quarter  <= clk_last_quarter(clk_first_quarter'length-2 downto 0) & '1';
               divider           <= (others => '0');
            else
               divider <= divider+1;
            end if;
         end if;
      end if;
   end process;
end Behavioral;

