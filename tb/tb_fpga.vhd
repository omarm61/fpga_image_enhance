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
    constant C_FILE_VIDEO_IN  : string := "video_in_sim.txt";
    constant C_FILE_VIDEO_OUT : string := "video_out_sim.txt";

    -- Signals
    signal enable : std_logic;
    signal counter: std_logic_vector (C_COUNTER_SIZE-1 downto 0);

    -- AXI-Stream
    -- Master
    signal m_axis_tdata     : std_logic_vector (15 downto 0);
    signal m_axis_tvalid    : std_logic;
    signal m_axis_tready    : std_logic;
    signal m_axis_tuser_sof : std_logic;
    signal m_axis_tlast     : std_logic;

    -- Slave
    signal s_axis_tdata     : std_logic_vector (15 downto 0);
    signal s_axis_tvalid    : std_logic;
    signal s_axis_tready    : std_logic;
    signal s_axis_tuser_sof : std_logic;
    signal s_axis_tlast     : std_logic;

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
        m_axis_tdata       <= (others => '0');
        m_axis_tvalid      <= '0';
        m_axis_tuser_sof   <= '0';
        m_axis_tlast       <= '0';
        s_axis_tready      <= '0';
        v_pixel_counter    := 0;
        v_line_counter     := 0;

        -- Open File
        file_open(read_file, C_FILE_VIDEO_IN, read_mode);
        --file_open(write_file, "target.txt", write_mode);
            --while not endfile(read_file) loop
        state_rfile <= sIDLE;
        loop
            -- Wait for clock cycle
            wait until (i_sim_clk'event and i_sim_clk = '1');
            s_axis_tready <= '1';
            case(state_rfile) is
                when sIDLE =>
                    -- Reset Signals
                    m_axis_tlast     <= '0';
                    m_axis_tvalid    <= '0';
                    m_axis_tuser_sof <= '0';
                    m_axis_tdata     <= (others => '0');
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
                    m_axis_tdata <= (others => '0');
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
                    if (m_axis_tready = '1') then
                        -- Read first two bytes
                        read(line_v, char_byte0);
                        read(line_v, char_byte1);
                        -- Set Start of frame signal
                        m_axis_tuser_sof <= '1';
                        m_axis_tlast     <= '0';
                        m_axis_tvalid    <= '1';
                        m_axis_tdata     <= conv_char_to_logic_vector(char_byte1, char_byte0);
                        -- Increment counter
                        v_pixel_counter := v_pixel_counter + 1;
                        v_pixel_index   <= v_pixel_counter;
                        -- Next State
                        state_rfile <= sSEND_LINE;
                        v_line_length <= line_v'length;
                    end if;

                when sSEND_LINE =>
                    --
                    m_axis_tuser_sof <= '0';
                    -- Read pixel
                    if (v_pixel_counter = C_IMAGE_WIDTH - 1) then
                        -- wait for tready signal
                        if (m_axis_tready = '1') then
                            read(line_v, char_byte0);
                            read(line_v, char_byte1);
                            m_axis_tlast  <= '1';
                            m_axis_tvalid <= '1';
                            m_axis_tdata  <= conv_char_to_logic_vector(char_byte1, char_byte0);
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
                        if (m_axis_tready = '1') then
                            read(line_v, char_byte0);
                            read(line_v, char_byte1);
                            m_axis_tvalid <= '1';
                            m_axis_tlast <= '0';
                            m_axis_tdata     <= conv_char_to_logic_vector(char_byte1, char_byte0);
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
                    m_axis_tlast <= '0';
                    m_axis_tvalid <= '0';
                    m_axis_tdata  <= (others => '0');
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
        s_axis_tready <= '1';
        v_frame_counter := 0;
        v_pixel_counter := 0;
        -- Open File
        file_open(write_file, C_FILE_VIDEO_OUT, write_mode);
        loop
            -- Wait for clock cycle
            wait until (i_sim_clk'event and i_sim_clk = '1');
            if (s_axis_tvalid = '1' and s_axis_tready = '1') then
                if (s_axis_tdata(7 downto 0) = x"0A") then
                    write(v_oline, conv_std_logic_vector_to_char(x"0B"));
                else
                    write(v_oline, conv_std_logic_vector_to_char(s_axis_tdata(7 downto 0)));
                end if;
                if (s_axis_tdata(15 downto 8) = x"0A") then
                    write(v_oline, conv_std_logic_vector_to_char(x"0B"));
                else
                    write(v_oline, conv_std_logic_vector_to_char(s_axis_tdata(15 downto 8)));
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
            s_axis_tdata     => m_axis_tdata,
            s_axis_tvalid    => m_axis_tvalid,
            s_axis_tready    => m_axis_tready,
            s_axis_tuser_sof => m_axis_tuser_sof,
            s_axis_tlast     => m_axis_tlast,

            -- Video out - YUV 422
            m_axis_tdata     => s_axis_tdata,
            m_axis_tvalid    => s_axis_tvalid,
            m_axis_tready    => s_axis_tready,
            m_axis_tuser_sof => s_axis_tuser_sof,
            m_axis_tlast     => s_axis_tlast,

            -- Control Registers
            i_reg_matrix_select => w_reg_matrix_select,
            i_reg_grayscale_en  => w_reg_grayscale_en,
            i_reg_kernel_bypass => w_reg_kernel_bypass,
            i_reg_kernel_gain   => w_reg_kernel_gain
        );

end tb;
