----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/23/2022 06:58:35 PM
-- Design Name: 
-- Module Name: mpg - Behavioral
-- Project Name: 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mpg is
    Port(clk : in STD_LOGIC;
    input: in STD_LOGIC;
    enable: out STD_LOGIC);
end mpg;

architecture Behavioral of mpg is
signal cnt: STD_LOGIC_VECTOR(31 downto 0):=x"00000000";
signal Q1: std_logic;
signal Q2: std_logic;
signal Q3: std_logic;

begin

    counter: process(clk)
    begin
    if rising_edge(clk) then 
       cnt <= cnt + 1;
     end if;
    end process counter;
    
    register1: process(clk)
    begin
        if rising_edge(clk) then
            if cnt(15 downto 0)="1111111111111111" then
                Q1<=input;
            end if;
       end if;
   end process register1;
   
   register2_3: process(clk)
   begin
        if rising_edge(clk) then
            Q2<=Q1;
            Q3<=Q2;
        end if;
   end process register2_3;
    
   enable <= Q2 AND (not Q3);


end Behavioral;
