library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-------------------------------------------------------------------------------
-- Entity: dpram
-- True dual‐port RAM with independent clocks, enables, and write‐controls.
-- Allows simultaneous read/write on each port.
-------------------------------------------------------------------------------
entity dpram is
  generic (
    G_ADDR_WIDTH : positive := 11;  -- Address bus width (depth = 2**G_ADDR_WIDTH)
    G_DATA_WIDTH : positive := 8    -- Data word width
  );
  port (
    -- Port A
    i_clk_a   : in  std_logic;                                  -- Clock A
    i_en_a    : in  std_logic;                                  -- Enable A
    i_we_a    : in  std_logic;                                  -- Write enable A
    i_addr_a  : in  std_logic_vector(G_ADDR_WIDTH-1 downto 0);  -- Address A
    i_write_a : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);  -- Write data A
    o_read_a  : out std_logic_vector(G_DATA_WIDTH-1 downto 0);  -- Read data A

    -- Port B
    i_clk_b   : in  std_logic;                                  -- Clock B
    i_en_b    : in  std_logic;                                  -- Enable B
    i_we_b    : in  std_logic;                                  -- Write enable B
    i_addr_b  : in  std_logic_vector(G_ADDR_WIDTH-1 downto 0);  -- Address B
    i_write_b : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);  -- Write data B
    o_read_b  : out std_logic_vector(G_DATA_WIDTH-1 downto 0)   -- Read data B
  );
end entity dpram;

-------------------------------------------------------------------------------
-- Architecture: rtl
-------------------------------------------------------------------------------
architecture rtl of dpram is

  -----------------------------------------------------------------------------
  -- Type & Constants
  -----------------------------------------------------------------------------
  constant RAM_DEPTH : positive := 2**G_ADDR_WIDTH - 1;  
  -- Memory array spans 0 to RAM_DEPTH inclusive
  type ram_t is array (0 to RAM_DEPTH) of std_logic_vector(G_DATA_WIDTH-1 downto 0);

  -----------------------------------------------------------------------------
  -- Internal Signals
  -----------------------------------------------------------------------------
  signal ram      : ram_t;                                      -- RAM storage
  signal r_addr_a : std_logic_vector(G_ADDR_WIDTH-1 downto 0);  -- Registered read address A
  signal r_addr_b : std_logic_vector(G_ADDR_WIDTH-1 downto 0);  -- Registered read address B

begin

  -----------------------------------------------------------------------------
  -- Continuous Read Outputs
  -- Data is read asynchronously from the registered addresses.
  -----------------------------------------------------------------------------
  o_read_a <= ram(to_integer(unsigned(r_addr_a)));
  o_read_b <= ram(to_integer(unsigned(r_addr_b)));

  -----------------------------------------------------------------------------
  -- Dual‐Clock RAM Process
  -- On each rising edge of i_clk_a or i_clk_b, handle port A and B operations.
  -----------------------------------------------------------------------------
  p_dpram: process(i_clk_a, i_clk_b)
  begin
    -- Port A operations
    if rising_edge(i_clk_a) then
      if i_en_a = '1' then
        -- Register address for read
        r_addr_a <= i_addr_a;
        -- Write on write‐enable
        if i_we_a = '1' then
          ram(to_integer(unsigned(i_addr_a))) <= i_write_a;
        end if;
      end if;
    end if;

    -- Port B operations
    if rising_edge(i_clk_b) then
      if i_en_b = '1' then
        -- Register address for read
        r_addr_b <= i_addr_b;
        -- Write on write‐enable
        if i_we_b = '1' then
          ram(to_integer(unsigned(i_addr_b))) <= i_write_b;
        end if;
      end if;
    end if;
  end process p_dpram;

end architecture rtl;
