library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library unisim;
	use unisim.vcomponents.all;
library work;
	use work.mt_toolbox.all;
	
entity midimux_clklogic is
	port(
		-- clock input
		clk_in_13 : in  std_logic;		-- 13MHz clock input
	
		-- generated clocks
		clk_50    : out std_logic;		-- 50Mhz clock
		rst_50    : out std_logic 		-- 50Mhz reset
	);
end midimux_clklogic;

architecture rtl of midimux_clklogic is
	
	-- reset generation
	signal rst_dcm    : std_logic;
	signal dcm_locked : std_logic;	-- DCM locked
	signal reset_i    : std_logic;
	
	-- system clock management
	signal clk_13_dcm : std_logic;
	signal clk_13_buf : std_logic;
	signal clk_50_dcm : std_logic;
	signal clk_50_buf : std_logic;
	
begin

	--
	-- reset generation
	--
	
	-- generate asynchronous reset-signal
	rg: entity mt_reset_gen
		port map (
			clk 		=> clk_in_13,
			pll_locked	=> dcm_locked,
			reset_pll	=> rst_dcm,
			reset_sys	=> reset_i
		);
	
	-- sync reset to clock-domains
	rs: entity mt_reset_sync
		port map (
			clk     => clk_50_buf,
			rst_in  => reset_i, 
			rst_out => rst_50
		);

	--
	-- system clock
	--

	-- DCM for system-clock
	mydcm : DCM
		generic map (
			CLKIN_PERIOD   => 76.923,
            CLKFX_DIVIDE   => 6,
            CLKFX_MULTIPLY => 23
		)
		port map(
			CLKIN    => clk_in_13,
			CLKFB    => clk_13_buf,
			DSSEN    => '0',
			PSINCDEC => '0',
			PSEN     => '0',
			PSCLK    => '0',
			RST      => rst_dcm,
			CLK0     => clk_13_dcm,
			CLK90    => open,
			CLK180   => open,
			CLK270   => open,
			CLK2X    => open,
			CLK2X180 => open,
			CLKDV    => open,
			CLKFX    => clk_50_dcm,
			CLKFX180 => open,
			LOCKED   => dcm_locked,
			PSDONE   => open,
			STATUS   => open
		);
		
	-- buffer feedback-clock
 	gbuf1: BUFG
		port map(
			I => clk_13_dcm,
			O => clk_13_buf
		);
		
	-- buffer 25mhz-clock
 	gbuf2: BUFG
		port map(
			I => clk_50_dcm,
			O => clk_50_buf
		);

	-- output clocks
	clk_50 <= clk_50_buf;
	
end rtl;

