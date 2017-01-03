----------------------------------------------------------------------------------
-- Engineer:    Gert-Jan Andries - info@gertjanandries.com
-- Project:     VHDL Audio Spectrum Analyzer - Zynq 7000 Zedboard
-- Description: Oled text module
----------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.NUMERIC_STD.all;
    
entity OledText is
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
end OledText;

architecture Behavioral of OledText is
    
    COMPONENT SpiCtrl
        PORT(
            CLK        : IN  std_logic;
            RST        : IN  std_logic;
            SPI_EN     : IN  std_logic;
            SPI_DATA   : IN  std_logic_vector(7 downto 0);
            CS         : OUT std_logic;
            SDO        : OUT std_logic;
            SCLK       : OUT std_logic;
            SPI_FIN    : OUT std_logic
        );
    END COMPONENT;
    
    COMPONENT Delay
        PORT(
            CLK        : IN  std_logic;
            RST        : IN  std_logic;
            DELAY_MS   : IN  std_logic_vector(11 downto 0);
            DELAY_EN   : IN  std_logic;
            DELAY_FIN  : OUT std_logic
        );
    END COMPONENT;
    
    COMPONENT charLib
        PORT  (
            clka    : IN    STD_LOGIC; 
            addra   : IN    STD_LOGIC_VECTOR(10 DOWNTO 0); 
            douta   : OUT   STD_LOGIC_VECTOR(7 DOWNTO 0) 
        );
    END COMPONENT;
    
    COMPONENT addressMultiplier
        PORT (
            A : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
            P : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT textMemory
        PORT (
            clka    : IN    STD_LOGIC;
            addra   : IN    STD_LOGIC_VECTOR(8 DOWNTO 0);
            douta   : OUT   STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;
    
    type states is (
        Idle,
        ClearDC,
        SetPage,
        PageNum,
        LeftColumn1,
        LeftColumn2,
        SetDC,
        UpdateScreen,
        SendChar1,
        SendChar2,
        SendChar3,
        SendChar4,
        SendChar5,
        SendChar6,
        SendChar7,
        SendChar8,
        ReadMem,
        ReadMem2,
        Done,
        Trans1,
        Trans2,
        Trans3,
        Trans4,
        Trans5,
        set_line_2,
        set_line_3,
        set_line_4,
        read_line,
        clean_screen,
        process_data_in,
        delay_one_clock,
        delay_three_clocks,
        delay_three_clocks_stage1,
        delay_three_clocks_stage2,
        get_start_address,
        textscreen,  
        Wait1                  
    );
    
    type OledMem is array(0 to 3, 0 to 15) of STD_LOGIC_VECTOR(7 downto 0);
    signal current_screen : OledMem; 
    
    constant clear_screen : OledMem :=  (
    (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),    
    (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
    (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
    (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20")
    );
    
    signal text_screen : OledMem    :=  (
    (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),    
    (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
    (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
    (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20")
    );
    
    signal current_state            : states := Idle;
    signal after_state              : states;
    signal after_page_state         : states;
    signal after_char_state         : states;
    signal after_update_state       : states;
    signal after_delay_one_clock    : states;
    signal after_delay_three_clocks : states;
    signal after_read_line_state    : states;    
    signal temp_dc                  : STD_LOGIC := '0';
    signal temp_delay_ms            : STD_LOGIC_VECTOR (11 downto 0); 
    signal temp_delay_en            : STD_LOGIC := '0'; 
    signal temp_delay_fin           : STD_LOGIC;
    signal temp_spi_en              : STD_LOGIC := '0'; 
    signal temp_spi_data            : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal temp_spi_fin             : STD_LOGIC; 
    signal temp_char                : STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); 
    signal temp_addr                : STD_LOGIC_VECTOR (10 downto 0) := (others => '0'); 
    signal temp_dout                : STD_LOGIC_VECTOR (7 downto 0); 
    signal temp_page                : STD_LOGIC_VECTOR (1 downto 0) := (others => '0'); 
    signal temp_index               : integer range 0 to 15 := 0;     
    signal s_data_in                : STD_LOGIC_VECTOR(19 downto 0) := (others => '0'); 
    signal previous_data_in         : STD_LOGIC_VECTOR(19 downto 0) := (others => '0'); 
    signal addres_line_to_multiply  : STD_LOGIC_VECTOR(4 downto 0) := (others => '0'); 
    signal start_address_out        : STD_LOGIC_VECTOR(8 downto 0) := (others => '0'); 
    signal address_of_char_in_memory: integer range 0 to 511;
    signal text_memory_char_out     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal temp                     : std_logic := '0';
    signal address_to_lookup        : std_logic_vector(8 downto 0) := "000000000";
    signal row_counter              : integer range 0 to 3 := 0; 
    signal char_counter             : integer range 0 to 15 := 0;       
    signal TEMP1                    : std_logic_vector(8 downto 0);
    
begin
    address_to_lookup <= std_logic_vector(to_unsigned(address_of_char_in_memory,9));
    DC <= temp_dc;
    FIN <= '1' when (current_state = Done) else '0';
    
    SPI_COMP: SpiCtrl 
        PORT MAP (
            CLK         => CLK,
            RST         => RST,
            SPI_EN      => temp_spi_en,
            SPI_DATA    => temp_spi_data,
            CS          => CS,
            SDO         => SDO,
            SCLK        => SCLK,
            SPI_FIN     => temp_spi_fin
        );
    
    DELAY_COMP: Delay 
        PORT MAP (
            CLK         => CLK,
            RST         => RST,
            DELAY_MS    => temp_delay_ms,
            DELAY_EN    => temp_delay_en,
            DELAY_FIN   => temp_delay_fin
        );
    
    CHAR_LIB_COMP : charLib
        PORT MAP (
            clka    => CLK,
            addra   => temp_addr,
            douta   => temp_dout
        );
    
    ADDRESS_MULTIPLIER : addressMultiplier
        PORT MAP (
            A             => addres_line_to_multiply,
            P(8 downto 0) => start_address_out,
            P(9)          => temp
        ); 
    
    TEXT_MEMORY : textMemory
        PORT MAP (
            clka    => CLK,
            addra   => address_to_lookup,
            douta   => text_memory_char_out
        );
    
    process(CLK)
    begin
        if(rising_edge(CLK))then
            case(current_state) is
            ------------------------------------------------------------------------------------------
            when Idle =>                    
                if(EN = '1') then
                    current_state <= process_data_in;
                    after_page_state <= clean_screen;
                    previous_data_in <= DATA_IN;
                    temp_page <= "00";
                    row_counter <= 0;
                    char_counter <= 0;    
                    READY <= '0';             
                end if;
                ------------------------------------------------------------------------------------------
            when delay_one_clock =>
                current_state <= after_delay_one_clock;
                ------------------------------------------------------------------------------------------
            when delay_three_clocks =>
                current_state <= delay_three_clocks_stage1;
                ------------------------------------------------------------------------------------------
            when delay_three_clocks_stage1 =>
                current_state <= delay_three_clocks_stage2;
                ------------------------------------------------------------------------------------------
            when delay_three_clocks_stage2 =>
                current_state <= after_delay_three_clocks;
                ------------------------------------------------------------------------------------------
            when process_data_in =>
                s_data_in <= DATA_IN;
                addres_line_to_multiply <= DATA_IN(4 downto 0);                    
                after_delay_one_clock <= get_start_address;     
                after_read_line_state <= set_line_2;               
                current_state <= delay_one_clock;
                ------------------------------------------------------------------------------------------                    
            when get_start_address =>
                address_of_char_in_memory <= conv_integer(start_address_out);          
                after_delay_three_clocks <= read_line;
                current_state <= delay_three_clocks;
                ------------------------------------------------------------------------------------------
            when read_line =>
                if(char_counter = 15) then
                    text_screen(row_counter,char_counter) <= text_memory_char_out;
                    char_counter <= 0;
                    row_counter <= row_counter + 1;
                    current_state <= after_read_line_state;
                else
                    text_screen(row_counter,char_counter) <= text_memory_char_out;
                    after_delay_three_clocks <= read_line;
                    current_state <= delay_three_clocks;
                    char_counter <= char_counter + 1;
                    address_of_char_in_memory <= address_of_char_in_memory + 1;                        
                end if;
                ------------------------------------------------------------------------------------------
            when set_line_2 =>
                addres_line_to_multiply <=  s_data_in(9 downto 5);
                current_state <= get_start_address;
                after_read_line_state <= set_line_3;
                ------------------------------------------------------------------------------------------  
            when set_line_3 =>
                addres_line_to_multiply  <=   s_data_in(14 downto 10);
                current_state <= get_start_address;
                after_read_line_state <= set_line_4;
                ------------------------------------------------------------------------------------------ 
            when set_line_4 =>
                addres_line_to_multiply  <=  s_data_in(19 downto 15);
                current_state <= get_start_address;
                after_read_line_state <= ClearDC;
                ------------------------------------------------------------------------------------------ 
            when ClearDC =>
                temp_dc <= '0';
                current_state <= SetPage;
                ------------------------------------------------------------------------------------------
            when SetPage =>
                temp_spi_data <= "00100010";
                after_state <= PageNum;
                current_state <= Trans1;
                ------------------------------------------------------------------------------------------
            when PageNum =>
                temp_spi_data <= "000000" & temp_page;
                after_state <= LeftColumn1;
                current_state <= Trans1;
                ------------------------------------------------------------------------------------------
            when LeftColumn1 =>
                temp_spi_data <= "00000000";
                after_state <= LeftColumn2;
                current_state <= Trans1;
                ------------------------------------------------------------------------------------------
            when LeftColumn2 =>
                temp_spi_data <= "00010000";
                after_state <= SetDC;
                current_state <= Trans1;
                ------------------------------------------------------------------------------------------
            when SetDC =>
                temp_dc <= '1';
                current_state <= after_page_state;
                ------------------------------------------------------------------------------------------                
            when clean_screen =>
                current_screen <= clear_screen;
                current_state <= UpdateScreen;
                after_update_state <= Wait1;
                ------------------------------------------------------------------------------------------
            when Wait1 => 
                temp_delay_ms <= "000000001000"; 
                after_state <= textscreen;
                current_state <= Trans3;
                ------------------------------------------------------------------------------------------ 
            when textscreen =>
                current_screen <= text_screen;
                after_update_state <= Done;
                current_state <= UpdateScreen;
                ------------------------------------------------------------------------------------------
            when UpdateScreen =>
                temp_char <= current_screen(CONV_INTEGER(temp_page),temp_index);
                if(temp_index = 15) then    
                    temp_index <= 0;
                    temp_page <= temp_page + 1;
                    after_char_state <= ClearDC;
                    if(temp_page = "11") then
                        after_page_state <= after_update_state;
                    else    
                        after_page_state <= UpdateScreen;
                    end if;
                else
                    temp_index <= temp_index + 1;
                    after_char_state <= UpdateScreen;
                end if;
                current_state <= SendChar1;
                ------------------------------------------------------------------------------------------                
            when SendChar1 =>
                temp_addr <= temp_char & "000";
                after_state <= SendChar2;
                current_state <= ReadMem;
                ------------------------------------------------------------------------------------------
            when SendChar2 =>
                temp_addr <= temp_char & "001";
                after_state <= SendChar3;
                current_state <= ReadMem;
                ------------------------------------------------------------------------------------------
            when SendChar3 =>
                temp_addr <= temp_char & "010";
                after_state <= SendChar4;
                current_state <= ReadMem;
                ------------------------------------------------------------------------------------------
            when SendChar4 =>
                temp_addr <= temp_char & "011";
                after_state <= SendChar5;
                current_state <= ReadMem;
                ------------------------------------------------------------------------------------------
            when SendChar5 =>
                temp_addr <= temp_char & "100";
                after_state <= SendChar6;
                current_state <= ReadMem;
                ------------------------------------------------------------------------------------------
            when SendChar6 =>
                temp_addr <= temp_char & "101";
                after_state <= SendChar7;
                current_state <= ReadMem;
                ------------------------------------------------------------------------------------------
            when SendChar7 =>
                temp_addr <= temp_char & "110";
                after_state <= SendChar8;
                current_state <= ReadMem;
                ------------------------------------------------------------------------------------------
            when SendChar8 =>
                temp_addr <= temp_char & "111";
                after_state <= after_char_state;
                current_state <= ReadMem;
                ------------------------------------------------------------------------------------------
            when ReadMem =>
                current_state <= ReadMem2;
                ------------------------------------------------------------------------------------------
            when ReadMem2 =>
                temp_spi_data <= temp_dout;
                current_state <= Trans1;
                ------------------------------------------------------------------------------------------
            when Trans1 =>
                temp_spi_en <= '1';
                current_state <= Trans2;
                ------------------------------------------------------------------------------------------
            when Trans2 =>
                if(temp_spi_fin = '1') then
                    current_state <= Trans5;
                end if;
                ------------------------------------------------------------------------------------------
            when Trans3 =>
                temp_delay_en <= '1';
                current_state <= Trans4;
                ------------------------------------------------------------------------------------------
            when Trans4 =>
                if(temp_delay_fin = '1') then
                    current_state <= Trans5;
                end if;
                ------------------------------------------------------------------------------------------
            when Trans5 =>
                temp_spi_en <= '0';
                temp_delay_en <= '0';
                current_state <= after_state;
                ------------------------------------------------------------------------------------------
            when Done =>
                READY <= '1';
                if(previous_data_in = DATA_IN) then
                    current_state <= Done;
                else
                    current_state <= Idle;
                end if;
                ------------------------------------------------------------------------------------------                    
            when others =>                        
                current_state <= Idle;
                ------------------------------------------------------------------------------------------
            end case;
        end if;
    end process;
end Behavioral;
