----------------------------------------------------------------------------------
-- Engineer:    Gert-Jan Andries <info@gertjanandries.com>
-- Project:     VHDL Audio Spectrum Analyzer - Zynq 7000 Zedboard
-- Description: Address generator
----------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    
entity fft_read_address_generator is
    Port (
        clk_100M : in std_logic;
        fft_ready_to_read: in std_logic;
        
        write_address: out std_logic_vector(8 downto 0)
    );
end fft_read_address_generator;

architecture Behavioral of fft_read_address_generator is
    
    signal s_start: std_logic := '0';
    signal s_fft_ready_to_read_previous : std_logic := '0';
    signal s_write_address: integer range 0 to 512;
    signal write_counter : unsigned(7 downto 0);
    
begin
    process(clk_100M)
    begin
        if rising_edge(clk_100M) then
            if(fft_ready_to_read = '1' and s_fft_ready_to_read_previous = '0') then
                s_start <= '1';
                s_write_address <= 0;
            else
                s_start <= s_start;
            end if;
            
            if(s_start = '1') then
                if(s_write_address < 512) then
                    s_write_address <= s_write_address + 1;
                else
                    s_write_address <= 511;
                    s_start <= '0';
                end if;
            else
                s_write_address <= 0;
            end if;
        end if;
    end process;
    
    write_address <= conv_std_logic_vector(s_write_address,9);
    
end Behavioral;

