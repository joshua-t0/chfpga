----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:21:53 05/27/2011 
-- Design Name: 
-- Module Name:    SPI_DEVICE - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SPI_SLAVE is
	 generic (
		ADDRESS: integer :=4;
		BYTES: integer :=2;
		READ_VALUE: STD_LOGIC_VECTOR :=X"0000"
		);
    port ( 
		--SPI signals
		
		SPI_SCK: in STD_LOGIC;
		SPI_MISO: out STD_LOGIC;
		SPI_MOSI: in STD_LOGIC;
		SPI_ADDR: in STD_LOGIC_VECTOR(2 downto 0);
		SPI_RST_N: in STD_LOGIC;
		
		-- System-level signals
		
		RST: in STD_LOGIC
	);

end SPI_SLAVE;

architecture Behavioral of SPI_SLAVE is

signal CS: STD_LOGIC:='1';
signal REG: STD_LOGIC_VECTOR(15 downto 0);
signal CTR: UNSIGNED(5 downto 0);

begin

CS<='1' when UNSIGNED(SPI_ADDR)=ADDRESS else '0';
SPI_MISO<='Z' when CS='0' else REG(REG'Length-1);

spi: process(all)
	begin
		if (RST='1' or CS='0') then
			REG<=READ_VALUE;
			CTR<=TO_UNSIGNED(8*BYTES,CTR'Length);
		elsif SPI_SCK'Event and SPI_SCK='0' then -- update bus on falling edges on SCK
			REG<= STD_LOGIC_VECTOR(UNSIGNED(REG) ROL 1);
		end if; --RST and CLK
	end process;
	

end Behavioral;

