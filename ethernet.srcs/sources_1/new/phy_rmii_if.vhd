library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity phy_rmii_if is
  port (
    -- RMII PHY interface
    phy_rxd         : in  std_logic_vector(1 downto 0); -- 2-bit RX data from PHY (RMII)
    phy_crs_dv      : in  std_logic;                    -- Carrier Sense/Data Valid
    phy_tx_en       : out std_logic;                    -- TX enable to PHY
    phy_txd         : out std_logic_vector(1 downto 0); -- 2-bit TX data to PHY (RMII)
    phy_ref_clk     : in  std_logic;                    -- 50MHz RMII reference clock

    -- MDIO management interface
    phy_mdio        : inout std_logic;                  -- MDIO data (not driven in this block)
    phy_mdc         : out std_logic;                    -- MDC clock

    -- TX side (headers/payload feeding)
    tx_fifo_empty   : in  std_logic;                    -- payload FIFO empty indicator
    mac_tx_byte     : in  std_logic_vector(7 downto 0); -- payload byte from MAC FIFO
    header_byte     : in  std_logic_vector(7 downto 0); -- byte from header FIFO
    header_rd_en    : out std_logic;                    -- read enable for header FIFO
    header_fifo_empty : in std_logic;                   -- header FIFO empty
    mac_rd_en       : out std_logic;                    -- read enable for payload FIFO
    fifo_wr_en      : out std_logic;                    -- write enable to capture RX payload
    fifo_full       : in  std_logic;                    -- capture FIFO full (not used here)
    fifo_din        : out std_logic_vector(7 downto 0); -- captured RX byte to FIFO
    start_frame_tx  : in  std_logic;                    -- request to start TX frame
    crc_gen_en      : out std_logic;                    -- CRC generator enable (byte qualifies)
    init_tx         : out std_logic;                    -- pulse at end of TX (frame done)

    -- CRC/helper/status
    crc_data_valid  : out std_logic;                    -- indicates RX byte valid for CRC
    frame_ready     : out std_logic;                    -- RX frame complete
    crc_ok          : out std_logic;                    -- RX CRC matches expected (simple check)
    init            : out std_logic;                    -- pulse to reinit downstream (derived)
    crc_gen_data    : out std_logic_vector(7 downto 0); -- TX byte presented to CRC generator
    crc_data_in     : out std_logic_vector(7 downto 0); -- RX byte presented to CRC checker
    led_out         : out std_logic_vector(12 downto 0);-- debug LEDs
    led_s           : out std_logic_vector(1 downto 0); -- spare LEDs (unused, left un-driven)
    crc_tx          : in  std_logic_vector(31 downto 0);-- TX CRC (LSB-first nibbles)
    computed_crc32  : in  std_logic_vector(31 downto 0);-- RX computed CRC (external checker)

    -- Resets and system clock
    reset_b         : in  std_logic;                    -- active-low reset (RMII domain)
    reset_n         : in  std_logic;                    -- active-low reset (sys clock domain)
    sys_clk         : in  std_logic                     -- system clock for MDC generation
  );
end entity;

architecture Behavioral of phy_rmii_if is

  -- Converts 2-bit RMII stream to byte with valid strobe on each assembled byte
  component shift2to8 is
    Port (
      clk        : in  std_logic;
      rst_n      : in  std_logic;
      in_valid   : in  std_logic;
      init       : in  std_logic;
      in_2b      : in  std_logic_vector(1 downto 0);
      out_valid  : out std_logic;
      out_8b     : out std_logic_vector(7 downto 0)
    );
  end component;

  -- Single-bit synchronizer
  component synchronizer is
    port (
      i_clk   : in  std_logic;
      i_rst_n : in  std_logic;
      i_data  : in  std_logic;
      o_data  : out std_logic
    );
  end component;

  -- RX byte assembly / status
  signal byte_ready       : std_logic := '0';                 -- asserted when assembled_byte is valid
  signal assembled_byte   : std_logic_vector(7 downto 0) := (others => '0');


  type t_last4_array is array(3 downto 0) of std_logic_vector(7 downto 0);
  signal last4_bytes    : t_last4_array := (others => (others => '0'));

  -- Edge/flag helpers
  signal dv_d             : std_logic := '0';                 -- delayed phy_crs_dv
  signal dv_dd            : std_logic := '0';                 -- twice delayed phy_crs_dv
  signal saw_55_pulse     : std_logic := '0';                 -- 1-cycle pulse when assembled_byte=0x55
  signal init_sig         : std_logic := '0';                 -- internal init pulse mirrored to 'init'
  signal start_frame_sync : std_logic := '0';                 -- start_frame_tx synchronized to phy_ref_clk

  -- TX datapath/temp storage
  signal head_buffer      : std_logic_vector(7 downto 0) := (others => '0'); -- holds current header byte for nibble-wise TX
  signal byte_buffer      : std_logic_vector(7 downto 0) := (others => '0'); -- holds current payload byte for nibble-wise TX

  -- Counters
  signal count            : integer range 0 to 40  := 0;     -- MDC divider in sys_clk domain
  signal inter_count      : integer range 0 to 5   := 0;     -- inter-frame idles (RMII nibbles)
  signal nibble_cnt       : integer range 0 to 15  := 0;     -- nibble position within byte/CRC
  signal preamble_cnt     : integer range 0 to 7   := 0;     -- RX preamble byte counter
  signal preamble_cnt_1   : integer range 0 to 31  := 0;     -- TX preamble SFD nibble counter
  signal ifr_count        : integer range 1 to 50  := 1;     -- inter-frame recovery counter
  signal byte_count       : integer range 0 to 2047 := 0;    -- RX byte counter within frame
  signal data_count       : integer := 0;                     -- TX payload byte count (debug/bookkeeping)

  -- Status/flags
  signal phy_tx_en_s      : std_logic;                        -- local (optional) staging
  signal complete         : std_logic := '0';                 -- indicates end of TX (debug)
  signal crc_gen_en_s     : std_logic;                        -- local staging for CRC enable (optional)

  -- LED/debug
  signal led              : std_logic_vector(12 downto 0) := (others => '0');

  -- FSMs
  type state is (IDLE, INTER, PREAMBLE_SFD, HEADER, DATA, CRC, IFR);
  signal p_state_1 : state := IDLE;                           -- TX state machine

  type state_type is (IDLE, PREAMBLE, WAIT_SFD, RECEIVE, CAPTURE_CRC);
  signal p_state   : state_type := IDLE;                      -- RX state machine

  ATTRIBUTE MARK_DEBUG : STRING;
  ATTRIBUTE MARK_DEBUG OF assembled_byte : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF p_state        : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF byte_ready     : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF p_state_1      : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF nibble_cnt     : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF preamble_cnt_1 : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF byte_buffer    : SIGNAL IS "true";
  ATTRIBUTE MARK_DEBUG OF head_buffer    : SIGNAL IS "true";

begin
  -- Expose debug LEDs and init pulse
  led_out <= led;
  init    <= init_sig;

  -- Assemble RMII 2-bit stream to bytes
  shift2b: shift2to8
    Port map(
      clk       => phy_ref_clk,
      rst_n     => reset_b,
      in_valid  => phy_crs_dv,
      init      => init_sig,
      in_2b     => phy_rxd,
      out_valid => byte_ready,
      out_8b    => assembled_byte
    );

  -- Synchronize start_frame_tx into RMII clock domain
  start_sync: synchronizer
    port map(
      i_clk   => phy_ref_clk,
      i_rst_n => reset_b,
      i_data  => start_frame_tx,
      o_data  => start_frame_sync
    );

  -----------------------------------------------------------------------------
  -- MDC generation in sys_clk domain (simple divider)
  -----------------------------------------------------------------------------
  process(sys_clk, reset_n)
  begin
    if (reset_n = '0') then
      count  <= 0;
      phy_mdc <= '0';
    elsif rising_edge(sys_clk) then
      count <= count + 1;
      if (count = 40) then
        phy_mdc <= '1';
        count   <= 0;
      else
        phy_mdc <= '0';
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- TX state machine (RMII domain): emits preamble+SFD, header bytes, payload,
  -- and CRC nibble-wise over phy_txd.
  -----------------------------------------------------------------------------
  process(phy_ref_clk, reset_b)
  begin
    if reset_b = '0' then
      p_state_1      <= IDLE;
      preamble_cnt_1 <= 0;
      phy_tx_en      <= '0';
      phy_txd        <= "00";
      mac_rd_en      <= '0';
      header_rd_en   <= '0';
      nibble_cnt     <= 0;
      crc_gen_en     <= '0';
      init_tx        <= '0';
      inter_count    <= 0;
      ifr_count      <= 1;
    elsif rising_edge(phy_ref_clk) then
      case p_state_1 is
        when IDLE =>
          phy_tx_en      <= '0';
          preamble_cnt_1 <= 0;
          phy_txd        <= "00";
          mac_rd_en      <= '0';
          header_rd_en   <= '0';
          inter_count    <= 0;
          nibble_cnt     <= 0;
          ifr_count      <= 1;
          crc_gen_en     <= '0';
          init_tx        <= '0';
          if start_frame_tx = '1' then
            p_state_1 <= PREAMBLE_SFD;
          end if;

        when INTER =>
          phy_tx_en      <= '1';
          preamble_cnt_1 <= 0;
          phy_txd        <= "00";
          mac_rd_en      <= '0';
          header_rd_en   <= '0';
          nibble_cnt     <= 0;
          crc_gen_en     <= '0';
          init_tx        <= '0';
          inter_count    <= inter_count + 1;
          if inter_count = 5 then
            p_state_1 <= PREAMBLE_SFD;
          end if;

        when PREAMBLE_SFD =>
          -- Emit 7 bytes of 0x55 (RMII pattern "01" per nibble), then SFD 0xD5 ("11" for last nibble pair)
          phy_tx_en    <= '1';
          mac_rd_en    <= '0';
          header_rd_en <= '0';
          crc_gen_en   <= '0';
          if preamble_cnt_1 < 32 then
            phy_txd        <= "01";                        -- preamble nibble
            preamble_cnt_1 <= preamble_cnt_1 + 1;
            if preamble_cnt_1 = 28 then
              header_rd_en <= '1';                         -- prefetch first header byte
            elsif preamble_cnt_1 = 30 then
              head_buffer  <= header_byte;
              crc_gen_en   <= '1';                         -- start CRC with first header byte
              crc_gen_data <= header_byte;
            elsif preamble_cnt_1 = 31 then
              phy_txd   <= "11";                           -- SFD trailing nibble
              p_state_1 <= HEADER;
            end if;
          end if;

        when HEADER =>
          -- Nibble-wise transmit header bytes; fill next header/payload bytes in parallel
          crc_gen_en   <= '0';
          mac_rd_en    <= '0';
          header_rd_en <= '0';
          phy_tx_en    <= '1';
          if header_fifo_empty = '1' then
            -- Header FIFO empty: switch to payload after first header byte nibbles
            phy_txd    <= head_buffer((2*nibble_cnt)+1 downto 2*nibble_cnt);
            nibble_cnt <= nibble_cnt + 1;
            if nibble_cnt = 0 then
              mac_rd_en <= '1';                            -- request first payload byte
            elsif nibble_cnt = 2 then
              byte_buffer  <= mac_tx_byte;                 -- latch payload byte
              crc_gen_en   <= '1';
              crc_gen_data <= mac_tx_byte;                 -- include in CRC
              data_count   <= data_count + 1;
            elsif nibble_cnt = 3 then
              p_state_1  <= DATA;
              crc_gen_en <= '0';
              nibble_cnt <= 0;
            end if;
          else
            -- Still have header bytes to send
            phy_txd    <= head_buffer((2*nibble_cnt)+1 downto 2*nibble_cnt);
            nibble_cnt <= nibble_cnt + 1;
            if nibble_cnt = 1 then
              header_rd_en <= '1';                         -- fetch next header byte
            elsif nibble_cnt = 3 then
              head_buffer  <= header_byte;                 -- stage next header byte
              crc_gen_en   <= '1';
              crc_gen_data <= header_byte;                 -- include header in CRC
              nibble_cnt   <= 0;
            end if;
          end if;

        when DATA =>
          -- Nibble-wise transmit payload; pull new byte every 4 nibbles
          crc_gen_en   <= '0';
          mac_rd_en    <= '0';
          header_rd_en <= '0';
          phy_tx_en    <= '1';
          if tx_fifo_empty = '1' then
            -- Payload exhausted, flush last staged byte and move to CRC
            phy_txd    <= byte_buffer((2*nibble_cnt)+1 downto 2*nibble_cnt);
            nibble_cnt <= nibble_cnt + 1;
            if nibble_cnt = 3 then
              p_state_1  <= CRC;
              data_count <= 0;
              crc_gen_en <= '0';
              nibble_cnt <= 0;
            end if;
          else
            -- Continue streaming payload
            phy_txd    <= byte_buffer((2*nibble_cnt)+1 downto 2*nibble_cnt);
            nibble_cnt <= nibble_cnt + 1;
            if nibble_cnt = 1 then
              mac_rd_en <= '1';                            -- request next payload byte
            elsif nibble_cnt = 3 then
              byte_buffer  <= mac_tx_byte;                 -- stage next byte
              data_count   <= data_count + 1;
              crc_gen_en   <= '1';
              crc_gen_data <= mac_tx_byte;                 -- include in CRC
              nibble_cnt   <= 0;
            end if;
          end if;

        when CRC =>
          -- Transmit CRC32 nibbles (assumed LSB-first nibble order)
          phy_tx_en <= '1';
          if nibble_cnt < 16 then
            phy_txd    <= crc_tx((2*nibble_cnt)+1 downto 2*nibble_cnt);
            nibble_cnt <= nibble_cnt + 1;
            if nibble_cnt = 15 then
              nibble_cnt <= 0;
              init_tx    <= '1';                           -- pulse to indicate TX complete
              complete   <= '1';
              p_state_1  <= IFR;
            end if;
          end if;

        when IFR =>
          -- Inter-frame recovery: deassert TX for required idle nibbles
          phy_tx_en  <= '0';
          init_tx    <= '0';
          complete   <= '0';
          ifr_count  <= ifr_count + 1;
          if ifr_count > 49 then
            p_state_1 <= IDLE;
          end if;

        when others =>
          p_state_1 <= IDLE;
      end case;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- RX state machine (RMII domain): detect preamble/SFD, receive bytes, and
  -- provide last 4 bytes and CRC check indication.
  -----------------------------------------------------------------------------
  process(phy_ref_clk, reset_b)
  begin
    if reset_b = '0' then
      p_state       <= IDLE;
      preamble_cnt  <= 0;
      last4_bytes   <= (others => (others => '0'));
      frame_ready   <= '0';
      crc_ok        <= '0';
      byte_count    <= 0;
      init_sig      <= '0';
      led           <= (others => '0');
    elsif rising_edge(phy_ref_clk) then
      -- Detect single 0x55 byte pulse for debug LED
      if byte_ready = '1' and assembled_byte = x"55" then
        saw_55_pulse <= '1';
      else
        saw_55_pulse <= '0';
      end if;

      case p_state is
        when IDLE =>
          frame_ready <= '0';
          if byte_ready = '1' and assembled_byte = x"55" then
            preamble_cnt <= 1;
            p_state      <= PREAMBLE;
          else
            preamble_cnt <= 0;
            p_state      <= IDLE;
          end if;
          init_sig    <= '0';
          led(4)      <= '1';
          byte_count  <= 0;

        when PREAMBLE =>
          if byte_ready = '1' then
            if assembled_byte = x"55" then
              led(12 downto 5) <= assembled_byte;
              preamble_cnt     <= preamble_cnt + 1;
              p_state          <= PREAMBLE;

            elsif (preamble_cnt >= 7) and (assembled_byte = x"55") then
              preamble_cnt <= preamble_cnt + 1;
              p_state      <= PREAMBLE;

            elsif (preamble_cnt >= 7) and (assembled_byte = x"D5") then
              p_state      <= RECEIVE;
              preamble_cnt <= 0;
              led(12 downto 5) <= assembled_byte;

            else
              preamble_cnt <= 0;
              p_state      <= IDLE;
            end if;
          end if;
          led(3) <= '1';

        when RECEIVE =>
          if byte_ready = '1' then
            -- Shift window of last 4 received bytes (for CRC extraction)
            last4_bytes(3) <= last4_bytes(2);
            last4_bytes(2) <= last4_bytes(1);
            last4_bytes(1) <= last4_bytes(0);
            last4_bytes(0) <= assembled_byte;

            byte_count <= byte_count + 1;

            -- Detect end of frame on CRS_DV falling edge
            if phy_crs_dv = '0' and dv_d = '1' then
              p_state <= CAPTURE_CRC;
            else
              p_state <= RECEIVE;
            end if;
          end if;
          led(2) <= '1';

        when CAPTURE_CRC =>
          -- Simple CRC check against provided computed_crc32
          if computed_crc32 = x"C704DD7B" then
            crc_ok <= '1';
          else
            crc_ok <= '0';
          end if;
          frame_ready <= '1';
          p_state     <= IDLE;
          init_sig    <= '1';
          led(1)      <= '1';

        when others =>
          p_state <= IDLE;
      end case;
    end if;
  end process;

  -- Delay line for CRS_DV to detect falling edge
  process(phy_ref_clk, reset_b)
  begin
    if reset_b = '0' then
      dv_d  <= '0';
      dv_dd <= '0';
    elsif rising_edge(phy_ref_clk) then
      dv_d  <= phy_crs_dv;
      dv_dd <= dv_d;
    end if;
  end process;

  -- RX capture interface and CRC checker inputs
  fifo_din        <= last4_bytes(3);                                          -- oldest of the last 4 bytes
  crc_data_in     <= assembled_byte;                                          -- feed CRC checker
  fifo_wr_en      <= '1' when p_state = RECEIVE and byte_ready = '1' and byte_count >= 4 else '0';
  crc_data_valid  <= '1' when p_state = RECEIVE and byte_ready = '1' else '0';

  -- Debug LED: pulse when 0x55 seen
  led(0) <= saw_55_pulse;

  -- Unused outputs left at default (avoid latches)
  led_s <= (others => '0');

end Behavioral;
