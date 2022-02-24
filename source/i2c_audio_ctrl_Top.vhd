-------------------------------
-- Author : Ahmed Asim Ghouri
-- Dated:21 Dec 2011
-- I2c Audio Control Top file
-- Configures WM8731 into slave mode  
-- Implemented on DE2-115 Cyclone-IV FPGA
-- Tested and verified it, it works ADC->DAC output
-- Ver 1.1.0
-- Upgrade : incorporating codec device reset 
-- also added the LR channel signal control signal and Bclk generator 
-- from Neuron project , works fine without the clicking noise 
-- Dated : 12 April 2012
-- Enabling ADC serial data out to one of the pins of GPIO for testing only  
--
-- Ver 1.2.0
-- Upgrade : incorporating reocrd types and subtypes in audio_codec_pkg package file 
-- Dated : 16 febrary 2022
-- Observation : Audio in : into Line In produces better sound output
-- 
-- Ver 1.2.1
-- Dated   : 24 febrary 2022
-- Upgrade : inclued I2C Command subtypes and I2C Command constants in audio_codec_pkg package file  
---------------------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;
USE IEEE.std_logic_arith.ALL;
use work.audio_codec_pkg.all; 
-- i2c Audio Contrl ---------
entity i2c_audio_ctrl_Top is
    port (
	     CLOCK_50 : in std_logic;
	     KEY      : in nibble;  
		  LED      : out nibble;  
        SW       : in std_logic_vector ( 17 downto 0 );    
        LEDR     : out std_logic_vector ( 17 downto 0 );
		  LEDG     : out Byt_t;
		  GPIO     : out Byt_t; -- 40-pin Connector 
		  --I2C ports
		  -- Changing pin assignments for I2C Clk and Data to 40 pin connector 
		  -- on DE2 to test lecroy
		  -- SCLK => pin Y17 => IO_D3
		  I2C_SCLK : out std_logic; --<< 250Khz
		  -- SDAT => pin AC15 => IO_D1 ( on cennector ) 
		  I2C_SDAT : inout std_logic;
		  --audio codec ports
		  AUD_ADCDAT : in std_logic;  --<< ADC Digital Data input 
		  AUD_ADCLRCK: out std_logic; --<< ADC Sample Rate clock R/L
		  AUD_DACLRCK: out std_logic; --<< DAC Sample Rate clock R/L
		  AUD_DACDAT : out std_logic; --<< DAC Digital Data Output 
		  AUD_XCK    : out std_logic; --<< 18.432Mhz
		  AUD_BCLK   : out std_logic  --<< 500.0Khz : Digital Audio Bit clock 
		 ); 
end i2c_audio_ctrl_Top;
-------------------------------------------------------
architecture audio_processing of  i2c_audio_ctrl_Top is 
-- delacont will count to 999 to create a delay of 5ms 
signal delacont      : integer range 0 to 1000; 
signal cont          : integer range 0 to 10; 
signal bitcont       : integer range 0 to 26; 
signal Data_pACKsigt    : std_logic_vector(26 downto 0);
signal clk18mhz, Pllckd,Pllrst,Clk500Khz : std_logic;
signal Clk10Khz, Audio_EN : std_logic; 
signal SW_reg       : nibble;
--
attribute keep: boolean;
-- attribute keep of Audio_EN: signal is true;
----------------------------------------------------
component audio_pll IS
	PORT
	(
		areset	 : in STD_LOGIC;
		inclk0	 : in STD_LOGIC;	
		c0		    : out STD_LOGIC ;  --<< 18.432Mhz
		c1		    : out STD_LOGIC ;  --<< 500.0Khz , switching to 100Khz 
		c2        : out STD_LOGIC ;  --<< 10.0Khz
		locked    : out STD_LOGIC  
	);
end component;
-----------------------------
component Audio_data_ctrl is 
 port (
	    audio_ctrl_in  : in audio_data_control_in_t;
		 audio_ctrl_out : out audio_data_control_out_t 
		   ); 
end component;
-- FSM--------------------------------------------------
	type Audio_control_type is (   --THESE ARE THE STATES
	      IDLE,       -- stay here and wait for push buttons
			Reset_codec,  
			Reset_codec1,
			Config,     -- get configuration for various settings
			Config1,
			Config2,
			Config3,
			Update_Config,
			Tx1,		-- Transimiting I2S data
			Tx2,		-- Transimiting I2S data
			Tx3,		-- Transimiting I2S data
			Lag_State,
			Lag_State1,
			Audio_acquire, -- Acquiring audio data from ADC
			Audio_acquire1 -- Audio data processing 
			 ); --we'll add more as needed	
signal currt_state	: Audio_control_type ;
----------------------------------------------
attribute keep of currt_state : signal is true;
begin
--
AUD_XCK  <= clk18mhz;
Pllrst   <= not (KEY(PLL_RST)); 
--LEDG(1)  <= Clk500Khz; -- Just for testing 
--LEDG(2)  <= KEY(STOP); -- Just for testing 
--LEDG(3)  <= Clk10Khz; -- Just for testing
--LEDG(4)  <= Audio_EN; -- Just for testing
-- Connecttions below going to 40-pin connector 
GPIO(0)  <= Clk500Khz;   -- to pin IO_D1(pin 2) => FPGA pin AC15
GPIO(1)  <= KEY(STOP); -- to pin IO_D3(pin 4) => FPGA pin 
GPIO(2)  <= Clk10Khz;    -- to pin IO_D5(pin 6) => FPGA pin 
GPIO(3)  <= Audio_EN;    -- to pin IO_D7(pin 8) => FPGA pin 


 	
-- Port Map --
PLL_ports : audio_pll
	port map (
		      areset  => Pllrst,
		      inclk0  => CLOCK_50,	
		      c0	     => clk18mhz,  --<< 18.432Mhz
		      c1      => Clk500Khz,
		      c2      => Clk10Khz,
		      locked  => LEDG(0)	
	); 
----------------------------
Audio_control_ports : Audio_data_ctrl
 port map (
            audio_ctrl_in.Rst        => KEY(RST),     
				audio_ctrl_in.Clock18Mhz => clk18mhz,			
				audio_ctrl_in.EN         => Audio_EN,        
				audio_ctrl_in.Control    => SW_reg,   
				audio_ctrl_out.Bclk      => AUD_BCLK,     
				audio_ctrl_out.DAC_LRc   => AUD_DACLRCK,   
				audio_ctrl_out.Adc_LRc   => AUD_ADCLRCK,   
				audio_ctrl_out.DAC_dat   => AUD_DACDAT,   
				audio_ctrl_in.Adc_dat    => AUD_ADCDAT,
		      audio_ctrl_out.ADC_data_out => GPIO(4) 		
				);
-- FSM--------------------------------------------------------------------------
Main_fsm : process(currt_state,Clk500Khz, KEY) -- Single Process for Fsm operation --
begin
	if KEY(RST) = '0' then
	   I2C_SCLK <= '1';
	   I2C_SDAT <= '1';
		cont <= 0;
		Audio_EN <='0';
		bitcont <= 26;  
		delacont <= 0;
	currt_state <= Reset_codec;
		------------------------------
	elsif rising_edge(Clk500Khz) then
		case currt_state is
      -------------------------------------------------------------------------------------------------	
		when IDLE => 	
		            if KEY(STRT) = '0' then
			              currt_state <= Config;
						if KEY(RST) = '0' then
				           currt_state <= Reset_codec;		
						else 
	                  currt_state <= IDLE; 	
						end if ;	
						end if ;
		--------------------------------------------------------------------------------------------------
      when Reset_codec => I2C_SCLK <= '1';
	                       I2C_SDAT <= '1';
		                    cont <= 0;
		                    Audio_EN <='0';
		                    bitcont <= 26;  
		                    delacont <= 0;
								  currt_state <= Reset_codec1; 
		--------------------------------------------------------------------------------------------------
		when Reset_codec1 => I2C_SCLK <= '1';
	                        I2C_SDAT <= '1';
		                     cont <= 0;
		                     Audio_EN <='0';
		                     bitcont <= 26;  
		                     delacont <= 0;
								   currt_state <= IDLE; 
		-----------------------------------------
		when Config =>
		           if cont = 10 then 
					     I2C_SCLK <= '1';
	                 I2C_SDAT <= '1';
					     cont <= 0 ;
						  currt_state <= Lag_State;
					  else 	
					    bitcont <= 26;
						 I2C_SCLK <= '1';
	                I2C_SDAT <= '1'; 
						 currt_state <= Config1; 
					 end if; 	
		--------------------------------------			 
		when Config1 => I2C_SCLK <= '1';
	                   I2C_SDAT <= '1'; 
						    currt_state <= Config2;  
		---------------------------------------------
      when Config2 => I2C_SCLK <= '1';
	                   I2C_SDAT <= '1'; 
						    currt_state <= Config3;
		---------------------------------------------
      when Config3 => I2C_SCLK <= '1';
	                   I2C_SDAT <= '1'; 
						    currt_state <= Update_Config;		
		---------------------------------------------------------------
		when Update_Config =>
		     		  -- Sending Control registers configuration 
					  
					  case cont is 
					  														 
							 when 0 => Data_pACKsigt <= Leftline_cmd;
							 
							 when 1 => Data_pACKsigt <= Rightline_cmd;
							 
							 when 2 => Data_pACKsigt <= LeftHphon_cmd;
							 
							 when 3 => Data_pACKsigt <= RightHphon_cmd;
							 
							 when 4 => Data_pACKsigt <= Analogaudio_cmd;
							 
							 when 5 => Data_pACKsigt <= Digitalaudio_cmd;
							 
							 when 6 => Data_pACKsigt <= PWR_cmd;
							 
							 when 7 => Data_pACKsigt <= Digitalaudiointf_cmd;
							 
							 when 8 => Data_pACKsigt <= SampingCtrl_cmd;
							 
							 when 9 => Data_pACKsigt <= ActiveCtrl_cmd;
							 
							 when others => Data_pACKsigt <= (others=>'1'); 
							 
							 
		             end case ;
						 
						 currt_state <= Tx1; 
						 
		-----------------------------------------------------------------------------------------------------------------------				
		 when Tx1 => I2C_SCLK <= '0';
		             I2C_SDAT <= '0';
                   currt_state <= Tx2; 
		-----------------------------------------------				 
		when Tx2 => I2C_SCLK <= '1';
                  I2C_SDAT <= Data_pACKsigt(bitcont); 
						currt_state <= Tx3; 		
		    
		---------------------------------------------
      when Tx3 => if bitcont = 0 then 
	                  cont <= cont + 1;
							I2C_SCLK <= '0';
	                  currt_state <= Config;
					   else 		
				         I2C_SCLK <= '0';
                     I2C_SDAT <= Data_pACKsigt(bitcont); 
							bitcont <= bitcont - 1;	
				         currt_state <= Tx2;	
					   end if ; 	
		---------------------------------------------
      when Lag_State => -- if delacont > 999 then 
		                  if delacont > 9 then 
                           currt_state <= Audio_acquire;	
								else 
								   currt_state <= Lag_State1;
							   end if;   	
		---------------------------------------------
      when Lag_State1 => delacont <= delacont + 1;
		                   currt_state <= Lag_State;
       ----------------------------------------------				
		when Audio_acquire => SW_reg <= SW(3 downto 0);
                            currt_state <= Audio_acquire1; 	
		---------------------------------------------				
		when Audio_acquire1 => Audio_EN <= '1';
                            currt_state <= IDLE; 									 
						
		---------------------------------------------	
   	when others  => currt_state <= IDLE; 
     end case;
	end if;
end process;		

---------------	
end audio_processing;
			