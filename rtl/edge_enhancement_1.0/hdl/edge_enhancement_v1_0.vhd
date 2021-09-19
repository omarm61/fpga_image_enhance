library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity edge_enhancement_v1_0 is
	generic (
		-- Users to add parameters here
		NUM_PIXELS              : integer   := 1920;
		NUM_LINES               : integer   := 1080;

		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here

		i_axis_aclk     : in  std_logic;
		i_axis_aresetn  : in  std_logic;

		-- Video In - YUV422
    	s_axis_tdata     : in  std_Logic_vector (15 downto 0);	-- Slave AXI-Stream
    	s_axis_tvalid    : in  std_logic;
    	s_axis_tready    : out std_Logic;
    	s_axis_tuser_sof : in  std_Logic;
    	s_axis_tlast     : in  std_logic;

    	-- Video out - YUV 422
    	m_axis_tdata     : out std_Logic_vector (15 downto 0);
    	m_axis_tvalid    : out std_logic;
    	m_axis_tready    : in  std_Logic;
    	m_axis_tuser_sof : out std_Logic;
    	m_axis_tlast     : out std_logic;

        -- Control Registers
        i_reg_matrix_select : in std_logic;
        i_reg_grayscale_en  : in std_logic;
        i_reg_kernel_bypass : in std_logic;
        i_reg_kernel_gain   : in std_logic_vector (11 downto 0)

		-- Ports of Axi Slave Bus Interface S00_AXI
		--s00_axi_aclk	: in std_logic;
		--s00_axi_aresetn	: in std_logic;
		--s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		--s00_axi_awprot	: in std_logic_vector(2 downto 0);
		--s00_axi_awvalid	: in std_logic;
		--s00_axi_awready	: out std_logic;
		--s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		--s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		--s00_axi_wvalid	: in std_logic;
		--s00_axi_wready	: out std_logic;
		--s00_axi_bresp	: out std_logic_vector(1 downto 0);
		--s00_axi_bvalid	: out std_logic;
		--s00_axi_bready	: in std_logic;
		--s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		--s00_axi_arprot	: in std_logic_vector(2 downto 0);
		--s00_axi_arvalid	: in std_logic;
		--s00_axi_arready	: out std_logic;
		--s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		--s00_axi_rresp	: out std_logic_vector(1 downto 0);
		--s00_axi_rvalid	: out std_logic;
		--s00_axi_rready	: in std_logic
	);
end edge_enhancement_v1_0;

architecture arch_imp of edge_enhancement_v1_0 is

	-- component declaration
	--component edge_enhancement_v1_0_S00_AXI is
	--	generic (
	--	C_S_AXI_DATA_WIDTH	: integer	:= 32;
	--	C_S_AXI_ADDR_WIDTH	: integer	:= 32
	--	);
	--	port (
	--	o_matrix_select : out std_logic;
	--	o_grayscale_en  : out std_logic;
	--	o_kernel_bypass : out std_logic;
	--	o_kernel_gain   : out std_logic_vector (11 downto 0);
	--	--
	--	S_AXI_ACLK	    : in std_logic;
	--	S_AXI_ARESETN	: in std_logic;
	--	S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	--	S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
	--	S_AXI_AWVALID	: in std_logic;
	--	S_AXI_AWREADY	: out std_logic;
	--	S_AXI_WDATA	    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	--	S_AXI_WSTRB	    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
	--	S_AXI_WVALID	: in std_logic;
	--	S_AXI_WREADY	: out std_logic;
	--	S_AXI_BRESP	    : out std_logic_vector(1 downto 0);
	--	S_AXI_BVALID	: out std_logic;
	--	S_AXI_BREADY	: in std_logic;
	--	S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	--	S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
	--	S_AXI_ARVALID	: in std_logic;
	--	S_AXI_ARREADY	: out std_logic;
	--	S_AXI_RDATA	    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	--	S_AXI_RRESP	    : out std_logic_vector(1 downto 0);
	--	S_AXI_RVALID	: out std_logic;
	--	S_AXI_RREADY	: in std_logic
	--	);
	--end component edge_enhancement_v1_0_S00_AXI;

	-- Shift Register - Width: 18, Depth: 960
	component shift_register is
		generic (
        	DATA_WIDTH :  integer    := 19;
        	DEPTH      :  integer    := 960
		);
		port (
        	i_aclk    : in std_logic;
        	i_aresetn : in std_logic;
        	i_enable  : in std_logic;
        	--
        	i_data_in   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        	--
        	o_data_out  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        	o_data_valid : out std_logic
		);
	end component shift_register;

	-- 3x3 Kernel
	component kernel_matrix is
		generic (
			-- Parameters
			NUM_LINES	: integer	:= 1080
		);
		port (
			-- Users to add ports here

			i_aclk           : in  std_logic;
			i_aresetn        : in  std_logic;
			i_enable         : in  std_logic;
			-- Control
			i_matrix_select  : in std_logic;
			i_gain           : in std_logic_vector (11 downto 0);
			-- Video in
			i_video_l0       : in std_logic_vector (7 downto 0);   -- Video in Line 1 - Y Luminance
			i_video_l1       : in std_logic_vector (7 downto 0);   -- Video in Line 2 - Y Luminance
			i_video_l2       : in std_logic_vector (7 downto 0);   -- Video in Line 3 - Y Luminance
			i_axis_tlast     : in std_logic;                       -- End of a line - Center line
			i_axis_tuser_sof : in std_logic;                       -- Start of a new frame - Center line
			-- Video out
			o_video          : out std_logic_vector (7 downto 0)
		);
	end component kernel_matrix;

	signal w_shift_wen     : std_logic;
	-- Shift line 1
	signal w_shift_line1_data_in    : std_Logic_vector (18 downto 0); -- Shift register 1 data
	signal w_shift_line1_data_out   : std_Logic_vector (18 downto 0); -- Shift register 1 data    Line 1
	signal w_shift_line1_data_valid : std_logic;
	-- Shift line 2
	signal w_shift_line2_data_in    : std_Logic_vector (10 downto 0); -- Shift register 3 data
	signal w_shift_line2_data_out   : std_Logic_vector (10 downto 0); -- Shift register 3 data    Line 2
	signal w_shift_line2_data_valid : std_logic;
	-- Shift Register Cb/Cr components
	signal w_shift_kernel_data_in  : std_logic_vector (10 downto 0);
	signal w_shift_kernel_data_out : std_logic_vector (10 downto 0);
	-- Kernel Signals
	signal w_kernel_video_l0       : std_Logic_vector (7 downto 0);
	signal w_kernel_video_l1       : std_logic_vector (7 downto 0);
	signal w_kernel_video_l2       : std_logic_vector (7 downto 0);
	signal w_kernel_axis_tlast     : std_logic;
	signal w_kernel_axis_tuser_sof : std_logic;
	signal w_kernel_enable         : std_logic;
	signal w_kernel_video_out      : std_logic_vector (7 downto 0);
	signal w_kernel_matrix_select  : std_logic;
	signal w_kernel_gain           : std_logic_vector (11 downto 0);

	signal w_videout_tdata         : std_logic_vector (15 downto 0);
    signal w_videout_tvalid        : std_logic;
    signal w_videout_tlast         : std_logic;
    signal w_videout_tuser_sof     : std_logic;

	-- MISC
	signal w_grayscale_en  : std_logic;
	signal w_kernel_bypass : std_logic;


begin
	-- Slave Tready signal
	--s_axis_tready <= m_axis_tready;  -- Tready signal

	-- Master Stream
	-- output video stream
	w_videout_tdata      <= (w_shift_kernel_data_out(7 downto 0) & w_kernel_video_out);
	w_videout_tvalid     <= w_shift_kernel_data_out(8);
	w_videout_tlast      <= w_shift_kernel_data_out(9);
	w_videout_tuser_sof  <= w_shift_kernel_data_out(10);

	-- Slave Tready signal
	s_axis_tready <= m_axis_tready;  -- Tready signal
	-- Shift registers enable
	w_shift_wen <= m_axis_tready;

	output_porc : process (i_axis_aclk, i_axis_aresetn)
	begin
	  if (i_axis_aresetn = '0') then
	  	m_axis_tdata     <= (others => '0');
	  	m_axis_tvalid    <= '0';
	  	m_axis_tlast     <= '0';
	  	m_axis_tuser_sof <= '0';
	  elsif (i_axis_aclk'event and i_axis_aclk = '1') then
		if (m_axis_tready = '1') then
			if (i_reg_kernel_bypass = '0') then
				if (i_reg_grayscale_en = '0') then
					m_axis_tdata <= w_videout_tdata;
				else
					m_axis_tdata <= x"80" & w_videout_tdata(7 downto 0);
				end if;
				m_axis_tvalid    <= w_videout_tvalid;
				m_axis_tlast     <= w_videout_tlast;
				m_axis_tuser_sof <= w_videout_tuser_sof;
			else
				if (i_reg_grayscale_en = '0') then
					m_axis_tdata <= w_shift_line1_data_out(15 downto 0);
				else
					m_axis_tdata <= x"80" & w_shift_line1_data_out(7 downto 0);
				end if;
				m_axis_tvalid    <= w_shift_line1_data_out(16);
				m_axis_tlast     <= w_shift_line1_data_out(17);
				m_axis_tuser_sof <= w_shift_line1_data_out(18);
			end if;
		end if;
	  end if;
	end process;


	-- Line 1
	w_shift_line1_data_in <= s_axis_tuser_sof & s_axis_tlast & s_axis_tvalid & s_axis_tdata; -- = (sof, tlast, tvalid, Cb/Cr, Y)
	-- line 2
	w_shift_line2_data_in <= w_shift_line1_data_out(18) & w_shift_line1_data_out(17) & w_shift_line1_data_out(16) & w_shift_line1_data_out(7 downto 0); -- = (sof, tlast, tvalid, Y)

	-- kernel shift register
	w_shift_kernel_data_in <= w_shift_line1_data_out(18) & w_shift_line1_data_out(17) & w_shift_line1_data_out(16) & w_shift_line1_data_out(15 downto 8); -- = (sof, tlast, tvalid, Cb/Cr)


	-- Kernel wires
	w_kernel_enable         <= (w_shift_line1_data_out(16) and w_shift_wen);
	w_kernel_video_l0       <= s_axis_tdata(7 downto 0);           -- Extract the Y component
	w_kernel_video_l1       <= w_shift_line1_data_out(7 downto 0); -- Extract the Y component from line 1
	w_kernel_video_l2       <= w_shift_line2_data_out(7 downto 0); -- Extract the Y component from line 2
	w_kernel_axis_tlast     <= w_shift_line1_data_out(17);
	w_kernel_axis_tuser_sof <= w_shift_line1_data_out(18);

	-- Edge detection

-- Instantiation of Axi Bus Interface S00_AXI
--edge_enhancement_v1_0_S00_AXI_inst : edge_enhancement_v1_0_S00_AXI
--	generic map (
--		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
--		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
--	)
--	port map (
--		o_matrix_select => w_kernel_matrix_select,
--		o_grayscale_en  => w_grayscale_en,
--		o_kernel_bypass => w_kernel_bypass,
--		o_kernel_gain   => w_kernel_gain,
--		--
--		S_AXI_ACLK	    => s00_axi_aclk,
--		S_AXI_ARESETN	=> s00_axi_aresetn,
--		S_AXI_AWADDR	=> s00_axi_awaddr,
--		S_AXI_AWPROT	=> s00_axi_awprot,
--		S_AXI_AWVALID	=> s00_axi_awvalid,
--		S_AXI_AWREADY	=> s00_axi_awready,
--		S_AXI_WDATA	    => s00_axi_wdata,
--		S_AXI_WSTRB	    => s00_axi_wstrb,
--		S_AXI_WVALID	=> s00_axi_wvalid,
--		S_AXI_WREADY	=> s00_axi_wready,
--		S_AXI_BRESP	    => s00_axi_bresp,
--		S_AXI_BVALID	=> s00_axi_bvalid,
--		S_AXI_BREADY	=> s00_axi_bready,
--		S_AXI_ARADDR	=> s00_axi_araddr,
--		S_AXI_ARPROT	=> s00_axi_arprot,
--		S_AXI_ARVALID	=> s00_axi_arvalid,
--		S_AXI_ARREADY	=> s00_axi_arready,
--		S_AXI_RDATA	    => s00_axi_rdata,
--		S_AXI_RRESP	    => s00_axi_rresp,
--		S_AXI_RVALID	=> s00_axi_rvalid,
--		S_AXI_RREADY	=> s00_axi_rready
--	);


    -- Buffer two lines using four shift registers
    -- Shift Register half a line
    ram_shift1_inst :shift_register       -- Line 1
    generic map (
        DATA_WIDTH => 19,
        DEPTH      => (NUM_PIXELS -1)
    )
    port map(
        i_aclk       => i_axis_aclk,
        i_aresetn    => i_axis_aresetn,
        i_enable     => w_shift_wen,
        i_data_in    => w_shift_line1_data_in,
        o_data_out   => w_shift_line1_data_out,
        o_data_valid => w_shift_line1_data_valid
    );

    ram_shift2_inst :shift_register
    generic map (
        DATA_WIDTH => 11,
        DEPTH      => (NUM_PIXELS -1)
    )
    port map(
        i_aclk       => i_axis_aclk,
        i_aresetn    => i_axis_aresetn,
        i_enable     => w_shift_wen,
        i_data_in    => w_shift_line2_data_in,
        o_data_out   => w_shift_line2_data_out,
        o_data_valid => open
    );

        -- short shift register to lineup incoming data with the kernel output
    ram_shift3_inst :shift_register     -- Line 2
    generic map (
        DATA_WIDTH => 11,           -- Tuser,tlast, and 8-bit data (cb/cr)
        DEPTH      => 7
    )
    port map(
        i_aclk       => i_axis_aclk,
        i_aresetn    => i_axis_aresetn,
        i_enable     => w_shift_wen,
        i_data_in    => w_shift_kernel_data_in,
        o_data_out   => w_shift_kernel_data_out,
        o_data_valid => w_shift_line1_data_valid
    );


        -- 3x3 Kernel
    kernel_3x3_inst :kernel_matrix
    generic map(
            -- Parameters
        NUM_LINES	=> NUM_LINES
    )
    port map(
            -- Users to add ports here

        i_aclk           => i_axis_aclk,
        i_aresetn        => i_axis_aresetn,
        i_enable         => w_kernel_enable,
            -- Control
        i_matrix_select  => i_reg_matrix_select,     -- FIXME: w_kernel_matrix_select,
        i_gain           => i_reg_kernel_gain,       -- FIXME: w_kernel_gain,
                                                     -- Video in
        i_video_l0       => w_kernel_video_l0,       -- Video in Line 1 - Y Luminance
        i_video_l1       => w_kernel_video_l1,       -- Video in Line 2 - Y Luminance
        i_video_l2       => w_kernel_video_l2,       -- Video in Line 3 - Y Luminance
        i_axis_tlast     => w_kernel_axis_tlast,     -- End of a line - Center line
        i_axis_tuser_sof => w_kernel_axis_tuser_sof, -- Start of a new frame - Center line
                                                     -- Video out
        o_video          => w_kernel_video_out
    );

end arch_imp;
