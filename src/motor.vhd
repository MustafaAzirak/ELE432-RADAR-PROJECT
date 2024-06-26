library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.ALL;

entity motor is 
    generic (
	    motor_speed1 : integer := 149_999; -----------------
		motor_speed2 : integer := 224_999;------------------
		motor_speed3 : integer := 299_999;------------------
		motor_speed4 : integer := 599_999;------------------
		
	    clk_freq_s : integer := 50_000_000; ----------------
		boudrate_s : integer := 9600;
        wait_count : natural := 1  -- -- wait time for the stepper        
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
		  resol:out std_logic_vector(1 downto 0);
		
		--btn_l : in std_logic; -- for ccw turn 
		--btn_r : in std_logic; -- for  cw turn 
		
		rx_i_s  : in std_logic;
        --cw  : in std_logic; -- counter clock wise rotation
		motor_location_o : out integer range 0 to 360;
		
        coils : out std_logic_vector(3 downto 0) -- connected to IN1..IN4
		--step_value : out integer
    );
end motor;

architecture rtl of motor is

  component uartRX is
    generic(
      clk_freq: integer := 50_000_000;	  		
      boudrate: integer := 9600  --user defined
    );
    port(
      clk      : in std_logic;
      Rx_i     : in std_logic;
      reset_i  : in std_logic;
      dataout  : out std_logic_vector (7 downto 0);
      Rx_done  : out std_logic
    );
  end component;


  signal count : integer;
  type mach_states is (WAIT_CFG_DONE,s1,s2,s3,s4,ONE_S_WAIT, s5,s6,s7,s8,STEP_CHECK_FRST,STEP_CHECK_SCND,ONE_S_WAIT2);
  signal m_states : mach_states:=s1;
  signal step_count : integer:=0;
  
  signal rx_done_s : std_logic;
  signal rx_dataout_s : std_logic_vector(7 downto 0);
  
  signal cnt_limit : integer;
  signal cfg_done  : std_logic;
  
  type mach2_states is (WAIT_RX_DONE,CFG_MOTOR);
  signal rx_state : mach2_states;
  signal step_value : integer;
  
  signal manual_motor_control : std_logic; 
  
  signal btn_l : std_logic;
  signal btn_r : std_logic;
  
  signal step_count_r : integer ;
  signal resol_r: std_logic_vector(1 downto 0);
  
  signal clk_prsc : integer range 0 to 1000000 := 0;
  signal location : integer range 0 to 180 := 0;
  signal direction : std_logic := '0';
  
begin

motor_location_o <= location;

process(clk) begin
if rising_edge(clk) then
	if clk_prsc = (1000000-1) then
		clk_prsc <= 0;
		if direction = '0' then
			if location = 180 then
				direction <= '1';
				location <= location - 1;
			else
				location <= location + 1;
			end if;
		else
			if location = 0 then
				direction <= '0';
				location <= location + 1; 
			else
				location <= location - 1;
			end if;
		end if;
	
	else
	clk_prsc <= clk_prsc + 1;
	
	end if;
end if;
end process;

    resol<=resol_r;
    uart_receiver : uartRX 
    generic map (
      clk_freq => clk_freq_s,
      boudrate => boudrate_s
    )
    port map (
      clk      => clk,
      Rx_i     => (rx_i_s),
      reset_i  => rst,
      dataout  => rx_dataout_s,
      Rx_done  => rx_done_s
    );
  
  --motor_location_o<=step_count_r*360/256;
  
  motor_p : process (rst , clk)
  begin
    if (rst = '0') then 
	   count <= 0;
		coils <= (others => '0');
		m_states <= WAIT_CFG_DONE;
		step_count <= 0;
		step_value <= 0;
		step_count_r <= 0;
	 elsif (rising_edge(clk)) then 
	   step_value <= step_count; 
		case m_states is
		  
		  when WAIT_CFG_DONE =>
		    if (cfg_done = '1') then
              m_states <= s1;			
			else 
			  m_states <= WAIT_CFG_DONE;
			end if;
	      
		  when s1 => 
		    if (cfg_done = '0') then 
			  if (manual_motor_control = '0') then 
		        if (count = cnt_limit) then
			      count <= 0;
			      coils(3) <= '0';
			      m_states <= s2;
			    else
		          count <= count + 1;
		          coils(3) <= '1';
		          m_states <= s1;		
			    end if;
			  else 
			    if (btn_l = '1') then ----------------------------------------------- btn condition
				  m_states <= s5;
                elsif (btn_r = '1') then -------------------------------------------- btn condition 
		          if (count = cnt_limit) then
			        count <= 0;
			        coils(3) <= '0';
			        m_states <= s2;
			      else
		            count <= count + 1;
		            coils(3) <= '1';
		            m_states <= s1;		
			      end if;				  
				end if;
              end if; 		  
			else 
			  count    <= 0;
			  m_states <= s1;
			  step_count <= 0;  
			end if; 
		  
		  when s2 => 
		    if (cfg_done = '0') then 
			  if (manual_motor_control = '0') then 
		        if (count = cnt_limit) then
			      count <= 0;
			      coils(2) <= '0';
			      m_states <= s3;
			    else
		          count <= count + 1;
		          coils(2) <= '1';
		          m_states <= s2;		
			    end if;
			  else 
			    if (btn_l = '1') then ----------------------------------------------- btn condition
				  m_states <= s5;
                elsif (btn_r = '1') then -------------------------------------------- btn condition 
		          if (count = cnt_limit) then
			        count <= 0;
			        coils(2) <= '0';
			        m_states <= s3;
			      else
		            count <= count + 1;
		            coils(2) <= '1';
		            m_states <= s2;		
			      end if;				  
				end if;			    
			  end if;
			else 
			  count    <= 0;
			  m_states <= s1;
			  step_count <= 0;  			  
			end if;
		  
		  when s3 => 
		    if (cfg_done = '0') then 
			  if (manual_motor_control = '0') then 
		        if (count = cnt_limit) then
			      count <= 0;
			      coils(1) <= '0';
			      m_states <= s4;
			    else
		          count <= count + 1;
		          coils(1) <= '1';
		          m_states <= s3;		
			    end if;
		      else 
			    if (btn_l = '1') then ----------------------------------------------- btn condition
				  m_states <= s5;
                elsif (btn_r = '1') then -------------------------------------------- btn condition 
		          if (count = cnt_limit) then
			        count <= 0;
			        coils(1) <= '0';
			        m_states <= s4;
			      else
		            count <= count + 1;
		            coils(1) <= '1';
		            m_states <= s3;		
			      end if;				  
				end if;				    
			  end if;
			else 
			  count    <= 0;
			  m_states <= s1;
			  step_count <= 0;  			  
			end if;
		  
		  when s4 => 
		    if (cfg_done = '0') then
			  if (manual_motor_control = '0') then 
		        if (count = cnt_limit) then
			      count <= 0;
			      coils(0) <= '0';
			      m_states <= STEP_CHECK_FRST;
			    else
		          count <= count + 1;
		          coils(0) <= '1';
		          m_states <= s4;		
			    end if;
			  else 
			    if (btn_l = '1') then ----------------------------------------------- btn condition
				  m_states <= s5;
                elsif (btn_r = '1') then -------------------------------------------- btn condition 
		          if (count = cnt_limit) then
			        count <= 0;
			        coils(0) <= '0';
			        m_states <= STEP_CHECK_FRST;
			      else
		            count <= count + 1;
		            coils(0) <= '1';
		            m_states <= s4;		
			      end if;				  
				end if;
              end if;				
			else 
			  count    <= 0;
			  m_states <= s1;
			  step_count <= 0;  			  
			end if;
		  
		  when STEP_CHECK_FRST => 
		    step_count_r <= step_count; 
		    if (cfg_done = '0') then 
		      if (step_count = 511) then 
			    m_states <= ONE_S_WAIT;
			    step_count <= 0;
			  else 
			    step_count <= step_count + 1;
			    m_states   <= s1;
			  end if;
			else 
			  step_count <= 0;  
			  count      <= 0;
			  m_states   <= s1;
			end if;
		  
		  when ONE_S_WAIT => 
		    if (cfg_done = '0') then 
			  if (manual_motor_control = '0') then 
		        if (count = 49_999_999) then 
			      count <= 0;
			      m_states <= s5;
			    else 
			      count <= count + 1;
			      m_states <= ONE_S_WAIT;
			    end if;
			  else 
			    if (btn_l  = '1') then ------------------------------------------------------- btn condition
				  m_states <= s5;
				  count    <= 0;
				  step_count <= 0;
				elsif (btn_r = '1') then ------------------------------------------------------- btn condition
				  m_states <= s1;
				  count    <= 0;
				  step_count <= 0;
				end if;
			  end if;
			else 
			  count      <= 0;
			  m_states   <= s1;	
			  step_count <= 0;  			  
			end if;
		  
		  when s5 => 
		    if (cfg_done = '0') then 
			  if (manual_motor_control = '0') then 
		        if (count = cnt_limit) then
			      count <= 0;
			      coils(0) <= '0';
			      m_states <= s6;
			    else
		          count <= count + 1;
		          coils(0) <= '1';
		          m_states <= s5;		
			    end if;
			  else 
			    if (btn_r = '1') then ----------------------------------------------- btn condition
				  m_states <= s1;
                elsif (btn_l = '1') then -------------------------------------------- btn condition 
		          if (count = cnt_limit) then
			        count <= 0;
			        coils(0) <= '0';
			        m_states <= s6;
			      else
		            count <= count + 1;
		            coils(0) <= '1';
		            m_states <= s5;		
			      end if;				  
				end if;				    			  
			  end if;
			else 
			  count      <= 0;
			  m_states   <= s1;	
			  step_count <= 0;  			  
			end if;
		  
		  when s6 =>
		    if (cfg_done = '0') then 
			  if (manual_motor_control = '0') then 
		        if (count = cnt_limit) then
			      count <= 0;
			      coils(1) <= '0';
			      m_states <= s7;
			    else
		          count <= count + 1;
		          coils(1) <= '1';
		          m_states <= s6;		
			    end if;
			  else 
			    if (btn_r = '1') then ----------------------------------------------- btn condition
				  m_states <= s1;
                elsif (btn_l = '1') then -------------------------------------------- btn condition 
		          if (count = cnt_limit) then
			        count <= 0;
			        coils(1) <= '0';
			        m_states <= s7;
			      else
		            count <= count + 1;
		            coils(1) <= '1';
		            m_states <= s6;		
			      end if;				  
				end if;				  
			  end if;
			else 
			  count      <= 0;
			  m_states   <= s1;	
			  step_count <= 0;  			  
			end if;
		  
		  when s7 =>
		    if (cfg_done = '0') then 
			  if (manual_motor_control = '0') then 
		        if (count = cnt_limit) then
			      count <= 0;
			      coils(2) <= '0';
			      m_states <= s8;
			    else
		          count <= count + 1;
		          coils(2) <= '1';
		          m_states <= s7;		
			    end if;
			  else 
			    if (btn_r = '1') then ----------------------------------------------- btn condition
				  m_states <= s1;
                elsif (btn_l = '1') then -------------------------------------------- btn condition 
		          if (count = cnt_limit) then
			        count <= 0;
			        coils(2) <= '0';
			        m_states <= s8;
			      else
		            count <= count + 1;
		            coils(2) <= '1';
		            m_states <= s7;		
			      end if;				  
				end if;				  
			  end if;
			else
			  count      <= 0;
			  m_states   <= s1;	
			  step_count <= 0;  			  
			end if;
		  
		  when s8 =>
		    if (cfg_done = '0') then 
			  if (manual_motor_control = '0') then 
		        if (count = cnt_limit) then
			      count <= 0;
			      coils(3) <= '0';
			      m_states <= STEP_CHECK_SCND;
			    else
		          count <= count + 1;
		          coils(3) <= '1';
		          m_states <= s8;		
			    end if;
			  else
			    if (btn_r = '1') then ----------------------------------------------- btn condition
				  m_states <= s1;
                elsif (btn_l = '1') then -------------------------------------------- btn condition 
		          if (count = cnt_limit) then
			        count <= 0;
			        coils(3) <= '0';
			        m_states <= STEP_CHECK_SCND;
			      else
		            count <= count + 1;
		            coils(3) <= '1';
		            m_states <= s8;		
			      end if;				  
				end if;				  
			  end if;
			else 
			  count      <= 0;
			  m_states   <= s1;		
			  step_count <= 0;  			  
			end if;
		  
		  when STEP_CHECK_SCND =>
		    step_count_r <=511- step_count; 
		    if (cfg_done = '0') then 
		      if (step_count = 511) then 
			    m_states <= ONE_S_WAIT2;
			    step_count <= 0;
			  else 
			    step_count <= step_count + 1;
			    m_states   <= s5;
			  end if;
			else 
			  step_count <= 0;  
			  count      <= 0;
			  m_states   <= s1;			  
			end if;
		  
		  when ONE_S_WAIT2 => 
		    if (cfg_done = '0') then
			  if (manual_motor_control = '0') then 
		        if (count = 49_999_999) then 
			      count <= 0;
			      m_states <= s1;
			    else 
			      count <= count + 1;
			      m_states <= ONE_S_WAIT2;
			    end if;
			  else 
			    if (btn_r = '1') then   ------------------------------------------------------- btn condition
				  m_states <= s1;
				  count    <= 0;
				  step_count <= 0;
				elsif (btn_l = '1') then  ----------------------------------------------------  btn condition
				  m_states <= s5;
				  count    <= 0;
				  step_count <= 0;
				end if;
			  end if;
			else
			  count      <= 0;
			  m_states   <= s1;	
			  step_count <= 0;  			  
			end if;
		  
		  when others =>  
		    count <= 0;
			coils <= (others => '0');
			m_states <= WAIT_CFG_DONE; 
		
		end  case;
	 end if; 
  end process;
  
  RX_PROC : process (rst, clk) 
  begin
    if (rst = '0') then
      cnt_limit <= 0;  
      rx_state  <= WAIT_RX_DONE;
	  cfg_done  <= '0';
	  manual_motor_control <= '0';
	  btn_l     <= '0';
	  btn_r     <= '0';
     resol_r     <= '1' &'0';
    elsif (rising_edge(clk)) then 
	  resol_r     <= resol_r;
	  case rx_state is 
	    when WAIT_RX_DONE =>
          cfg_done  <= '0';  
		  --manual_motor_control <= '0';
		  if (rx_done_s = '1') then 
		    rx_state <= CFG_MOTOR;
		  else 
		    rx_state <= WAIT_RX_DONE;
          end if;
		  
        when CFG_MOTOR =>
          case rx_dataout_s is
            when x"01" =>
			  cnt_limit <= motor_speed1;
			  rx_state  <= WAIT_RX_DONE;
			  cfg_done  <= '1';
			  manual_motor_control <= '0';
            when x"02" =>
			  cnt_limit <=  motor_speed2;
			  rx_state  <= WAIT_RX_DONE;
			  cfg_done  <= '1';
			  manual_motor_control <= '0';			  
            when x"03" =>
              cnt_limit <=  motor_speed3;
			  rx_state  <= WAIT_RX_DONE;
			  cfg_done  <= '1';
			  manual_motor_control <= '0';
			when x"AF" =>
			  cnt_limit <=  motor_speed2;
			  rx_state  <= WAIT_RX_DONE;
			  manual_motor_control <= '1';
			  cfg_done  <= '1';
			  btn_l     <= '0';
			  btn_r     <= '0';
			  
            when x"CC" =>
              btn_l <= '1';
              btn_r <= '0';

            
            when x"DD" =>
              btn_l <= '0';
              btn_r <= '1';			  
				when x"E1" => ---- res 160*120
				  resol_r     <= '1' &'0';
				when x"E2" => ---- res 320*240
				  resol_r     <= '0' &'1';  
				when x"E3" => ---- res 640*320
				  resol_r     <= '0' &'0';  	    
            when others =>
			  cnt_limit <= motor_speed4;
              rx_state  <= WAIT_RX_DONE;
			  cfg_done  <= '1';
			  manual_motor_control <= '0';
			  btn_l     <= '0';
	          btn_r     <= '0';
          end case;		  	  
      end case;	  
    end if;	
  end process;
  
end architecture;
