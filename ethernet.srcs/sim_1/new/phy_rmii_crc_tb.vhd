-------------------------------------------------------------------------------
-- Test bench for ethernet_top (with correct CRC bytes for single‐byte payload),
-- but now sending LSB‐first nibbles over RMII. That is, for each byte:
--   • First send bits [1:0], then [3:2], then [5:4], then [7:6].
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ethernet_top is
  -- No external ports
end entity;

architecture Behavioral of tb_ethernet_top is

  ----------------------------------------------------------------------------
  -- Clock / reset signals
  ----------------------------------------------------------------------------
  signal sys_clk     : std_logic := '0';  -- 100 MHz
  signal phy_ref_clk : std_logic := '0';  -- 50 MHz (RMII reference)
  signal reset_n     : std_logic := '0';  -- active‐low reset

  ----------------------------------------------------------------------------
  -- PHY → MAC (inputs to ethernet_top)
  ----------------------------------------------------------------------------
  signal phy_rxd    : std_logic_vector(1 downto 0) := (others => '0');
  signal phy_rx_dv  : std_logic := '0';
  signal phy_crs_dv : std_logic := '0';

  ----------------------------------------------------------------------------
  -- PHY ← MAC (outputs from ethernet_top)
  ----------------------------------------------------------------------------
  signal phy_tx_en  : std_logic;
  signal phy_txd    : std_logic_vector(1 downto 0);

  ----------------------------------------------------------------------------
  -- MDIO/MDC (unused in this TB, but required ports)
  ----------------------------------------------------------------------------
  signal phy_mdio : std_logic := 'Z';
  signal phy_mdc  : std_logic := '0';

  ----------------------------------------------------------------------------
  -- Status signals (not used in this TB)
  ----------------------------------------------------------------------------
  signal frame_error : std_logic;
  signal frame_valid : std_logic;

  ----------------------------------------------------------------------------
  -- Internal nets for instantiated modules
  ----------------------------------------------------------------------------
  signal rst_b           : std_logic := '0';
  signal mac_rx_rd_en    : std_logic := '0';
  signal mac_wr_en       : std_logic := '0';
  signal tx_fifo_full    : std_logic := '0';
  signal mac_rd_en       : std_logic := '0';
  signal tx_fifo_empty   : std_logic := '1';
  signal phy_wr_en       : std_logic := '0';
  signal rx_fifo_full    : std_logic := '0';
  signal rx_fifo_empty   : std_logic := '1';
  signal crc_data_valid  : std_logic := '0';
  signal frame_ready     : std_logic := '0';
  signal crc_ok          : std_logic := '0';
  signal crc_data_in     : std_logic_vector(7 downto 0) := (others => '0');
  signal mac_byte        : std_logic_vector(7 downto 0) := (others => '0');
  signal mac_tx          : std_logic_vector(7 downto 0) := (others => '0');
  signal mac_rx_byte     : std_logic_vector(7 downto 0) := (others => '0');
  signal computed_crc32  : std_logic_vector(31 downto 0) := (others => '0');

begin

  ----------------------------------------------------------------------------
  -- Instantiate the DUT
  ----------------------------------------------------------------------------
  DUT: entity work.ethernet_top
    port map(
      -- PHY side
      phy_rxd     => phy_rxd,
      phy_rx_dv   => phy_rx_dv,
      phy_crs_dv  => phy_crs_dv,
      phy_tx_en   => phy_tx_en,
      phy_txd     => phy_txd,
      ref_clk => phy_ref_clk,
      phy_mdio    => phy_mdio,
      --phy_mdc     => phy_mdc,

      -- MAC status
      --frame_error => frame_error,
      --frame_valid => frame_valid,

      -- Clock / Reset
      reset     => reset_n,
      sys_clk     => sys_clk
    );

  ----------------------------------------------------------------------------
  -- 100 MHz system clock
  ----------------------------------------------------------------------------
  clk_process_sys: process
  begin
    sys_clk <= '0';
    wait for 5 ns;
    sys_clk <= '1';
    wait for 5 ns;
  end process;

  ----------------------------------------------------------------------------
  -- 50 MHz RMII reference clock
  ----------------------------------------------------------------------------
  clk_process_phy: process
  begin
    phy_ref_clk <= '0';
    wait for 10 ns;
    phy_ref_clk <= '1';
    wait for 10 ns;
  end process;

  ----------------------------------------------------------------------------
  -- Reset: hold low for 100 ns, then release
  ----------------------------------------------------------------------------
  reset_process: process
  begin
    reset_n <= '1';
    wait for 100 ns;
    reset_n <= '0';
    wait;
  end process;

  ----------------------------------------------------------------------------
  -- Mirror phy_rx_dv to phy_crs_dv (no collisions in this TB)
  ----------------------------------------------------------------------------
  phy_crs_dv <= phy_rx_dv;

  ----------------------------------------------------------------------------
  -- Stimulus: send one frame with proper CRC at RMII, using LSB‐first nibble order
  ----------------------------------------------------------------------------
  stimulus_process: process
    -- Function: break a byte into four 2‐bit RMII symbols, LSB‐first:
    --   nibble0 = b(1 downto 0), nibble1 = b(3 downto 2), nibble2 = b(5 downto 4), nibble3 = b(7 downto 6)
    function byte_to_nibbles_lsb_first(b: std_logic_vector(7 downto 0))
      return std_logic_vector is
      variable outv: std_logic_vector(7 downto 0);
    begin
      outv(1 downto 0) := b(1 downto 0);
      outv(3 downto 2) := b(3 downto 2);
      outv(5 downto 4) := b(5 downto 4);
      outv(7 downto 6) := b(7 downto 6);
      return outv;
    end function;

    -- Frame bytes
    constant ZERO_BYTE     : std_logic_vector(7 downto 0) := x"00";
    constant PREAMBLE_BYTE : std_logic_vector(7 downto 0) := x"55";
    constant SFD_BYTE      : std_logic_vector(7 downto 0) := x"D5";
    constant PAYLOAD_BYTE  : std_logic_vector(7 downto 0) := x"A5";  -- single‐byte payload

    -- CRC‐32 (Ethernet/reflected) of {0xA5} = 0xA6BC5767
    constant CRC_BYTE0     : std_logic_vector(7 downto 0) := x"A8";
    constant CRC_BYTE1     : std_logic_vector(7 downto 0) := x"E2";
    constant CRC_BYTE2     : std_logic_vector(7 downto 0) := x"82";
    constant CRC_BYTE3     : std_logic_vector(7 downto 0) := x"D1";

    variable nibble_stream : std_logic_vector(7 downto 0);
    variable i             : integer;
    variable byte_index    : integer;
  begin
    -- Wait until reset is deasserted
    wait until reset_n = '1';
    wait for 50 ns;


        for byte_index in 1 to 7 loop
      nibble_stream := byte_to_nibbles_lsb_first(ZERO_BYTE);
      for i in 0 to 3 loop
        phy_rx_dv <= '1';
        -- Pick nibble i: bits (2*i+1 downto 2*i)
        phy_rxd   <= nibble_stream(2*i+1 downto 2*i);
        wait until rising_edge(phy_ref_clk);
      end loop;
    end loop;

    wait until rising_edge(phy_ref_clk);



    ----------------------------------------------------------------------------
    -- 1) Send 7× preamble bytes (0x55) – each byte = 4 RMII nibbles (LSB‐first)
    ----------------------------------------------------------------------------
    for byte_index in 1 to 7 loop
      nibble_stream := byte_to_nibbles_lsb_first(PREAMBLE_BYTE);
      for i in 0 to 3 loop
        phy_rx_dv <= '1';
        -- Pick nibble i: bits (2*i+1 downto 2*i)
        phy_rxd   <= nibble_stream(2*i+1 downto 2*i);
        wait until rising_edge(phy_ref_clk);
      end loop;
    end loop;

    --wait until rising_edge(phy_ref_clk);

    ----------------------------------------------------------------------------
    -- 2) Send SFD (0xD5) – 4 nibbles (LSB‐first)
    ----------------------------------------------------------------------------
    nibble_stream := byte_to_nibbles_lsb_first(SFD_BYTE);
    for i in 0 to 3 loop
      phy_rx_dv <= '1';
      phy_rxd   <= nibble_stream(2*i+1 downto 2*i);
      wait until rising_edge(phy_ref_clk);
    end loop;

    ----------------------------------------------------------------------------
    -- 3) Send payload byte (0xA5) – 4 nibbles (LSB‐first)
    ----------------------------------------------------------------------------
    nibble_stream := byte_to_nibbles_lsb_first(PAYLOAD_BYTE);
    for i in 0 to 3 loop
      phy_rx_dv <= '1';
      phy_rxd   <= nibble_stream(2*i+1 downto 2*i);
      wait until rising_edge(phy_ref_clk);
    end loop;

    ----------------------------------------------------------------------------
    -- 4) Send the four CRC bytes (0xA6, 0xBC, 0x57, 0x67) – each 4 nibbles (LSB‐first)
    ----------------------------------------------------------------------------
    nibble_stream := byte_to_nibbles_lsb_first(CRC_BYTE0);
    for i in 0 to 3 loop
      phy_rx_dv <= '1';
      phy_rxd   <= nibble_stream(2*i+1 downto 2*i);
      wait until rising_edge(phy_ref_clk);
    end loop;

    nibble_stream := byte_to_nibbles_lsb_first(CRC_BYTE1);
    for i in 0 to 3 loop
      phy_rx_dv <= '1';
      phy_rxd   <= nibble_stream(2*i+1 downto 2*i);
      wait until rising_edge(phy_ref_clk);
    end loop;

    nibble_stream := byte_to_nibbles_lsb_first(CRC_BYTE2);
    for i in 0 to 3 loop
      phy_rx_dv <= '1';
      phy_rxd   <= nibble_stream(2*i+1 downto 2*i);
      wait until rising_edge(phy_ref_clk);
    end loop;

    nibble_stream := byte_to_nibbles_lsb_first(CRC_BYTE3);
    for i in 0 to 3 loop
      phy_rx_dv <= '1';
      phy_rxd   <= nibble_stream(2*i+1 downto 2*i);
      wait until rising_edge(phy_ref_clk);
    end loop;

    ----------------------------------------------------------------------------
    -- 5) End-of-Frame: deassert phy_rx_dv, bring lines idle one cycle
    ----------------------------------------------------------------------------
    phy_rx_dv <= '0';
    phy_rxd   <= (others => '0');
    wait until rising_edge(phy_ref_clk);

    ----------------------------------------------------------------------------
    -- 6) Wait until the MAC signals frame_ready, then check crc_ok
    ----------------------------------------------------------------------------
    wait until frame_ready = '1';
    assert crc_ok = '1'
      report "CRC check failed! Expected crc_ok = '1'." severity error;

    ----------------------------------------------------------------------------
    -- 7) Hold idle for a bit, then finish simulation
    ----------------------------------------------------------------------------
    wait for 200 ns;
    report "Testbench: Simulation finished successfully." severity note;
    wait;
  end process;

end architecture;
