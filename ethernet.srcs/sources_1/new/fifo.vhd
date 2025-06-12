library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library lib_cdc;
use lib_cdc.cdc_pkg.all;

-------------------------------------------------------------------------------
-- Entity: fifo
-- Asynchronous FIFO with independent write/read clocks, using
-- gray‐counter pointers and a dual‐port RAM for storage.
-------------------------------------------------------------------------------
entity fifo is
  generic (
    G_ADDR_WIDTH : positive := 9;    -- Address width (depth = 2**G_ADDR_WIDTH)
    G_DATA_WIDTH : positive := 32    -- Data word width
  );
  port (
    -- Write port (clk domain A)
    i_write_clk  : in  std_logic;                                     -- Write clock
    i_write_rstn : in  std_logic;                                     -- Active‐low write reset
    i_write_en   : in  std_logic;                                     -- Write enable
    i_write_data : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);     -- Data to write
    o_full       : out std_logic;                                     -- FIFO full flag

    -- Read port (clk domain B)
    i_read_clk   : in  std_logic;                                     -- Read clock
    i_read_rstn  : in  std_logic;                                     -- Active‐low read reset
    i_read_en    : in  std_logic;                                     -- Read enable
    o_read_data  : out std_logic_vector(G_DATA_WIDTH-1 downto 0);     -- Data read out
    o_empty      : out std_logic                                      -- FIFO empty flag
  );
end entity fifo;

-------------------------------------------------------------------------------
-- Architecture: rtl
-------------------------------------------------------------------------------
architecture rtl of fifo is

  -----------------------------------------------------------------------------
  -- Internal Signals: Write side
  -----------------------------------------------------------------------------
  signal r_write_en          : std_logic;                                    -- Gated write enable
  signal r_full              : std_logic;                                    -- Registered full flag
  signal r_write_address     : std_logic_vector(G_ADDR_WIDTH-1 downto 0);    -- Binary write address
  signal r_write_pointer     : std_logic_vector(G_ADDR_WIDTH downto 0);      -- Gray‐coded write pointer
  signal r_read_pointer_sync : std_logic_vector(G_ADDR_WIDTH downto 0);      -- Synchronized read pointer

  -----------------------------------------------------------------------------
  -- Internal Signals: Read side
  -----------------------------------------------------------------------------
  signal r_read_en           : std_logic;                                    -- Gated read enable
  signal r_empty             : std_logic;                                    -- Registered empty flag
  signal r_read_address      : std_logic_vector(G_ADDR_WIDTH-1 downto 0);    -- Binary read address
  signal r_read_pointer      : std_logic_vector(G_ADDR_WIDTH downto 0);      -- Gray‐coded read pointer
  signal r_write_pointer_sync: std_logic_vector(G_ADDR_WIDTH downto 0);      -- Synchronized write pointer

begin

  -----------------------------------------------------------------------------
  -- Output Assignments
  -----------------------------------------------------------------------------
  o_full  <= r_full;
  o_empty <= r_empty;

  -----------------------------------------------------------------------------
  -- Address Generation & Enable Signals
  -----------------------------------------------------------------------------
  r_write_address <= gray2bin(r_write_pointer(G_ADDR_WIDTH-1 downto 0));
  r_write_en      <= i_write_en and not r_full;

  r_read_address  <= gray2bin(r_read_pointer(G_ADDR_WIDTH-1 downto 0));
  r_read_en       <= i_read_en;

  -----------------------------------------------------------------------------
  -- Dual‐Port RAM for Storage
  -----------------------------------------------------------------------------
  u_dpram : dpram
    generic map (
      G_ADDR_WIDTH => G_ADDR_WIDTH,
      G_DATA_WIDTH => G_DATA_WIDTH
    )
    port map (
      -- Write port A
      i_clk_a   => i_write_clk,
      i_en_a    => r_write_en,
      i_we_a    => r_write_en,
      i_addr_a  => r_write_address,
      i_write_a => i_write_data,
      o_read_a  => open,

      -- Read port B
      i_clk_b   => i_read_clk,
      i_en_b    => r_read_en,
      i_we_b    => '0',
      i_addr_b  => r_read_address,
      i_write_b => (others => '0'),
      o_read_b  => o_read_data
    );

  -----------------------------------------------------------------------------
  -- Synchronize Read Pointer into Write Clock Domain
  -----------------------------------------------------------------------------
  g_read_pointer_sync : for i in 0 to r_read_pointer'length-1 generate
    u_read_pointer_sync : synchronizer
      port map (
        i_clk   => i_write_clk,
        i_rst_n => i_write_rstn,
        i_data  => r_read_pointer(i),
        o_data  => r_read_pointer_sync(i)
      );
  end generate g_read_pointer_sync;

  -----------------------------------------------------------------------------
  -- Write Pointer & Full Flag Logic (in write clock domain)
  -----------------------------------------------------------------------------
  p_write : process(i_write_clk)
    variable write_counter : unsigned(G_ADDR_WIDTH downto 0);
    variable full_flag     : std_logic;
  begin
    if rising_edge(i_write_clk) then
      if i_write_rstn = '0' then
        write_counter := (others => '0');
        full_flag     := '0';
      else
        -- Full when next write pointer would catch read pointer (inverted MSBs & match LSBs)
        if ( r_write_pointer(G_ADDR_WIDTH downto G_ADDR_WIDTH-1) =
             not r_read_pointer_sync(G_ADDR_WIDTH downto G_ADDR_WIDTH-1) ) and
           ( r_write_pointer(G_ADDR_WIDTH-2 downto 0) =
             r_read_pointer_sync(G_ADDR_WIDTH-2 downto 0) ) then
          full_flag := '1';
        else
          full_flag := '0';
        end if;

        -- Increment write counter if writing and not full
        if i_write_en = '1' and full_flag = '0' then
          write_counter := write_counter + 1;
        end if;
      end if;

      -- Update gray‐coded pointer & full flag
      r_write_pointer <= bin2gray(std_logic_vector(write_counter));
      r_full          <= full_flag;
    end if;
  end process p_write;

  -----------------------------------------------------------------------------
  -- Synchronize Write Pointer into Read Clock Domain
  -----------------------------------------------------------------------------
  g_write_pointer_sync : for i in 0 to r_write_pointer'length-1 generate
    u_write_pointer_sync : synchronizer
      port map (
        i_clk   => i_read_clk,
        i_rst_n => i_read_rstn,
        i_data  => r_write_pointer(i),
        o_data  => r_write_pointer_sync(i)
      );
  end generate g_write_pointer_sync;

  -----------------------------------------------------------------------------
  -- Read Pointer & Empty Flag Logic (in read clock domain)
  -----------------------------------------------------------------------------
  p_read : process(i_read_clk)
    variable read_counter : unsigned(G_ADDR_WIDTH downto 0);
    variable empty_flag   : std_logic;
  begin
    if rising_edge(i_read_clk) then
      if i_read_rstn = '0' then
        read_counter := (others => '0');
        empty_flag   := '1';
      else
        -- Empty when read pointer equals synchronized write pointer
        if r_read_pointer = r_write_pointer_sync then
          empty_flag := '1';
        else
          empty_flag := '0';
        end if;

        -- Increment read counter if reading and not empty
        if i_read_en = '1' and empty_flag = '0' then
          read_counter := read_counter + 1;
        end if;
      end if;

      -- Update gray‐coded pointer & empty flag
      r_read_pointer <= bin2gray(std_logic_vector(read_counter));
      r_empty        <= empty_flag;
    end if;
  end process p_read;

end architecture rtl;
