library ieee;
use ieee.std_logic_1164.all;

----------------------------------------------------------------------
-- As the name says: An implementation of a simple shift register.
-- The register is implemented using a circular buffer.
----------------------------------------------------------------------

entity shift_register is
    generic (
        DATA_WIDTH :  integer    := 19;
        DEPTH      :  integer    := 960
    );
    port (
        i_aclk    : in std_logic;
        i_aresetn : in std_logic;
        i_enable  : in std_logic;
        
        i_data_in    : in std_logic_vector(DATA_WIDTH-1 downto 0);
        o_data_out   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        o_data_valid : out std_logic
    );
end shift_register;

----------------------------------------------------------------------

architecture rtl of shift_register is   
    -- A memory that will keep the data
    type t_memory is array(0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal memory: t_memory;
    attribute ram_style: string;
    attribute ram_style of memory: signal is "block";
    
    -- Read and write pointers to the memory
    signal read_pointer : integer range 0 to DEPTH-1;
    signal write_pointer: integer range 0 to DEPTH-1;
    signal r_data_in_d  : std_logic_vector (DATA_WIDTH-1 downto 0);

begin
 
    
    process(i_aclk, i_aresetn) begin
        if i_aresetn = '0' then
            write_pointer <= 0;
            read_pointer  <= 0;
            memory <= (others => (others => '0'));
            r_data_in_d <= (others => '0');
            o_data_out <= (others => '0');
            o_data_valid <= '0';
        elsif i_aclk'event and i_aclk = '1' then
            if i_enable = '1' then
                -- The read pointer is always 1 ahead of the write pointer
                if (read_pointer >= DEPTH-1) then
                    read_pointer <= 0;
                else
                    read_pointer <= read_pointer + 1;
                end if;
                
                -- Advance write pointer by setting it to read pointer
                write_pointer <= read_pointer;

                r_data_in_d <= i_data_in;

                -- Write to memory
                memory(write_pointer) <= r_data_in_d;
                o_data_out <= memory(read_pointer);
                o_data_valid <= '1';
            else
                o_data_valid <= '0';
            end if;
        end if;
    end process;
end rtl;