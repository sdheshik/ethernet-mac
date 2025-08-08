
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.udp_utils.all;  -- Expects calc_udp_checksum(...)

entity udp_header is
  Port (
    clk        : in  std_logic;                     -- clock
    rst_n      : in  std_logic;                     -- active-low reset
    init       : in  std_logic;                     -- start header emission
    pay_en     : in  std_logic;                     -- payload capture enable
    pay_data   : in  std_logic_vector(7 downto 0);  -- payload byte in
    fifo_full  : in  std_logic;                     -- backpressure input
    valid      : out std_logic;                     -- header byte valid strobe
    done       : out std_logic;                     -- pulse after last header byte
    byte_out   : out std_logic_vector(7 downto 0)   -- header byte out
  );
end udp_header;

architecture Behavioral of udp_header is

  -- Byte pair container for 16-bit fields (big-endian order)
  type byte_2_array is array(1 downto 0) of std_logic_vector(7 downto 0);

  -- Fixed UDP ports (Source/Destination) in network byte order
  signal source_port      : byte_2_array := (x"13", x"8D");  -- 0x138D
  signal destination_port : byte_2_array := (x"17", x"76");  -- 0x1776

  -- Checksum bytes and temporary 16-bit checksum value
  signal check       : byte_2_array := (x"00", x"00");
  signal check_temp  : std_logic_vector(15 downto 0);

  -- UDP length field (header+payload)
  signal len         : std_logic_vector(15 downto 0) := (others => '0');

  -- Header emission state machine
  type state is (IDLE, SO_PORT, DEST_PORT, LENGTH, CHECKSUM);
  signal p_state     : state := IDLE;

  -- Byte counters
  signal byte_count  : integer range 0 to 3 := 0;  -- counts 0..1 for 16-bit fields (2 bytes)
  signal pay_count   : integer := 0;               -- counts payload bytes captured

  -- Payload capture buffer (MSB-first packing)
  signal payload     : std_logic_vector(4095 downto 0) := (others => '0');

  -- Debug slice of payload (top 368 bytes = 2944 bits, indices 4095..1152)
  signal payload_fin : std_logic_vector(367 downto 0) := (others => '0');

  -- Payload length in bytes (constant; adjust as needed)
  signal pay_len     : integer := 52;

  -- Debug marking attributes (for synthesis tools that support MARK_DEBUG)
  attribute MARK_DEBUG : string;
  attribute MARK_DEBUG of payload_fin : signal is "true";
  attribute MARK_DEBUG of pay_count   : signal is "true";

begin

  ------------------------------------------------------------------------------
  -- Payload capture
  -- Captures pay_data on each cycle pay_en='1' and packs into payload MSB-first.
  -- pay_count increments per captured byte.
  ------------------------------------------------------------------------------
  process(clk, rst_n)
  begin
    if (rst_n = '0') then
      payload   <= (others => '0');
      pay_count <= 0;
    elsif rising_edge(clk) then
      if pay_en = '1' then
        pay_count <= pay_count + 1;
        -- Place newest byte at descending locations: [4095:4088], [4087:4080], ...
        payload(4095 - (pay_count*8) downto 4088 - (pay_count*8)) <= pay_data;
      end if;
    end if;
  end process;

  -- Expose upper slice for debug/ILA visibility
  payload_fin <= payload(4095 downto 3728);

  ------------------------------------------------------------------------------
  -- Header emission FSM
  -- Streams 8-byte UDP header while fifo_full='0'.
  -- Field order (each 16-bit, big-endian): Source Port, Dest Port, Length, Checksum.
  ------------------------------------------------------------------------------
  process(clk, rst_n)
  begin
    if (rst_n = '0') then
      valid      <= '0';
      byte_count <= 0;
      done       <= '0';
      byte_out   <= (others => '0');
      p_state    <= IDLE;
      len        <= (others => '0');
      check      <= (others => (others => '0'));
      check_temp <= (others => '0');
    elsif rising_edge(clk) then
      if fifo_full = '0' then
        case p_state is

          when IDLE =>
            -- Initialize interface outputs; wait for init to start
            valid      <= '0';
            done       <= '0';
            byte_out   <= (others => '0');
            byte_count <= 0;

            if init = '1' then
              p_state <= SO_PORT;
              -- UDP Length = payload bytes + header(8)
              len <= std_logic_vector(to_unsigned(pay_len + 8, 16));
            end if;

          when SO_PORT =>
            -- Emit Source Port high byte then low byte
            valid    <= '1';
            byte_out <= source_port(1 - byte_count);
            if byte_count = 1 then
              p_state    <= DEST_PORT;
              byte_count <= 0;
            else
              byte_count <= byte_count + 1;
            end if;

          when DEST_PORT =>
            -- Emit Destination Port high byte then low byte
            valid    <= '1';
            byte_out <= destination_port(1 - byte_count);

            -- Compute checksum once while outputting dest port
            -- Constants here represent IPs, UDP length, and header bytes.
            --       udp_data uses entire payload buffer; data_bytes=46 as example.
            check_temp <= calc_udp_checksum(
                            src_ip     => x"A9FEFCFF",
                            dst_ip     => x"FFFFFFFF",
                            udp_len    => x"0036",
                            udp_hdr    => x"138D177600360000",
                            udp_data   => payload(4095 downto 0),
                            data_bytes => 46
                          );

            if byte_count = 1 then
              p_state    <= LENGTH;
              byte_count <= 0;
            else
              byte_count <= byte_count + 1;
            end if;

          when LENGTH =>
            -- Emit Length high byte then low byte; latch checksum bytes
            valid    <= '1';
            byte_out <= len(15 - (byte_count*8) downto 8 - (byte_count*8));

            -- Latch computed checksum into byte array (big-endian)
            check(0) <= check_temp(15 downto 8);  -- high byte
            check(1) <= check_temp(7 downto 0);   -- low byte

            if byte_count = 1 then
              p_state    <= CHECKSUM;
              byte_count <= 0;
            else
              byte_count <= byte_count + 1;
            end if;

          when CHECKSUM =>
            -- Emit Checksum high byte then low byte
            valid    <= '1';
            byte_out <= check(1 - byte_count);
            if byte_count = 1 then
              done       <= '1';     -- pulse done after last byte
              p_state    <= IDLE;
            else
              byte_count <= byte_count + 1;
            end if;

          when others =>
            -- Safety fallback
            p_state <= IDLE;

        end case;
      else
        -- Backpressure active: hold interface inactive (no valid)
        valid    <= '0';
        done     <= '0';
        byte_out <= (others => '0');
      end if;
    end if;
  end process;

end Behavioral;
