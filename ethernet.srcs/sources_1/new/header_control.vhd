library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity header_control is
  Port (
    clk        : in  std_logic;
    rst_n      : in  std_logic;
    init       : in  std_logic;                     -- external start (edge-detected internally)
    pay_en     : in  std_logic;                     -- payload capture enable (to UDP header)
    init_tx    : in  std_logic;                     -- level start (alternative start trigger)
    pay_data   : in  std_logic_vector(7 downto 0);  -- payload byte (to UDP header)
    fifo_full  : in  std_logic;                     -- backpressure from downstream FIFO
    fifo_data  : out std_logic_vector(7 downto 0);  -- byte to FIFO
    fifo_en    : out std_logic;                     -- write enable to FIFO
    done       : out std_logic                      -- pulse when all headers complete
  );
end header_control;

architecture Behavioral of header_control is

  -- Byte outputs from sub-headers
  signal ether_byte  : std_logic_vector(7 downto 0) := (others => '0');
  signal ip_byte     : std_logic_vector(7 downto 0) := (others => '0');
  signal udp_byte    : std_logic_vector(7 downto 0) := (others => '0');

  -- FIFO output staging
  signal fifo_in     : std_logic_vector(7 downto 0) := (others => '0');

  -- Start strobes to sub-headers
  signal ether_init  : std_logic := '0';
  signal ip_init     : std_logic := '0';
  signal udp_init    : std_logic := '0';

  -- Valid/done handshakes from sub-headers
  signal ether_valid : std_logic := '0';
  signal ip_valid    : std_logic := '0';
  signal udp_valid   : std_logic := '0';
  signal ether_done  : std_logic := '0';
  signal ip_done     : std_logic := '0';
  signal udp_done    : std_logic := '0';

  -- Control/flags
  signal fifo_wr_en  : std_logic := '0';
  signal init_sig    : std_logic := '0';  -- delayed init for edge detect
  signal init_frame  : std_logic := '0';  -- one-cycle pulse on init rising edge
  signal complete    : std_logic := '0';  -- not used externally (kept for debug/ILA)

  type state is (IDLE, ETHERNET, IP, UDP);
  signal p_state : state := IDLE;

  ATTRIBUTE MARK_DEBUG : STRING;
  ATTRIBUTE MARK_DEBUG OF fifo_wr_en : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF fifo_in    : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF p_state    : SIGNAL IS "true";

  component ethernet_header is
    Port (
      clk       : in  std_logic;
      rst_n     : in  std_logic;
      init      : in  std_logic;
      fifo_full : in  std_logic;
      valid     : out std_logic;
      done      : out std_logic;
      byte_out  : out std_logic_vector(7 downto 0)
    );
  end component;

  component ip_header is
    Port (
      clk       : in  std_logic;
      rst_n     : in  std_logic;
      init      : in  std_logic;
      fifo_full : in  std_logic;
      valid     : out std_logic;
      done      : out std_logic;
      byte_out  : out std_logic_vector(7 downto 0)
    );
  end component;

  component udp_header is
    Port (
      clk       : in  std_logic;
      rst_n     : in  std_logic;
      init      : in  std_logic;
      pay_en    : in  std_logic;
      pay_data  : in  std_logic_vector(7 downto 0);
      fifo_full : in  std_logic;
      valid     : out std_logic;
      done      : out std_logic;
      byte_out  : out std_logic_vector(7 downto 0)
    );
  end component;

begin

  -- Drive external FIFO interface
  fifo_data <= fifo_in;
  fifo_en   <= fifo_wr_en;

  -- Ethernet header generator
  eth_head: ethernet_header
    Port map(
      clk        => clk,
      rst_n      => rst_n,
      init       => ether_init,     -- asserted during ETHERNET state
      fifo_full  => fifo_full,      -- propagate backpressure
      valid      => ether_valid,    -- per-byte valid
      done       => ether_done,     -- pulse when eth header finished
      byte_out   => ether_byte
    );

  -- IPv4 header generator
  ip_head: ip_header
    Port map(
      clk        => clk,
      rst_n      => rst_n,
      init       => ip_init,        -- asserted during IP state
      fifo_full  => fifo_full,
      valid      => ip_valid,
      done       => ip_done,
      byte_out   => ip_byte
    );

  -- UDP header generator
  udp_head: udp_header
    Port map(
      clk        => clk,
      rst_n      => rst_n,
      init       => udp_init,       -- asserted during UDP state
      pay_en     => pay_en,         -- payload capture enable (upstream)
      pay_data   => pay_data,       -- payload byte
      fifo_full  => fifo_full,
      valid      => udp_valid,
      done       => udp_done,
      byte_out   => udp_byte
    );

  -- Rising-edge detector for 'init' to generate one-cycle 'init_frame'
  EDGE_DETECTOR_PROC : process(clk)
  begin
    if rising_edge(clk) then
      init_sig <= init;                               -- register previous value

      -- pulse when init rises (one cycle wide)
      if init = '1' and init_sig = '0' then
        init_frame <= '1';
      else
        init_frame <= '0';
      end if;
    end if;
  end process;

  -- Top-level FSM: sequence Ethernet -> IP -> UDP headers into FIFO
  process(clk, rst_n)
  begin
    if (rst_n = '0') then
      done        <= '0';
      fifo_wr_en  <= '0';
      fifo_in     <= (others => '0');
      ether_init  <= '0';
      ip_init     <= '0';
      udp_init    <= '0';
      p_state     <= IDLE;
      complete    <= '0';

    elsif rising_edge(clk) then
      case p_state is

        when IDLE =>
          -- Idle/clear outputs; start on edge of init or level of init_tx
          done        <= '0';
          fifo_wr_en  <= '0';
          fifo_in     <= (others => '0');
          ether_init  <= '0';
          ip_init     <= '0';
          udp_init    <= '0';
          if init_frame = '1' or init_tx = '1' then
            p_state <= ETHERNET;
          end if;

        when ETHERNET =>
          -- Stream Ethernet header bytes to FIFO
          ether_init  <= '1';           -- keep asserted while emitting
          fifo_in     <= ether_byte;
          fifo_wr_en  <= ether_valid and not fifo_full;
          done        <= '0';
          if ether_done = '1' then
            p_state    <= IP;
            ether_init <= '0';          -- deassert before moving on
          end if;

        when IP =>
          -- Stream IP header bytes to FIFO
          ip_init     <= '1';
          ether_init  <= '0';
          fifo_in     <= ip_byte;
          fifo_wr_en  <= ip_valid and not fifo_full;
          done        <= '0';
          if ip_done = '1' then
            p_state  <= UDP;
            ip_init  <= '0';
          end if;

        when UDP =>
          -- Stream UDP header bytes (and payload captured inside UDP block) to FIFO
          udp_init    <= '1';
          ip_init     <= '0';
          fifo_in     <= udp_byte;
          fifo_wr_en  <= udp_valid and not fifo_full;
          done        <= '0';
          if udp_done = '1' then
            done       <= '1';          -- signal completion (one cycle)
            complete   <= '1';          -- debug flag
            p_state    <= IDLE;
            ip_init    <= '0';
            ether_init <= '0';
            udp_init   <= '0';
          end if;

        when others =>
          done    <= '0';
          p_state <= IDLE;

      end case;
    end if;
  end process;

end Behavioral;
