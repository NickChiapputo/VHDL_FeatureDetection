library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package int_to_string_pkg is
	function toString( int : integer ) return string;
end package;

package body int_to_string_pkg is
	-- Convert an integer (absolute value of 1 to 99,999) to a string
	function toString( int : integer ) return string is
		variable a 		: integer range 0 to 99999 := 0;
		variable cmp	: integer range 0 to 99999 := 0;
		variable str 	: string( 5 downto 1 ) := "00000";
	begin
		a := int;
	
		for i in 1 to str'length loop
			-- Get least significant decimal value (0-9)
			cmp := a mod 10;
			report LF & "A:   " & integer'image( a ) & LF &
						"LSD: " & integer'image( cmp );
			
			-- Convert single digit decimal integer to character and add to string
			-- starting at leftmost index of string
			if cmp >= 0 and cmp <= 9 then
				str( i ) := character'val( cmp + 48 );
			else
				str( i ) := 'x';
			end if;
			
			-- Get rid of least significant digit
			a := a / 10;
		end loop;
		
		return str;
	end function;
end package body int_to_string_pkg;


-- These are created just so that the file shows up in the Source explorer in Vivado
entity int_to_string is
end int_to_string;
architecture structural of int_to_string is
begin
end structural;
