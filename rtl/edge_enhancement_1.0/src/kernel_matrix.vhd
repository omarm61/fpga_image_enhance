library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.ALL;
use ieee.numeric_std.all;


-- 3x3 Matrix
entity kernel_matrix is
	generic (
		-- Parameters
		NUM_LINES	: integer	:= 1080
	);
	port (
		-- Users to add ports here
		i_aclk     : in  std_logic;
		i_aresetn  : in  std_logic;
		i_enable   : in  std_logic;
		-- Control
		i_matrix_select  : in std_logic;
		i_gain           : in std_logic_vector (11 downto 0);
		-- Video in
		i_video_l0       : in std_logic_vector (7 downto 0);  -- Video in Line 1 - Y Luminance
		i_video_l1       : in std_logic_vector (7 downto 0);  -- Video in Line 2 - Y Luminance
		i_video_l2       : in std_logic_vector (7 downto 0);  -- Video in Line 3 - Y Luminance
		i_axis_tlast     : in std_logic;                       -- End of a line - Center line
		i_axis_tuser_sof : in std_logic;                       -- Start of a new frame - Center line
		-- Video out
		o_video          : out std_logic_vector (7 downto 0)
	);
end kernel_matrix;

architecture RTL of kernel_matrix is

	-- Control
	signal r_dsp_cen   : std_logic;
	signal w_dsp_reset : std_logic;


	-- Stage 1 - Addition - P = A:B + C
	signal w_dsp_s1_ab : std_logic_vector (47 downto 0); -- In
	alias  w_dsp_s1_a  : std_logic_vector (29 downto 0) is  w_dsp_s1_ab(47 downto 18);
	alias  w_dsp_s1_b  : std_logic_vector (17 downto 0) is  w_dsp_s1_ab(17 downto 0);
	--
	signal w_dsp_s1_c  : std_logic_vector (47 downto 0); -- In
	--
	signal w_dsp_s1_p     : std_logic_vector (47 downto 0); -- Out
	alias w_dsp_s1_p_sum0 : std_logic_vector (11 downto 0) is  w_dsp_s1_p(11 downto 0);
	alias w_dsp_s1_p_sum1 : std_logic_vector (11 downto 0) is  w_dsp_s1_p(23 downto 12);
	alias w_dsp_s1_p_sum2 : std_logic_vector (11 downto 0) is  w_dsp_s1_p(35 downto 24);
	alias w_dsp_s1_p_sum3 : std_logic_vector (11 downto 0) is  w_dsp_s1_p(47 downto 36);
	--
	signal w_dsp_s1_carryout : std_logic_vector (3 downto 0);

	-- Stage 2 - Addition - P = A:B + C
	signal w_dsp_s2_ab : std_logic_vector (47 downto 0); -- In
	alias  w_dsp_s2_a  : std_logic_vector (29 downto 0) is  w_dsp_s2_ab(47 downto 18);
	alias  w_dsp_s2_b  : std_logic_vector (17 downto 0) is  w_dsp_s2_ab(17 downto 0);
	--
	signal w_dsp_s2_c : std_logic_vector (47 downto 0); -- In
	--
	signal w_dsp_s2_p      : std_logic_vector (47 downto 0); -- Out
	alias  w_dsp_s2_p_sum0 : std_logic_vector (23 downto 0) is  w_dsp_s2_p(23 downto 0);
	alias  w_dsp_s2_p_sum1 : std_logic_vector (23 downto 0) is  w_dsp_s2_p(47 downto 24);


	-- Stage 3 - Addition - P = A:B + C
	signal w_dsp_s3_ab : std_logic_vector (47 downto 0); -- In
	alias  w_dsp_s3_a  : std_logic_vector (29 downto 0) is  w_dsp_s3_ab(47 downto 18);
	alias  w_dsp_s3_b  : std_logic_vector (17 downto 0) is  w_dsp_s3_ab(17 downto 0);
	--
	signal w_dsp_s3_c : std_logic_vector (47 downto 0); -- In
	--
	signal w_dsp_s3_p : std_logic_vector (47 downto 0); -- Out

	-- Stage 4 - Mutliplication and subtraction - P = (B*A) - C
	signal w_dsp_s4_a : std_logic_vector (29 downto 0); -- In
	signal w_dsp_s4_b : std_logic_vector (17 downto 0); -- In
	signal w_dsp_s4_c : std_logic_vector (47 downto 0); -- In
	--
	signal w_dsp_s4_p      : std_logic_vector (47 downto 0); -- Out
	--

	signal r_pixel_gain     : std_logic_vector (11 downto 0);

    -- Matrix values
	signal r_mat_m00   : std_logic_vector (7 downto 0);
	signal r_mat_m01   : std_logic_vector (7 downto 0);
	signal r_mat_m02   : std_logic_vector (7 downto 0);
	signal r_mat_m10   : std_logic_vector (7 downto 0);
	signal r_mat_m11   : std_logic_vector (7 downto 0);
	signal r_mat_m12   : std_logic_vector (7 downto 0);
	signal r_mat_m20   : std_logic_vector (7 downto 0);
	signal r_mat_m21   : std_logic_vector (7 downto 0);
	signal r_mat_m22   : std_logic_vector (7 downto 0);

	-- Matrix masked values
	signal r_mat_m00_mask   : std_logic_vector (7 downto 0);
	signal r_mat_m01_mask   : std_logic_vector (7 downto 0);
	signal r_mat_m02_mask   : std_logic_vector (7 downto 0);
	signal r_mat_m10_mask   : std_logic_vector (7 downto 0);
	signal r_mat_m11_mask   : std_logic_vector (7 downto 0);
	signal r_mat_m12_mask   : std_logic_vector (7 downto 0);
	signal r_mat_m20_mask   : std_logic_vector (7 downto 0);
	signal r_mat_m21_mask   : std_logic_vector (7 downto 0);
	signal r_mat_m22_mask   : std_logic_vector (7 downto 0);

	-- MISC
	signal r_first_line   : std_logic;
	signal r_new_line     : std_logic;
	signal r_last_line    : std_logic;
	signal r_line_counter : std_logic_vector (11 downto 0);
	--
	signal r_mat_m11_mask_d   : std_logic_vector(7 downto 0);
	signal r_mat_m11_mask_dd  : std_logic_vector(7 downto 0);
	signal r_mat_m11_mask_ddd : std_logic_vector(7 downto 0);
	signal r_pixel_overflow   : std_logic_vector(7 downto 0);
	--
	signal r_axis_tlast       : std_logic;
	signal r_axis_tuser_sof   : std_logic;

    --
    -- State machine. Zero Padding around the frame.
    --Frame:
    --       C00 ------ C01
    --        |          |
    --        |          |
    --       C10 ------ C11
    type t_pxl_mask_fsm is (sIDLE, sC00, sFIRST_LINE, sC01, sLAST_PIXEL, sFIRST_PIXEL, sC10, sLAST_LINE, sC11);
    signal pxl_mask_fsm 	: t_pxl_mask_fsm;


begin
	--
	--        [-1 -1 -1]        [ 0 -1  0]
	-- mat0 = [-1  9 -1] mat1 = [-1  5 -1]
	--        [-1 -1 -1]        [ 0 -1  0]
	-- Direction of the video stream into the  kernel
	-- [M00 M01 M02]  <-- i_video_l2
	-- [M10 M11 M12]  <-- i_video_l1
	-- [M20 M21 M22]  <-- i_video_l0
	matrix_ctrl_prc : process (i_aclk, i_aresetn)
	begin
	  if (i_aresetn = '0') then
	  	r_dsp_cen <= '0';
	  	--
	  	r_pixel_gain <= (others => '0');
	  	--
	  	r_mat_m00      <= (others => '0');
		r_mat_m01      <= (others => '0');
		r_mat_m02      <= (others => '0');
		r_mat_m10      <= (others => '0');
		r_mat_m11      <= (others => '0');
		r_mat_m12      <= (others => '0');
		r_mat_m20      <= (others => '0');
		r_mat_m21      <= (others => '0');
		r_mat_m22      <= (others => '0');
		--
	  	r_mat_m00_mask <= (others => '0');
		r_mat_m01_mask <= (others => '0');
		r_mat_m02_mask <= (others => '0');
		r_mat_m10_mask <= (others => '0');
		r_mat_m11_mask <= (others => '0');
		r_mat_m12_mask <= (others => '0');
		r_mat_m20_mask <= (others => '0');
		r_mat_m21_mask <= (others => '0');
		r_mat_m22_mask <= (others => '0');
		--
		r_first_line   <= '0';
		r_new_line     <= '0';
		r_last_line    <= '0';
		r_line_counter <= (others => '0');

		r_mat_m11_mask_d   <= (others => '0');
		r_mat_m11_mask_dd  <= (others => '0');
		r_mat_m11_mask_ddd <= (others => '0');

		r_axis_tlast       <= '0';
		r_axis_tuser_sof   <= '0';

	  	pxl_mask_fsm <= sIDLE;
	  	o_video <= (others => '0');

	  elsif (i_aclk'event and i_aclk = '1') then

	  		-- Center pixel Gain
	  		r_pixel_gain <= i_gain;

	  		r_axis_tlast       <= i_axis_tlast;
	  		r_axis_tuser_sof   <= i_axis_tuser_sof;

	  	-- Convolution zero padding
	  	-- check if the matrix need zero padding for the four coreners of the frame
	  	-- Start of a frame
	  	if (i_enable = '1') then
	  		-- Output video
	  		r_pixel_overflow <= r_mat_m11_mask_ddd;
	  		if (i_matrix_select = '1') then
	  			if (w_dsp_s4_p(9) = '0') then
	  				o_video <= w_dsp_s4_p(9 downto 2);
	  			else
	  				o_video <= r_pixel_overflow;
	  			end if;
	  		else
                if (w_dsp_s4_p(47) = '1') then
                    o_video <= x"00";
                elsif(w_dsp_s4_p(11 downto 8) > "0000") then
                    o_video <= x"FF";
                else
                    o_video <= w_dsp_s4_p(7 downto 0);
                end if;
	  			--if (w_dsp_s4_p(12) = '0' and w_dsp_s4_p(11 downto 0) >= x"060") then
	  			--	o_video <= r_pixel_overflow + x"10";
	  			--else
	  			--	o_video <= r_pixel_overflow;
	  			--end if;
	  		end if;

	  		r_mat_m02 <= i_video_l2;
	  		r_mat_m01 <= r_mat_m02;
	  		r_mat_m00 <= r_mat_m01;
	  		--
	  		r_mat_m12 <= i_video_l1;
	  		r_mat_m11 <= r_mat_m12;  -- Center pixel
	  		r_mat_m10 <= r_mat_m11;
	  		--
	  		r_mat_m22 <= i_video_l0;
	  		r_mat_m21 <= r_mat_m22;
	  		r_mat_m20 <= r_mat_m21;
	  		-- Enable DSP
	  		r_dsp_cen <= '1';
	  		--
	  		if (r_axis_tuser_sof = '1') then
	  			pxl_mask_fsm <= sC00;         -- Top left corner
	  			r_first_line <= '1';
	  			r_last_line  <= '0';
	  			r_line_counter <= (others => '0');
	  		elsif (r_axis_tlast = '1') then
	  			-- Incremnet line counter
	  			r_line_counter <= r_line_counter + 1;
	  			r_new_line <= '1';
	  			r_first_line <= '0';
	  			-- Check if its the last line
	  			if (r_line_counter >= NUM_LINES - 2) then
	  				r_last_line <= '1';
	  			else
	  				r_last_line <= '0';
	  			end if;
	  			-- Check if it's one of the right corners
	  			if (r_first_line = '1') then
	  				pxl_mask_fsm <= sC01;       -- Top right corner
	  				r_first_line <= '0';
	  			elsif (r_last_line = '1') then
	  				pxl_mask_fsm <= sC11;       -- Bottom right corner
				else
					--pxl_mask_fsm <= sLAST_PIXEL; -- Last pixel of a line
					pxl_mask_fsm <= sIDLE;
	  			end if;
	  			--
	  		else
	  			r_new_line <= '0';
	  			if (r_first_line = '1') then
	  				pxl_mask_fsm <= sFIRST_LINE;   -- First line
	  			elsif (r_new_line = '1' and r_last_line = '0') then
	  				--pxl_mask_fsm <= sFIRST_PIXEL;  -- First pixel of a line
					pxl_mask_fsm <= sIDLE;
	  			elsif (r_new_line = '1' and r_last_line = '1') then
	  				pxl_mask_fsm <= sC10;          -- Bottom left corner
	  			elsif (r_new_line = '0' and r_last_line = '1') then
	  				pxl_mask_fsm <= sLAST_LINE;    -- Bottom Line
	  			else
	  				pxl_mask_fsm <= sIDLE;         -- No masking/padding
	  			end if;
	  		end if;
	  	else
	  		-- Disable DSP
	  		r_dsp_cen <= '0';
	  	end if;

	  	r_mat_m11_mask_d   <= r_mat_m11_mask;
	  	r_mat_m11_mask_dd  <= r_mat_m11_mask_d;
	  	r_mat_m11_mask_ddd <= r_mat_m11_mask_dd;

	  	case(pxl_mask_fsm) is
	  		when sIDLE =>
	  			-- No padding
	  			r_mat_m00_mask <= r_mat_m00;
	  			r_mat_m01_mask <= r_mat_m01;
	  			r_mat_m02_mask <= r_mat_m02;
	  			--
	  			r_mat_m10_mask <= r_mat_m10;
	  			r_mat_m11_mask <= r_mat_m11;
	  			r_mat_m12_mask <= r_mat_m12;
	  			--
	  			r_mat_m20_mask <= r_mat_m20;
	  			r_mat_m21_mask <= r_mat_m21;
	  			r_mat_m22_mask <= r_mat_m22;

	  		when sC00 =>
	  			-- Left top corner, Start of Frame
	  			-- Top line and left pixels are zeros
	  			r_mat_m00_mask <= (others => '0');
	  			r_mat_m01_mask <= (others => '0');
	  			r_mat_m02_mask <= (others => '0');
	  			--
	  			r_mat_m10_mask <= (others => '0');
	  			r_mat_m11_mask <= r_mat_m11;
	  			r_mat_m12_mask <= r_mat_m12;
	  			--
	  			r_mat_m20_mask <= (others => '0');
	  			r_mat_m21_mask <= r_mat_m21;
	  			r_mat_m22_mask <= r_mat_m22;

	  		when sFIRST_LINE =>
	  			-- Top line
	  			r_mat_m02_mask <= (others => '0');
	  			r_mat_m01_mask <= (others => '0');
	  			r_mat_m00_mask <= (others => '0');
	  			--
	  			r_mat_m22_mask <= r_mat_m22;
	  			r_mat_m21_mask <= r_mat_m21;
	  			r_mat_m20_mask <= r_mat_m20;
	  			--
	  			r_mat_m12_mask <= r_mat_m12;
	  			r_mat_m11_mask <= r_mat_m11;  -- Center pixel
	  			r_mat_m10_mask <= r_mat_m10;

	  		when sC01 =>
	  			-- Right top corner
	  			r_mat_m00_mask <= (others => '0');
	  			r_mat_m01_mask <= (others => '0');
	  			r_mat_m02_mask <= (others => '0');
	  			--
	  			r_mat_m10_mask <= r_mat_m10;
	  			r_mat_m11_mask <= r_mat_m11;
	  			r_mat_m12_mask <= (others => '0');
	  			--
	  			r_mat_m20_mask <= r_mat_m20;
	  			r_mat_m21_mask <= r_mat_m21;
	  			r_mat_m22_mask <= (others => '0');

	  		when sFIRST_PIXEL =>
	  			-- First pixel
	  			r_mat_m00_mask <= (others => '0');
	  			r_mat_m01_mask <= r_mat_m01;
	  			r_mat_m02_mask <= r_mat_m02;
	  			--
	  			r_mat_m10_mask <= (others => '0');
	  			r_mat_m11_mask <= r_mat_m11;
	  			r_mat_m12_mask <= r_mat_m12;
	  			--
	  			r_mat_m20_mask <= (others => '0');
	  			r_mat_m21_mask <= r_mat_m21;
	  			r_mat_m22_mask <= r_mat_m22;

	  		when sLAST_PIXEL =>
	  			-- last pixel
	  			r_mat_m00_mask <= r_mat_m00;
	  			r_mat_m01_mask <= r_mat_m01;
	  			r_mat_m02_mask <= (others => '0');
	  			--
	  			r_mat_m10_mask <= r_mat_m10;
	  			r_mat_m11_mask <= r_mat_m11;
	  			r_mat_m12_mask <= (others => '0');
	  			--
	  			r_mat_m20_mask <= r_mat_m20;
	  			r_mat_m21_mask <= r_mat_m21;
	  			r_mat_m22_mask <= (others => '0');

	  		when sC10 =>
	  			-- Left bottom corner
	  			r_mat_m00_mask <= (others => '0');
	  			r_mat_m01_mask <= r_mat_m01;
	  			r_mat_m02_mask <= r_mat_m02;
	  			--
	  			r_mat_m10_mask <= (others => '0');
	  			r_mat_m11_mask <= r_mat_m11;
	  			r_mat_m12_mask <= r_mat_m12;
	  			--
	  			r_mat_m20_mask <= (others => '0');
	  			r_mat_m21_mask <= (others => '0');
	  			r_mat_m22_mask <= (others => '0');

	  		when sLAST_LINE =>
	  			-- Last line
	  			r_mat_m00_mask <= r_mat_m00;
	  			r_mat_m01_mask <= r_mat_m01;
	  			r_mat_m02_mask <= (others => '0');
	  			--
	  			r_mat_m10_mask <= r_mat_m10;
	  			r_mat_m11_mask <= r_mat_m11;
	  			r_mat_m12_mask <= (others => '0');
	  			--
	  			r_mat_m20_mask <= (others => '0');
	  			r_mat_m21_mask <= (others => '0');
	  			r_mat_m22_mask <= (others => '0');

	  		when sC11 =>
	  			-- Right bottom corner, End of frame
	  			r_mat_m00_mask <= r_mat_m00;
	  			r_mat_m01_mask <= r_mat_m01;
	  			r_mat_m02_mask <= r_mat_m02;
	  			--
	  			r_mat_m10_mask <= r_mat_m10;
	  			r_mat_m11_mask <= r_mat_m11;
	  			r_mat_m12_mask <= r_mat_m12;
	  			--
	  			r_mat_m20_mask <= (others => '0');
	  			r_mat_m21_mask <= (others => '0');
	  			r_mat_m22_mask <= (others => '0');
	  		when others =>
	  			null;
	  	end case;
	  end if;
	end process ;



	-- DSP Reset
	w_dsp_reset <= not i_aresetn;

	-- Stage 1-3 add all the neighbouring pixels
	-- Stage 4 multiply the center pixel by a gain and subtract all the neighbouring pixels
	-- Matrix:
	-- [M00 M01 M02]
	-- [M10 M11 M12]
	-- [M20 M21 M22]
	-- P = A:B + C
	-- P[11:0]  = S1_0 = M00 + M02
	-- P[23:12] = S1_1 = M10 + M12
	-- P[35:24] = S1_2 = M20 + M22
	-- P[47:36] = S1_3 = M01 + M21

	-- Stage one signals
	w_dsp_s1_ab(11 downto 0)  <= x"0" & r_mat_m00_mask;
	w_dsp_s1_ab(23 downto 12) <= x"0" & r_mat_m10_mask;
	w_dsp_s1_ab(35 downto 24) <= x"0" & r_mat_m20_mask;
	w_dsp_s1_ab(47 downto 36) <= x"0" & r_mat_m01_mask;
	--
	w_dsp_s1_c(11 downto 0)  <= x"0" & r_mat_m02_mask;
	w_dsp_s1_c(23 downto 12) <= x"0" & r_mat_m12_mask;
	w_dsp_s1_c(35 downto 24) <= x"0" & r_mat_m22_mask;
	w_dsp_s1_c(47 downto 36) <= x"0" & r_mat_m21_mask;


	-- Stage one add the corners of the matrix
	DSP48E1_stage1_inst : entity work.dsp48_wrap
	generic map (
	    PREG => 1,			-- Pipeline stages for P (0 or 1)
	    USE_SIMD => "FOUR12" )	-- SIMD selection ("ONE48", "TWO24", "FOUR12")
	port map (
	    CLK     => i_aclk,			    -- 1-bit input: Clock input
	    A       => w_dsp_s1_a,			-- M00, M10, M20[5:0]
	    B       => w_dsp_s1_b,			-- M20[7:6], M01
	    C       => w_dsp_s1_c,			-- M02, M12, M22, M21
	    ALUMODE => "0000",		        -- 4-bit input: ALU control input
	    OPMODE  => "0110011",	        -- 7-bit input: Operation mode input
	    CEP     => r_dsp_cen,			-- 1-bit input: CE input for PREG
	    -- Reset Signals
		RSTA          => w_dsp_reset,
		RSTB          => w_dsp_reset,
		RSTC          => w_dsp_reset,
		RSTD          => w_dsp_reset,
		RSTM          => w_dsp_reset,
		RSTP          => w_dsp_reset,
		RSTINMODE     => w_dsp_reset,
		RSTALUMODE    => w_dsp_reset,
		RSTCTRL       => w_dsp_reset,
	    --
	    P        => w_dsp_s1_p,		        -- 48-bit output: Primary data output
	    CARRYOUT => w_dsp_s1_carryout );	-- 4-bit carry output

	-- P = A:B + C
	-- P[23:0]  = S2_0 = S1_0 + S1_1
	-- P[47:24] = S2_1 = S1_2 + S1_3
	-- Stage two wires
	w_dsp_s2_ab(23 downto 0)  <= x"000" & w_dsp_s1_p_sum0;
	w_dsp_s2_ab(47 downto 24) <= x"000" & w_dsp_s1_p_sum2;
	--
	w_dsp_s2_c(23 downto 0)   <= x"000" & w_dsp_s1_p_sum1;
	w_dsp_s2_c(47 downto 24)  <= x"000" & w_dsp_s1_p_sum3;

	-- Stage two - Addition
	DSP48E1_stage2_inst : entity work.dsp48_wrap
	generic map (
	    PREG => 1,			    -- Pipeline stages for P (0 or 1)
	    USE_SIMD => "TWO24" )	-- SIMD selection ("ONE48", "TWO24", "FOUR12")
	port map (
	    CLK     => i_aclk,         -- 1-bit input: Clock input
	    A       => w_dsp_s2_a,	   -- S1_0, S1_2[5:0]
	    B       => w_dsp_s2_b,	   -- S1_2[11:6]
	    C       => w_dsp_s2_c,	   -- S1_1, S1_3
	    ALUMODE => "0000",		   -- 4-bit input: ALU control input
	    OPMODE  => "0110011",	   -- 7-bit input: Operation mode input
	    CEP     => r_dsp_cen,	   -- 1-bit input: CE input for PREG
	    -- Reset Signals
		RSTA          => w_dsp_reset,
		RSTB          => w_dsp_reset,
		RSTC          => w_dsp_reset,
		RSTD          => w_dsp_reset,
		RSTM          => w_dsp_reset,
		RSTP          => w_dsp_reset,
		RSTINMODE     => w_dsp_reset,
		RSTALUMODE    => w_dsp_reset,
		RSTCTRL       => w_dsp_reset,
	    --
	    P => w_dsp_s2_p,    -- 48-bit output: Primary data output
	    CARRYOUT => open );	-- 4-bit carry output

	-- P = A:B + C
	-- P[47:0] = S3_0 = S2_0 + S2_1
	-- Stage three wires
	w_dsp_s3_ab <= x"000000" & w_dsp_s2_p_sum0;
	w_dsp_s3_c  <= x"000000" & w_dsp_s2_p_sum1;

	-- Stage three - Addition
	DSP48E1_stage3_inst : entity work.dsp48_wrap
	generic map (
	    PREG => 1,				-- Pipeline stages for P (0 or 1)
	    MASK => x"000000000000",		-- 48-bit mask value for pattern detect
	    SEL_PATTERN => "C",			-- Select pattern value ("PATTERN" or "C")
	    USE_PATTERN_DETECT => "PATDET",	-- ("PATDET" or "NO_PATDET")
	    USE_SIMD => "ONE48" )		-- SIMD selection ("ONE48", "TWO24", "FOUR12")
	port map (
	    CLK     => i_aclk,		      -- 1-bit input: Clock input
	    A       => w_dsp_s3_a,		  -- S2_0
	    B       => w_dsp_s3_b,	  	  -- 0
	    C       => w_dsp_s3_c,		  -- S2_1
	    OPMODE  => "0110011",			  -- 7-bit input: Operation mode input
	    ALUMODE => "0000",	      -- 7-bit input: Operation mode input
	    CARRYIN => '0',			      -- 1-bit input: Carry input signal
	    CEP     => r_dsp_cen,	      -- 1-bit input: CE input for PREG
	    -- Reset Signals
		RSTA          => w_dsp_reset,
		RSTB          => w_dsp_reset,
		RSTC          => w_dsp_reset,
		RSTD          => w_dsp_reset,
		RSTM          => w_dsp_reset,
		RSTP          => w_dsp_reset,
		RSTINMODE     => w_dsp_reset,
		RSTALUMODE    => w_dsp_reset,
		RSTCTRL       => w_dsp_reset,
	    --
	    P => w_dsp_s3_p );			-- 48-bit output: Primary data output

	-- Stage four wires
	w_dsp_s4_a <= x"00000" & "00" & r_mat_m11_mask_ddd; -- Center pixel
	w_dsp_s4_b <= x"0" & "00" & r_pixel_gain;

	w_dsp_s4_c <= w_dsp_s3_p; -- Two's compliment, sum of neighbouring pixels

	-- Stage four - Multiplication, Subtraction = (Gain * Center pixel) - neighbouring pixels
    -- P[47:0] = (gain * M11) - S3_0
    DSP48E1_stage4_inst : entity work.dsp48_wrap
	generic map (
	    PREG => 1,				        -- Pipeline stages for P (0 or 1)
	    USE_MULT => "MULTIPLY",
	    USE_DPORT => TRUE,
	    MASK => x"000000000000",		    -- 48-bit mask value for pattern detect
	    SEL_PATTERN => "PATTERN",			-- Select pattern value ("PATTERN" or "C")
	    USE_PATTERN_DETECT => "NO_PATDET",	-- ("PATDET" or "NO_PATDET")
	    USE_SIMD => "ONE48" )		        -- SIMD selection ("ONE48", "TWO24", "FOUR12")
	port map (
	    CLK       => i_aclk,            -- 1-bit input: Clock input
	    A         => w_dsp_s4_a,        -- M11
	    B         => w_dsp_s4_b,        -- Gain
	    C         => w_dsp_s4_c,        -- S3_0
	    INMODE    => "00000",
	    OPMODE    => "0110101",         -- 7-bit input: Operation mode input
	    ALUMODE   => "0001",			-- 7-bit input: Operation mode input --
	    CARRYIN   => '0',			    -- 1-bit input: Carry input signal
	    CEC       => r_dsp_cen,
	    CECARRYIN => r_dsp_cen,
	    CECTRL    => r_dsp_cen,
		CEM		  => r_dsp_cen,  -- 1-bit input: CE input for Multiplier
	    CEP       => r_dsp_cen,  -- 1-bit input: CE input for PREG
	    CEA1      => r_dsp_cen,
	    -- Reset Signals
		RSTA          => w_dsp_reset,
		RSTB          => w_dsp_reset,
		RSTC          => w_dsp_reset,
		RSTD          => w_dsp_reset,
		RSTM          => w_dsp_reset,
		RSTP          => w_dsp_reset,
		RSTINMODE     => w_dsp_reset,
		RSTALUMODE    => w_dsp_reset,
		RSTCTRL       => w_dsp_reset,
		RSTALLCARRYIN => w_dsp_reset,
	    --
	    PATTERNDETECT => open,		  -- Match indicator P[47:0] with pattern
	    P             => w_dsp_s4_p); -- 48-bit output: Primary data output




end RTL;
