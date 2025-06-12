
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ethernet_top is
  port (
    -- PHY side (external pins)
    phy_rxd     : in  std_logic_vector(1 downto 0);
    phy_rx_dv   : in  std_logic;
    phy_crs_dv  : in  std_logic;      -- carrier sense + data valid
    phy_tx_en   : out std_logic;
    phy_txd     : out std_logic_vector(1 downto 0);
    --ref_clk : in  std_logic;       -- 50 MHz RMII clock (shared TX/RX)
    ref_clk     : out  std_logic;       -- 50 MHz RMII clock (shared TX/RX)
    phy_mdio    : inout std_logic;
    --PhyRxErr    : inout std_logic;
    --phy_mdc     : out   std_logic;
    phy_crs_dv_o  : out  std_logic;
    led_s         : out std_logic_vector(1 downto 0);
    --frame_valid : out std_logic;
    led            : out std_logic_vector(12 downto 0);
    start_frame_tx     : in std_logic;

    -- clock/reset
    reset         : in  std_logic;
    sys_clk       : in  std_logic       -- e.g. 100 MHz system clock
  );
end ethernet_top;

architecture Structural of ethernet_top is

component phy_rmii_if is
  port (
    -- PHY side (external pins)
    phy_rxd            : in  std_logic_vector(1 downto 0);
    phy_rx_dv          : in  std_logic;
    phy_crs_dv         : in  std_logic;      -- carrier sense + data valid
    phy_tx_en          : out std_logic;
    phy_txd            : out std_logic_vector(1 downto 0);
    phy_ref_clk        : in  std_logic;       -- 50 MHz RMII clock (shared TX/RX)
    phy_mdio           : inout std_logic;
    phy_mdc            : out   std_logic;

    -- MAC side (internal)
    tx_fifo_empty      : in std_logic;
    mac_tx_byte        : in  std_logic_vector(7 downto 0);
    mac_rd_en          : out std_logic;
    fifo_wr_en         : out std_logic;
    fifo_full          : in std_logic;
    fifo_din           : out std_logic_vector(7 downto 0);
    start_frame_tx     : in std_logic;
    crc_gen_en         : out std_logic;
    init_tx            : out std_logic;

    crc_data_valid     : out std_logic; 
    frame_ready        : out std_logic;
    crc_ok             : out std_logic;
    init               : out std_logic;
    crc_gen_data       : out std_logic_vector(7 downto 0);
    crc_data_in        : out std_logic_vector(7 downto 0);
    led_out            : out std_logic_vector(12 downto 0);
    led_s              : out std_logic_vector(1 downto 0);
    crc_tx             : in std_logic_vector(31 downto 0);
    computed_crc32     : in std_logic_vector(31 downto 0);

    -- clock/reset
    reset_b            : in  std_logic;
    reset_n            : in  std_logic;
    sys_clk            : in  std_logic       -- e.g. 100 MHz system clock
  );
end component;

component fifo is
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
end component;

component crc is
  port ( data_rev : in std_logic_vector (7 downto 0);
    crc_en , rst, clk : in std_logic;
    init              : in std_logic;
    crc_out : out std_logic_vector (31 downto 0));
end component;

component crc_gen is
  port ( data_in : in std_logic_vector (7 downto 0);
    crc_en , rst, clk : in std_logic;
    init              : in std_logic;
    crc_out : out std_logic_vector (31 downto 0));
end component;

component rst_sync is
  port (
    i_clk   : in  std_logic;  -- Target domain clock
    i_rst_n : in  std_logic;  -- Global async reset (active-low)
    o_rst_n : out std_logic   -- Local synchronized reset (active-low)
  );
end component;

COMPONENT vio_reset
  PORT(
    clk        : IN STD_LOGIC;
    probe_out0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END COMPONENT;

component clk_wiz_0 is
 port (
  clk_out1     : out std_logic;
  resetn       : in std_logic;
  locked       : out std_logic;
  clk_in1      : in std_logic
 );
 end component;

signal rst_b              : std_logic:= '1';
signal reset_n            : std_logic:= '1';
signal mac_rx_rd_en       : std_logic:= '0';
signal mac_wr_en          : std_logic:= '0';
signal tx_fifo_full       : std_logic:= '0';
signal mac_rd_en          : std_logic:= '0';
signal tx_fifo_empty      : std_logic:= '0';
signal phy_wr_en          : std_logic:= '0';
signal rx_fifo_full       : std_logic:= '0';
signal rx_fifo_empty      : std_logic:= '0';
signal crc_data_valid     : std_logic:= '0';
signal frame_ready        : std_logic:= '0';
signal crc_ok             : std_logic:= '0';
signal phy_ref_clk        : std_logic:= '0';
signal ref_clk_1          : std_logic:= '0';            
signal locked             : std_logic:= '0';
signal phy_mdc            : std_logic:= '0';
signal phy_crs_dv_sig     : std_logic:= '0';
signal start_frame_tx_sig : std_logic:= '0';
signal phy_tx_en_sig      : std_logic:= '0';
signal init               : std_logic:= '0';
signal crc_gen_en         : std_logic:= '0';
signal init_tx            : std_logic:= '0';
signal reset_vio          : std_logic_vector(0 downto 0):= (others => '0');
signal led_debug          : std_logic_vector(1 downto 0):= (others => '0');
signal phy_rxd_sig        : std_logic_vector(1 downto 0):= (others => '0');
signal phy_txd_sig        : std_logic_vector(1 downto 0):= (others => '0');
signal crc_data_in        : std_logic_vector(7 downto 0):= (others => '0');
signal mac_byte           : std_logic_vector(7 downto 0):= (others => '0');
signal mac_tx             : std_logic_vector(7 downto 0):= (others => '0');
signal mac_rx_byte        : std_logic_vector(7 downto 0):= (others => '0');
signal rx_byte            : std_logic_vector(7 downto 0):= (others => '0');
signal crc_gen_data       : std_logic_vector(7 downto 0):= (others => '0');
signal crc_tx             : std_logic_vector(31 downto 0):= (others => '0');
signal computed_crc32     : std_logic_vector(31 downto 0):= (others => '0');

ATTRIBUTE MARK_DEBUG : STRING;

--ATTRIBUTE MARK_DEBUG OF ref_clk_1 : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF phy_crs_dv_sig : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF phy_rxd_sig : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF mac_rx_byte : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF phy_wr_en   : SIGNAL IS "true";

ATTRIBUTE MARK_DEBUG OF tx_fifo_empty   : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF mac_byte   : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF mac_rd_en   : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF crc_gen_data   : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF crc_tx   : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF phy_tx_en_sig   : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF phy_txd_sig   : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF init   : SIGNAL IS "true";

begin

phy_mdio <= 'Z';
--PhyRxErr <= PhyRxErr;

ref_clk <= ref_clk_1; --when locked = '1' else '0';
phy_ref_clk <= ref_clk_1; --when locked = '1' else '0';

-- phy_ref_clk <= ref_clk;

led_s(0) <= crc_ok and frame_ready;
led_s(1) <= frame_ready;

--reset_n <= not reset;
reset_n <= reset_vio(0) and (not reset);

phy_crs_dv_o <= phy_crs_dv;

phy_crs_dv_sig <= phy_crs_dv;

phy_rxd_sig <= phy_rxd;

phy_txd <= phy_txd_sig;

phy_tx_en <= phy_tx_en_sig;

start_frame_tx_sig <= start_frame_tx;



eth_phy: phy_rmii_if
  port map(
    -- PHY side (external pins)
    phy_rxd     => phy_rxd_sig,
    phy_rx_dv   => phy_rx_dv,
    phy_crs_dv  => Phy_crs_dv_sig,
    phy_tx_en   => phy_tx_en_sig,
    phy_txd     => phy_txd_sig,
    phy_ref_clk => phy_ref_clk,
    phy_mdio    => phy_mdio,
    phy_mdc     => phy_mdc,

    -- MAC side (internal)
    tx_fifo_empty      => tx_fifo_empty,
    mac_tx_byte        => mac_byte,
    mac_rd_en          => mac_rd_en,
    fifo_wr_en         => phy_wr_en,
    fifo_full          => rx_fifo_full,
    fifo_din           => mac_rx_byte,
    start_frame_tx     => init,--start_frame_tx_sig,
    crc_gen_en         => crc_gen_en,
    init_tx            => init_tx,


    crc_data_valid     => crc_data_valid,
    frame_ready        => frame_ready,
    crc_ok             => crc_ok,
    init               => init,
    crc_gen_data       => crc_gen_data,
    crc_data_in        => crc_data_in,
    led_out            => led,
    led_s              => led_debug,
    crc_tx             => crc_tx,
    computed_crc32     => computed_crc32,


    -- clock/reset
    reset_b       => rst_b,
    reset_n       => reset_n,
    sys_clk       => sys_clk
  );

cdc_tx: fifo
  generic map(
    G_ADDR_WIDTH => 9,
    G_DATA_WIDTH => 8
  )
  port map(
    -- Write port (clk domain A)
    i_write_clk  => sys_clk,
    i_write_rstn => reset_n,
    i_write_en   => mac_wr_en,
    i_write_data => rx_byte,--mac_tx,
    o_full       => tx_fifo_full,

    -- Read port (clk domain B)
    i_read_clk   => phy_ref_clk,
    i_read_rstn  => rst_b,
    i_read_en    => mac_rd_en,
    o_read_data  => mac_byte,
    o_empty      => tx_fifo_empty
  );

--   mac_wr_en <= '1' when rx_fifo_empty = '0' and tx_fifo_full = '0' else '0';
--   mac_rx_rd_en <= '1' when rx_fifo_empty = '0' and tx_fifo_full = '0' else '0';

cdc_rx: fifo
  generic map(
    G_ADDR_WIDTH => 9,
    G_DATA_WIDTH => 8
  )
  port map(
    -- Write port (clk domain A)
    i_write_clk  => phy_ref_clk,
    i_write_rstn => rst_b,
    i_write_en   => phy_wr_en,
    i_write_data => mac_rx_byte,
    o_full       => rx_fifo_full,

    -- Read port (clk domain B)
    i_read_clk   => sys_clk,
    i_read_rstn  => reset_n,
    i_read_en    => mac_rx_rd_en,
    o_read_data  => rx_byte,
    o_empty      => rx_fifo_empty
  );


-- cdc_rx: fifo
--   generic map(
--     G_ADDR_WIDTH => 9,
--     G_DATA_WIDTH => 8
--   )
--   port map(
--     -- Write port (clk domain A)
--     i_write_clk  => phy_ref_clk,
--     i_write_rstn => rst_b,
--     i_write_en   => phy_wr_en,
--     i_write_data => mac_rx_byte,
--     o_full       => rx_fifo_full,

--     -- Read port (clk domain B)
--     i_read_clk   => phy_ref_clk,
--     i_read_rstn  => rst_b,
--     i_read_en    => mac_rd_en,
--     o_read_data  => mac_byte,
--     o_empty      => tx_fifo_empty
--   );

crc_check: crc
  port map(
    clk         => phy_ref_clk,
    rst         => rst_b,
    data_rev     => crc_data_in,
    init        => init,
    crc_en      => crc_data_valid,                 -- assert ’1’ for each byte to be processed
    crc_out     => computed_crc32                  -- current CRC remainder (reflected & XOR’d)
  );


crc_ge: crc_gen
  port map(
    clk         => phy_ref_clk,
    rst         => rst_b,
    data_in     => crc_gen_data,
    init        => init_tx,
    crc_en      => crc_gen_en,                 -- assert ’1’ for each byte to be processed
    crc_out     => crc_tx                  -- current CRC remainder (reflected & XOR’d)
  );

b_rst: rst_sync
  port map(
    i_clk   => phy_ref_clk,
    i_rst_n => reset_n,
    o_rst_n => rst_b
  );

vio_p: vio_reset
  PORT map(
    clk        => sys_clk,
    probe_out0 => reset_vio
  );

clk_50m: clk_wiz_0
 port map(
  clk_out1     => ref_clk_1,
  resetn       => reset_n,
  locked       => locked,
  clk_in1      => sys_clk
 );


end Structural;
