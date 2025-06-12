
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package crc_pkg is
    constant reflected_poly : std_logic_vector(31 downto 0):= x"EDB88320";
    function crc32_byte(
        rem_pre : std_logic_vector(31 downto 0);
        data_in : std_logic_vector(7 downto 0)
    )return std_logic_vector;
end package;

package body crc_pkg is

    function crc32_byte(
        rem_pre : std_logic_vector(31 downto 0);
        data_in : std_logic_vector(7 downto 0)
    )return std_logic_vector is
        variable rem_1    : std_logic_vector(31 downto 0) := rem_pre;
        variable dbits  : std_logic_vector(7 downto 0) := data_in;
        variable bit_in : std_logic;
    begin
        for i in 0 to 7 loop
            bit_in := dbits(i) xor rem_1(0);
            rem_1 := rem_1(31 downto 1) & bit_in;
            if bit_in = '1' then
                rem_1 := rem_1 xor reflected_poly;
            end if;
        end loop;
        return rem_1;
    end function;
end package body;
