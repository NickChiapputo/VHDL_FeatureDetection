library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real."ceil";
use ieee.math_real."log2";
use ieee.math_real."sqrt";
use work.kernel_pkg.all;				-- Defines kernel, GAUSSIAN_KERNEL_ROWS, and GAUSSIAN_KERNEL_COLS values
use work.int_to_string_pkg."toString";	-- Converts number to 5 character string

entity gaussian_blur is
	generic(	filename_out	: string := "C:\Users\Nikolai\Desktop\School\EENG 4760\canny\canny.sim\sim_1\behav\xsim\src\out\bc_out.ppm";	-- Output file name
				file_width		: integer range 1 to 5000 := 10;					-- Image width
				file_height 	: integer range 1 to 5000 := 10;					-- Image height
				kern			: gauss_kernel( 0 to GAUSSIAN_KERNEL_ROWS - 1 ) := getGaussianKernel( GAUSSIAN_KERNEL_ROWS ) );	-- Gaussian blur mask
	port(	clk			: in  std_logic;
			enable		: in  boolean;
			ram			: in  gray_image( 0 to file_height - 1, 0 to file_width - 1 ) := ( others => ( others => "01010101" ) ); 
			image_out	: out gray_image( 0 to file_height - 1, 0 to file_width - 1 ) := ( others => ( others => "01010101" ) );
			wr_data		: out std_logic_vector( 23 downto 0 );
			done		: out boolean
	);
end gaussian_blur;

architecture Behavioral of gaussian_blur is
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
		
		-- Used for gaussian kernel
		variable weight			: integer range 1 to 1000 	:= 1;	-- Summation of values in kernel
		variable result			: integer range 0 to 255 	:= 0;	-- Summation result of convolution
		
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
					
					result := 0;
					weight := 0;
					
					for i in ( (-1) * ( GAUSSIAN_KERNEL_ROWS / 2 ) ) to ( GAUSSIAN_KERNEL_ROWS / 2 ) loop			-- Go through each row of the kernel
						for j in ( (-1) * ( GAUSSIAN_KERNEL_COLS / 2 ) ) to ( GAUSSIAN_KERNEL_COLS / 2 ) loop		-- Go through each col of the kernel
							weight := weight + kern( ( i + ( GAUSSIAN_KERNEL_ROWS / 2 ) ) )( ( j + ( GAUSSIAN_KERNEL_COLS / 2 ) ) );
						
							if( ( row_index + i ) < 1 or ( col_index + j ) < 1 or ( row_index + i ) >= file_height - 1 or ( col_index + j ) >= file_width - 1 ) then 
								result := result + ( to_integer( unsigned( ram( row_index, col_index ) ) ) ) * kern( ( i + ( GAUSSIAN_KERNEL_ROWS / 2 ) ) )( ( j + ( GAUSSIAN_KERNEL_COLS / 2 ) ) );
							else 
								result := result + ( to_integer( unsigned( ram( ( row_index + i ), ( col_index + j ) ) ) ) ) * kern( ( i + ( GAUSSIAN_KERNEL_ROWS / 2 ) ) )( ( j + ( GAUSSIAN_KERNEL_COLS / 2 ) ) );
							end if;
						end loop;
					end loop;
					
					result := result / weight;

					-- Blur
					output_byte := std_logic_vector( to_unsigned( result, output_byte'length ) );
					
					-- Write data to file
					write( ffile_out, character'val( to_integer( unsigned( output_byte ) ) ) );
					write( ffile_out, character'val( to_integer( unsigned( output_byte ) ) ) );
					write( ffile_out, character'val( to_integer( unsigned( output_byte ) ) ) );
					image_out( row_index, col_index ) <= output_byte;
					wr_data <= output_byte & output_byte & output_byte;
					
					-- Increment number of pixels written
					col_index := ( col_index + 1 ) mod file_width;
					
					if( col_index = 0 ) then
						row_index := row_index + 1;
					end if;
				else
					file_close( ffile_out );
					done <= true;
				end if; 
			end if;
		end if;
	end process;
end Behavioral;
