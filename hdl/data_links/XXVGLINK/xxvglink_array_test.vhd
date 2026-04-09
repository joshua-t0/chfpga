entity xxvglink_array_test is
	generic (
        WORKS: integer := 0; -- good comment
		NUMBER_OF_LINKS: integer        := LINK_TO_QUAD_MAP'LENGTH; --  Number of physical data links (GTYs) - Do not override
		SIM: boolean                    := FALSE -- This should not be gobbled by the parser
	);
	port (
		CTRL_RST : in std_logic := '0' -- Also not gobbled by the parser
	);
end xxvglink_array_test;

