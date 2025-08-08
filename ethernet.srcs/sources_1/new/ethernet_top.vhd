library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ethernet_top is
  port (
    -- RMII PHY I/O
    phy_rxd         : in  std_logic_vector(1 downto 0);
    phy_crs_dv      : in  std_logic;
    phy_tx_en       : out std_logic;
    phy_txd         : out std_logic_vector(1 downto 0);
    ref_clk         : out std_logic;                       -- exported 50MHz RMII ref clock
    phy_mdio        : inout std_logic;

    -- Debug LEDs
    led_s           : out std_logic_vector(1 downto 0);
    led             : out std_logic_vector(12 downto 0);

    -- Triggers
    start_frame_tx  : in  std_logic;                       -- start TX frame (raw)
    head_start      : in  std_logic;                       -- trigger to generate headers

    -- Global reset/clock
    reset           : in  std_logic;                       -- active-high async reset input
    sys_clk         : in  std_logic                        -- system clock (to derive ref clock, VIO)
  );
end ethernet_top;

architecture Structural of ethernet_top is

  -- RMII PHY interface (TX/RX handling, CRC hookup, nibble serialization)
  component phy_rmii_if is
    port (
      phy_rxd           : in  std_logic_vector(1 downto 0);
      phy_crs_dv        : in  std_logic;
      phy_tx_en         : out std_logic;
      phy_txd           : out std_logic_vector(1 downto 0);
      phy_ref_clk       : in  std_logic;
      phy_mdio          : inout std_logic;

      -- TX payload/header FIFOs
      tx_fifo_empty     : in  std_logic;
      mac_tx_byte       : in  std_logic_vector(7 downto 0);
      mac_rd_en         : out std_logic;
      header_byte       : in  std_logic_vector(7 downto 0);
      header_rd_en      : out std_logic;
      header_fifo_empty : in  std_logic;

      -- RX capture FIFO
      fifo_wr_en        : out std_logic;
      fifo_full         : in  std_logic;
      fifo_din          : out std_logic_vector(7 downto 0);

      -- Control
      start_frame_tx    : in  std_logic;
      crc_gen_en        : out std_logic;
      init_tx           : out std_logic;

      -- Status/CRC
      crc_data_valid    : out std_logic;
      frame_ready       : out std_logic;
      crc_ok            : out std_logic;
      init              : out std_logic;
      crc_gen_data      : out std_logic_vector(7 downto 0);
      crc_data_in       : out std_logic_vector(7 downto 0);
      led_out           : out std_logic_vector(12 downto 0);
      led_s             : out std_logic_vector(1 downto 0);
      crc_tx            : in  std_logic_vector(31 downto 0);
      computed_crc32    : in  std_logic_vector(31 downto 0);

      -- Resets/clocks
      reset_b           : in  std_logic;
      reset_n           : in  std_logic;
      sys_clk           : in  std_logic
    );
  end component;

  -- Simple dual-clock FIFO (used single-clock here)
  component fifo is
    generic (
      G_ADDR_WIDTH : positive := 9;
      G_DATA_WIDTH : positive := 32
    );
    port (
      i_write_clk  : in  std_logic;
      i_write_rstn : in  std_logic;
      i_write_en   : in  std_logic;
      i_write_data : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
      o_full       : out std_logic;

      i_read_clk   : in  std_logic;
      i_read_rstn  : in  std_logic;
      i_read_en    : in  std_logic;
      o_read_data  : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
      o_empty      : out std_logic
    );
  end component;

  -- Byte ROM streamer for payload generation
  component tx_rom is
    generic (
      data_width : integer := 8;
      depth      : integer := 52;
      data_file  : string  := "tx_data.mif"
    );
    Port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      start     : in  std_logic;
      init_tx   : in  std_logic;
      wr_en     : out std_logic;
      w_out     : out std_logic_vector(data_width-1 downto 0)
    );
  end component;

  -- RX-side CRC32 checker (expects bit-reversed byte mapping)
  component crc is
    port (
      data_rev : in  std_logic_vector(7 downto 0);
      crc_en   : in  std_logic;
      rst      : in  std_logic;
      clk      : in  std_logic;
      init     : in  std_logic;
      crc_out  : out std_logic_vector(31 downto 0)
    );
  end component;

  -- TX-side CRC32 generator
  component crc_gen is
    port (
      datain  : in  std_logic_vector(7 downto 0);
      crc_en  : in  std_logic;
      rst     : in  std_logic;
      clk     : in  std_logic;
      init    : in  std_logic;
      crc_out : out std_logic_vector(31 downto 0)
    );
  end component;

  -- Ethernet/IP/UDP header construction pipeline
  component header_control is
    Port (
      clk       : in  std_logic;
      rst_n     : in  std_logic;
      init      : in  std_logic;
      pay_en    : in  std_logic;
      init_tx   : in  std_logic;
      pay_data  : in  std_logic_vector(7 downto 0);
      fifo_full : in  std_logic;
      fifo_data : out std_logic_vector(7 downto 0);
      fifo_en   : out std_logic;
      done      : out std_logic
    );
  end component;

  -- Reset synchronizer
  component rst_sync is
    port (
      i_clk   : in  std_logic;
      i_rst_n : in  std_logic;
      o_rst_n : out std_logic
    );
  end component;

  -- VIO to control reset (external debug core)
  COMPONENT vio_reset
    PORT(
      clk       : IN  STD_LOGIC;
      probe_out0: OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
  END COMPONENT;

  -- Clocking wizard: derive 50MHz RMII reference from sys_clk
  component clk_wiz_0 is
    port (
      clk_out1 : out std_logic;
      resetn   : in  std_logic;
      locked   : out std_logic;
      clk_in1  : in  std_logic
    );
  end component;

  -- Resets/clocks
  signal rst_b           : std_logic := '1';               -- active-low reset (RMII domain)
  signal reset_n         : std_logic := '1';               -- active-low global reset (from VIO & reset)
  signal phy_ref_clk     : std_logic := '0';               -- 50MHz ref clock to PHY
  signal ref_clk_1       : std_logic := '0';
  signal locked          : std_logic := '0';

  -- TX payload/header FIFOs and control
  signal mac_rx_rd_en    : std_logic := '0';               -- RX FIFO read (unused here)
  signal mac_wr_en       : std_logic := '0';               -- payload ROM -> TX FIFO write enable
  signal tx_fifo_full    : std_logic := '0';
  signal mac_rd_en       : std_logic := '0';               -- TX FIFO read enable (asserted by RMII IF)
  signal tx_fifo_empty   : std_logic := '0';

  -- RX capture FIFO
  signal phy_wr_en       : std_logic := '0';
  signal rx_fifo_full    : std_logic := '0';
  signal rx_fifo_empty   : std_logic := '0';

  -- CRC/status
  signal crc_data_valid  : std_logic := '0';
  signal frame_ready     : std_logic := '0';
  signal header_ready    : std_logic := '0';
  signal crc_ok          : std_logic := '0';
  signal init            : std_logic := '0';
  signal crc_gen_en      : std_logic := '0';
  signal init_tx         : std_logic := '0';

  -- Header FIFO
  signal head_wr_en      : std_logic := '0';
  signal head_rd_en      : std_logic := '0';
  signal head_fifo_full  : std_logic := '0';
  signal head_fifo_empty : std_logic := '0';

  -- Start triggers (edge-detected)
  signal start_frame_sig : std_logic := '0';
  signal start_frame     : std_logic := '0';
  signal head_sig        : std_logic := '0';
  signal init_frame      : std_logic := '0';

  -- VIO reset
  signal reset_vio       : std_logic_vector(0 downto 0) := (others => '0');

  -- PHY I/O staging
  signal phy_crs_dv_sig  : std_logic := '0';
  signal phy_tx_en_sig   : std_logic := '0';
  signal phy_rxd_sig     : std_logic_vector(1 downto 0) := (others => '0');
  signal phy_txd_sig     : std_logic_vector(1 downto 0) := (others => '0');

  -- Data paths
  signal crc_data_in     : std_logic_vector(7 downto 0) := (others => '0'); -- RX byte to CRC checker
  signal mac_byte        : std_logic_vector(7 downto 0) := (others => '0'); -- TX FIFO -> RMII IF
  signal mac_tx          : std_logic_vector(7 downto 0) := (others => '0'); -- ROM -> TX FIFO
  signal head_byte       : std_logic_vector(7 downto 0) := (others => '0'); -- header_ctrl -> header FIFO
  signal head_out_byte   : std_logic_vector(7 downto 0) := (others => '0'); -- header FIFO -> RMII IF
  signal mac_rx_byte     : std_logic_vector(7 downto 0) := (others => '0'); -- RMII IF -> RX FIFO
  signal rx_byte         : std_logic_vector(7 downto 0) := (others => '0'); -- RX FIFO -> (unused)
  signal crc_gen_data    : std_logic_vector(7 downto 0) := (others => '0'); -- byte to TX CRC generator
  signal crc_tx          : std_logic_vector(31 downto 0) := (others => '0');-- generated TX CRC
  signal computed_crc32  : std_logic_vector(31 downto 0) := (others => '0');-- RX computed CRC

  -- LEDs/debug
  signal led_debug       : std_logic_vector(1 downto 0) := (others => '0');

  ATTRIBUTE MARK_DEBUG : STRING;
  ATTRIBUTE MARK_DEBUG OF phy_crs_dv_sig : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF phy_rxd_sig    : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF mac_rx_byte    : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF phy_wr_en      : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF start_frame    : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF tx_fifo_empty  : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF head_fifo_empty: SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF head_rd_en     : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF mac_byte       : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF mac_rd_en      : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF mac_tx         : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF mac_wr_en      : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF crc_gen_data   : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF crc_gen_en     : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF crc_tx         : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF phy_tx_en_sig  : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF phy_txd_sig    : SIGNAL IS "true";

begin
  -- MDIO tri-state (not driven here)
  phy_mdio <= 'Z';

  -- Clock distribution
  ref_clk     <= ref_clk_1;               -- export ref clock
  phy_ref_clk <= ref_clk_1;               -- feed RMII core

  -- LED status: frame_ready and CRC OK
  led_s(0) <= crc_ok and frame_ready;
  led_s(1) <= frame_ready;

  -- Global active-low reset composed from VIO control and external reset
  reset_n <= reset_vio(0) and (not reset);

  -- Stage PHY signals
  phy_crs_dv_sig <= phy_crs_dv;
  phy_rxd_sig    <= phy_rxd;
  phy_txd        <= phy_txd_sig;
  phy_tx_en      <= phy_tx_en_sig;

  -- RMII interface: handles TX preamble/SFD, nibble serialization, RX assembly,
  -- CRC generation/checking, and FIFO handshakes.
  eth_phy: phy_rmii_if
    port map(
      phy_rxd           => phy_rxd_sig,
      phy_crs_dv        => phy_crs_dv_sig,
      phy_tx_en         => phy_tx_en_sig,
      phy_txd           => phy_txd_sig,
      phy_ref_clk       => phy_ref_clk,
      phy_mdio          => phy_mdio,

      tx_fifo_empty     => tx_fifo_empty,
      mac_tx_byte       => mac_byte,
      mac_rd_en         => mac_rd_en,
      header_byte       => head_out_byte,
      header_rd_en      => head_rd_en,
      header_fifo_empty => head_fifo_empty,

      fifo_wr_en        => phy_wr_en,
      fifo_full         => rx_fifo_full,
      fifo_din          => mac_rx_byte,

      start_frame_tx    => start_frame,
      crc_gen_en        => crc_gen_en,
      init_tx           => init_tx,

      crc_data_valid    => crc_data_valid,
      frame_ready       => frame_ready,
      crc_ok            => crc_ok,
      init              => init,
      crc_gen_data      => crc_gen_data,
      crc_data_in       => crc_data_in,
      led_out           => led,
      led_s             => led_debug,
      crc_tx            => crc_tx,
      computed_crc32    => computed_crc32,

      reset_b           => rst_b,
      reset_n           => reset_n,
      sys_clk           => sys_clk
    );

  -- Header FIFO (single-clock RMII domain): header_control -> RMII IF
  cdc_tx_header: fifo
    generic map(
      G_ADDR_WIDTH => 6,
      G_DATA_WIDTH => 8
    )
    port map(
      i_write_clk  => phy_ref_clk,
      i_write_rstn => rst_b,
      i_write_en   => head_wr_en,
      i_write_data => head_byte,
      o_full       => head_fifo_full,

      i_read_clk   => phy_ref_clk,
      i_read_rstn  => rst_b,
      i_read_en    => head_rd_en,
      o_read_data  => head_out_byte,
      o_empty      => head_fifo_empty
    );

  -- TX payload FIFO: ROM -> FIFO -> RMII IF
  cdc_tx: fifo
    generic map(
      G_ADDR_WIDTH => 9,
      G_DATA_WIDTH => 8
    )
    port map(
      i_write_clk  => phy_ref_clk,
      i_write_rstn => rst_b,
      i_write_en   => mac_wr_en,
      i_write_data => mac_tx,
      o_full       => tx_fifo_full,

      i_read_clk   => phy_ref_clk,
      i_read_rstn  => rst_b,
      i_read_en    => mac_rd_en,
      o_read_data  => mac_byte,
      o_empty      => tx_fifo_empty
    );

  -- RX capture FIFO: RMII IF -> FIFO
  cdc_rx: fifo
    generic map(
      G_ADDR_WIDTH => 9,
      G_DATA_WIDTH => 8
    )
    port map(
      i_write_clk  => phy_ref_clk,
      i_write_rstn => rst_b,
      i_write_en   => phy_wr_en,
      i_write_data => mac_rx_byte,
      o_full       => rx_fifo_full,

      i_read_clk   => phy_ref_clk,
      i_read_rstn  => rst_b,
      i_read_en    => mac_rx_rd_en,         -- left '0' by default (no consumer here)
      o_read_data  => rx_byte,
      o_empty      => rx_fifo_empty
    );

  -- Payload ROM streamer; starts on header completion (init_frame) and end-of-frame pulse (init_tx)
  rom_tx: tx_rom
    generic map(
      data_width => 8,
      depth      => 52,
      data_file  => "tx_data.mif"
    )
    Port map(
      clk       => phy_ref_clk,
      rst       => rst_b,
      start     => init_frame,              -- edge from head_start
      init_tx   => init_tx,                 -- also used as (re)start trigger at EoF
      wr_en     => mac_wr_en,
      w_out     => mac_tx
    );

  -- Edge detector for start_frame_tx (one-cycle pulse in phy_ref_clk)
  EDGE_DETECTOR_PROC : process(phy_ref_clk)
  begin
    if rising_edge(phy_ref_clk) then
      start_frame_sig <= start_frame_tx;
      if start_frame_tx = '1' and start_frame_sig = '0' then
        start_frame <= '1';
      else
        start_frame <= '0';
      end if;
    end if;
  end process;

  -- Edge detector for head_start -> init_frame (header generation trigger)
  EDGE_DETECTOR_HEAD : process(phy_ref_clk)
  begin
    if rising_edge(phy_ref_clk) then
      head_sig <= head_start;
      if head_start = '1' and head_sig = '0' then
        init_frame <= '1';
      else
        init_frame <= '0';
      end if;
    end if;
  end process;

  -- RX CRC checker (byte-wise enable)
  crc_check: crc
    port map(
      clk      => phy_ref_clk,
      rst      => rst_b,
      data_rev => crc_data_in,          -- RMII IF provides byte in required bit order
      init     => init,                 -- pulse at frame end to reload preset
      crc_en   => crc_data_valid,       -- advance per valid RX byte
      crc_out  => computed_crc32
    );

  -- TX CRC generator (bytes from headers+payload)
  crc_ge: crc_gen
    port map(
      clk     => phy_ref_clk,
      rst     => rst_b,
      datain  => crc_gen_data,          -- byte stream to include in CRC
      init    => init_tx,               -- init at start-of-frame in TX path
      crc_en  => crc_gen_en,            -- qualify bytes
      crc_out => crc_tx
    );

  -- Header pipeline: creates Ethernet/IP/UDP header bytes into header FIFO
  header_ctrl: header_control
    Port map(
      clk       => phy_ref_clk,
      rst_n     => reset_n,
      init      => head_start,          -- kicks off header emission
      pay_en    => mac_wr_en,           -- payload stream enable (to align with UDP header)
      init_tx   => init_tx,             -- TX EoF pulse
      pay_data  => mac_tx,              -- payload bytes (for UDP checksum block inside)
      fifo_full => head_fifo_full,
      fifo_data => head_byte,           -- header bytes to header FIFO
      fifo_en   => head_wr_en,
      done      => header_ready
    );

  -- Reset synchronizer into RMII clock domain
  b_rst: rst_sync
    port map(
      i_clk   => phy_ref_clk,
      i_rst_n => reset_n,
      o_rst_n => rst_b
    );

  -- Virtual I/O providing reset control
  vio_p: vio_reset
    PORT map(
      clk       => sys_clk,
      probe_out0=> reset_vio
    );

  -- Clock wizard to generate 50MHz reference for RMII
  clk_50m: clk_wiz_0
    port map(
      clk_out1 => ref_clk_1,
      resetn   => reset_n,
      locked   => locked,
      clk_in1  => sys_clk
    );

end Structural;
