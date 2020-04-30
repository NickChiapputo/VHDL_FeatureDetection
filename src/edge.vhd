library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real."ceil";
use ieee.math_real."log2";
use ieee.math_real."sqrt";
use work.kernel_pkg.all;

entity edge is
	generic(	filename_in			: string := "C:\Users\Nikolai\Desktop\School\EENG 4760\canny\canny.sim\sim_1\behav\xsim\src\a.ppm";				-- Input file name
				gaussian_filename	: string :=	"C:\Users\Nikolai\Desktop\School\EENG 4760\canny\canny.sim\sim_1\behav\xsim\src\out\gaussian.ppm";	-- Gaussian blur output file name
				filename_out		: string := "C:\Users\Nikolai\Desktop\School\EENG 4760\canny\canny.sim\sim_1\behav\xsim\src\out\bc_out.ppm";	-- Output file name
				file_width			: integer range 1 to 5000 := 10;
				file_height 		: integer range 1 to 5000 := 10;
				gaussian_kernel		: gauss_kernel( 0 to GAUSSIAN_KERNEL_ROWS - 1 ) := getGaussianKernel( GAUSSIAN_KERNEL_ROWS );
				sobel_kernel_x		: sobel_kernel( 0 to SOBEL_KERNEL_ROWS - 1 ) := getSobelXKernel( SOBEL_KERNEL_ROWS );
				sobel_kernel_y		: sobel_kernel( 0 to SOBEL_KERNEL_ROWS - 1 ) := getSobelYKernel( SOBEL_KERNEL_ROWS );
				low_threshold		: integer range 0 to 255 := 0;
				high_threshold		: integer range 0 to 255 := 0 );
				
	port( 		clk				: in  std_logic;
				data_in			: out std_logic_vector( 23 downto 0 );
				input 			: out boolean;
				gaussian		: out boolean;
				sobel_en		: out boolean;
				done_top		: out boolean );
end edge;

architecture structural of edge is
	-- Initial file input signals
	signal input_read_data 	: std_logic_vector( 7 downto 0 );	-- Data read in from input file
	signal file_input_data 	: std_logic_vector( 23 downto 0 );	-- RGB (3 bytes) pixel data from input file
	signal pixel_row_addr 	: std_logic_vector( integer( ceil( log2( real( file_height ) ) ) ) downto 0 );	-- Address line for rows of RAM
	signal pixel_col_addr 	: std_logic_vector( integer( ceil( log2( real( file_width ) ) ) ) downto 0 );	-- Address line for columns of RAM
	
	-- Storage for color input image
	
	signal file_read_done	: boolean := false;
	signal file_read_enable	: boolean := true;
	
	-- Gaussian Blur signals
	signal gaussian_done	: boolean := false;
	signal gaussian_enable 	: boolean := false;
	signal gaussian_image	: gray_image( 0 to file_height - 1, 0 to file_width - 1 ) := ( others => ( others => "00000000" ) );
	
	-- Sobel signals
	signal sobel_enable		: boolean := false;
	signal sobel_done 		: boolean := false;
	
	-- RAM Storage For Pixel Data
	signal gray : gray_image( 0 to file_height - 1, 0 to file_width - 1 ) := ( others => ( others => "00000000" ) );
begin
	file_input : entity work.file_input( Behavioral )
		generic map( 	filename_in		=> filename_in,
						file_width		=> file_width,
						file_height		=> file_height )
		port map(	clk			=> clk,
					enable 		=> file_read_enable,
					data_in		=> data_in,
					done		=> file_read_done,
					data_out	=> file_input_data,
					gray_image	=> gray );
	
	file_read_enable <= not file_read_done;
	input <= file_read_enable;
	
	gaussian_enable <= file_read_done and not gaussian_done;
	
	gaussian_blur : entity work.gaussian_blur( Behavioral )
		generic map(	filename_out 	=> gaussian_filename,
						file_width		=> file_width,
						file_height		=> file_height,
						kern			=> gaussian_kernel )
		port map(	clk			=> clk,
					enable		=> file_read_done,
					ram			=> gray,
					image_out	=> gaussian_image,
					wr_data		=> data_in,
					done		=> gaussian_done );
	
	gaussian <= gaussian_enable;
	sobel_enable <= gaussian_done and not sobel_done;
					
	sobel : entity work.sobel( Behavioral )
		generic map( 	filename_out	=> filename_out,
						file_width		=> file_width,
						file_height		=> file_height,
						kernX			=> sobel_kernel_x,
						kernY			=> sobel_kernel_y,
						high_threshold	=> high_threshold,
						low_threshold	=> low_threshold )
		port map(	clk		=> clk,
					enable 	=> sobel_enable,
					ram		=> gaussian_image,
					wr_data	=> data_in,
					done	=> sobel_done );
	
	sobel_en <= sobel_enable;
	done_top <= sobel_done;
end structural;
