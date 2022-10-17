VHDL Coding Conventions
***********************

VHDL Editor
-----------

A good text editor with VHDL syntax highlighting is recommended.

The internal Vivado text editor is not bad and is getting better as Vivado evolves. It does basic syntax highlighting, it does not offer much coding help. However, Vivado can be configured to use any external editor.


The chFPGA code was written mainly using Sublime Text (https://www.sublimetext.com/), which is free, works on any platform, and has a large ecosystem of plug-ins that are useful for VHDL source file and documentation editing. Sublime Text significant increases productivity. One of its best feature is the multi-cursor which allows for editing multiple lines at once, which happens a lot when working on port assignments in VHDL. The following Sublime Text packages were used:

   * VHDL: provides syntax highlighting of VHDL code
   * Alignment: (:kbd:`control-alt-a`): allows block of code to be aligned to ``<=``, ``:`` or other key characters with a single keystroke, making the code easier to read.
   * WrapPlus (:kbd:`alt-q`): nicely reformat comment blocks, even in in VHDL
   * TrailingSpaces: removes any trailing spaces when the file is saved

Sublime Text also has modules for writing and building reStructeredText, LaTeX documents, Vivado TCL files etc. This all-in-one character made it our daily editor.

What Sublime Text lacks is a VHDL linting tool, which would interactively show us syntax errors, unused variables etc. We have not found good, free VHDL linting tools. That would be very useful.
Sigasi offer a non-free specialized HDL editor that seems very good and offers many advanced features (like linting), but we have not tried it out.

Line width
----------

Ideally, lines should not exceed 100 characters, but that is enforced only very loosely.  On a 16:9 monitor, editors can easily show 160 characters per line with a decent font size. The line length mostly matter if the code is to be viewed on web-based viewers (like BitBucket, GitHub), or in diff tools, so it is still worth the trouble to try and mainting a decent line length.

We avoided breaking down long lines of code in multiple lines if that made the code harder to read.  But maybe that is just lazyness.

We certainly didn't refrain from putting comments at the end because of the line length target. Having comments is more important that having good formatting. The comment cna be modes to the previous line in a cleanup phase.

File Headers
------------

All the VHDL files have a header, usually inderted by Xilinx when the module was originally created.
We tried to keep those up to date.

We used to keep an history of changes in the header, but the habit was dropped when we started to use git for code version management. However, we sometimes still felt compelled to put a history entry if big changes in the code were made.

Filenames and file structure
----------------------------

The source code is located in the ``hdl`` folder, separate from the Xilinx project folder since the same HDL is used in multiple projects. This makes version control easier as well. Subfolders are used to group related files.

We most exclusively use one file per entity, which contains the entity and
architecture (we never have used more than one architecture per entity)

One package file defines all the helper functions, types, system-wide
constants and black-box component declarations for all the project. This file
is used in almost all modules. This has the disadvantage that if this file is
touched, all modules that depends on it (e.g. ``CHAN``) need to be re-
synthesized, but that does not happen often.

Another package file is used to define components representing Xilinx cores.


Comments
--------

Well, of course, comments are important. Especially on a somewhat cryptic language like VHDL. We tried to comment the following:

   Entities: We tried to put blocks of comments before the entity to describe what it does (but how how it does it: that is the architecture)
   Architectures:
   Procedures:
   Assignments:
   State machine/case statements:

Auto-documentation tools
------------------------

We used ``doxygen`` to automatically generate documentation based on the content of the source files. For this reason, comments in the code follow the doxygen convension.
The automatically-generated code is generally limited in scope to each module.

We used Sphinx (which was used to generate this document) to write high-level documentation, since it is already used extensively to document the Python code that operates the system.


Indentation and alignment
-------------------------

The code tries to follow the smart tabbing convention, where:

 *  tabs are used *only* at the beginning of a line to indicate hierarchy levels
 *  any subsequent alignemnt is made with exclusively with spaces.

This approach is convenient because it makes typing the code faster (almost every line is indented) and is not impacted much if the editor tab size in changed.

Instantiation
-------------

Whenever possible, **entity instantiation** is used as opposed to **component instantiation** so we do not have to define a ``component`` for each entity we want to instantiate. We do not use the power of VHDL configurations that are made possible by components. This reduces the redundancy in the code and make it smaller, more readable and much more maintainable.

Signal and variable names
-------------------------

    - variable and signals

        - names are lowercase, with underscores to separate words. Some early Xilix example code used all uppercase signal names (probably before there was good syntax highlighting editors), and that habit was used for a long time in our code. We converted some of the code to lowercase, but you will find modules that are still in uppercase.
        - variables are suffixed by _var.
        - signals have no suffix in our code
        - Additional prefix/suffixes

            - _int : denote an internal signal. It is often used to represent a copy of a signal that connects to an output port so the signal can be read.
            - dly, dly1, dly2... : used for a signal registered with the specific intent to create a delay
            - reg, reg1, reg2... : indigcte registered version of a signal
            - clkxxx:  for clocks, where xxx is the frequency in MHz
            - rst or reset: for resets. We do not have prefix/suffix to distinguish sync/async reset.
            - AXI bus ports: prefixed with m_axis_function_item for master port, s_axis_function_item for slave port. Wehre function is the function of the bus, and item is tvalid, tdata, tuser, tlast, tready.
            - AXI buses between modules: no m or s prefix.

    - generics and constants:

        - All uppercase with underscores
        - We did not use prefix or suffix to distinguish between constants and generics.

    - entities and architectures:

        - All uppercase with underscores
        - We did not use prefix or suffix to distinguish between constants and generics.

    - labels

        - generate (if-generate, for-generate)

            - Case and suffixing is not consistent in the current code. We tried to keep the name short because it becomes part of the netlist name of all the modules within the generate block, and very long names makes it hard to debug the netlist and implementation.
            - We tend toward all lowercase with underscores, with _gen suffix.

        - processes:

            - All lowercase with underscores with the '_proc' suffix



Array indexing
--------------

Arrays that represent numeric values (like std_logic_vector, unsigned, signed) are indexed with **downto**, i.e. the leftmost bit is the MSB.
Arrays representing a collection of objects are indexed with **to**.

Arrays are always indexed from index zero.

Packages
--------



References
----------


svn.ohwr.org/white-rabbit/trunk/documentation/management/VHDLcoding.pdf

