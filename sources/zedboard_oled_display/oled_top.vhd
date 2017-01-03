----------------------------------------------------------------------------------
-- Engineer:    Gert-Jan Andries - info@gertjanandries.com
-- Project:     VHDL Audio Spectrum Analyzer - Zynq 7000 Zedboard
-- Description: Oled toplevel
----------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use ieee.std_logic_unsigned.ALL;
    use ieee.std_logic_arith.all;
    
    
entity oled_top is
    Port ( 
        CLK 	: in  STD_LOGIC;
        RST 	: in  STD_LOGIC;
        SDIN	: out STD_LOGIC;
        SCLK	: out STD_LOGIC;
        DC		: out STD_LOGIC;
        RES	    : out STD_LOGIC;
        VBAT	: out STD_LOGIC;
        VDD	    : out STD_LOGIC;
        DATA_IN : in STD_LOGIC_VECTOR( 19 DOWNTO 0);
        ENABLE  : in STD_LOGIC;
        INIT_READY : out STD_LOGIC;
        TEXT_READY : out STD_LOGIC
	);
end oled_top;

architecture Behavioral of oled_top is
    
    COMPONENT Delay
        PORT(
            CLK        : IN  std_logic;
            RST        : IN  std_logic;
            DELAY_MS   : IN  std_logic_vector(11 downto 0);
            DELAY_EN   : IN  std_logic;
            DELAY_FIN  : OUT std_logic
        );
    END COMPONENT;
    
    component OledText is
        Port ( 
            CLK 	    : in  STD_LOGIC; 
            RST      : in  STD_LOGIC; 
            EN       : in  STD_LOGIC; 
            CS       : out STD_LOGIC; 
            SDO      : out STD_LOGIC; 
            SCLK     : out STD_LOGIC; 
            DC       : out STD_LOGIC; 
            FIN      : out STD_LOGIC;
            DATA_IN  : in  STD_LOGIC_VECTOR(19 downto 0);
            READY    : out STD_LOGIC
        );
    end component;
    
    component OledInit is
        Port ( 
            CLK     : in  STD_LOGIC;
            RST     : in  STD_LOGIC;
            EN      : in  STD_LOGIC;
            CS      : out STD_LOGIC;
            SDO     : out STD_LOGIC;
            SCLK    : out STD_LOGIC;
            DC      : out STD_LOGIC;
            RES     : out STD_LOGIC;
            VBAT    : out STD_LOGIC;
            VDD     : out STD_LOGIC;
            INIT_READY_OUT     : out STD_LOGIC
        );
    end component;
    
    type states is (idle, OledInitialize, OledTextState, Done,text2, delay_ms);
    
    signal current_state 	: states := idle;
    
    signal init_en		  : STD_LOGIC := '0';
    signal init_done      : STD_LOGIC;
    signal init_cs        : STD_LOGIC;
    signal init_sdo       : STD_LOGIC;
    signal init_sclk      : STD_LOGIC;
    signal init_dc        : STD_LOGIC;
    signal OledText_en    : STD_LOGIC := '0';
    signal OledText_cs    : STD_LOGIC;
    signal OledText_sdo   : STD_LOGIC;
    signal OledText_sclk  : STD_LOGIC;
    signal OledText_dc    : STD_LOGIC;
    signal OledText_done  : STD_LOGIC;
    signal s_data_in      : std_logic_vector(19 downto 0) := "00000000000000000000";    
    signal CS             : std_logic;    
    signal temp_delay_ms  : std_logic_vector(11 downto 0) := "111100001111";
    signal temp_delay_en  : STD_LOGIC := '0';
    signal temp_delay_fin : STD_LOGIC;
    signal s_oled_ready   : STD_LOGIC := '0';
    signal s_init_ready   : STD_LOGIC := '0';
    
begin
    
    Init: OledInit port map
        (
        CLK => CLK, 
        RST => RST, 
        EN => init_en, 
        CS => init_cs, 
        SDO => init_sdo, 
        SCLK => init_sclk, 
        DC => init_dc, 
        RES => RES, 
        VBAT => VBAT, 
        VDD => VDD,  
        INIT_READY_OUT => s_init_ready
    );
    
    OLED_TEXT: OledText Port map
        (
        CLK => CLK, 
        RST =>RST, 
        EN => OledText_en, 
        CS => OledText_cs, 
        SDO => OledText_sdo, 
        SCLK => OledText_sclk, 
        DC => OledText_dc, 
        FIN => OledText_done,
        DATA_IN => s_data_in, 
        READY => s_oled_ready
    );
    
    DELAY_COMP: Delay PORT MAP (
        CLK => CLK,
        RST => RST,
        DELAY_MS => temp_delay_ms,
        DELAY_EN => temp_delay_en,
        DELAY_FIN => temp_delay_fin
    );
    
    CS     <= init_cs   when (current_state = OledInitialize) else OledText_cs;
    SDIN   <= init_sdo  when (current_state = OledInitialize) else OledText_sdo;
    SCLK   <= init_sclk when (current_state = OledInitialize) else OledText_sclk;
    DC     <= init_dc   when (current_state = OledInitialize) else OledText_dc;
    TEXT_READY <= s_oled_ready;
    
	process(CLK)
    begin
        if(rising_edge(CLK)) then
            if(ENABLE = '1') then  
                if(RST = '1') then
                    current_state <= idle;
                else
                    case(current_state) is
                    ---------------------------------------------
                    when idle =>
                        INIT_READY <= '0';
                        current_state <= OledInitialize;       
                        ---------------------------------------------            
                    when OledInitialize =>
                        init_en <= '1';
                        if(s_init_ready = '1') then
                            INIT_READY <= '1';
                            current_state <= OledTextState;
                        end if;
                        ---------------------------------------------                    
                    when OledTextState =>
                        s_data_in <=  DATA_IN;
                        OledText_en <= '1';
                        init_en <= '0';
                        current_state <= OledTextState;
                    when others =>
                        current_state <= idle;
                        ---------------------------------------------
                    end case;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
