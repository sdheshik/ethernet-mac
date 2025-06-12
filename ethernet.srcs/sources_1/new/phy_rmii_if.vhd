
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity phy_rmii_if is
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
end entity;

architecture Behavioral of phy_rmii_if is


component shift2to8 is
 Port ( 
    clk            : in std_logic;
    rst_n          : in std_logic;
    in_valid       : in std_logic;
    init           : in  std_logic;
    in_2b          : in std_logic_vector(1 downto 0);
    out_valid      : out std_logic;
    out_8b         : out std_logic_vector(7 downto 0)
 );
end component;

component synchronizer is
  port (
    i_clk   : in  std_logic;  -- Destination domain clock
    i_rst_n : in  std_logic;  -- Active‐low synchronous reset
    i_data  : in  std_logic;  -- Asynchronous input signal
    o_data  : out std_logic   -- Synchronized output signal
  );
end component;


signal byte_hold          : std_logic:= '0';
signal last_crs_dv        : std_logic:= '0';
signal sfd_received       : std_logic:= '0';
signal byte_ready         : std_logic:= '0';
signal dv_d               : std_logic:= '0';
signal dv_dd              : std_logic:= '0';
signal saw_55_pulse       : std_logic:= '0';
signal init_sig           : std_logic:= '0';
signal start_frame_sync   : std_logic:= '0';
signal bit_count          : integer range 0 to 3:= 0;
signal nibble_cnt         : integer range 0 to 15:= 0;
signal preamble_cnt       : integer range 0 to 7:= 0;
signal preamble_cnt_1     : integer range 0 to 31:= 0;
signal count              : integer range 0 to 40:= 0;
signal byte_count         : integer range 0 to 2047 := 0;
signal assembled_byte     : std_logic_vector(7 downto 0):= (others => '0');
signal byte_buffer        : std_logic_vector(7 downto 0):= (others => '0');
signal byte_reg           : std_logic_vector(7 downto 0):= (others => '0');
signal led                : std_logic_vector(12 downto 0):= (others => '0');




type t_last4_array is array(3 downto 0) of std_logic_vector(7 downto 0);
signal last4_bytes    : t_last4_array := (others => (others => '0'));

type state is (IDLE, PREAMBLE_SFD, DATA, CRC);
signal p_state_1 : state := IDLE;           -- Present and next state


type state_type is (IDLE, PREAMBLE, WAIT_SFD, RECEIVE, CAPTURE_CRC);
signal p_state : state_type := IDLE;           -- Present and next state

ATTRIBUTE MARK_DEBUG : STRING;

ATTRIBUTE MARK_DEBUG OF assembled_byte : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF p_state : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF byte_ready : SIGNAL IS "true";

ATTRIBUTE MARK_DEBUG OF p_state_1 : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF nibble_cnt : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF preamble_cnt_1 : SIGNAL IS "true";
ATTRIBUTE MARK_DEBUG OF byte_buffer : SIGNAL IS "true";


begin

led_out <= led;

init <= init_sig;


shift2b: shift2to8
 Port map( 
    clk            => phy_ref_clk,
    rst_n          => reset_b,
    in_valid       => phy_crs_dv,
    init           => init_sig,
    in_2b          => phy_rxd,
    out_valid      => byte_ready,
    out_8b         => assembled_byte
 );

start_sync: synchronizer
  port map(
    i_clk   => phy_ref_clk,
    i_rst_n => reset_b,
    i_data  => start_frame_tx,
    o_data  => start_frame_sync
  );


process(sys_clk, reset_n)
  begin
    if (reset_n = '0') then
      count   <= 0;
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




 process(phy_ref_clk, reset_b)
  begin
    if reset_b = '0' then
      p_state_1     <= IDLE;
      preamble_cnt_1  <= 0;
      phy_tx_en <= '0';
      phy_txd <= "00";
      mac_rd_en <= '0';
      nibble_cnt <= 0;
      crc_gen_en <= '0';
      init_tx <= '0';
      

    elsif rising_edge(phy_ref_clk) then

      case p_state_1 is

          ------------------------------------------------------------
        when IDLE =>
          phy_tx_en <= '0';
          preamble_cnt_1 <= 0;
          phy_txd <= "00";
          mac_rd_en <= '0';
          nibble_cnt <= 0;
          crc_gen_en <= '0';
          init_tx <= '0';
          if start_frame_sync = '1' then
            phy_tx_en <= '1';
            p_state_1 <= PREAMBLE_SFD;
          end if;

          ------------------------------------------------------------
        when PREAMBLE_SFD =>
          phy_tx_en <= '1';
          mac_rd_en <= '0';
          crc_gen_en <= '0';
          if preamble_cnt_1 < 32 then 
            phy_txd <= "01";
            preamble_cnt_1 <= preamble_cnt_1 + 1;
            if preamble_cnt_1 = 28 then
              mac_rd_en <= '1';
            elsif preamble_cnt_1 = 30 then
              byte_buffer <= mac_tx_byte;
              crc_gen_en <= '1';
              crc_gen_data <= mac_tx_byte;
            elsif preamble_cnt_1 = 31 then
              phy_txd <= "11";
              p_state_1 <= DATA;
            end if;
          end if;  

          ------------------------------------------------------------
        when DATA =>
          crc_gen_en <= '0';
          mac_rd_en <= '0';
          phy_tx_en <= '1';
          if tx_fifo_empty = '1' then
            phy_txd <= byte_buffer((2*nibble_cnt)+1 downto 2*nibble_cnt);
            nibble_cnt <= nibble_cnt + 1;
            if nibble_cnt = 3 then
              p_state_1 <= CRC;
              crc_gen_en <= '0';
              nibble_cnt <= 0;
            end if;
          else 
            phy_txd <= byte_buffer((2*nibble_cnt)+1 downto 2*nibble_cnt);
            nibble_cnt <= nibble_cnt + 1;
            if nibble_cnt = 1 then
              mac_rd_en <= '1';
            elsif nibble_cnt = 3 then
              byte_buffer <= mac_tx_byte;
              crc_gen_en <= '1';
              crc_gen_data <= mac_tx_byte;
              nibble_cnt <= 0;
            end if;
          end if;
        
          ------------------------------------------------------------
        when CRC =>
          phy_tx_en <= '1';
          if nibble_cnt < 16 then
            phy_txd <= crc_tx((2*nibble_cnt)+1 downto 2*nibble_cnt);
            nibble_cnt <= nibble_cnt + 1;
            if nibble_cnt = 15 then
              nibble_cnt <= 0;
              init_tx <= '1';
              p_state_1 <= IDLE;
            end if;
          end if;  
          ------------------------------------------------------------
        when others =>
          p_state_1 <= IDLE;
      end case;
    end if;
  end process;



  process(phy_ref_clk, reset_b)
  begin
    if reset_b = '0' then
      p_state         <= IDLE;
      preamble_cnt  <= 0;
      last4_bytes   <= (others => (others => '0'));
      frame_ready   <= '0';
      crc_ok        <= '0';
      byte_count    <= 0;
      init_sig <= '0';
      led           <= (others => '0');

    elsif rising_edge(phy_ref_clk) then
      if byte_ready = '1' and assembled_byte = x"55" then
        saw_55_pulse <= '1';
      else
        saw_55_pulse <= '0';
      end if;

        case p_state is

          ------------------------------------------------------------
          when IDLE =>
            if byte_ready = '1' and assembled_byte = x"55" then
              preamble_cnt <= 1;

              p_state        <= PREAMBLE;
            else
              preamble_cnt <= 0;
              p_state        <= IDLE;
            end if;
            init_sig <= '0';
            led(4) <= '1';
            byte_count <= 0;

          ------------------------------------------------------------
          when PREAMBLE =>
            if byte_ready = '1' then
          
              if assembled_byte = x"55" then
                led(12 downto 5) <= assembled_byte;
                preamble_cnt <= preamble_cnt + 1;
                p_state        <= PREAMBLE;

              elsif (preamble_cnt >= 7) and (assembled_byte = x"55") then
                preamble_cnt <= preamble_cnt + 1;
                p_state        <= PREAMBLE;

              elsif (preamble_cnt >= 7) and (assembled_byte = x"D5") then
                p_state <= RECEIVE;
                preamble_cnt <= 0;
                led(12 downto 5) <= assembled_byte;
            
              else
                preamble_cnt <= 0;
                p_state        <= IDLE;
              end if;
            end if;
              led(3) <= '1';

          ------------------------------------------------------------
          when RECEIVE =>
            if byte_ready = '1' then
              last4_bytes(3) <= last4_bytes(2);
              last4_bytes(2) <= last4_bytes(1);
              last4_bytes(1) <= last4_bytes(0);
              last4_bytes(0) <= assembled_byte;

              byte_count <= byte_count + 1;

                if phy_crs_dv  = '0' and dv_d = '1' then
                  p_state        <= CAPTURE_CRC;
                else
                  p_state <= RECEIVE; 
                end if;   
            end if;
              led(2) <= '1';

          ------------------------------------------------------------
          when CAPTURE_CRC =>
            if computed_crc32 = x"C704DD7B" then
              crc_ok      <= '1';
            else
              crc_ok      <= '0';
            end if;
            frame_ready <= '1';  
            p_state       <= IDLE;
            init_sig <= '1';
            led(1) <= '1';

          ------------------------------------------------------------
          when others =>
            p_state <= IDLE;
        end case;
    end if;
  end process;

  -------------------------------------------------------------------------
  -- 6a) Edge-detect for rmii_dv falling (end‐of‐frame marker)
  -------------------------------------------------------------------------
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

fifo_din   <= last4_bytes(3);
crc_data_in   <= assembled_byte;
fifo_wr_en <= '1' when p_state = RECEIVE and byte_ready = '1' and byte_count >= 4 else '0';
crc_data_valid <= '1' when p_state = RECEIVE and byte_ready = '1' else '0';


led(0) <= saw_55_pulse;




end Behavioral;
