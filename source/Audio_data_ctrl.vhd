-------------------------------
--Author : Ahmed Asim Ghouri
-- Dated:26 Jan 2012
-- Audio Data Control file
-- Acquires and sends audio data to WM8731 in slave mode  
-- Implemented on DE2-115 Cyclone-IV FPGA
--------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;
USE IEEE.std_logic_arith.ALL;
use work.audio_codec_pkg.all; 
-- Audio Data Contrl -----------------------------------
entity Audio_data_ctrl is
    port (
	    	 audio_ctrl_in  : in audio_data_control_in_t;
		    audio_ctrl_out : out audio_data_control_out_t 
		   ); 
end Audio_data_ctrl;
--
architecture audio_acquisition of  Audio_data_ctrl is

----------------
--bitCount generator.  Changes every 12 counts of the master clock (18MHz)
	component bclk_counter is
		port(
			--active high reset
			reset: in std_logic; 
			mclk: in std_logic;
			bclk: out std_logic
		);
	end component;
	
	--generates left/right channel signal
	component LRchannelCounter is
		port(
			--active high reset
			reset: in std_logic;
			bclk: in std_logic;
			--left = '1', right = '0'
			LRchannel: out std_logic
		);
	end component;

	--active-high reset
	signal reset: std_logic;
	
	--bit clock
	signal bitClock_sig: std_logic;
	
	--left/right channnel control signal
	signal LRchannel_sig: std_logic;

	--counts the bit of neuron data to be sent
	signal bitCounter: integer range 15 downto 0 := 15;

--
signal LRcontr    : integer range 0 to 15; 
signal reg_contr  : integer range 0 to 10;
signal clk_contr  : std_logic_vector(15 downto 0); 
signal EN1,LReg, Rst_sig   : std_logic;
--
--attribute keep: boolean;
--attribute keep of EN1: signal is true;
---- FSM----------------------------------------------------------
--	type Audio_data_acquisition is (   --THESE ARE THE STATES
--			IDLE,               -- stay here and wait untile enabled 
--			Control_config,     -- Read control bits 
--			Bypass_audio,       -- ADC->to->DAC 
--			ADC_data 		     -- Latch ADC serial data 
--			 ); --we'll add more as needed	
--	signal currnt_state	: Audio_data_acquisition ;

begin
-----
Rst_sig <= not (audio_ctrl_in.Rst); 
audio_ctrl_out.DAC_dat <= audio_ctrl_in.Adc_dat and audio_ctrl_in.EN ;
--audio_ctrl_out.ADC_data_out <= audio_ctrl_in.Adc_dat when audio_ctrl_in.EN = '1';
--audio_ctrl_out.DAC_dat <= '0';
-----------------------------------------------
	reset <= Rst_sig;
	
	bclk_counterMap: bclk_counter port map(
	                                      Rst_sig,
													  audio_ctrl_in.Clock18Mhz,
													  bitClock_sig
													  );
	----------------------------------------------
	LRchannelCounterMap: LRchannelCounter port map(
	                                               Rst_sig,
																  bitClock_sig,
																  LRchannel_sig
																  );
---------------------------------------------------------------
	
--output signals
audio_ctrl_out.Bclk <= bitClock_sig;
audio_ctrl_out.DAC_LRc <= LRchannel_sig;
audio_ctrl_out.Adc_LRc <= LRchannel_sig;
	
	     	
end audio_acquisition;

