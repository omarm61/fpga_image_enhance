
library IEEE;
use IEEE.std_logic_1164.ALL;

package edge_enhancement_pkg is
    --Control Registers 
    CONSTANT EDGE_ENHANCE_CONTROL_REG_OFFSET        : integer := 0;
    CONSTANT EDGE_ENHANCE_MATRIX_SELECT_INDEX_START : integer := 0;
    CONSTANT EDGE_ENHANCE_MATRIX_SELECT_INDEX_SIZE  : integer := 1;

    CONSTANT EDGE_ENHANCE_GRAYSCALE_EN_INDEX_START  : integer := 1;
    CONSTANT EDGE_ENHANCE_GRAYSCALE_EN_INDEX_SIZE   : integer := 1;

    CONSTANT EDGE_ENHANCE_KERNEL_BYP_INDEX_START    : integer := 2;
    CONSTANT EDGE_ENHANCE_KERNEL_BYP_INDEX_SIZE     : integer := 1;

    CONSTANT EDGE_ENHANCE_KERNAL_GAIN_REG_OFFSET    : integer := 4;
    CONSTANT EDGE_ENHANCE_KERNAL_GAIN_INDEX_START   : integer := 0;
    CONSTANT EDGE_ENHANCE_KERNAL_GAIN_INDEX_SIZE    : integer := 12;  
end;

package body edge_enhancement_pkg is

end package body;
