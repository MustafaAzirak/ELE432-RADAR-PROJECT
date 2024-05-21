library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity send_tx is
  port(
    clk          : in std_logic;
	 distance_out : in integer range 0 to 255 ;
	 rst				: in std_logic;
	 motor_location_i : in integer range 0 to 360;
	 tx_n 				   : out std_logic
	 
  );
end send_tx;

architecture Behavioral of send_tx is

signal data_i         :STD_LOGIC_VECTOR(7 downto 0);
signal data_en			 : STD_LOGIC;
signal tx_busy			 : STD_LOGIC;
signal tx_busy_r	    : STD_LOGIC;			
  type mach1_states is (WAIT_TX_DONE,TX_location,TX_distance,Tx_s);
  signal tx_state : mach1_states;
  signal step_value : integer;
  signal tx 		:STD_LOGIC;
--  type MysetType is array (0 to 7) of std_logic_vector(7 down to 0); -- Declare array type
--  signal myset : MysetType := (x"82",x"65",x"68",x"65",x"82",x"32",x"83",x"84"); -- Initialize array 082 065 068 065 082 032 083 084 065 082 084
--  
begin
tx_n<= not tx ;
uarttx:entity work.uartTX
  port map(
    data_i        =>data_i,
    data_en	      =>data_en,
    clk          =>clk,
    reset_i       =>rst,
    tx_busy	      =>tx_busy, 
    Tx_o          =>tx
  );
  
    RX_PROC : process (rst, clk) 
  begin
    if (rst = '0') then
		tx_state<=WAIT_TX_DONE;
	   data_i<=(others=>'0');
		data_en<='0';
		tx_busy_r<='0';
		
    elsif (rising_edge(clk)) then 
	  tx_busy_r<=tx_busy;
	  case tx_state is 
	    when WAIT_TX_DONE =>
		   data_en<='1';
			data_i <= std_logic_Vector (to_Unsigned(motor_location_i/2,8));
			tx_state<=TX_location;
			
--		when 	 Tx_s=>
--		  	data_en<='0';
--			if (tx_busy_r ='1' and  tx_busy ='0') then
--					tx_state<=TX_location;
--		         data_en<='1';
--			     data_i <= std_logic_Vector (to_Unsigned(motor_location_i/2,8));
--			     tx_state<=TX_location;
--			else
--					tx_state<=Tx_s;
--					
--			end if;
--			
		 
       
		  
       when TX_location =>
			data_en<='0';
			if (tx_busy_r ='1' and  tx_busy ='0') then
					tx_state<=TX_distance;
					data_en<='1';
					data_i <= std_logic_Vector (to_Unsigned(distance_out,8));
			else
					tx_state<=TX_location;
					
			end if;
			
			
		 
		 when TX_distance =>
		 
		  	data_en<='0';
			if (tx_busy_r ='1' and  tx_busy ='0') then
					tx_state<=TX_location;
					data_i <= std_logic_Vector (to_Unsigned(motor_location_i/2,8));
					data_en<='1';
			else
					tx_state<=TX_distance;
			end if;	  
--       when Tx_s =>
--		 
--		  	data_en<='0';
--			if (tx_busy_r ='1' and  tx_busy ='0') then
--					tx_state<=TX_location;
--					data_i <= std_logic_Vector (to_Unsigned(motor_location_o/2,8));
--					data_en<='1';
--			else
--					tx_state<=Tx_s;
--			end if;	
			
       when others =>
			tx_state<=WAIT_TX_DONE;
	  	  
      end case;	  
    end if;	
  end process;
  
  
  
	
	
end Behavioral;
