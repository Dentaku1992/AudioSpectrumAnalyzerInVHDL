----------------------------------------------------------------------------------
-- Engineer:    Gert-Jan Andries - info@gertjanandries.com
-- Project:     VHDL Audio Spectrum Analyzer - Zynq 7000 Zedboard
-- Description: SPI controller
----------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    
entity SpiCtrl is
    Port ( CLK 		: in  STD_LOGIC;
    RST 		: in  STD_LOGIC; 
    SPI_EN 	: in  STD_LOGIC; 
    SPI_DATA : in  STD_LOGIC_VECTOR (7 downto 0); 
    CS		: out STD_LOGIC; 
    SDO 		: out STD_LOGIC; 
    SCLK 	: out STD_LOGIC; 
    SPI_FIN	: out STD_LOGIC);
end SpiCtrl;

architecture Behavioral of SpiCtrl is
    
	type states is (
        Idle,
        Send,
        Hold1,
        Hold2,
        Hold3,
        Hold4,
        Done
    );
    
	signal current_state 	: states := Idle; 
	signal shift_register	: STD_LOGIC_VECTOR(7 downto 0); 
	signal shift_counter 	: STD_LOGIC_VECTOR(3 downto 0); 
	signal clk_divided 		: STD_LOGIC := '1'; 
	signal counter 			: STD_LOGIC_VECTOR(4 downto 0) := (others => '0'); 
	signal temp_sdo			: STD_LOGIC := '1'; 
	signal falling 			: STD_LOGIC := '0'; 
    
begin
    clk_divided 	<= 	not counter(4); 
    SCLK 			<= 	clk_divided;
    SDO 			<= 	temp_sdo;
    CS 				<= 	'1' when (current_state = Idle and SPI_EN = '0') 	else	'0';
    SPI_FIN 		<= 	'1' when (current_state = Done) 					else	'0';
    
    STATE_MACHINE : process (CLK)
    begin
        if(rising_edge(CLK)) then
            if(RST = '1') then 
                current_state <= Idle;
            else
                case (current_state) is
                --------------------------------------------------------------
                when Idle => 
                    if(SPI_EN = '1') then
                        current_state <= Send;
                    end if;
                    --------------------------------------------------------------
                when Send => 
                    if(shift_counter = "1000" and falling = '0') then
                        current_state <= Hold1;
                    end if;
                    --------------------------------------------------------------
                when Hold1 => 
                    current_state <= Hold2;
                    --------------------------------------------------------------
                when Hold2 => 
                    current_state <= Hold3;
                    --------------------------------------------------------------
                when Hold3 => 
                    current_state <= Hold4;
                    --------------------------------------------------------------
                when Hold4 =>
                    current_state <= Done;
                    --------------------------------------------------------------
                when Done => 
                    if(SPI_EN = '0') then
                        current_state <= Idle;
                    end if;
                    --------------------------------------------------------------
                when others =>
                    current_state <= Idle;
                    --------------------------------------------------------------
                end case;
            end if;
        end if;
    end process;
    
    CLK_DIV : process (CLK)
    begin
        if(rising_edge(CLK)) then
            if (current_state = Send) then 
                counter <= counter + 1;
            else 
                counter <= (others => '0');
            end if;
        end if;
    end process;
    
    SPI_SEND_BYTE : process (CLK)
    begin
        if(CLK'event and CLK = '1') then
            if(current_state = Idle) then
                shift_counter <= (others => '0');
                shift_register <= SPI_DATA; 
                temp_sdo <= '1';
            elsif(current_state = Send) then
                if( clk_divided = '0' and falling = '0') then 
                    falling <= '1'; 
                    temp_sdo <= shift_register(7);
                    shift_register <= shift_register(6 downto 0) & '0';
                    shift_counter <= shift_counter + 1; 
                elsif(clk_divided = '1') then 
                    falling <= '0';
                end if;
            end if;
        end if;
    end process;
	
end Behavioral;
