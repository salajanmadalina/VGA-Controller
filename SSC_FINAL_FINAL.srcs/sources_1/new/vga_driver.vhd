library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity vga_driver is
     port (clk : in  std_logic; 
           hsync : out std_logic;
           vsync : out std_logic;
           R,G : out std_logic_vector (2 downto 0);
           invert : in std_logic;
           brighten : in std_logic;
           darken : in std_logic;
           btnup: in std_logic;
           btndown: in std_logic;
           btnleft: in std_logic;
           btnright: in std_logic;
           res: in std_logic;
           B : out std_logic_vector (1 downto 0));
end vga_driver;

architecture behavioral of vga_driver is

signal clk25 : std_logic := '0'; -- Semnalul de ceas de 25 MHz (frecventa pixelilor)
signal clk40 : std_logic := '0'; -- Semnalul de ceas de 25 MHz (frecventa pixelilor)
signal clkpixel : std_logic := '0';

constant picture_size : integer := 65536; 

--Signals for Block RAM
signal wea : std_logic_vector(0 downto 0) := "0";
signal addra : std_logic_vector(15 downto 0):= (others => '0');
signal dina : std_logic_vector(7 downto 0) := (others => '0');
signal douta : std_logic_vector(7 downto 0):= (others => '0');

constant HD1 : integer := 640; -- Horizontal Display 
constant HFP1 : integer := 16; --  Right border (front porch)
constant HSP1 : integer := 96; -- Sync pulse (retrace)
constant HBP1 : integer := 48; --  Left border (back porch)

-- HD + HFP + HSP + HBP = 800
	
constant VD1 : integer := 480;  -- Vertical Display (480)
constant VFP1 : integer := 10;  -- Right border (front porch)
constant VSP1 : integer := 2; -- Sync pulse (retrace)
constant VBP1 : integer := 33; --  Left border (back porch)

-- VD + VHP + VSP + VBP = 525

constant HD2 : integer := 800; -- Horizontal Display 
constant HFP2 : integer := 40; --  Right border (front porch)
constant HSP2 : integer := 128; -- Sync pulse (retrace)
constant HBP2 : integer := 88; --  Left border (back porch)

-- HD + HFP + HSP + HBP = 1056
	
constant VD2 : integer := 600;  -- Vertical Display (480)
constant VFP2 : integer := 1;  -- Right border (front porch)
constant VSP2 : integer := 4; -- Sync pulse (retrace)
constant VBP2 : integer := 23; --  Left border (back porch)

-- VD + VHP + VSP + VBP = 628
	
signal row : integer := 0;
signal column : integer := 0;

signal hPos : integer := 1;
signal vPos : integer := 0; 
signal startH : integer := 0;
signal startV: integer := 0; 
signal index: integer := 30;

signal videoOn : std_logic := '0';
signal counter: integer := 0;
signal btnRight1: std_logic:= '0';
signal btnup1: std_logic:= '0';
signal btndown1: std_logic:= '0';
signal btnleft1: std_logic:= '0';

signal inv : std_logic := '0';
signal bri : std_logic := '0';
signal dark : std_logic := '0';

signal HD : integer := 0; -- Horizontal Display 
signal HFP : integer := 0; --  Right border (front porch)
signal HSP : integer := 0; -- Sync pulse (retrace)
signal HBP : integer := 0; --  Left border (back porch)

-- HD + HFP + HSP + HBP = 800
	
signal VD : integer := 0;  -- Vertical Display (480)
signal VFP : integer := 0;  -- Right border (front porch)
signal VSP : integer := 0; -- Sync pulse (retrace)
signal VBP : integer := 0; --  Left border (back porch)

-- VD + VHP + VSP + VBP = 525

component blk_mem_gen_0
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END component;

component clk_wiz_1
    port( clk_out1 : out std_logic; --ceasul cu frecventa de 25MHz
    clk_out2: out std_logic;
    clk_in1: in std_logic);
end component;

component mpg
    Port(clk : in STD_LOGIC;
    input: in STD_LOGIC;
    enable: out STD_LOGIC);
end component;

begin
picture_load : blk_mem_gen_0 port map (clka => clk25, wea => wea, addra => addra, dina => dina, douta => douta);   
clk_divider: clk_wiz_1 port map (clk_out1 => clk25, clk_out2 => clk40, clk_in1 => clk);
btn_Right: mpg port map (clk => clk, input => btnRight, enable => btnRight1);
btn_Left: mpg port map (clk => clk, input => btnLeft, enable => btnLeft1);
btn_Up: mpg port map (clk => clk, input => btnUp, enable => btnUp1);
btn_Down: mpg port map (clk => clk, input => btnDown, enable => btnDown1);

Resolution:process(res)
begin
    if res = '0' then
        HD <= HD1;
        HFP <= HFP1;
        HSP <= HSP1;
        HBP <= HBP1;
        
        VD <= VD1;
        VFP <= VFP1;
        VSP <= VSP1;
        VBP <= VBP1;
        
        clkpixel <= clk25;
     else
        HD <= HD2;
        HFP <= HFP2;
        HSP <= HSP2;
        HBP <= HBP2;
        
        VD <= VD2;
        VFP <= VFP2;
        VSP <= VSP2;
        VBP <= VBP2;
        
        clkpixel <= clk40;
        
    end if;
end process;
 
HPC : process(clkpixel)
begin
	if clkpixel'event and clkpixel = '1' then
		if hPos = HD + HFP + HSP + HBP - 1 then
			hPos <= 0;
		else
			hPos <= hPos + 1;
		end if;
	end if;
end process;

VPC : process(clkpixel, hPos)
begin
	if clkpixel'event and clkpixel = '1' then
		if hPos = HD + HFP + HSP + HBP - 1 then
			if vPos = VD + VFP + VSP + VBP - 1 then
			    vPos <= 0;
			else
				vPos <= vPos + 1;
			end if;
		end if;
	end if;
end process;

HorizontalSync : process(clkpixel, hPos, res)
begin
	if clkpixel'event and clkpixel = '1' then
		if((hPos < (HD + HFP)) OR (hPos >= HD + HFP + HSP))then		
			if res = '0' then
			     hsync <= '1';
			 else
			     hsync <= '0';
			 end if;
		else
		  if res = '0' then
			     hsync <= '0';
			 else
			     hsync <= '1';
			 end if;
		end if;
	end if;
end process;

VerticalSync: process(clkpixel, vPos)
begin
	if clkpixel'event and clkpixel = '1' then
		if((vPos < (VD + VFP)) OR (vPos >= VD + VFP + VSP))then		
			if res = '0' then
			     vsync <= '1';
			 else
			     vsync <= '0';
			 end if;
		else
			if res = '0' then
			     vsync <= '0';
			 else
			     vsync <= '1';
			 end if;
		end if;
	end if;
end process;

Video : process(clkpixel, hPos, vPos)
begin
	if clkpixel'event and clkpixel = '1' then
		if hPos <= HD and vPos <= VD then
			videoOn <= '1';
		else  
			videoOn <= '0';
		end if;
	end if;
end process;

ImageMove : process(clkpixel, btnup, btndown, btnleft, btnright)
begin
    if rising_edge(clkpixel) then
        if btnup1 = '1' then
            startV <= startV - 10;
        elsif btndown1 = '1' then
            startV <= startV + 10;
        end if;
        if btnleft1 = '1' then
            startH <= startH - 10;
        elsif btnright1 = '1' then
            startH <= startH + 10;
        end if;
    end if;
end process;

RowColum : process(hPos, vPos)
begin
	IF(hPos < HD) THEN  --horiztonal display time
        column <= hPos;           --set horiztonal pixel coordinate
	END IF;
	IF(vPos < VD) THEN  --vertical display time
        row <= vPos;              --set vertical pixel coordinate
	END IF;
end process;
	
draw : process(clkpixel, column, row, videoOn, douta)
begin
	if clkpixel'event and clkpixel = '1' then
		if videoOn = '1' then
            if column - startH <= 255 AND row - startV <= 255 then
				addra <= std_logic_vector(to_unsigned((row - startV) * 255 + (column - startH), 16));
				R <= douta(7 downto 5); 
				G <= douta(4 downto 2); 
				B <= douta(1 downto 0);
				
				if invert = '1' and brighten  = '0' and darken = '0' then
                        R <= "111" - douta(7 downto 5); 
                        G <= "111" - douta(4 downto 2); 
                        B <= "11" - douta(1 downto 0);
                    end if;
                    
                if brighten  = '1' and invert = '0' and darken = '0'  then
                        if douta(7 downto 5) < "100" then
                            R <= douta(6 downto 5) & "0" ;
                        else
                            R <= "111";
                        end if;
                        if douta(4 downto 2) < "100" then
                            G <= douta(3 downto 2) & "0" ;
                        else
                            G <= "111";
                        end if;
                        if douta(1 downto 0) < "10" then
                            B <= douta(0) & "0" ;
                        else
                            B <= "11";
                        end if;
                    end if;
                    
                if invert = '0' and brighten  = '0' and darken = '1' then
                        R <= "0" &  douta(7 downto 6); 
                        G <= "0" & douta(4 downto 3); 
                        B <= "0" & douta(1);
                    end if;
			else
				R <= (others => '0');
				G <= (others => '0');
				B <= (others => '0');
			end if;
	       
		else
			R <= (others => '0');
			G <= (others => '0');
			B <= (others => '0');
		end if;		
	end if;
end process;

inv <= invert;
bri <= brighten;
dark <= darken;

end behavioral;
