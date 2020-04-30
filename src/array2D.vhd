library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package kernel_pkg is
	constant GAUSSIAN_KERNEL_ROWS : integer range 1 to 19 := 3;
	constant GAUSSIAN_KERNEL_COLS : integer range 1 to 19 := 3;
	
	constant SOBEL_KERNEL_ROWS : integer range 1 to 19 := 3;
	constant SOBEL_KERNEL_COLS : integer range 1 to 19 := 3;

	type rgb_image is array( natural range <>, natural range <> ) of std_logic_vector( 23 downto 0 );	-- Create data type matrix to store pixels RGB data (1 byte per color)
	type gray_image is array( natural range <>, natural range <> ) of std_logic_vector( 7 downto 0 );	-- Create data type matrix to store pixels grayscale data (1 byte per pixel)
	
	type sobel_kernel_row is array( natural range<> ) of integer range -50 to 50;
	type sobel_kernel is array( natural range<> ) of sobel_kernel_row( 0 to SOBEL_KERNEL_COLS - 1 );
	
	type gauss_kernel_row is array( natural range<> ) of integer range 0 to 5000;
	type gauss_kernel is array( natural range<> ) of gauss_kernel_row( 0 to GAUSSIAN_KERNEL_COLS - 1 );			-- Matrix for holding kernel formatted data

	-- Function to get gaussian kernel given the size input.
	-- This makes setting the kernel in the test bench much easier and cleaner.
	function getGaussianKernel( int : integer ) return gauss_kernel;
	
	-- Function to get Sobel Gx and Gy kernels given the size input.
	-- This makes setting the kernel in the test bench much easier and cleaner.
	function getSobelXKernel( int : integer ) return sobel_kernel;
	function getSobelYKernel( int : integer ) return sobel_kernel;
end package;

package body kernel_pkg is
	function getGaussianKernel( int : integer ) return gauss_kernel is
		variable kern : gauss_kernel( 0 to int - 1 );
	begin
		if( int = 9 ) then
			kern := (	(  4,  6,  8,  9, 10,  9, 8,   6,  4 ), 		-- 9x9 Kernel
						(  6,  9, 11, 13, 14, 13, 11,  9,  6 ), 
						(  8, 11, 15, 18, 19, 18, 15, 11,  8 ),
						(  9, 13, 18, 21, 22, 21, 18, 13,  9 ),
						( 10, 14, 19, 22, 23, 22, 19, 14, 10 ),
						(  9, 13, 18, 21, 22, 21, 18, 13,  9 ),
						(  8, 11, 15, 18, 19, 18, 15, 11,  8 ),
						(  6,  9, 11, 13, 14, 13, 11,  9,  6 ), 
						(  4,  6,  8,  9, 10,  9,  8,  6,  4 ) );
		elsif( int = 7 ) then
			kern := (	( 1, 1, 2, 2, 2, 1, 1 ), 		-- 7x7 Kernel
						( 1, 2, 2, 2, 2, 2, 1 ), 
						( 2, 2, 3, 3, 3, 2, 2 ),
						( 2, 2, 3, 3, 3, 2, 2 ),
						( 2, 2, 3, 3, 3, 2, 2 ),
						( 1, 2, 2, 2, 2, 2, 1 ),
						( 1, 1, 2, 2, 2, 1, 1 ) );
		elsif( int = 5 ) then
			kern := (	( 3, 4, 4, 4, 4 ), 		-- 5x5 Kernel
						( 4, 4, 5, 4, 4 ), 
						( 4, 5, 5, 5, 4 ),
						( 4, 4, 5, 4, 4 ),
						( 3, 4, 4, 4, 3 ) );
		else
			kern := (	( 1, 2, 1 ),-- 3x3 Kernel
						( 2, 4, 2 ),
						( 1, 2, 1 ) );
		end if;
		
		return kern;
	end function;
	
	function getSobelXKernel( int : integer ) return sobel_kernel is
		variable kern : sobel_kernel( 0 to int - 1 );
	begin
		kern := (	( -1,  0,  1 ),
					( -2,  0,  2 ),
					( -1,  0,  1 ) );
		return kern;
	end function;
	
	function getSobelYKernel( int : integer ) return sobel_kernel is
		variable kern : sobel_kernel( 0 to int - 1 );
	begin
		kern := (	(  1,  2,  1 ),
					(  0,  0,  0 ),
					( -1, -2, -1 ) );
		return kern;
	end function;
end package body kernel_pkg;

-- These are created just so that the file shows up in the Source explorer in Vivado
entity array2D is
end array2D;
architecture structural of array2D is
begin
end structural;
