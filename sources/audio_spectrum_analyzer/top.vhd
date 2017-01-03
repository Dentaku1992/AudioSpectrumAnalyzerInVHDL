----------------------------------------------------------------------------------
-- Engineer:    Gert-Jan Andries <info@gertjanandries.com>
-- Project:     VHDL Audio Spectrum Analyzer - Zynq 7000 Zedboard
-- Description: Top level project
----------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;    
    use IEEE.NUMERIC_STD.ALL;
    
entity top is
    Port ( 
        clk_main_in: std_logic; 
        m_clk : out std_logic;  
        lr_clk : out std_logic; 
        b_clk : out std_logic; 
        sdata : in std_logic; 
        sda : out std_logic; 
        scl : out std_logic; 
        i2c_addr : out std_logic_vector(1 downto 0); 
        serial_data_out : out std_logic ;        
        vga_r         : out  STD_LOGIC_VECTOR (3 downto 0);
        vga_g         : out  STD_LOGIC_VECTOR (3 downto 0);
        vga_b         : out  STD_LOGIC_VECTOR (3 downto 0);
        vga_hs        : out  STD_LOGIC;
        vga_vs        : out  STD_LOGIC;        
        hdmi_clk      : out  STD_LOGIC;
        hdmi_hsync    : out  STD_LOGIC;
        hdmi_vsync    : out  STD_LOGIC;
        hdmi_d        : out  STD_LOGIC_VECTOR (15 downto 0);
        hdmi_de       : out  STD_LOGIC;
        hdmi_scl      : out  STD_LOGIC;
        hdmi_sda      : inout  STD_LOGIC;        
        button_dotmode : in std_logic;
        button_edgemode : in std_logic;
        button_theme : in std_logic;
        button_gridmode : in std_logic;
        button_averaging : in std_logic;
        button_rounding : in std_logic;
        button_peakmode : in std_logic;        
        SCLK  : out STD_LOGIC;
        DC    : out STD_LOGIC;
        RES     : out STD_LOGIC;
        VBAT  : out STD_LOGIC;
        VDD     : out STD_LOGIC;
        pusher: in STD_LOGIC;
        reset : in std_logic; --p16
        LED0 : out STD_LOGIC;
        LED1 : out STD_LOGIC;
        LED2 : out STD_LOGIC;
        LED3 : out STD_LOGIC;
        LED4 : out STD_LOGIC;
        LED5 : out STD_LOGIC;
        LED6 : out STD_LOGIC;
        LED7 : out STD_LOGIC
    );
END top;

ARCHITECTURE Behavioral OF top IS
    
    COMPONENT clk_wiz_0
        PORT(
            clk_in1           : in     std_logic;
            clk_100M          : out    std_logic;
            clk_12M288          : out    std_logic;
            clk_75M          : out    std_logic;
            clk_150M          : out    std_logic;
            reset             : in     std_logic;
            locked            : out    std_logic
        );
    END COMPONENT;
    
    ATTRIBUTE SYN_BLACK_BOX : BOOLEAN;
    ATTRIBUTE SYN_BLACK_BOX OF clk_wiz_0 : COMPONENT IS TRUE;
    ATTRIBUTE BLACK_BOX_PAD_PIN : STRING;
    ATTRIBUTE BLACK_BOX_PAD_PIN OF clk_wiz_0 : COMPONENT IS "clk_in1,clk_100M,clk_12M288,reset,locked";
    
    COMPONENT oled_top 
        Port ( 
            CLK     : in  STD_LOGIC;
            RST     : in  STD_LOGIC;
            SDIN    : out STD_LOGIC;
            SCLK    : out STD_LOGIC;
            DC        : out STD_LOGIC;
            RES        : out STD_LOGIC;
            VBAT    : out STD_LOGIC;
            VDD        : out STD_LOGIC;
            DATA_IN : in STD_LOGIC_VECTOR( 19 DOWNTO 0);
            ENABLE  : in STD_LOGIC;
            INIT_READY : out STD_LOGIC;
            TEXT_READY : out STD_LOGIC
        );
    end COMPONENT;
    
    COMPONENT fft_output_blockmem
        PORT (
            clka : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
            clkb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT audio_if IS
        PORT ( 
            clk_100M_in : in std_logic;
            clk_12M288 : in std_logic;
            m_clk : out std_logic;
            lr_clk : out std_logic;
            b_clk : out std_logic;
            sdata : in std_logic;
            sda : out std_logic;
            scl : out std_logic;
            i2c_addr : out std_logic_vector(1 downto 0);
            sample_clk : out std_logic;
            sample_l : out std_logic_vector(15 downto 0);
            sample_r : out std_logic_vector(15 downto 0);            
            audio_sample_in_l : in STD_LOGIC_VECTOR (15 downto 0);
            audio_sample_in_r : in STD_LOGIC_VECTOR (15 downto 0);
            serial_data_out : out std_logic            
        );
    END COMPONENT;
    
    component mem_control is
        Port (
            clk_100M : in std_logic;
            sample_clk_in: in std_logic;
            ready_enable_out : out std_logic;
            last_flag : out std_logic;
            
            write_address: out std_logic_vector(9 downto 0);
            read_address: out std_logic_vector(9 downto 0) 
        );
    end component;
    
    COMPONENT blk_mem_samples
        PORT (
            clka : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT block_mem_hamming_values
        PORT (
            clka : IN STD_LOGIC;
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT hamming_multiplier
        PORT (
            CLK : IN STD_LOGIC;
            A : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            B : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            P : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT xfft_dual_channel
        PORT (
            aclk : IN STD_LOGIC;
            s_axis_config_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            s_axis_config_tvalid : IN STD_LOGIC;
            s_axis_config_tready : OUT STD_LOGIC;
            s_axis_data_tdata : IN STD_LOGIC_VECTOR(95 DOWNTO 0);
            s_axis_data_tvalid : IN STD_LOGIC;
            s_axis_data_tready : OUT STD_LOGIC;
            s_axis_data_tlast : IN STD_LOGIC;
            m_axis_data_tdata : OUT STD_LOGIC_VECTOR(159 DOWNTO 0);
            m_axis_data_tvalid : OUT STD_LOGIC;
            m_axis_data_tready : IN STD_LOGIC;
            m_axis_data_tlast : OUT STD_LOGIC;
            event_frame_started : OUT STD_LOGIC;
            event_tlast_unexpected : OUT STD_LOGIC;
            event_tlast_missing : OUT STD_LOGIC;
            event_status_channel_halt : OUT STD_LOGIC;
            event_data_in_channel_halt : OUT STD_LOGIC;
            event_data_out_channel_halt : OUT STD_LOGIC
        );
    END COMPONENT;
    
    component fft_read_address_generator 
        Port (
            clk_100M : in std_logic;
            fft_ready_to_read: in std_logic;
            
            write_address: out std_logic_vector(8 downto 0)
        );
    end component;
    
    component vga_hdmi
        Port ( clk_100       : in  STD_LOGIC;
        
        vga_r         : out  STD_LOGIC_VECTOR (3 downto 0);
        vga_g         : out  STD_LOGIC_VECTOR (3 downto 0);
        vga_b         : out  STD_LOGIC_VECTOR (3 downto 0);
        vga_hs        : out  STD_LOGIC;
        vga_vs        : out  STD_LOGIC;
        
        hdmi_clk      : out  STD_LOGIC;
        hdmi_hsync    : out  STD_LOGIC;
        hdmi_vsync    : out  STD_LOGIC;
        hdmi_d        : out  STD_LOGIC_VECTOR (15 downto 0);
        hdmi_de       : out  STD_LOGIC;
        hdmi_scl      : out  STD_LOGIC;
        hdmi_sda      : inout  STD_LOGIC;
        
        button_dotmode : in std_logic;
        button_edgemode : in std_logic;
        button_theme : in std_logic;
        button_gridmode : in std_logic;
        button_averaging : in std_logic;
        button_rounding : in std_logic;
        button_peakmode : in std_logic;
        
        data_address : out std_logic_vector(8 downto 0);
        data_data : in std_logic_vector(17 downto 0);
        oled_data  : in STD_LOGIC
        );
        
    end component;
    
    COMPONENT Delay
        PORT(
            CLK        : IN  std_logic;
            RST        : IN  std_logic;
            DELAY_MS   : IN  std_logic_vector(11 downto 0);
            DELAY_EN   : IN  std_logic;
            DELAY_FIN  : OUT std_logic
        );
    END COMPONENT;
    
    --signals
    signal s_clk_100M : std_logic;
    signal s_clk_12M288: std_logic; 
    signal s_clk_75M : std_logic;
    signal s_clk_150M : std_logic;    
    signal s_sample_clk: std_logic;
    signal s_sample_l :  std_logic_vector(15 downto 0);
    signal s_sample_r :  std_logic_vector(15 downto 0);    
    signal s_write_address:  std_logic_vector(9 downto 0);
    signal s_read_address:  std_logic_vector(9 downto 0); 
    signal s_ready_enable_out :  std_logic;
    signal s_last_flag : std_logic;    
    signal s_bock_mem_sample_out_l: std_logic_vector(15 downto 0);
    signal s_bock_mem_sample_out_r: std_logic_vector(15 downto 0);    
    signal s_hamming_value : std_logic_vector(7 downto 0);    
    signal s_left_channel_after_hamming :std_logic_vector(23 downto 0);
    signal s_right_channel_after_hamming :std_logic_vector(23 downto 0);    
    signal s_ready_enable_1_delay : std_logic := '0';
    signal s_ready_enable_2_delay : std_logic := '0';
    signal s_last_flag_1_delay : std_logic := '0' ;
    signal s_last_flag_2_delay : std_logic := '0' ;    
    signal s_left_channel_after_fft : std_logic_vector(34 downto 0); 
    signal s_right_channel_after_fft : std_logic_vector(34 downto 0);     
    signal s_fres_spec_ready : std_logic;    
    signal s_fft_ready_generated_address: std_logic_vector(8 downto 0);    
    signal s_fft_data_to_hdmi : std_logic_vector(17 downto 0);    
    signal s_serial_data_out : std_logic;
    signal s_lr_clk : std_logic;    
    --state machine
    signal s_oled_data_input : std_logic := '0'; 
    type states is (Init,StartUpText1,StartUpText2,Hdmi, Oled);
    signal current_state : states := Init;  
    --oled
    signal s_oled_sclk : std_logic := '0'; 
    signal s_oled_text_in : std_logic_vector(19 downto 0) := "00000000000000000000";
    signal s_oled_init_ready : std_logic := '0'; 
    signal s_oled_text_ready : std_logic := '0';     
    signal s_current_text_data : std_logic_vector(19 downto 0) := "00010000100001000010";
    signal s_previous_text_data : std_logic_vector(19 downto 0) := "00010000100001000010";
    signal s_temp_oled_data : std_logic_vector(19 downto 0) := (others => '0');
    signal s_hdmi_clk : std_logic := '0';     
    signal s_delay_reset : std_logic := '0';
    signal temp_delay_fin : std_logic := '0';
    signal temp_delay_en : std_logic := '0';
    signal temp_delay_ms : std_logic_vector := "000000000011";    
    signal oled_text_systemdesign : std_logic_vector(4 downto 0) := "00000"; 
    signal oled_text_with_vhdl : std_logic_vector(4 downto 0) := "00001"; 
    signal oled_text_project_made_by : std_logic_vector(4 downto 0) := "00010"; 
    signal oled_text_gert_jan_andries : std_logic_vector(4 downto 0) := "00011"; 
    signal oled_text_xavier_dejager : std_logic_vector(4 downto 0) := "00100"; 
    signal oled_text_nick_steen : std_logic_vector(4 downto 0) := "00101"; 
    signal oled_text_continuous : std_logic_vector(4 downto 0) := "00110"; 
    signal oled_text_rectangular : std_logic_vector(4 downto 0) := "00111"; 
    signal oled_text_rounded_rect : std_logic_vector(4 downto 0) := "01000"; 
    signal oled_text_top_continuous : std_logic_vector(4 downto 0) := "01001"; 
    signal oled_text_top_blocks : std_logic_vector(4 downto 0) := "01010"; 
    signal oled_text_green_orange_red : std_logic_vector(4 downto 0) := "01011"; 
    signal oled_text_orange_red : std_logic_vector(4 downto 0) := "01100"; 
    signal oled_text_single_sample : std_logic_vector(4 downto 0) := "01101"; 
    signal oled_text_averaged_sample : std_logic_vector(4 downto 0) := "01110"; 
    signal oled_text_empty : std_logic_vector(4 downto 0) := "11111";
    -- hdmi
    signal s_data_address : std_logic_vector(8 downto 0);
    signal s_data_data : std_logic_vector(17 downto 0);    
    signal dina_in : std_logic_vector(69 downto 0);
    
begin
    
    INST_CLOCKING : clk_wiz_0
        port map ( 
            clk_in1 => clk_main_in,
            clk_100M => s_clk_100M,
            clk_12M288 => s_clk_12M288,
            clk_75M  => s_clk_75M,
            clk_150M  => s_clk_150M,             
            reset => '0',
            locked => open            
        );
    
    INST_AUDIO_INTERFACE: audio_if
        port map(
            clk_100M_in => s_clk_100M ,
            clk_12M288 => s_clk_12M288 ,
            m_clk => m_clk,
            lr_clk => s_lr_clk,
            b_clk => b_clk,
            sdata => sdata,
            sda => sda,
            scl => scl,
            i2c_addr => i2c_addr,
            sample_clk => s_sample_clk,
            sample_l=> s_sample_l,
            sample_r => s_sample_r,            
            audio_sample_in_l => s_sample_l,
            audio_sample_in_r => s_sample_r,
            serial_data_out => s_serial_data_out            
        );
    
    INST_MEM_CONTROL: mem_control
        port map (
            clk_100M  => s_clk_100M,
            sample_clk_in => s_sample_clk ,
            ready_enable_out => s_ready_enable_out,
            last_flag => s_last_flag ,                     
            write_address => s_write_address ,
            read_address =>  s_read_address
        );
    
    AUDIO_SAMPLE_BLOCK_MEM : blk_mem_samples
        port map (
            clka => s_sample_clk,
            wea => "1",
            addra => s_write_address,
            dina => s_sample_l & s_sample_r,
            clkb => s_clk_100M,
            enb => s_ready_enable_out,
            addrb => s_read_address,
            doutb(15 downto 0) => s_bock_mem_sample_out_l ,
            doutb(31 downto 16) => s_bock_mem_sample_out_r
        );
    
    BLOCK_MEM_HAMMING : block_mem_hamming_values
        PORT MAP (
            clka => s_clk_100M,
            addra => s_read_address,
            douta => s_hamming_value
        );
    
    HAMMING_MUL_LEFT : hamming_multiplier
        PORT MAP (
            CLK => s_clk_100M,
            A => s_bock_mem_sample_out_l,
            B => s_hamming_value,
            P => s_left_channel_after_hamming
        );
    
    HAMMING_MUL_RIGHT : hamming_multiplier
        PORT MAP (
            CLK => s_clk_100M,
            A => s_bock_mem_sample_out_r,
            B => s_hamming_value,
            P => s_right_channel_after_hamming
        );
    FFT_LR : xfft_dual_channel
        PORT MAP (
            
            aclk => s_clk_100M,
            s_axis_config_tdata => "00000011",
            s_axis_config_tvalid => '1',
            s_axis_config_tready => open,
            
            s_axis_data_tdata(71 downto 48) => s_left_channel_after_hamming,
            s_axis_data_tdata(23 downto 0) => s_right_channel_after_hamming,
            s_axis_data_tdata(47 downto 24) => "000000000000000000000000",
            s_axis_data_tdata(95 downto 72) => "000000000000000000000000",
            
            s_axis_data_tvalid => s_ready_enable_2_delay,
            s_axis_data_tready => open,
            s_axis_data_tlast => s_last_flag_1_delay,
            
            m_axis_data_tdata(114 downto 80) => s_left_channel_after_fft,
            m_axis_data_tdata(34 downto 0) => s_right_channel_after_fft,
            m_axis_data_tdata(159 downto 115) => open,
            m_axis_data_tdata(79 downto 35) => open,
            
            m_axis_data_tvalid => s_fres_spec_ready,
            m_axis_data_tready => '1',
            m_axis_data_tlast =>open,
            event_frame_started => open,
            event_tlast_unexpected => open,
            event_tlast_missing => open,
            event_status_channel_halt => open,
            event_data_in_channel_halt => open,
            event_data_out_channel_halt => open
        ); 
    
    DELAY_COMP: Delay 
        PORT MAP (
            CLK         => s_clk_100M,
            RST         => s_delay_reset,
            DELAY_MS    => temp_delay_ms,
            DELAY_EN    => temp_delay_en,
            DELAY_FIN   => temp_delay_fin
        );
    
    fft_output_mem : fft_output_blockmem
        PORT MAP (
            clka => s_clk_100M,
            wea => "1",
            addra => s_fft_ready_generated_address,
            
            dina(17 downto 9) => dina_in(61 downto 53), 
            dina(8 downto 0) => dina_in(26 downto 18), 
            
            clkb => s_clk_75M,
            addrb => s_data_address,
            doutb => s_data_data
        );      
    
    FFT_READ_ADDR_GEN : fft_read_address_generator 
        Port map (
            clk_100M => s_clk_100M,
            fft_ready_to_read => s_fres_spec_ready,                                      
            write_address => s_fft_ready_generated_address
        ); 
    
    OLED_TEXT:  oled_top 
        Port map ( 
            CLK      => s_clk_100M ,
            RST      => reset,     
            SDIN     => s_oled_data_input,    
            SCLK     => s_oled_sclk,
            DC       => DC,    
            RES      => RES, 
            VBAT     =>VBAT ,
            VDD      => VDD,  
            DATA_IN  => s_current_text_data,
            ENABLE   => '1',
            INIT_READY  => s_oled_init_ready , 
            TEXT_READY  => s_oled_text_ready
            
        );
    
    inst_vga_hdmi : vga_hdmi
        Port map ( 
            clk_100      => s_clk_100M,
            
            vga_r         => vga_r,
            vga_g         => vga_g,
            vga_b         => vga_b,
            vga_hs        => vga_hs,
            vga_vs        => vga_vs,
            
            hdmi_clk      => hdmi_clk,
            hdmi_hsync    => hdmi_hsync,
            hdmi_vsync    => hdmi_vsync,
            hdmi_d        => hdmi_d,
            hdmi_de       => hdmi_de,
            hdmi_scl      => hdmi_scl,
            hdmi_sda      => hdmi_sda,
            
            button_dotmode => button_dotmode,
            button_edgemode => button_edgemode,
            button_theme => button_theme,
            button_gridmode => button_gridmode,
            button_averaging => button_averaging,
            button_rounding => button_rounding,
            button_peakmode => button_peakmode,
            
            data_address => s_data_address,
            data_data => s_data_data,
            
            oled_data  => s_oled_data_input
        );
    
    serial_data_out <= s_serial_data_out;
    lr_clk <= s_lr_clk;
    
    SCLK <= s_oled_sclk;
    
    temp_delay_ms <= "000000000011" when (current_state = Oled ) else "111111111111";
    
    process(s_clk_100M)
    begin
        dina_in(69 downto 35) <=  std_logic_vector(unsigned(abs(signed(s_left_channel_after_fft))));
        dina_in(34 downto 0) <=  std_logic_vector(unsigned(abs(signed(s_right_channel_after_fft))));
        if rising_edge(s_clk_100M) then
            s_ready_enable_2_delay <= s_ready_enable_1_delay;
            s_ready_enable_1_delay <=  s_ready_enable_out;
            s_last_flag_2_delay  <= s_last_flag_1_delay ;
            s_last_flag_1_delay <= s_last_flag;   
            
            s_previous_text_data <= s_current_text_data;
            
            if(reset = '1') then 
                current_state <= StartUpText1;
                s_current_text_data <= oled_text_empty & oled_text_empty & oled_text_empty &oled_text_empty;
            else
                current_state <= current_state;
                --complete assign
            end if;
            
            
            case current_state is
                when Init =>
                    if(s_oled_init_ready = '1') then
                        current_state <= StartUpText1;                        
                    else
                        current_state <= current_state;
                    end if;
                when StartUpText1 =>
                    temp_delay_en <= '1';
                    s_delay_reset <= '0';
                    s_current_text_data <= oled_text_empty & oled_text_project_made_by  & oled_text_with_vhdl & oled_text_systemdesign;
                    if(temp_delay_fin = '1') then
                        current_state <= StartUpText2;
                        temp_delay_en <= '0';
                        s_delay_reset <= '1';
                        
                    else                        
                        current_state <= current_state;
                    end if;
                when StartUpText2 =>
                    temp_delay_en <= '1';
                    s_delay_reset <= '0';
                    s_current_text_data <= oled_text_empty & oled_text_xavier_dejager  & oled_text_nick_steen &oled_text_gert_jan_andries;
                    if(temp_delay_fin = '1') then
                        current_state <= Hdmi;
                        temp_delay_en <= '0';
                        s_delay_reset <= '1';
                    else                        
                        current_state <= current_state;
                    end if;
                when Hdmi => 
                    s_current_text_data <= s_temp_oled_data;
                    temp_delay_en <= '0';                    
                    ------------------------------------------------------
                    if (button_gridmode = '1') then                
                        s_temp_oled_data(9 downto 5) <= oled_text_rectangular ;
                        LED3 <= '1';
                    else               
                        LED3 <= '0';
                    end if;
                    if (button_theme = '1') then
                        s_temp_oled_data <= s_current_text_data(19 downto 5) & oled_text_orange_red ;
                        LED2 <= '1';
                    else
                        s_temp_oled_data <= s_current_text_data(19 downto 5) & oled_text_green_orange_red ;
                        LED2 <= '0';
                    end if;
                    if (button_dotmode = '1') then
                        s_temp_oled_data(9 downto 5) <= oled_text_rectangular ;
                        LED0 <= '1';
                    else
                        s_temp_oled_data(9 downto 5) <= oled_text_continuous ;
                        LED0 <= '0';
                    end if;
                    if (button_edgemode  = '1') then
                        --TODO
                        LED1 <= '1';
                    else
                        -- TODO
                        LED1 <= '0';
                    end if;
                    if (button_averaging = '1') then
                        s_temp_oled_data(19 downto 15) <= oled_text_single_sample ;
                        LED4 <= '1';
                    else
                        s_temp_oled_data(19 downto 15) <= oled_text_averaged_sample ;
                        LED4 <= '0';
                    end if;
                    if (button_rounding = '1') then
                        s_temp_oled_data(9 downto 5) <= oled_text_rounded_rect ;
                        LED5 <= '1';
                    else
                        --TODO
                        LED5 <= '0';
                    end if;
                    if (button_peakmode = '1') then
                        --s_temp_oled_data <= ;   -- "TODO" ;
                        LED6 <= '1';
                    else
                        --TODO
                        LED6 <= '0';
                    end if;
                    -----------------------------------------------------                    
                    if(s_current_text_data = s_previous_text_data) then
                        current_state <= current_state;    
                    else
                        current_state <= Oled;
                    end if;
                    
                    s_current_text_data <= s_temp_oled_data;                    
                when Oled =>
                    s_current_text_data <= s_temp_oled_data;
                    temp_delay_en <= '1';
                    s_delay_reset <= '0';
                    if(temp_delay_fin = '1') then
                        current_state <= Hdmi;
                        temp_delay_en <= '0';
                        s_delay_reset <= '1';
                    else                        
                        current_state <= current_state;
                    end if;
                when others =>    
                    current_state <= Hdmi;
            end case;
            
        end if;
    end process;
    
end Behavioral;
