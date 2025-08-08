library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package udp_utils is
  -- Calculate UDP checksum with pseudo-header
  function calc_udp_checksum(
    src_ip    : std_logic_vector(31 downto 0);   -- Source IP
    dst_ip    : std_logic_vector(31 downto 0);   -- Destination IP  
    udp_len   : std_logic_vector(15 downto 0);   -- UDP length
    udp_hdr   : std_logic_vector(63 downto 0);   -- UDP header (checksum field zeroed)
    udp_data  : std_logic_vector(4095 downto 0); -- UDP payload (max 512 bytes)
    data_bytes: integer                          -- Payload length in bytes
  ) return std_logic_vector;
end package udp_utils;

package body udp_utils is

  function calc_udp_checksum(
    src_ip    : std_logic_vector(31 downto 0);
    dst_ip    : std_logic_vector(31 downto 0);
    udp_len   : std_logic_vector(15 downto 0);
    udp_hdr   : std_logic_vector(63 downto 0);
    udp_data  : std_logic_vector(4095 downto 0);  -- FIXED: Matches declaration
    data_bytes: integer
  ) return std_logic_vector is
    variable sum    : unsigned(16 downto 0) := (others=>'0');
    variable w      : unsigned(15 downto 0);
    variable result : unsigned(15 downto 0);
    variable udp_hdr_temp : std_logic_vector(63 downto 0);
    variable total_words : integer;
    variable byte_idx : integer;
  begin
    -- Zero out UDP checksum field (bits 15 downto 0 of UDP header)
    udp_hdr_temp := udp_hdr;
    udp_hdr_temp(15 downto 0) := (others => '0');
    
    -- Add pseudo-header words
    -- Source IP (2 words)
    w := unsigned(src_ip(31 downto 16));
    sum := sum + ('0' & w);
    if sum(16) = '1' then
      sum := RESIZE(unsigned(sum(15 downto 0)) + 1, 17);
    end if;
    
    w := unsigned(src_ip(15 downto 0));
    sum := sum + ('0' & w);
    if sum(16) = '1' then
      sum := RESIZE(unsigned(sum(15 downto 0)) + 1, 17);
    end if;
    
    -- Destination IP (2 words)
    w := unsigned(dst_ip(31 downto 16));
    sum := sum + ('0' & w);
    if sum(16) = '1' then
      sum := RESIZE(unsigned(sum(15 downto 0)) + 1, 17);
    end if;
    
    w := unsigned(dst_ip(15 downto 0));
    sum := sum + ('0' & w);
    if sum(16) = '1' then
      sum := RESIZE(unsigned(sum(15 downto 0)) + 1, 17);
    end if;
    
    -- Protocol (17 = UDP) + UDP length
    w := x"0011";  -- Protocol 17 (UDP)
    sum := sum + ('0' & w);
    if sum(16) = '1' then
      sum := RESIZE(unsigned(sum(15 downto 0)) + 1, 17);
    end if;
    
    w := unsigned(udp_len);
    sum := sum + ('0' & w);
    if sum(16) = '1' then
      sum := RESIZE(unsigned(sum(15 downto 0)) + 1, 17);
    end if;
    
    -- Add UDP header (4 words, checksum already zeroed)
    for i in 0 to 3 loop
      w := unsigned(udp_hdr_temp(63 - 16*i downto 48 - 16*i));
      sum := sum + ('0' & w);
      if sum(16) = '1' then
        sum := RESIZE(unsigned(sum(15 downto 0)) + 1, 17);
      end if;
    end loop;
    
    -- FIXED: Process UDP data correctly
    total_words := (data_bytes + 1) / 2;  -- Round up for odd byte counts
    
    for i in 0 to total_words - 1 loop
      byte_idx := i * 2;
      w := (others => '0');  -- Initialize to zero
      
      if byte_idx < data_bytes then
        -- Get first byte (MSB of word)
        w(15 downto 8) := unsigned(udp_data(4095 - byte_idx*8 downto 4088 - byte_idx*8));
        
        if byte_idx + 1 < data_bytes then
          -- Get second byte (LSB of word)
          w(7 downto 0) := unsigned(udp_data(4087 - byte_idx*8 downto 4080 - byte_idx*8));
        else
          -- Odd number of bytes - pad with zero
          w(7 downto 0) := x"00";
        end if;
        
        sum := sum + ('0' & w);
        if sum(16) = '1' then
          sum := RESIZE(unsigned(sum(15 downto 0)) + 1, 17);
        end if;
      end if;
    end loop;
    
    -- Final end-around carry if any
    if sum(16) = '1' then
      sum := RESIZE(unsigned(sum(15 downto 0)) + 1, 17);
    end if;
    
    -- One's-complement
    result := not sum(15 downto 0);
    
    -- Special case: if result is 0x0000, return 0xFFFF
    if result = x"0000" then
      result := x"FFFF";
    end if;
    
    return std_logic_vector(result);
  end function;

end package body udp_utils;
