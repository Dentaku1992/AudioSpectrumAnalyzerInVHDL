----------------------------------------------------------------------------------
-- Engineer:    Gert-Jan Andries <info@gertjanandries.com>
-- Project:     VHDL Audio Spectrum Analyzer - Zynq 7000 Zedboard
-- Description: An interface for the adau1761 audio codec
----------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
    use UNISIM.VComponents.all;
    
entity adau1761_if is
    Port ( lr_clk : in STD_LOGIC;
    b_clk : in STD_LOGIC;
    sdata : in STD_LOGIC;
    sample_l : out STD_LOGIC_VECTOR (15 downto 0);
    sample_r : out STD_LOGIC_VECTOR (15 downto 0);
    sample_clk : out std_logic;		   
    audio_sample_in_l : in STD_LOGIC_VECTOR (15 downto 0);
    audio_sample_in_r : in STD_LOGIC_VECTOR (15 downto 0);
    serial_data_out : out std_logic
	);
end adau1761_if;

architecture Behavioral of adau1761_if is
    
	signal s_sdata_cntr : integer range 0 to 64;
	signal s_lr_clk : std_logic;
	signal s_sample_l : std_logic_vector(15 downto 0);
	signal s_sample_r : std_logic_vector(15 downto 0);
	signal s_sample_l_out : std_logic_vector(15 downto 0);
	signal s_sample_r_out : std_logic_vector(15 downto 0);
	signal s_sample_clk_en : std_logic;	
	signal s_sample : std_logic_vector(63 downto 0) := (others => '0'); 
    
begin
    
	process(b_clk)
	begin
		if rising_edge(b_clk) then
			s_lr_clk <= lr_clk;
			
			if s_lr_clk = '1' and lr_clk = '0' then 
				s_sdata_cntr <= 0;
				s_sample_l_out <= s_sample_l;
				s_sample_r_out <= s_sample_r;
				s_sample_clk_en <= '1';
				s_sample <= audio_sample_in_l & x"0000" & audio_sample_in_r & x"0000";
			else
				s_sdata_cntr <= s_sdata_cntr + 1;
				s_sample_l_out <= s_sample_l_out;
				s_sample_r_out <= s_sample_r_out;
				s_sample_clk_en <= '0';
				
				s_sample <= s_sample(s_sample'high-1 downto 0) & '0';
			end if;
            
			if s_sdata_cntr < 17 then
				s_sample_l <= s_sample_l(14 downto 0) & sdata;
			else
				s_sample_l <= s_sample_l;
			end if;
			
			if s_sdata_cntr-32 < 17 then
				s_sample_r <= s_sample_r(14 downto 0) & sdata;
			else
				s_sample_r <= s_sample_r;
			end if;
            
		end if;
	end process;
    
	serial_data_out <= s_sample(s_sample'high);	
	sample_l <= s_sample_l_out;
	sample_r <= s_sample_r_out;
	
	BUFGCE_inst : BUFGCE
		port map (
			O => sample_clk,   
			CE => s_sample_clk_en, 
			I => b_clk   
		);
    
end Behavioral;
