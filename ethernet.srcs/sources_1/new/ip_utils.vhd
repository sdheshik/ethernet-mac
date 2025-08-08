library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package ip_utils is
  -- IPv4 headers are exactly 160 bits (20 bytes)
  function calc_ip_checksum(
    hdr : std_logic_vector(159 downto 0)
  ) return std_logic_vector;
end package ip_utils;

package body ip_utils is

  function calc_ip_checksum(
    hdr : std_logic_vector(159 downto 0)
  ) return std_logic_vector is
    variable sum    : unsigned(16 downto 0) := (others=>'0');
    variable w      : unsigned(15 downto 0);
    variable result : unsigned(15 downto 0);
    variable hdr_temp : std_logic_vector(159 downto 0);
  begin
    -- Zero out the checksum field (bits 79 downto 64)
    hdr_temp := hdr;
    hdr_temp(79 downto 64) := (others => '0');
    
    -- Fold in each of the ten 16-bit words
    for i in 0 to 9 loop
      w   := unsigned(hdr_temp(159 - 16*i downto 144 - 16*i));
      sum := sum + ('0' & w);
      if sum(16) = '1' then
        sum := RESIZE(unsigned(sum(15 downto 0)) + 1, 17);
      end if;
    end loop;

    -- Final end-around carry if any
    if sum(16) = '1' then
      sum := RESIZE(unsigned(sum(15 downto 0)) + 1, 17);
    end if;

    -- One's-complement
    result := not sum(15 downto 0);
    return std_logic_vector(result);
  end function;

end package body ip_utils;
