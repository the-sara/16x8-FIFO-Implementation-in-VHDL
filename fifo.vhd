--vhdl code for synchronous fifo:
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--the entity:
entity fifo is 
port(
clk:in std_logic;
rst:in std_logic ;
wr,rd:in std_logic;
data_in:in std_logic_vector(7 downto 0);
full_flag:out std_logic;
empty_flag:out std_logic;
data_out:out std_logic_vector(7 downto 0));
end entity;

--the architecture:
architecture logic of fifo is 

	--write pointer component:
	component write_pointer is 
	port(
	clk:in std_logic;
	rst:in std_logic;
	wr:in std_logic;
	not_full:in std_logic;
	write_ad:out std_logic_vector(4 downto 0);
	wr_en:out std_logic);
	end component;

	--read pointer component:
	component read_pointer is 
	port(
	clk:in std_logic;
	rst:in std_logic;
	rd:in std_logic;
	not_empty:in std_logic;
	read_ad:out std_logic_vector(4 downto 0);--the reading address
	rd_en:out std_logic);
	end component;

	--status component:
	component status is 
	port(
	read_ad,write_ad:in std_logic_vector(4 downto 0);
	full_status_flag,empty_status_flag:out std_logic );
	end component;

	--memory array component:
	component memory_array is 
	port(
	clk:in std_logic;
	rst:in std_logic ;
	write_ad,read_ad:in std_logic_vector(4 downto 0);
	wr_en,rd_en:in std_logic;
	data_in:in std_logic_vector(7 downto 0);
	data_out:out std_logic_vector(7 downto 0));
	end component;

	signal full_sig,empty_sig,wr_en_sig,rd_en_sig: std_logic;
	signal write_ad_sig,read_ad_sig:std_logic_vector(4 downto 0);
	--signal data_out_sig,data_in_sig:std_logic_vector(7 downto 0);
	begin

	--the writer pointer
	writer_pointer_unit:write_pointer
	port map(
	clk=>clk,
	rst=>rst,
	wr_en=>wr_en_sig,
	write_ad=>write_ad_sig,
	wr=>wr,
	not_full=>not(full_sig));

	--the read pointer:
	read_pointer_unit:read_pointer
	port map(
	clk=>clk,
	rst=>rst,
	rd_en=>rd_en_sig,
	read_ad=>read_ad_sig,
	rd=>rd,
	not_empty=>not(empty_sig));

	--the status:
	the_status_unit:status
	port map(
	read_ad=>read_ad_sig,
	write_ad=>write_ad_sig,
	full_status_flag=>full_sig,
	empty_status_flag=>empty_sig);

	--the memo array:
	the_memo_unit:memory_array
	port map(
	clk=>clk,
	rst=>rst,
	write_ad=>write_ad_sig,
	read_ad=>read_ad_sig,
	wr_en=>wr_en_sig,
	rd_en=>rd_en_sig,
	data_in=>data_in,
	data_out=>data_out);
full_flag<=full_sig;
empty_flag<=empty_sig;

end logic;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity write_pointer is 
port(
clk:in std_logic;
rst:in std_logic;
wr:in std_logic;
not_full:in std_logic;
write_ad:out std_logic_vector(4 downto 0);
wr_en:out std_logic);
end entity;

architecture logic of write_pointer is
-- is a counter points to the next location to be written in 
signal wr_ad :std_logic_vector(4 downto 0);
begin
write_ad<=wr_ad;
wr_en<= wr and not_full;
process(clk,rst,wr,not_full)
begin
if rst='0' then
	if clk'event and clk ='1' then
		if wr='1' then
			wr_ad<= wr_ad + 1;
		else wr_ad<=wr_ad;
		end if;
	end if;
else
wr_ad<=(others=>'0');--for the rst
end if;
end process;
end logic;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity read_pointer is 
port(
clk:in std_logic;
rst:in std_logic;
rd:in std_logic;
not_empty:in std_logic;
read_ad:out std_logic_vector(4 downto 0);
rd_en:out std_logic);
end entity;

architecture logic of read_pointer is
-- is a counter points to the next location to be written in 
signal rd_ad :std_logic_vector(4 downto 0);
begin
read_ad<=rd_ad;
rd_en <=rd and not_empty;
process(clk,rst,rd,not_empty)
begin
if rst='0' then
	if clk'event and clk ='1' then
		if rd ='1' then
			rd_ad<= rd_ad+1;
		else rd_ad<=rd_ad;
		end if;
	end if;
else
rd_ad<=(others=>'0');--for the rst
end if;
end process;
end logic;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity status is 
port(
read_ad,write_ad:in std_logic_vector(4 downto 0);
full_status_flag,empty_status_flag:out std_logic );
end entity;

architecture logic of status is
signal wrap:std_logic;-- for the msbs
signal rest:std_logic;
begin
wrap<=write_ad(4) xor read_ad(4);--='1' if not equal
rest<='1' when write_ad(3 downto 0)= read_ad(3 downto 0)else '0';
full_status_flag<=wrap and rest;
empty_status_flag<= (not wrap)and rest;
end logic;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity memory_array is 
port(
clk:in std_logic;
rst:in std_logic ;
write_ad,read_ad:in std_logic_vector(4 downto 0);
wr_en,rd_en:in std_logic;
data_in:in std_logic_vector(7 downto 0);
data_out:out std_logic_vector(7 downto 0));
end entity;

architecture logic of memory_array is 
type memory_array is array(15 downto 0) of std_logic_vector(7 downto 0);
signal memo: memory_array;--internal
begin
process(clk,rst,wr_en,rd_en)
begin
if rst='0' then
	 if clk'event and clk='1' then 
		if wr_en='1' then
			memo(to_integer(unsigned(write_ad)))<= data_in;
		end if;
		if rd_en='1' then
			data_out<=memo(to_integer(unsigned(read_ad)));
		end if;
	end if;
end if;
end process;
end logic;



