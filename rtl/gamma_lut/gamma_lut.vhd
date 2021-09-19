library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library unimacro;
use unimacro.VCOMPONENTS.all;

entity gamma_lut is
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
end;

architecture rtl of gamma_lut is
    -- Signals
    signal r_axis_tdata_d     : std_logic_vector (C_PIXEL_WIDTH - C_GAMMA_WIDTH - 1 downto 0);
    signal r_axis_tvalid_d    : std_logic;
    signal r_axis_tuser_sof_d : std_logic;
    signal r_axis_tlast_d     : std_Logic;
    --
    signal w_lut_reset      : std_logic;
    signal w_lut_rdata      : std_logic_vector (C_GAMMA_WIDTH - 1 downto 0);
    signal w_lut_pixel_addr : std_logic_vector (10 downto 0);

    component BRAM_TDP_MACRO is
        generic (
            BRAM_SIZE : string := "18Kb";
            DEVICE : string := "VIRTEX5";
            INIT_FILE : string := "NONE";
            READ_WIDTH_A : integer := 1;
            READ_WIDTH_B : integer := 1;
            WRITE_WIDTH_A : integer := 1;
            WRITE_WIDTH_B : integer := 1

        );
        port (

            DOA : out std_logic_vector(READ_WIDTH_A-1 downto 0);
            DOB : out std_logic_vector(READ_WIDTH_B-1 downto 0);

            ADDRA : in std_logic_vector;
            ADDRB : in std_logic_vector;
            CLKA : in std_ulogic;
            CLKB : in std_ulogic;
            DIA : in std_logic_vector(WRITE_WIDTH_A-1 downto 0);
            DIB : in std_logic_vector(WRITE_WIDTH_B-1 downto 0);
            ENA : in std_ulogic;
            ENB : in std_ulogic;
            REGCEA : in std_ulogic;
            REGCEB : in std_ulogic;
            RSTA : in std_ulogic;
            RSTB : in std_ulogic;
            WEA : in std_logic_vector;
            WEB : in std_logic_vector

        );
    end component;

begin


    -- Video out
    m_axis_tdata     <= r_axis_tdata_d & w_lut_rdata;
    m_axis_tvalid    <= r_axis_tvalid_d;
    s_axis_tready    <= m_axis_tready;
    m_axis_tuser_sof <= r_axis_tuser_sof_d;
    m_axis_tlast     <= r_axis_tlast_d;

    -- 1 Clock cycle delay
    stream_delay : process (s_axis_aclk, s_axis_aresetn)
    begin
        if (s_axis_aresetn = '0') then
            r_axis_tdata_d     <= (others => '0');
            r_axis_tvalid_d    <= '0';
            r_axis_tuser_sof_d <= '0';
            r_axis_tlast_d     <= '0';
        elsif (s_axis_aclk'event and s_axis_aclk = '1') then
            r_axis_tdata_d     <= s_axis_tdata(C_PIXEL_WIDTH - 1 downto C_GAMMA_WIDTH);
            r_axis_tvalid_d    <= s_axis_tvalid;
            r_axis_tuser_sof_d <= s_axis_tuser_sof;
            r_axis_tlast_d     <= s_axis_tlast;
        end if;
    end process;

    w_lut_reset      <= not s_axis_aresetn;
    w_lut_pixel_addr <= "000" & s_axis_tdata(C_GAMMA_WIDTH-1 downto 0);

    --BRAM Memory
    -- Components
    BRAM_TDP_MACRO_lut : BRAM_TDP_MACRO
    generic map (
        BRAM_SIZE     => "18Kb",
        DEVICE        => "7SERIES",
        INIT_FILE     => C_INIT_FILE,
        READ_WIDTH_A  => C_GAMMA_WIDTH,
        READ_WIDTH_B  => C_GAMMA_WIDTH,
        WRITE_WIDTH_A => C_GAMMA_WIDTH,
        WRITE_WIDTH_B => C_GAMMA_WIDTH
    ) port map (
        -- Clock/Reset
        CLKA => s_axis_aclk,
        RSTA => w_lut_reset,
        CLKB => s_axis_aclk,
        RSTB => w_lut_reset,
        -- A port - Configuration
        DIA    => i_lut_wdata,
        DOA    => o_lut_rdata,
        ADDRA  => i_lut_addr,
        REGCEA => '0',
        ENA    => i_lut_enable,
        WEA    => "0",
        -- B port - Video In/Out
        DIB    => x"00",
        DOB    => w_lut_rdata,
        ADDRB  => w_lut_pixel_addr,
        REGCEB => '0',
        ENB    => '1',
        WEB    => "0"
    );

end rtl;
