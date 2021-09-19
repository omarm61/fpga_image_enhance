library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity counter_add is
    port (
            -- Clock/Reset
             i_clk          : in std_logic;
             i_aresetn      : in std_logic;
            -- Enable
             i_enable       : in std_logic;
            -- Output Count
             o_count        : out std_logic_vector (7 downto 0)
        );
end;

architecture rtl of counter_add is
    -- Signals
    signal counter : std_logic_vector (7 downto 0);
begin

    o_count <= counter;

	ctr: process(i_clk, i_aresetn)
	begin
		if (i_aresetn = '0') then
            counter <= (others => '0');
		elsif i_clk'event and (i_clk = '1') then
            if (i_enable = '1') then
                counter <= counter + '1';
            end if;
		end if;
	end process;

end rtl;


