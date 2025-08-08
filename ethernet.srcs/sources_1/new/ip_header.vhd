
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.ip_utils.all;  -- calc_ip_checksum(full_header: std_logic_vector)

entity ip_header is
  Port (
    clk        : in  std_logic;                     -- clock
    rst_n      : in  std_logic;                     -- active-low reset
    init       : in  std_logic;                     -- start emission
    fifo_full  : in  std_logic;                     -- backpressure input
    valid      : out std_logic;                     -- header byte valid strobe
    done       : out std_logic;                     -- pulse after last header byte
    byte_out   : out std_logic_vector(7 downto 0)   -- header byte out
  );
end ip_header;

architecture Behavioral of ip_header is

  -- Payload length (bytes). Total Length = pay_len + 8(UDP) + 20(IP)
  signal pay_len : integer := 52;

  -- IPv4 Version/IHL (0x45 => Version=4, IHL=5), and DSCP/ECN
  signal ip_version : std_logic_vector(7 downto 0) := x"45";
  signal DSC        : std_logic_vector(7 downto 0) := x"00";

  -- Identification (increments each packet)
  signal frame_counter : std_logic_vector(15 downto 0) := x"0000";

  -- Helper arrays for 16-bit and 32-bit fields split into bytes
  type byte_2_array is array(1 downto 0) of std_logic_vector(7 downto 0);

  -- Flags/Fragment Offset (2 bytes): default 0x0000 (no fragmentation)
  signal df : byte_2_array := (x"00", x"00");

  -- Total Length (2 bytes)
  signal len : std_logic_vector(15 downto 0) := x"0000";

  -- TTL and Protocol (UDP=0x11)
  signal t_t_l       : std_logic_vector(7 downto 0) := x"40";
  signal ip_protocol : std_logic_vector(7 downto 0) := x"11";

  -- Header checksum (2 bytes)
  signal header_checksum : std_logic_vector(15 downto 0) := x"0000";

  -- Source/Destination IP addresses (4 bytes each, big-endian)
  type byte_4_array is array(3 downto 0) of std_logic_vector(7 downto 0);
  signal source_ip       : byte_4_array := (x"A9", x"FE", x"FC", x"FF");
  signal destination_ip  : byte_4_array := (x"FF", x"FF", x"FF", x"FF");

  -- Counts bytes within multi-byte fields and across address emission
  signal byte_count : integer range 0 to 19 := 0;

  -- Full 20-byte header image used for checksum calculation:
  -- Version/IHL, DSCP/ECN, Total Length, Identification, Flags/Frag, TTL,
  -- Protocol, Header Checksum(0 during calc), Source IP, Destination IP.
  signal full_header : std_logic_vector(159 downto 0) := (others => '0');

  -- FSM states for sequential emission
  type state is (
    IDLE, VERSION, DSCP, LENGTH, IDENTIFICATION, FLAGS, TTL,
    PROTOCOL, CHECKSUM, SO_IP, DEST_IP
  );
  signal p_state : state := IDLE;

begin

  ------------------------------------------------------------------------------
  -- IPv4 Header Emission FSM
  ------------------------------------------------------------------------------
  process(clk, rst_n)
  begin
    if (rst_n = '0') then
      valid         <= '0';
      byte_count    <= 0;
      done          <= '0';
      byte_out      <= (others => '0');
      p_state       <= IDLE;
      len           <= (others => '0');
      header_checksum <= (others => '0');
      full_header   <= (others => '0');
      -- frame_counter intentionally retained on reset as x"0000"
    elsif rising_edge(clk) then
      if fifo_full = '0' then
        case p_state is

          -- Idle until init, then precompute Total Length
          when IDLE =>
            valid      <= '0';
            done       <= '0';
            byte_out   <= (others => '0');
            byte_count <= 0;
            if init = '1' then
              -- Total Length = payload + UDP(8) + IP(20)
              len     <= std_logic_vector(to_unsigned(pay_len + 8 + 20, 16));
              p_state <= VERSION;
            end if;

          -- Emit Version/IHL and build full header image for checksum
          when VERSION =>
            valid       <= '1';
            -- Construct header with checksum field set to 0x0000 for calculation
            full_header <= ip_version & DSC & len & frame_counter &
                           df(1) & df(0) & t_t_l & ip_protocol & x"0000" &
                           source_ip(3) & source_ip(2) & source_ip(1) & source_ip(0) &
                           destination_ip(3) & destination_ip(2) & destination_ip(1) & destination_ip(0);
            byte_out    <= ip_version;
            p_state     <= DSCP;

          -- DSCP/ECN
          when DSCP =>
            valid    <= '1';
            byte_out <= DSC;
            p_state  <= LENGTH;

          -- Total Length (2 bytes, big-endian)
          when LENGTH =>
            valid      <= '1';
            byte_out   <= len(15 - (byte_count*8) downto 8 - (byte_count*8));
            byte_count <= byte_count + 1;
            if byte_count = 1 then
              p_state    <= IDENTIFICATION;
              byte_count <= 0;
            end if;

          -- Identification (2 bytes); increments once emitted
          when IDENTIFICATION =>
            valid      <= '1';
            byte_out   <= frame_counter(15 - (byte_count*8) downto 8 - (byte_count*8));
            byte_count <= byte_count + 1;
            if byte_count = 1 then
              p_state        <= FLAGS;
              frame_counter  <= std_logic_vector(unsigned(frame_counter) + 1);
              byte_count     <= 0;
            end if;

          -- Flags/Fragment Offset (2 bytes)
          when FLAGS =>
            valid      <= '1';
            byte_out   <= df(1 - byte_count);
            byte_count <= byte_count + 1;
            if byte_count = 1 then
              p_state    <= TTL;
              byte_count <= 0;
            end if;

          -- TTL (1 byte)
          when TTL =>
            valid    <= '1';
            byte_out <= t_t_l;
            p_state  <= PROTOCOL;

          -- Protocol (1 byte), then compute checksum over full_header
          when PROTOCOL =>
            valid            <= '1';
            byte_out         <= ip_protocol;
            header_checksum  <= calc_ip_checksum(full_header);
            p_state          <= CHECKSUM;

          -- Header Checksum (2 bytes, big-endian)
          when CHECKSUM =>
            valid      <= '1';
            byte_out   <= header_checksum(15 - (byte_count*8) downto 8 - (byte_count*8));
            byte_count <= byte_count + 1;
            if byte_count = 1 then
              p_state    <= SO_IP;
              byte_count <= 0;
            end if;

          -- Source IP (4 bytes, big-endian)
          when SO_IP =>
            valid      <= '1';
            byte_out   <= source_ip(3 - byte_count);
            byte_count <= byte_count + 1;
            if byte_count = 3 then
              p_state    <= DEST_IP;
              byte_count <= 0;
            end if;

          -- Destination IP (4 bytes, big-endian)
          when DEST_IP =>
            valid      <= '1';
            byte_out   <= destination_ip(3 - byte_count);
            byte_count <= byte_count + 1;
            if byte_count = 3 then
              done     <= '1';   -- pulse end of header
              p_state  <= IDLE;
            end if;

          when others =>
            p_state <= IDLE;

        end case;
      else
        -- Backpressure active: hold outputs inactive
        valid    <= '0';
        done     <= '0';
        byte_out <= (others => '0');
      end if;
    end if;
  end process;

end Behavioral;
