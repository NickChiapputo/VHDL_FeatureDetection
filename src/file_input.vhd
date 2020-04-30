library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real."ceil";
use ieee.math_real."log2";
use work.kernel_pkg.all;

entity file_input is
	generic(	filename_in		: string := "C:\Users\Nikolai\Desktop\School\EENG 4760\canny\canny.sim\sim_1\behav\xsim\src\a.ppm";				-- Input file name
				file_width		: integer range 1 to 5000 := 10;	-- Image width
				file_height 	: integer range 1 to 5000 := 10 );	-- Image height
				
	port (		clk			: in  std_logic;						-- Clock Signal
				enable		: in  boolean;							-- Enable signal from top level
				data_in		: out std_logic_vector( 23 downto 0 );	-- Input RGB bytes from file
				done		: out boolean;							-- Control signal showing that file read is done
				data_out	: out std_logic_vector( 23 downto 0 );	-- Three byte long pixel data from file
				gray_image	: out gray_image( 0 to file_height - 1, 0 to file_width - 1 ) := ( others => ( others => "01010101" ) ) );	-- Grayscale image data
end file_input;

architecture Behavioral of file_input is
begin
	process( clk, enable )
		-- Define variables used to to help with I/O
		variable char_in		: character;				-- First part of current marker
		type f is file of character;						-- Create file variable type that stores characters
		
		-- Input file
		variable status			: FILE_OPEN_STATUS;			-- Status of file open. Used to check that file was successfully opened
		variable openfile		: boolean;  				-- If file is open. FALSE by default
		file ffile				: f;						-- Input file object of characters
		
		-- Output File
		variable char_val_out 	: character;				-- Byte to be written out to file.
		file ffile_gray			: f;						-- Output file object of characters (for grayscale image)
		
		-- Used to index the matrix to store data in ram
		variable row_index		: integer range 0 to file_width - 1 				:= 0;
		variable col_index		: integer range 0 to file_height - 1 				:= 0;
		
		-- Used to hold the RGB values of the current pixel
		variable red_byte		: std_logic_vector( 7 downto 0 ) := x"00";
		variable green_byte		: std_logic_vector( 7 downto 0 ) := x"00";
		variable blue_byte		: std_logic_vector( 7 downto 0 ) := x"00";
		
		variable lf_count 		: integer range 0 to 3   := 0;	-- Keep track of number of LFs. After 3, data starts.
		variable red_int		: integer range 0 to 255 := 0;
		variable green_int		: integer range 0 to 255 := 0;
		variable blue_int 		: integer range 0 to 255 := 0;
	begin
		if rising_edge (clk) and enable then
			if not openfile then
				-- If file is not already open, then open it
				file_open( status, ffile, filename_in, READ_MODE );			-- Open input file for reading
				file_open( status, ffile_gray, "C:\Users\Nikolai\Desktop\School\EENG 4760\canny\canny.sim\sim_1\behav\xsim\src\out\gray.ppm", WRITE_MODE );	-- Open output file for writing grayed image
								
				-- Handle case where file was not able to open successfully
				if status /= OPEN_OK then
					report "FILE_OPEN_STATUS = " & 
						FILE_OPEN_STATUS'IMAGE(status)
					severity FAILURE;
					done <= true;
				end if;

				openfile := TRUE;
				data_in <= "ZZZZZZZZZZZZZZZZZZZZZZZZ";
				done <= false;
			else 
				-- If file is open
				if not endfile(ffile) then
					-- If there is still something left to read in, continue
					done <= false;
					
					read( ffile, char_in );
					
					-- While on the first three lines, copy over the header.
					if lf_count < 3 then
						-- If first three header lines haven't been read in, then parse each one
						if std_logic_vector( to_unsigned( character'pos( char_in ), 8 ) ) = x"0A" then
							lf_count := lf_count + 1;
						end if;
						
						-- Copy header over to grayscale image file.
						write( ffile_gray, char_in );
						
						data_in <= std_logic_vector( to_unsigned( character'pos( char_in ), 24 ) );
					else	-- Header is complete, read in RGB data
						-- Get red byte
						red_byte := std_logic_vector( to_unsigned( character'pos( char_in ), 8 ) );
                		
                		-- Get green byte
						read( ffile, char_in );
						green_byte := std_logic_vector( to_unsigned( character'pos( char_in ), 8 ) );
                		
                		-- Get blue byte
						read( ffile, char_in );
						blue_byte := std_logic_vector( to_unsigned( character'pos( char_in ), 8 ) );
						
						data_in <= red_byte & green_byte & blue_byte;

						-- Set equal values for each of RGB to create gray tone
--						red_int := ( to_integer( unsigned( red_byte ) ) + to_integer( unsigned( green_byte ) ) + to_integer( unsigned( blue_byte ) ) ) / 3;
--						green_int := red_int;
--						blue_int := green_int;

						-- Compute averaged grayscale for each color element
						red_int := to_integer( unsigned( red_byte ) ) * 299 / 1000 + to_integer( unsigned( green_byte ) ) * 587 / 1000 + to_integer( unsigned( blue_byte ) ) * 114 / 1000;
						green_int := red_int;
						blue_int := green_int;

						-- No change to RGB
--						red_int := to_integer( unsigned( red_byte ) );
--						green_int := to_integer( unsigned( green_byte ) );
--						blue_int := to_integer( unsigned( blue_byte ) );

						-- Invert number from 255 for each of RGB to create inverted image
--						red_int := 255 - to_integer( unsigned( red_byte ) );
--						green_int := 255 - to_integer( unsigned( green_byte ) );
--						blue_int := 255 - to_integer( unsigned( blue_byte ) );

						write( ffile_gray, character'val( red_int ) ); 	-- Write first byte
						write( ffile_gray, character'val( green_int ) ); -- Write first byte
						write( ffile_gray, character'val( blue_int ) ); 	-- Write first byte
						
						gray_image( row_index, col_index ) <= std_logic_vector( to_unsigned( red_int, 8 ) );
						
						data_out <= std_logic_vector( to_unsigned( red_int, 8 ) ) & 
									std_logic_vector( to_unsigned( green_int, 8 ) ) & 
									std_logic_vector( to_unsigned( blue_int, 8 ) );
									
						-- Increment number of pixels read
						col_index := ( col_index + 1 ) mod file_width;
						
						if( col_index = 0 ) then
							row_index := row_index + 1;
						end if;
					end if;
				end if;
				
				if endfile(ffile) then
					-- If all data has been read in from input file then mark done and terminate program
					done <= true;
					
					file_close( ffile );
					file_close( ffile_gray );
				end if;
			end if;
		end if;
		
		if not enable then
			data_in <= "ZZZZZZZZZZZZZZZZZZZZZZZZ";
			data_out <= "ZZZZZZZZZZZZZZZZZZZZZZZZ";
		end if;
	end process;
end Behavioral;
