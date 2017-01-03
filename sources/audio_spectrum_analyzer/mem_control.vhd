----------------------------------------------------------------------------------
-- Engineer:    Gert-Jan Andries <info@gertjanandries.com>
-- Project:     VHDL Audio Spectrum Analyzer - Zynq 7000 Zedboard
-- Description: Memory controller 
----------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.NUMERIC_STD.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    
entity mem_control is
    Port (
        clk_100M : in std_logic;
        sample_clk_in: in std_logic;
        ready_enable_out : out std_logic;
        last_flag : out std_logic;
        
        write_address: out std_logic_vector(9 downto 0);
        read_address: out std_logic_vector(9 downto 0) 
    );
end mem_control;

architecture Behavioral of mem_control is
    
    signal data_ready : std_logic := '0';
    signal previous_data_ready : std_logic := '0';
    signal s_data_ready_buffer : std_logic := '0';
    signal s_write_address: integer range 0 to 1024;
    signal s_read_address: integer range 0 to 1024;
    
    signal s_counter: integer range 0 to 2500000;
    signal s_count: std_logic := '1';
    signal s_ready_to_send : std_logic := '0';
    
begin
    process(sample_clk_in)
    begin
        if rising_edge(sample_clk_in) then
            if(s_write_address < 1023) then                    
                s_write_address <= s_write_address + 1;
                data_ready <= '0';
            else                 
                data_ready <= '1';
                s_write_address <= 0;
            end if;
        end if;
    end process;
    
    write_address <= conv_std_logic_vector(s_write_address, 10);
    
    process(clk_100M)
    begin
        if rising_edge(clk_100M) then
            if (s_counter < 2499999 and s_count = '1') then
                s_ready_to_send <= '0';
                s_counter <= s_counter +1;
            else
                s_ready_to_send <= '1';
                s_count <= '0';
                s_counter <= 0;
            end if;
            
            
            if( data_ready = '1' and previous_data_ready ='0') then  
                if(s_ready_to_send = '1') then
                    s_data_ready_buffer <= '1';
                    previous_data_ready <= data_ready;
                end if;
            else
                s_data_ready_buffer <= s_data_ready_buffer;
                previous_data_ready <= data_ready;
            end if;
            
            if(s_data_ready_buffer = '1') then  
                if(s_read_address < 1023) then                        
                    s_read_address <= s_read_address + 1;
                    ready_enable_out <= '1';
                    last_flag <= '0';
                else 
                    s_read_address <= 0;                      
                    s_data_ready_buffer <= '0';
                    ready_enable_out <= '0';
                    last_flag <= '1';
                    s_count <= '1';
                end if;
            end if;
            
        end if;           
    end process;
    read_address <=  conv_std_logic_vector(s_read_address, 10); 
    
end Behavioral;

