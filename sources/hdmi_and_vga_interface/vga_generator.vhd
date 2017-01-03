----------------------------------------------------------------------------------
-- Engineer:    Xavier Dejager
-- Project:     VHDL Audio Spectrum Analyzer - Zynq 7000 Zedboard
-- Description: VGA generator
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_generator is
	port
	(
		clk   : in   std_logic;
		r     : out  std_logic_vector (7 downto 0);
		g     : out  std_logic_vector (7 downto 0);
		b     : out  std_logic_vector (7 downto 0);
		de    : out  std_logic;
		vsync : out  std_logic := '0';
		hsync : out  std_logic := '0';
		button_dotmode : in std_logic;
		button_edgemode : in std_logic;
		button_theme : in std_logic;
		button_gridmode : in std_logic;
		button_averaging : in std_logic;
		button_rounding : in std_logic;
		button_peakmode : in std_logic;

		data_address : out std_logic_vector(8 downto 0);
		data_data : in std_logic_vector(17 downto 0)
	);
end vga_generator;

architecture behavioral of vga_generator is
	component grad_jet
	port
	(
		clka : in std_logic;
		addra : in std_logic_vector(8 downto 0);
		douta : out std_logic_vector(23 downto 0)
	);
	end component;
	component pixel_map
	port
	(
		clka : in std_logic;
		addra : in std_logic_vector(10 downto 0);
		douta : out std_logic_vector(8 downto 0)
	);
	end component;
	component grad_orange
	port
	(
		clka : in std_logic;
		addra : in std_logic_vector(8 downto 0);
		douta : out std_logic_vector(23 downto 0)
	);
	end component;

	signal 		blanking   	: std_logic := '0';
	signal 		edge        : std_logic := '0';
	signal 		colour      : std_logic_vector (23 downto 0);

	signal		hcounter    : unsigned(11 downto 0) := (others => '0');
	signal 		vcounter    : unsigned(11 downto 0) := (others => '0');

	constant 	zero        : unsigned(11 downto 0) := (others => '0');
	signal   	hvisible    : unsigned(11 downto 0);
	signal   	hstartsync  : unsigned(11 downto 0);
	signal   	hendsync    : unsigned(11 downto 0);
	signal   	hmax        : unsigned(11 downto 0);

	signal   	vvisible    : unsigned(11 downto 0);
	signal   	vstartsync  : unsigned(11 downto 0);
	signal   	vendsync    : unsigned(11 downto 0);
	signal   	vmax        : unsigned(11 downto 0);

	signal   	theme_color  : std_logic_vector(23 downto 0) := (others => '0');
	signal   	jet_theme  : std_logic_vector(23 downto 0) := (others => '0');
	signal   	orange_theme  : std_logic_vector(23 downto 0) := (others => '0');
	signal   	gcounter    : unsigned(11 downto 0) := (others => '0');
	signal		drawcounter	: unsigned(11 downto 0) := (others => '0');
	signal		out_3232_addr_data : std_logic_vector(8 downto 0);
	signal		top_20		: std_logic;
	signal		top_5		: std_logic;
	signal		draw		: std_logic;
	signal 		edgesize	: unsigned(3 downto 0);

	signal		r_0 		: std_logic_vector(7 downto 0) := (others => '0');
	signal		g_0  		: std_logic_vector(7 downto 0) := (others => '0');
	signal		b_0 		: std_logic_vector(7 downto 0) := (others => '0');
	signal		de_0 		: std_logic := '0';
	signal		hsync_0		: std_logic := '0';
	signal		vsync_0		: std_logic := '0';
	signal		r_d_1		: std_logic_vector(7 downto 0) := (others => '0');
	signal		g_d_1 		: std_logic_vector(7 downto 0) := (others => '0');
	signal		b_d_1		: std_logic_vector(7 downto 0) := (others => '0');
	signal		de_d_1		: std_logic := '0';
	signal		hsync_d_1	: std_logic := '0';
	signal		vsync_d_1	: std_logic := '0';
	signal		r_d_2		: std_logic_vector(7 downto 0) := (others => '0');
	signal		g_d_2 		: std_logic_vector(7 downto 0) := (others => '0');
	signal		b_d_2		: std_logic_vector(7 downto 0) := (others => '0');
	signal		de_d_2		: std_logic := '0';
	signal		hsync_d_2	: std_logic := '0';
	signal		vsync_d_2	: std_logic := '0';

	signal		data_FFT	: std_logic_vector(17 downto 0);
	signal		data_LandR  : std_logic_vector(17 downto 0);
	signal		data_Disp  	: std_logic_vector(17 downto 0);
	signal		data 		: unsigned(8 downto 0);
	signal 		old_peakmode : std_logic := '0';

	type average_16 is array (0 to 15) of std_logic_vector(25 downto 0);
	signal average_dataval	: average_16;
	signal som_L			: std_logic_vector(12 downto 0);
	signal som_R			: std_logic_vector(12 downto 0);
	type peak is array (0 to 1279) of unsigned(12 downto 0);
	signal peak_L	: peak;
	signal peak_R	: peak;

begin
	gradient_jet_rom : grad_jet
	port map
	(
		clka => clk,
		addra => std_logic_vector(gcounter(8 downto 0)),
		douta => jet_theme
	);
	bars : pixel_map
	port map
	(
		clka => clk,
		addra => std_logic_vector(hcounter(10 downto 0)),
		douta => out_3232_addr_data
	);

  	data_address <= out_3232_addr_data;
    data_FFT <= data_data;
    
	gradient_orange_rom : grad_orange
	port map
	(
		clka => clk,
		addra => std_logic_vector(gcounter(8 downto 0)),
		douta => orange_theme
	);
	-- set the video mode to 1280x720x60hz (75MHz pixel clock needed)
	hvisible    <= zero + 1280;
	hstartsync  <= zero + 1280+72;
	hendsync    <= zero + 1280+72+80;
	hmax        <= zero + 1280+72+80+216-1;

	vvisible    <= zero + 720;
	vstartsync  <= zero + 720+3;
	vendsync    <= zero + 720+3+5;
	vmax        <= zero + 720+3+5+22-1;

	colour_proc: process(hcounter,vcounter)
	begin
		colour <= x"222222"; --achtergrondkleur

		-- Select theme colors
		if button_theme = '1' then
			theme_color <= orange_theme;
		else
			theme_color <= jet_theme;
		end if;

		-- Drawing the bars
		if gcounter < data then
			draw <= '1';
			if data - gcounter < 16 and button_gridmode = '0' then
				top_20 <= '1';
			elsif data - gcounter < 8 and button_gridmode = '1' then
				top_20 <= '1';
			else
				top_20 <= '0';
			end if;
			if data - gcounter < 4 then
				top_5 <= '1';
			else
				top_5 <= '0';
			end if;
			colour <= theme_color;
		else
			draw <='0';
		end if;

		-- Half brightness for edgemode
		if button_edgemode = '1' and top_5 = '0' and draw = '1' then
			colour <= '0' & theme_color(23 downto 17) & '0' & theme_color(15 downto 9) & '0' & theme_color(7 downto 1);
		end if;

		-- Refill backgroundcolor for dotmode
		if button_dotmode = '1' and top_20 = '0' and draw = '1' then
			colour <= x"222222";
		end if;
		if button_gridmode = '1' and (gcounter(2 downto 0) = 0 or gcounter(2 downto 0) = 7 or drawcounter(3 downto 0) = 0 or drawcounter(3 downto 0) = 15) then
				colour <= x"222222";
		end if;
		if button_rounding = '1' and button_gridmode = '1' and ((gcounter(2 downto 0) = 1 or gcounter(2 downto 0) = 6) and (drawcounter(3 downto 0) = 1 or drawcounter(3 downto 0) = 14)) then
				colour <= x"222222";
		end if;
		if drawcounter > 1279 - 32 then
			colour <= x"222222";
		end if;
	end process;
	clk_process: process (clk)
	begin
		if rising_edge(clk) then
			--delaying output signal, for syncing problem from the 2 cycle memory
			--r <= r_0;
			--g <= g_0;
			--b <= b_0;
			--de <= de_0;

			if button_averaging = '1' then
				som_L <= std_logic_vector(unsigned(data_FFT(17 downto 9)) + unsigned(som_L) - unsigned(average_dataval(15)(25 downto 13)));
				som_R <= std_logic_vector(unsigned(data_FFT(8 downto 0)) + unsigned(som_R) - unsigned(average_dataval(15)(12 downto 0)));
				average_dataval(1 to 15) <= average_dataval(0 to 14);
				average_dataval(0) <= "0000" & data_FFT(17 downto 9) & "0000" & data_FFT(8 downto 0);
				data_Disp <= som_L(12 downto 4) & som_R(12 downto 4);
			else
			data_Disp <= data_FFT;
			end if;

			hsync <= hsync_0;
			vsync <= vsync_0;

			if vcounter >= vvisible or hcounter >= hvisible then
				r <= (others => '0');
				g <= (others => '0');
				b <= (others => '0');
				de <= '0';
			else
				r  <= colour(23 downto 16);
				g  <= colour(15 downto  8);
				b  <= colour( 7 downto  0);
				de <= '1';
			end if;
			-- generate the vsync pulses
			if vcounter = vstartsync then
				vsync_0 <= '1';
			elsif vcounter = vendsync then
				vsync_0 <= '0';
			end if;
			-- generate the hsync pulses
			if hcounter = hstartsync then
				hsync_0 <= '1';
			elsif hcounter = hendsync then
				hsync_0 <= '0';
			end if;

			-- advance the position counters
			if hcounter = hmax  then
				-- starting a new line
				hcounter <= (others => '0');
				if vcounter = vmax then
					vcounter <= (others => '0');
					gcounter <= to_unsigned(360, 12);
				else
					vcounter <= vcounter + 1;
					if vcounter < 360 then
						gcounter <= gcounter - 1;
					elsif vcounter > 360 then
						gcounter <= gcounter + 1;
					else
						gcounter <= (others => '0');
					end if;
				end if;
			else
				hcounter <= hcounter + 1;
				drawcounter <= drawcounter + 1;
				if hcounter = 16 then
					drawcounter <= (others => '0');
				end if;
			end if;
			if vcounter < 360 or vcounter > 719 then
				data <= unsigned(data_LandR(17 downto 9));-- Left channel
			else
				data <= unsigned(data_LandR(8 downto 0));-- Right channel
			end if;
			if button_gridmode = '1' then
				if hcounter(3 downto 0) = "1111" then
					data_LandR <= data_Disp(17 downto 13) & "1000" & data_Disp(8 downto 4) & "1000";
				end if;
			else
				data_LandR <= data_Disp;
			end if;
		end if;
	end process;
end behavioral;