-- -----------------------------------------------------------------------
--   WM8731 register definitions and bit field constants
-- -----------------------------------------------------------------------
--  Version  : 1.0
--  Date     : feb 2022
--  Author   : Ahmed Asim Ghouri 
--  Web      : https://pk.linkedin.com/in/ahmed-asim-ghouri-15553917
--  Contact  : asimghr@gmail.com
-- -----------------------------------------------------------------------
--  FUNCTION :
--     VHDL translation of constants, defined in WM8731 Datasheet
--     Record Types 
--     Subtypes 
-- -----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
package audio_codec_pkg is 
--------------------------
subtype SevenBit_t is std_logic_vector(6 downto 0);
subtype Ninebit_t  is std_logic_vector(8 downto 0);
subtype Byt_t   is std_logic_vector(7 downto 0);
subtype nibble  is std_logic_vector(3 downto 0);
subtype cmd_pkt is std_logic_vector(26 downto 0);
--=-=-=-=-=-COMMANDS-=-=-=-=-=------------------
-- writing to Slave Address for the WM8731 
-- "0011,010" = Slave Mode with CSB = '0'
-- Slave_address = Bits[23..16]
constant Slave_addr	       : Byt_t:= "00110100"; -- 0x34
-- Control register addresses = Bits[15..9]
constant Leftlinin_addr	   : SevenBit_t:= "0000000"; 
constant Rigtlinin_addr	   : SevenBit_t:= "0000001";
constant Lheadfon_out_addr : SevenBit_t:= "0000010";
constant Rheadfon_out_addr : SevenBit_t:= "0000011";
constant Analgaudio_addr   : SevenBit_t:= "0000100";
constant Digtlaudio_addr   : SevenBit_t:= "0000101";
constant PWR_addr          : SevenBit_t:= "0000110";
constant Digtlintf_addr    : SevenBit_t:= "0000111";
constant Samplng_addr      : SevenBit_t:= "0001000";
constant ActiveCtrl_addr   : SevenBit_t:= "0001001";
constant DeviceRest_addr   : SevenBit_t:= "0001111";
----------------------------------------------------------------------
-- Data values for all the above control registers 
-- Their bit values will be changed by user in future.
-- Register data = Bits[8..0]
-- Any gain at Line in or Line out creates clicking noise 
constant R_Llinin_dat	   : Ninebit_t:= "000010111"; -- +0db 
constant R_Lheadfon_out_dat: Ninebit_t:= "001111001"; -- +0db
constant Analgaudio_dat    : Ninebit_t:= "000010010"; -- Muting Mic 
constant Digtlaudio_dat    : Ninebit_t:= "000010001"; -- Disabling HPF , and stored DC offset
constant PWR_dat           : Ninebit_t:= "000000000";
constant Digtlintf_dat     : Ninebit_t:= "000000001";
constant Samplng_dat       : Ninebit_t:= "000000010";
constant ActiveCtrl_dat    : Ninebit_t:= "000000001";
constant Rst_dat           : Ninebit_t:= "000000000";
constant ACKsig               : std_logic := 'Z';
----------------------------------------------------
-- I2C commands 
-- Command format : --<< 1st Byte + ACKsig + 2nd Byte + ACKsig + 3rd Byte + ACKsig >>--
constant Leftline_cmd  : cmd_pkt := Slave_addr & ACKsig & Leftlinin_addr & R_Llinin_dat(8) & ACKsig & R_Llinin_dat(7 downto 0) & ACKsig;
constant Rightline_cmd : cmd_pkt := Slave_addr & ACKsig & Rigtlinin_addr & R_Llinin_dat(8) & ACKsig & R_Llinin_dat(7 downto 0) & ACKsig;
constant LeftHphon_cmd : cmd_pkt := Slave_addr & ACKsig & Lheadfon_out_addr & R_Lheadfon_out_dat(8) & ACKsig & R_Lheadfon_out_dat(7 downto 0) & ACKsig;
constant RightHphon_cmd: cmd_pkt := Slave_addr & ACKsig & Rheadfon_out_addr & R_Lheadfon_out_dat(8) & ACKsig & R_Lheadfon_out_dat(7 downto 0) & ACKsig;
constant Analogaudio_cmd : cmd_pkt := Slave_addr & ACKsig & Analgaudio_addr & Analgaudio_dat(8) & ACKsig & Analgaudio_dat(7 downto 0) & ACKsig; 
constant Digitalaudio_cmd: cmd_pkt := Slave_addr & ACKsig & Digtlaudio_addr & Digtlaudio_dat(8) & ACKsig & Digtlaudio_dat(7 downto 0) & ACKsig;
constant PWR_cmd         : cmd_pkt := Slave_addr & ACKsig & PWR_addr & PWR_dat(8) & ACKsig & PWR_dat(7 downto 0) & ACKsig;
constant Digitalaudiointf_cmd : cmd_pkt := Slave_addr & ACKsig & Digtlintf_addr & Digtlintf_dat(8) & ACKsig & Digtlintf_dat(7 downto 0) & ACKsig;
constant SampingCtrl_cmd      : cmd_pkt := Slave_addr & ACKsig & Samplng_addr & Samplng_dat(8)& ACKsig & Samplng_dat(7 downto 0) & ACKsig;
constant ActiveCtrl_cmd       : cmd_pkt := Slave_addr & ACKsig & ActiveCtrl_addr & ActiveCtrl_dat(8) & ACKsig & ActiveCtrl_dat(7 downto 0) & ACKsig;
---------------------------------------------------------------------------------------------------------------------------------------------------- 
--------------------------------
constant RST	   : natural:=0;
constant STRT	   : natural:=1;
constant STOP	   : natural:=2;
constant PLL_RST  : natural:=3;
--------------------------------
-- Record Types 
-- Audio Control Entity 
type audio_data_control_in_t is record
	      Rst         : std_logic;
		   Clock18Mhz  : std_logic;
		   EN          : std_logic;
	      Control     : nibble; 
         Adc_dat     : std_logic;		  
end record;

type audio_data_control_out_t is record
	      Bclk         : std_logic;  
		   DAC_LRc      : std_logic;  
		   Adc_LRc      : std_logic;     
		   DAC_dat      : std_logic;  
         ADC_data_out : std_logic;  		  
end record;
-----------------------------------

end package;