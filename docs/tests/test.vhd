    /* Entity
    declaration
    header*/
    -- block
    -- comment
    entity e is
    -- port clause header comment
    port (
        x: in std_logic:=BIT; -- interface x trailing comment

        -- Isolated comment

        -- interface y,z header comment
        y,z:out gluglu := (s+10) -- interface y,z trailing comment
    ); -- port clause trailing comment
    end entity e; -- entity trailing comment

    -- isolated comment
