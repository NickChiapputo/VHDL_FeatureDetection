library ieee;
use ieee.std_logic_1164.all;
use work.kernel_pkg.all;

entity tb_edge is 
	generic(	
				filename_in			: string := "src/bc.ppm";
				gaussian_filename	: string := "src/out/gaussian.ppm";
				filename_out		: string := "src/out/out.ppm";
				file_width			: integer range 0 to 5000 := 640;
				file_height 		: integer range 0 to 5000 := 480;
				high_threshold		: integer range 0 to 255 := 25;
				low_threshold		: integer range 0 to 255 := 20;
				gaussian_kernel		: gauss_kernel( 0 to GAUSSIAN_KERNEL_ROWS - 1 ) := getGaussianKernel( GAUSSIAN_KERNEL_ROWS );
				sobel_kernel_x		: sobel_kernel( 0 to SOBEL_KERNEL_ROWS - 1 ) 	:= getSobelXKernel( SOBEL_KERNEL_ROWS );
				sobel_kernel_y		: sobel_kernel( 0 to SOBEL_KERNEL_ROWS - 1 ) 	:= getSobelXKernel( SOBEL_KERNEL_ROWS ) );
end tb_edge;

architecture behavior of tb_edge is
	signal clk			: std_logic := '0';
	signal data_in		: std_logic_vector( 23 downto 0 ) := x"000000";
	signal status		: string( 1 to 20 ) := "Not Started         ";
	signal input		: boolean;
	signal gaussian		: boolean;
	signal sobel_en		: boolean;
	signal done			: boolean;
	constant clk_period	: time := 10 ns;
	
	function tern( 	cond : boolean;  trueCase : string;  falseCase : string ) return string is
	begin
		if cond then
			return trueCase;
		else
			return falseCase;
		end if;
	end tern;
begin
	uut: entity work.edge( structural )
			generic map(	filename_in			=> filename_in,
							gaussian_filename	=> gaussian_filename,
							filename_out		=> filename_out,
							file_width			=> file_width,
							file_height			=> file_height,
							gaussian_kernel		=> gaussian_kernel,
							sobel_kernel_x		=> sobel_kernel_x,
							sobel_kernel_y		=> sobel_kernel_y,
							high_threshold		=> high_threshold,
							low_threshold		=> low_threshold )
			port map(	clk 		=> clk,
						input		=> input,
						gaussian	=> gaussian,
						sobel_en	=> sobel_en,
						data_in 	=> data_in,
						done_top 	=> done );
						
	clk_process:
		process
		begin
			if not done then
				clk <= '1';
				status <= 	tern( input, 	"File Input/Grayscale", 
							tern( gaussian, " Gaussian Blurring  ", 
							tern( sobel_en, "       Sobel        ", 
											"      Finished      " ) ) );
				wait for clk_period/2;
				clk <= '0';
				wait for clk_period/2;
			else
				status <= "      Finished      ";
				wait;
			end if;
		end process;
end architecture behavior;