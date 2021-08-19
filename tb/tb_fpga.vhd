library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_fpga is
    port (
           i_sim_clk     : in std_logic;
		   i_sim_aresetn : in std_logic
       );
end;

architecture tb of tb_fpga is

    -- Constants
    constant C_COUNTER_SIZE   : integer := 8;
    -- Image Dimension
    constant C_IMAGE_WIDTH  : integer := 128;
    constant C_IMAGE_HEIGHT : integer := 144;

    -- Files
    constant C_GAMMA_LUT      : string := "gamma_lut.mif";
    constant C_FILE_VIDEO_IN  : string := "video_in_sim.txt";
    constant C_FILE_VIDEO_OUT : string := "video_out_sim.txt";

    -- Signals
    signal enable : std_logic;
    signal counter: std_logic_vector (C_COUNTER_SIZE-1 downto 0);

    -- AXI-Stream
    -- SIM Input File -> Gamma LUT
    signal r_axis_sim_gamma_tdata     : std_logic_vector (15 downto 0);
    signal r_axis_sim_gamma_tvalid    : std_logic;
    signal w_axis_sim_gamma_tready    : std_logic;
    signal r_axis_sim_gamma_tuser_sof : std_logic;
    signal r_axis_sim_gamma_tlast     : std_logic;

    -- Gamma LUT -> Edge Enhance
    signal w_axis_gamma_edge_tdata    : std_logic_vector  (15 downto 0);
    signal w_axis_gamma_edge_tvalid   : std_logic;
    signal w_axis_gamma_edge_tready   : std_logic;
    signal w_axis_gamma_edge_tuser_sof: std_logic;
    signal w_axis_gamma_edge_tlast    : std_logic;

    -- Edge Enhance -> SIM Output File
    signal w_axis_edge_sim_tdata     : std_logic_vector (15 downto 0);
    signal w_axis_edge_sim_tvalid    : std_logic;
    signal r_axis_edge_sim_tready    : std_logic;
    signal w_axis_edge_sim_tuser_sof : std_logic;
    signal w_axis_edge_sim_tlast     : std_logic;

    -- Control Registers (NOTE: Currently these registers are controlled by the TCL script)
    signal w_reg_matrix_select : std_logic;
    signal w_reg_grayscale_en  : std_logic;
    signal w_reg_kernel_bypass : std_logic;
    signal w_reg_kernel_gain   : std_logic_vector (11 downto 0);

    -- Simulation Debug signals
    signal v_pixel_index : integer;
    signal v_line_index  : integer;
    signal v_line_length : integer;
    signal v_frame_index : integer;

    -- LUT write/read access
    signal r_lut_wdata : std_logic_vector (7 downto 0);
    signal r_lut_rdata : std_logic_vector (7 downto 0);
    signal r_lut_addr  : std_logic_vector (10 downto 0);
    signal r_lut_enable: std_logic;
    signal r_lut_wren  : std_logic;

    -- Read file state machine
    type t_read_state is (sIDLE, sREAD_LINE, sSEND_SOF, sSEND_LINE, sDONE, sERROR);
    signal state_rfile : t_read_state;

    -- Function: Convert CHAR to STD_LOGIC_VECTOR
    function conv_char_to_logic_vector(char0 : character; char1 : character)
    return std_logic_vector is

        variable v_byte0 : integer;
        variable v_byte1 : integer;
        variable ret     : std_logic_vector (15 downto 0);
    begin
        v_byte0 := character'pos(char0);
        v_byte1 := character'pos(char1);
        ret  := std_logic_vector(to_unsigned(v_byte0,8)) & std_logic_vector(to_unsigned(v_byte1,8));
        return ret;
    end function;

    -- Function: Convert STD_LOGIC_VECTOR to CHAR
    function conv_std_logic_vector_to_char(byte : std_logic_vector(7 downto 0)) return character is
        variable temp : integer := 0;
    begin
        -- Convert byte to integer
        temp := to_integer(unsigned(byte));
        return CHARACTER'VAL(temp);
    end function;

    -- Components
    -- Counter
    component counter_add is
        port (
            -- Clock/Reset
            i_clk     : in std_logic;
            i_aresetn : in std_logic;
            -- Enable
            i_enable  : in std_logic;
            -- Output Count
            o_count   : out std_logic_vector (7 downto 0)
        );
    end component;

    --Gamma Correction
    component gamma_lut is
    generic (
        C_INIT_FILE   : string  := "NONE";
        C_PIXEL_WIDTH : integer := 16;
        C_GAMMA_WIDTH : integer := 8
    );
    port (
        -- Clock/Reset
        s_axis_aclk    : in std_logic;
        s_axis_aresetn : in std_logic;
        -- Configure LUT
        i_lut_wdata      : in  std_logic_vector (C_GAMMA_WIDTH - 1 downto 0);
        o_lut_rdata      : out std_logic_vector (C_GAMMA_WIDTH - 1 downto 0);
        i_lut_addr       : in  std_logic_vector (10 downto 0);
        i_lut_enable     : in  std_logic;
        i_lut_wren       : in  std_logic;
        -- Video In - YUV422
        s_axis_tdata     : in  std_logic_vector (C_PIXEL_WIDTH - 1 downto 0);
        s_axis_tvalid    : in  std_logic;
        s_axis_tready    : out std_logic;
        s_axis_tuser_sof : in  std_logic;
        s_axis_tlast     : in  std_Logic;
        -- Video out - YUV422
        m_axis_tdata     : out std_logic_vector (C_PIXEL_WIDTH - 1 downto 0);
        m_axis_tvalid    : out std_logic;
        m_axis_tready    : in  std_logic;
        m_axis_tuser_sof : out std_logic;
        m_axis_tlast     : out std_Logic
    );
    end component;

    -- Edge Enhancements
    component edge_enhancement_v1_0 is
        generic (
            -- Users to add parameters here
            NUM_PIXELS              : integer   := 128;
            NUM_LINES               : integer   := 144
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
        );
    end component;

begin

    tb1 : process
    begin
        enable <= '0';
        -- Enable Counter
        wait for 400 ns;
        enable <= '1';

        -- Wait for simulation to end
        wait;
    end process;


    ------------------------------------------
    -- AXI-Stream: IN: Read from file
    ------------------------------------------
    file_read : process is
        variable line_v : line;
        file read_file : text;
        variable test : integer;
        variable slv_v : std_logic_vector(4 - 1 downto 0);
        variable char_byte0 : character;
        variable char_byte1 : character;
        -- Counters
        variable v_pixel_counter : integer;
        variable v_line_counter  : integer;
        variable v_frame_counter : integer;

    begin
        -- Reset Signals
        r_axis_sim_gamma_tdata       <= (others => '0');
        r_axis_sim_gamma_tvalid      <= '0';
        r_axis_sim_gamma_tuser_sof   <= '0';
        r_axis_sim_gamma_tlast       <= '0';
        r_axis_edge_sim_tready      <= '0';
        v_pixel_counter    := 0;
        v_line_counter     := 0;

        r_lut_wdata   <= x"00";
        r_lut_rdata   <= x"00";
        r_lut_addr    <= (others => '0');
        r_lut_enable  <= '0';
        r_lut_wren    <= '0';

        -- Open File
        file_open(read_file, C_FILE_VIDEO_IN, read_mode);
        --file_open(write_file, "target.txt", write_mode);
            --while not endfile(read_file) loop
        state_rfile <= sIDLE;
        loop
            -- Wait for clock cycle
            wait until (i_sim_clk'event and i_sim_clk = '1');
            r_axis_edge_sim_tready <= '1';
            case(state_rfile) is
                when sIDLE =>
                    -- Reset Signals
                    r_axis_sim_gamma_tlast     <= '0';
                    r_axis_sim_gamma_tvalid    <= '0';
                    r_axis_sim_gamma_tuser_sof <= '0';
                    r_axis_sim_gamma_tdata     <= (others => '0');
                    v_pixel_counter  := 0;
                    v_line_counter   := 0;
                    v_frame_counter  := 0;
                    v_pixel_index  <= 0;
                    v_line_index   <= 0;
                    v_frame_index  <= 0;
                    -- Wait for start signal
                    if (enable = '1') then
                        state_rfile <= sREAD_LINE;
                    end if;

                when sREAD_LINE =>
                    r_axis_sim_gamma_tdata <= (others => '0');
                    if (not endfile(read_file)) then
                        -- Read line
                        readline(read_file, line_v);
                        -- Send first pixel
                        state_rfile <= sSEND_SOF;
                    else
                        -- Error, end of file was reached before reading the full image
                        state_rfile <= sERROR;
                    end if;

                when sSEND_SOF =>
                    -- Wait for Tready
                    if (w_axis_sim_gamma_tready = '1') then
                        -- Read first two bytes
                        read(line_v, char_byte0);
                        read(line_v, char_byte1);
                        -- Set Start of frame signal
                        r_axis_sim_gamma_tuser_sof <= '1';
                        r_axis_sim_gamma_tlast     <= '0';
                        r_axis_sim_gamma_tvalid    <= '1';
                        r_axis_sim_gamma_tdata     <= conv_char_to_logic_vector(char_byte1, char_byte0);
                        -- Increment counter
                        v_pixel_counter := v_pixel_counter + 1;
                        v_pixel_index   <= v_pixel_counter;
                        -- Next State
                        state_rfile <= sSEND_LINE;
                        v_line_length <= line_v'length;
                    end if;

                when sSEND_LINE =>
                    --
                    r_axis_sim_gamma_tuser_sof <= '0';
                    -- Read pixel
                    if (v_pixel_counter = C_IMAGE_WIDTH - 1) then
                        -- wait for tready signal
                        if (w_axis_sim_gamma_tready = '1') then
                            read(line_v, char_byte0);
                            read(line_v, char_byte1);
                            r_axis_sim_gamma_tlast  <= '1';
                            r_axis_sim_gamma_tvalid <= '1';
                            r_axis_sim_gamma_tdata  <= conv_char_to_logic_vector(char_byte1, char_byte0);
                            v_line_length <= line_v'length;
                            -- Reset pixel counter
                            v_pixel_counter := 0;
                            v_pixel_index <= v_pixel_counter;
                            -- increment line counter
                            if (v_line_counter = C_IMAGE_HEIGHT - 1) then
                                -- Send next Image
                                state_rfile <= sSEND_SOF;
                                -- Frame Counter
                                v_frame_counter := v_frame_counter + 1;
                                v_frame_index  <= v_frame_counter;
                                v_line_counter := 0;
                                v_line_index   <= 0;
                            else
                                -- Increment counter
                                v_line_counter := v_line_counter + 1;
                                -- Debug
                                v_line_index  <= v_line_counter;
                            end if;
                        end if;
                    else
                        -- wait for tready signal
                        if (w_axis_sim_gamma_tready = '1') then
                            read(line_v, char_byte0);
                            read(line_v, char_byte1);
                            r_axis_sim_gamma_tvalid <= '1';
                            r_axis_sim_gamma_tlast <= '0';
                            r_axis_sim_gamma_tdata     <= conv_char_to_logic_vector(char_byte1, char_byte0);
                            v_line_length <= line_v'length;
                            -- Increment Pixel counter
                            v_pixel_counter := v_pixel_counter + 1;
                            v_pixel_index <= v_pixel_counter;
                        end if;
                    end if;
                    -- Check if line buffer is empty
                    if (line_v'length < 2) then
                        if (not endfile(read_file)) then
                            readline(read_file, line_v);
                        else
                            state_rfile <= sERROR;
                        end if;
                    end if;

                when sDONE =>
                    r_axis_sim_gamma_tlast <= '0';
                    r_axis_sim_gamma_tvalid <= '0';
                    r_axis_sim_gamma_tdata  <= (others => '0');
                    report "Video stream is done";
                    exit;

                when sERROR =>
                    report "Error, File too short";
                    exit;

                when others =>
                    exit;

            end case;
        end loop;
        file_close(read_file);
        report "File Read Done";
        wait;
    end process;

    ------------------------------------------
    -- AXI-Stream: OUT: Wirte to file
    ------------------------------------------
    file_write : process is
        file write_file : text;
        variable v_oline : line;
        variable v_frame_counter : integer;
        variable v_pixel_counter : integer;
    begin
        r_axis_edge_sim_tready <= '1';
        v_frame_counter := 0;
        v_pixel_counter := 0;
        -- Open File
        file_open(write_file, C_FILE_VIDEO_OUT, write_mode);
        loop
            -- Wait for clock cycle
            wait until (i_sim_clk'event and i_sim_clk = '1');
            if (w_axis_edge_sim_tvalid = '1' and r_axis_edge_sim_tready = '1') then
                if (w_axis_edge_sim_tdata(7 downto 0) = x"0A") then
                    write(v_oline, conv_std_logic_vector_to_char(x"0B"));
                else
                    write(v_oline, conv_std_logic_vector_to_char(w_axis_edge_sim_tdata(7 downto 0)));
                end if;
                if (w_axis_edge_sim_tdata(15 downto 8) = x"0A") then
                    write(v_oline, conv_std_logic_vector_to_char(x"0B"));
                else
                    write(v_oline, conv_std_logic_vector_to_char(w_axis_edge_sim_tdata(15 downto 8)));
                end if;
                -- Pixel Counter
                if (v_pixel_counter = 127) then
                    v_pixel_counter := 0;
                    writeline(write_file, v_oline);
                else
                    v_pixel_counter := v_pixel_counter + 1;
                end if;
                --if (stop_stream = '1') then
                --    exit;
                --end if
            end if;
        end loop;
        report "File save done";
        file_close(write_file);
    end process;

    u0 :counter_add
    port map (
        -- Clock/Reset
        i_clk     => i_sim_clk,
        i_aresetn => i_sim_aresetn,
        -- Enable
        i_enable  => enable,
        -- Counter
        o_count   => counter
    );

    --Gamma Correction
    gamma_lut_u0 :gamma_lut
    generic map(
        C_INIT_FILE   => C_GAMMA_LUT,
        C_PIXEL_WIDTH => 16,
        C_GAMMA_WIDTH => 8
    ) port map (
        -- Clock/Reset
        s_axis_aclk    => i_sim_clk,
        s_axis_aresetn => i_sim_aresetn,
        -- Configure LUT
        i_lut_wdata      => r_lut_wdata,
        o_lut_rdata      => r_lut_rdata,
        i_lut_addr       => r_lut_addr,
        i_lut_enable     => r_lut_enable,
        i_lut_wren       => r_lut_wren,
        -- Video In - YUV422
        s_axis_tdata     => r_axis_sim_gamma_tdata,
        s_axis_tvalid    => r_axis_sim_gamma_tvalid,
        s_axis_tready    => w_axis_sim_gamma_tready,
        s_axis_tuser_sof => r_axis_sim_gamma_tuser_sof,
        s_axis_tlast     => r_axis_sim_gamma_tlast,
        -- Video out - YUV422
        m_axis_tdata     => w_axis_gamma_edge_tdata,
        m_axis_tvalid    => w_axis_gamma_edge_tvalid,
        m_axis_tready    => w_axis_gamma_edge_tready,
        m_axis_tuser_sof => w_axis_gamma_edge_tuser_sof,
        m_axis_tlast     => w_axis_gamma_edge_tlast
    );

    edge_enhance :edge_enhancement_v1_0
        generic map (
            -- Users to add parameters here
            NUM_PIXELS => C_IMAGE_WIDTH,
            NUM_LINES  => C_IMAGE_HEIGHT
        ) port map (
            -- Users to add ports here
            i_axis_aclk     => i_sim_clk,
            i_axis_aresetn  => i_sim_aresetn,
            -- Video In - YUV422
            s_axis_tdata     => w_axis_gamma_edge_tdata,
            s_axis_tvalid    => w_axis_gamma_edge_tvalid,
            s_axis_tready    => w_axis_gamma_edge_tready,
            s_axis_tuser_sof => w_axis_gamma_edge_tuser_sof,
            s_axis_tlast     => w_axis_gamma_edge_tlast,

            -- Video out - YUV 422
            m_axis_tdata     => w_axis_edge_sim_tdata,
            m_axis_tvalid    => w_axis_edge_sim_tvalid,
            m_axis_tready    => r_axis_edge_sim_tready,
            m_axis_tuser_sof => w_axis_edge_sim_tuser_sof,
            m_axis_tlast     => w_axis_edge_sim_tlast,

            -- Control Registers
            i_reg_matrix_select => w_reg_matrix_select,
            i_reg_grayscale_en  => w_reg_grayscale_en,
            i_reg_kernel_bypass => w_reg_kernel_bypass,
            i_reg_kernel_gain   => w_reg_kernel_gain
        );

end tb;
