library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real."ceil";
use ieee.math_real."log2";
use ieee.math_real."sqrt";
use work.kernel_pkg.all;
use work.int_to_string_pkg."toString";

entity sobel is
	generic(	filename_out	: string := "src\out\bc_out.ppm";	-- Output file name
				file_width		: integer range 1 to 5000 := 10;				-- Image width
				file_height 	: integer range 1 to 5000 := 10;				-- Image height
				kernX			: sobel_kernel( 0 to SOBEL_KERNEL_ROWS - 1 ) := getSobelXKernel( SOBEL_KERNEL_ROWS );	-- Vertical Gradient Mask
				kernY			: sobel_kernel( 0 to SOBEL_KERNEL_ROWS - 1 ) := getSobelYKernel( SOBEL_KERNEL_ROWS ); 	-- Horizontal Gradient Mask
				high_threshold	: integer range 0 to 255 := 20;					-- Threshold for Sobel output
				low_threshold	: integer range 0 to 255 := 200 );
	port(	clk		: in  std_logic;
			enable	: in  boolean;
			ram		: in  gray_image( 0 to file_height - 1, 0 to file_width - 1 ) := ( others => ( others => "01010101" ) );	-- Grayscaled image input. Only one byte per pixel
			wr_data	: out std_logic_vector( 23 downto 0 );
			done	: out boolean );
end sobel;

architecture Behavioral of sobel is

begin
	process( clk, enable )
		-- Output File
		type f is file of character;						-- Create file variable type that stores characters
		file ffile_out 			: f;						-- Output file object of characters
		variable status			: FILE_OPEN_STATUS;			-- Status of file open. Used to check that file was successfully opened
		variable openfile		: boolean;  				-- If file is open. FALSE by default
		
		-- Used to store RGB byte data before being written
		variable output_byte 	: std_logic_vector( 7 downto 0 ) := x"00";
		
		-- Used to index the matrix of stored pixel data in ram
		variable row_index		: integer range 0 to file_width - 1 				:= 0;
		variable col_index		: integer range 0 to file_height - 1 				:= 0;
		
		-- Used for sobel kernel and gradient calculation
		variable norm			: integer range 1 to 1 := 1;
		variable resultX		: integer range -5000 to 5000 	:= 0;
		variable resultY 		: integer range -5000 to 5000 	:= 0;
		variable result			: integer range 0 to 255 		:= 0;	-- Summation result of convolution
		
		-- Used to store file width and height to add to header
		variable width_str		: string( 1 to 5 ) := toString( file_width );
		variable height_str		: string( 1 to 5 ) := toString( file_height );
	begin
		if rising_edge( clk ) and enable then
			if not openfile then
				-- If file is not already open, then open it
				file_open( status, ffile_out, filename_out, WRITE_MODE );	-- Open output file for writing

				-- Handle case where file was not able to open successfully
				if status /= OPEN_OK then
					report "FILE_OPEN_STATUS = " & 
						FILE_OPEN_STATUS'IMAGE(status)
					severity FAILURE;
					done <= true;
				end if;
				done <= false;
				
				-- Write the PPM header
				write( ffile_out, 'P' );					-- P
				write( ffile_out, '6' );					-- 6
				write( ffile_out, character'val( 10 ) );	-- newline
				
				-- Write width of image
				for i in width_str'range loop
					write( ffile_out, width_str( i ) );
				end loop;
				
				write( ffile_out, ' ' );					-- Space
				
				-- Write height of image
				for i in width_str'range loop
					write( ffile_out, height_str( i ) );
				end loop;
				
				write( ffile_out, character'val( 10 ) );	-- newline
				
				-- Set 255 as max value for each color byte
				write( ffile_out, '2' );					-- 2
				write( ffile_out, '5' );					-- 5
				write( ffile_out, '5' );					-- 5
				write( ffile_out, character'val( 10 ) );	-- newline

				openfile := TRUE;
				wr_data <= "ZZZZZZZZZZZZZZZZZZZZZZZZ";
			else
				if row_index < file_height then
					done <= false;
					
					-- Reset gradient calculations
					result := 0;
					resultX := 0;
					resultY := 0;
					
					-- Calculate vertical and horizontal gradients
					for i in ( (-1) * ( SOBEL_KERNEL_ROWS / 2 ) ) to ( SOBEL_KERNEL_ROWS / 2 ) loop			-- Go through each row of the kernel
						for j in ( (-1) * ( SOBEL_KERNEL_COLS / 2 ) ) to ( SOBEL_KERNEL_COLS / 2 ) loop		-- Go through each col of the kernel
							-- Check if row or column in source image is outside of bounds. If so, calculate based off of center pixel
							if( ( row_index + i ) < 1 or ( col_index + j ) < 1 or ( row_index + i ) >= file_height - 1 or ( col_index + j ) >= file_width - 1 ) then 
								resultX := resultX + ( to_integer( unsigned( ram( row_index, col_index ) ) ) ) * kernX( ( i + ( SOBEL_KERNEL_ROWS / 2 ) ) )( ( j + ( SOBEL_KERNEL_COLS / 2 ) ) );
								resultY := resultY + ( to_integer( unsigned( ram( row_index, col_index ) ) ) ) * kernY( ( i + ( SOBEL_KERNEL_ROWS / 2 ) ) )( ( j + ( SOBEL_KERNEL_COLS / 2 ) ) );
							else -- If row and column are within bounds, calculate normally.
								resultX := resultX + ( to_integer( unsigned( ram( ( row_index + i ), ( col_index + j ) ) ) ) ) * kernX( ( i + ( SOBEL_KERNEL_ROWS / 2 ) ) )( ( j + ( SOBEL_KERNEL_COLS / 2 ) ) );
								resultY := resultY + ( to_integer( unsigned( ram( ( row_index + i ), ( col_index + j ) ) ) ) ) * kernY( ( i + ( SOBEL_KERNEL_ROWS / 2 ) ) )( ( j + ( SOBEL_KERNEL_COLS / 2 ) ) );
							end if;
						end loop;
					end loop;
					
					-- Calculate the gradient magnitude
					result := 	integer( ceil( sqrt( Real( ( resultX ** 2 ) + ( resultY ** 2 ) ) ) ) ) / norm;
					
					-- If result is above the threshold, add it to the sobel image. Otherwise, set the pixel to black.
					if( result > high_threshold ) then output_byte := std_logic_vector( to_unsigned( result, output_byte'length ) );
					else output_byte := x"00"; end if;
					
					-- Sobel Normalized
--					if( resultX > high_threshold ) then
--						output_byte := std_logic_vector( to_unsigned( result, output_byte'length ) );
--					elsif( resultX < ( high_threshold * (-1) ) ) then
--						output_byte := x"00";
--					else
--						output_byte := x"80";
--					end if;
					
					-- Write data to file
					write( ffile_out, character'val( to_integer( unsigned( output_byte ) ) ) );
					write( ffile_out, character'val( to_integer( unsigned( output_byte ) ) ) );
					write( ffile_out, character'val( to_integer( unsigned( output_byte ) ) ) );
					wr_data <= output_byte & output_byte & output_byte;
					
					-- Increment number of pixels written
					col_index := ( col_index + 1 ) mod file_width;
					
					if( col_index = 0 ) then
						row_index := row_index + 1;
					end if;
				else
					-- Close output file and inform top level that we're done here.
					file_close( ffile_out );
					done <= true;
				end if; 
			end if;
		end if;
	end process;
end Behavioral;
