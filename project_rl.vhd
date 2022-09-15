----------------------------------------------------------------------------------
-- Company: Politecnico di Milano   
-- Prova Finale (Progetto di Reti Logiche)
-- Prof. Fabio Salice - Anno Accademico 2021/2022
-- Engineer: Alessandro Franzini (Codice Persona: 10690276 Matricola: 913663)
-- 
-- Create Date: 03.03.2022 16:57:34
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: ProgettoRL
-- Target Devices: 
-- Tool Versions: 
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

entity convolutore is
    port (
    in_clk : in std_logic;
  	in_rst : in std_logic;
  	in_start : in std_logic;
  	in_data : in std_logic_vector(7 downto 0);
  	out_data : out std_logic_vector(15 downto 0);
  	out_done : out std_logic := '0'
    );
end convolutore;

architecture Behavioural of convolutore is

	type state_type is (S0, S1, S2, S3);
   	signal current_state, next_state : state_type;
   	signal tmp, tmp_next : std_logic_vector(15 downto 0) := (others => '0');
	signal r_count, r_count_next : integer range -1 to 7 := 7;
	signal i, i_next : integer range 0 to 15 := 15;

	begin
        algorithm : process(in_clk, in_rst, in_start, in_data)
        begin
	       if(in_rst='0') then
		      current_state <= S0;
              tmp <= (others => '0');
              out_done <= '0';
		      r_count <= 7;
		      i <= 15;
		   elsif(rising_edge(in_clk)) then
		      if(r_count >= 0 and in_start = '1') then
		      current_state <= next_state;
		      tmp <= tmp_next;
		      r_count <= r_count_next;
		      i <= i_next;
		      case current_state is
		          when S0 =>
		              if (in_data(r_count) = '1') then      
                        tmp_next(i) <= '1';
                        tmp_next(i-1) <= '1';
                        next_state <= S2;
                      else
			             tmp_next(i) <= '0';
                         tmp_next(i-1) <= '0';
                       	 next_state <= S0;
                      end if;
                  when S1 =>
                    	if (in_data(r_count) = '1') then
                    	   tmp_next(i) <= '0';
                           tmp_next(i-1) <= '0';
                       	   next_state <= S2;
                        else
			               tmp_next(i) <= '1';
                           tmp_next(i-1) <= '1';
                       	   next_state <= S0;
                    	end if;
		          when S2 =>
			            if (in_data(r_count) = '1') then         
                           tmp_next(i) <= '1';
                           tmp_next(i-1) <= '0';
                       	   next_state <= S3;
                        else
			               tmp_next(i) <= '0';
                           tmp_next(i-1) <= '1';
                       	   next_state <= S1;
                    	end if;
		          when S3 =>
			             if (in_data(r_count) = '1') then         
                           tmp_next(i) <= '0';
                           tmp_next(i-1) <= '1';
                       	   next_state <= S3;
                        else
			               tmp_next(i) <= '1';
                           tmp_next(i-1) <= '0';
                       	   next_state <= S1;
                    	end if;
		      end case;
		      i_next <= i-2;
              r_count_next <= r_count-1;
              out_done <= '0';
          elsif(r_count < 0) then
              out_done <= '1';
              out_data <= tmp;
              tmp_next <= (others => '0');
              r_count <= 7;
              r_count_next <= 7;
              i <= 15;
              i_next <= 15;
		  end if;
	   end if;
	end process;
end Behavioural;

----------------------------------------------------------------------------------
library IEEE;
library project;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port (
           i_clk : in std_logic;
           i_rst : in std_logic;
           i_start : in std_logic;
           i_data : in std_logic_vector(7 downto 0);
           o_address : out std_logic_vector(15 downto 0);
           o_done : out std_logic;
           o_en : out std_logic;
           o_we : out std_logic;
           o_data : out std_logic_vector(7 downto 0)
           );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    type state_type is (IDLE, WAITING, GET_LENGTH, READ, WRITE, UPDATE, DONE);
    signal current_state, next_state : state_type;
    signal o_address_next : std_logic_vector(15 downto 0) := (others => '0'); 
    signal o_data_next : std_logic_vector(7 downto 0) := (others => '0');
    signal o_done_next, o_en_next, o_we_next , wr, wr_next, conv_done, conv_start, conv_start_next : std_logic := '0';
    signal count, count_next : integer range 1 to 256 := 1;
    signal length, length_next : integer range 0 to 255 := 0;
    signal result : std_logic_vector(15 downto 0) := (others => '0');
    signal uk, uk_next : std_logic_vector(7 downto 0) := (others => '0');
    signal write_address, write_address_next : integer  range 0 to 16385 := 1000;
    signal state_return,state_return_next : state_type;
    
    component convolutore is
        port (
  	   in_clk : in std_logic;
  	   in_rst : in std_logic;
  	   in_start : in std_logic;
  	   in_data : in std_logic_vector(7 downto 0);
  	   out_data : out std_logic_vector(15 downto 0);
  	   out_done : out std_logic
    	);
    end component;
    
    begin
        controller : convolutore
    	port map(
           in_clk => i_clk,
  	       in_rst => i_start,
  	       in_start => conv_start,
  	       in_data => uk,
  	       out_data => result,
  	       out_done => conv_done
    	);

        state_def: process(i_clk, i_rst)
        begin
        
            if (i_rst='1') then
                o_address <= (others => '0');
                o_done <= '0';
                o_en <= '0';
                o_we <= '0';
		        wr <= '0';
		        conv_start <= '0';
                o_data <= (others => '0');                
                current_state <= IDLE;
		        count <= 1;
		        length <= 0;
		        uk <= (others => '0');
                write_address <= 1000; 
                state_return <= IDLE;
                          
            elsif (rising_edge(i_clk)) then 
                o_address <= o_address_next;
                o_done <= o_done_next;
                o_en <= o_en_next; 
                o_we <= o_we_next;
                o_data <= o_data_next;
                wr <= wr_next;
                conv_start <= conv_start_next;    
                current_state <= next_state;
		        count <= count_next;
		        length <= length_next;
		        uk <= uk_next;
                write_address <= write_address_next;           
                state_return <= state_return_next;
                
            end if;
        end process;
            
        main: process(i_start, i_data, current_state, state_return, count, length, uk, result, write_address, wr, conv_done, conv_start)

        begin
            o_address_next <= (others => '0');
            o_done_next <= '0';
            o_en_next <= '0';
            o_we_next <= '0';
            o_data_next <= (others => '0');
            wr_next <= wr;
            conv_start_next <= conv_start;
	        count_next <= count;
	        length_next <= length;
	        uk_next <= uk;
	        write_address_next <= write_address;
            state_return_next <= state_return;
            
            case current_state is
                when IDLE =>
                    if (i_start = '1') then          
                        o_en_next <= '1';
                        state_return_next <= GET_LENGTH;
                        next_state <= WAITING;
                    else
                        next_state <= IDLE;
                    end if;
                when WAITING =>
                    o_en_next <= '1';
                    if (state_return = WRITE and conv_done = '0') then
                        state_return_next <= WRITE;
                        next_state <= WAITING;
                    elsif (conv_done = '1') then
                        conv_start_next <= '0';
                        o_address_next <= std_logic_vector (to_unsigned(write_address, 16));
                        write_address_next <= write_address + 1;
                        o_data_next <= std_logic_vector(resize(unsigned(result(15 downto 8)), 8));
                        o_we_next <= '1';
                        next_state <= state_return;
                    else
                        next_state <= state_return;
                    end if;
                when GET_LENGTH =>
                    o_address_next <= "0000000000000001";
                    o_en_next <= '1';
                    length_next <= to_integer(unsigned(i_data));
                    state_return_next <= READ;
                    next_state <= WAITING;
                when READ =>
                     if (length = 0) then
                        next_state <= UPDATE;
                     else
                        uk_next <= i_data;
                        conv_start_next <= '1';
                        count_next <= count + 1;
                        state_return_next <= WRITE;
                        next_state <= WAITING;
                     end if;
                when WRITE =>
		            if(wr = '0') then
                      o_en_next <= '1';
                      o_we_next <= '1';
		              o_data_next <= std_logic_vector(resize(unsigned(result(7 downto 0)), 8));
		              o_address_next <= std_logic_vector (to_unsigned(write_address, 16));
		              write_address_next <= write_address + 1;
		              wr_next <= '1';
                      next_state <= WRITE;
		            else
		              o_address_next <= std_logic_vector(to_unsigned(count, 16));
		              wr_next <= '0';
		              if (count = length + 1) then
                         count_next <= 1;
			             next_state <= UPDATE;
		              else
		                 o_en_next <= '1';
		                 state_return_next <= READ; 
			             next_state <= WAITING;
		              end if;
		            end if;
                when UPDATE =>
                    o_done_next <= '1';
                    write_address_next <= 1000;
                    uk_next <= (others => '0');
                    conv_start_next <= '0';
                    length_next <= 0;
                    next_state <= DONE;
                when DONE =>
                    if (i_start = '0') then                                 
                        next_state <= IDLE;
                    else
                        next_state <= DONE;
                    end if;
            end case;
        end process;
               
end Behavioral;