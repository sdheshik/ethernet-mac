library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ethernet_header is
  Port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    init      : in  std_logic;
    fifo_full : in  std_logic;
    valid     : out std_logic;
    done      : out std_logic;
    byte_out  : out std_logic_vector(7 downto 0)
  );
end ethernet_header;

architecture Behavioral of ethernet_header is

  -- 6-byte arrays for MAC addresses (big-endian emit: [5]..[0])
  type byte_6_array is array(5 downto 0) of std_logic_vector(7 downto 0);
  signal destination_address : byte_6_array := (x"FF", x"FF", x"FF", x"FF", x"FF", x"FF"); -- broadcast
  signal source_address      : byte_6_array := (x"00", x"11", x"22", x"33", x"44", x"55");

  -- 2-byte array for EtherType (0x0800 = IPv4)
  type byte_2_array is array(1 downto 0) of std_logic_vector(7 downto 0);
  signal ether_type_ipv4 : byte_2_array := (x"08", x"00");

  -- Byte-streaming FSM
  type state is (IDLE, DESTINATION, SOURCE, ETHER_TYPE);
  signal p_state    : state := IDLE;

  -- Counts bytes within current field:
  -- - DESTINATION/SOURCE use 0..5
  -- - ETHER_TYPE uses 0..1 (upper bits of the range unused)
  signal byte_count : integer range 0 to 5 := 0;

begin

  -- Sequential byte emission with simple backpressure (fifo_full)
  process(clk, rst_n)
  begin
    if (rst_n = '0') then
      valid      <= '0';
      byte_count <= 0;
      done       <= '0';
      byte_out   <= (others => '0');
      p_state    <= IDLE;

    elsif rising_edge(clk) then
      if fifo_full = '0' then
        case p_state is

          when IDLE =>
            -- Wait for init, clear controls
            valid      <= '0';
            done       <= '0';
            byte_out   <= (others => '0');
            byte_count <= 0;
            if init = '1' then
              p_state <= DESTINATION;
            end if;

          when DESTINATION =>
            -- Emit Destination MAC: bytes [5]..[0]
            valid <= '0';
            if byte_count < 6 then
              byte_out   <= destination_address(5 - byte_count);
              valid      <= '1';
              byte_count <= byte_count + 1;
              if byte_count = 5 then
                byte_count <= 0;
                p_state    <= SOURCE;
              end if;
            end if;

          when SOURCE =>
            -- Emit Source MAC: bytes [5]..[0]
            valid <= '0';
            if byte_count < 6 then
              byte_out   <= source_address(5 - byte_count);
              valid      <= '1';
              byte_count <= byte_count + 1;
              if byte_count = 5 then
                byte_count <= 0;
                p_state    <= ETHER_TYPE;
              end if;
            end if;

          when ETHER_TYPE =>
            -- Emit EtherType: 0x0800 (IPv4), high byte then low byte
            valid <= '0';
            if byte_count < 2 then
              byte_out   <= ether_type_ipv4(1 - byte_count);
              valid      <= '1';
              byte_count <= byte_count + 1;
              if byte_count = 1 then
                byte_count <= 0;
                done       <= '1';   -- pulse end of Ethernet header
                p_state    <= IDLE;
              end if;
            end if;

          when others =>
            p_state <= IDLE;

        end case;
      else
        -- Backpressure active: hold interface inactive
        valid    <= '0';
        done     <= '0';
        byte_out <= (others => '0');
      end if;
    end if;
  end process;

end Behavioral;
