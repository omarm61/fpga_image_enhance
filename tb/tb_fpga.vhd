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
    constant COUNTER_SIZE : integer := 8;
    -- Signals
    signal enable : std_logic;
    signal counter: std_logic_vector (COUNTER_SIZE-1 downto 0);


    -- Components
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
begin

    tb1 : process
    begin
        enable <= '0';
        -- Wait for Reset
        wait for 100 ps;
        -- Enable Counter
        enable <= '1';

        -- Wait for simulation to end
        wait;
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

end tb;
