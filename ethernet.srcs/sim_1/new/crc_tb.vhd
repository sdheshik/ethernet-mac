-------------------------------------------------------------------------------
-- Corrected TB for CRC32_LSBFirst.vhd, resolving type‐mismatch between 
-- std_logic_vector and bit_vector (GOLDEN_CRC).
--
-- This version:
--  • Keeps crc_out as std_logic_vector
--  • Defines GOLDEN_CRC as std_logic_vector
--  • Uses no bit_vector types in comparisons
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_crc32_lsb is
end entity;

architecture Behavioral of tb_crc32_lsb is

  -- Clock and reset
  signal clk       : std_logic := '0';
  signal rst_n     : std_logic := '0';

  -- CRC core inputs/outputs
  signal data_in    : std_logic_vector(7 downto 0) := (others => '0');
  signal data_valid : std_logic := '0';
  signal crc_out    : std_logic_vector(31 downto 0);

  --------------------------------------------------------------------------
  -- Instantiate the CRC core under test:
  --------------------------------------------------------------------------
  component CRC32_Ethernet is
    port (
      clk        : in  std_logic;
      rst_n      : in  std_logic;
      data_in    : in  std_logic_vector(7 downto 0);
      data_valid : in  std_logic;
      crc_out    : out std_logic_vector(31 downto 0)
    );
  end component;

begin
  UUT: CRC32_Ethernet
    port map(
      clk        => clk,
      rst_n      => rst_n,
      data_in    => data_in,
      data_valid => data_valid,
      crc_out    => crc_out
    );

  ----------------------------------------------------------------------------
  -- Clock generation: 50 MHz (20 ns period)
  ----------------------------------------------------------------------------
  clk_process: process
  begin
    clk <= '0';
    wait for 10 ns;
    clk <= '1';
    wait for 10 ns;
  end process;

  ----------------------------------------------------------------------------
  -- Test sequence:
  --  1) Assert reset for a few cycles
  --  2) Deassert reset; feed ASCII "123456789" (bytes 0x31..0x39)
  --     with data_valid='1' for exactly one cycle per byte.
  --  3) Wait one cycle, then check crc_out = x"CBF43926"
  --  4) Feed the four‐byte FCS (0x26,0x39,0xF4,0xCB) LSB‐first, and check crc_out = x"00000000"
  ----------------------------------------------------------------------------
  stimulus: process
    -- ASCII codes for "123456789"
    constant ASCII_STRING : std_logic_vector(9*8-1 downto 0) := 
      x"31" & x"32" & x"33" & x"34" & x"35" & x"36" & x"37" & x"38" & x"39";
    -- The known CRC-32 (reflected) of "123456789" is 0xCBF43926.
    constant GOLDEN_CRC   : std_logic_vector(31 downto 0) := x"CBF43926";

    -- FCS bytes LSB-first (little endian):  
    --   The four‐byte sequence that produces 0xCBF43926 is {0x26,0x39,0xF4,0xCB}.
    constant FCS_BYTES    : std_logic_vector(32-1 downto 0) := 
      x"26" & x"39" & x"F4" & x"CB";

    variable i        : integer;
    variable byte_val : std_logic_vector(7 downto 0);
  begin
    -- 1) Reset
    rst_n <= '0';
    data_valid <= '0';
    wait for 100 ns;
    rst_n <= '1';
    wait until rising_edge(clk);

    -- 2) Feed ASCII "123456789"
    for i in 0 to 8 loop
      byte_val   := ASCII_STRING((8*(9 - i)) - 1 downto (8*(9 - i - 1)));
      data_in    <= byte_val;
      data_valid <= '1';
      wait until rising_edge(clk);
      data_valid <= '0';
      wait until rising_edge(clk);
    end loop;

    -- 3) Wait one cycle, sample crc_out
    wait until rising_edge(clk);
    assert crc_out = GOLDEN_CRC
      report "CRC mismatch on '123456789': got " --& to_hstring(crc_out) &
             --" expected " --& to_hstring(GOLDEN_CRC)
      severity error;

    -- 4) Feed the four FCS bytes (LSB‐first inside each byte)
    for i in 0 to 3 loop
      byte_val   := FCS_BYTES((8*(4 - i)) - 1 downto (8*(4 - i - 1)));
      data_in    <= byte_val;
      data_valid <= '1';
      wait until rising_edge(clk);
      data_valid <= '0';
      wait until rising_edge(clk);
    end loop;

    -- 5) Wait one cycle, check crc_out = 0x00000000
    wait until rising_edge(clk);
    assert crc_out = x"00000000"
      report "CRC after feeding FCS did not go to zero; got " --& to_hstring(crc_out)
      severity error;

    -- Done
    report "CRC core test passed." severity note;
    wait;
  end process;
end architecture;
