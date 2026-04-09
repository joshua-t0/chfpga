***********************
VHDL Coding Conventions
***********************

=============
VHDL standard
=============

The source code for `chfpga` is written in VHDL2008. Although the original code was written for VHDL93, the modules have gradually been using VHDL2008 as it significantly simplifies the code. We have not attempted to preserve VHDL93 compatibility.

All files in the project must be tagged to use the VHDL2008 file type, otherwise the synthesizer will fail to compile many files. The default file type of files added to a project is "VHDL", meaning VHDL93. It must explicitely be changed to VHDL2008.


=============
Documentation
=============

VHDL documentation is generated using Sphinx using a home-made VHDL domain extension.

We use a hybrid documentation methodology, where short descriptions and memory map tables that are tightly coupled to the code is placed in the VHDL source files as comment blocks, but longer descriptions on principle of operations and graphics are written in standalone Restructuredtext files.

We use Sphinx and a custom-made Sphinx extension to semi-automatically fetch the documentation form the VHDL source files and combine them in the RestructuredText files using special directives.   The user is responsible for manually creating a master file for each module (we don't have a autodoc-like capability).

Sphinx is used to compile the documentation into stand-alone HTML files. A Bitbucket continuous integration pipeline script automatically builds and publishes the documentation whenver select branches are pushed to the repository. Howver, local building is preferred when working on documentation so almost-instantaneous feedback can be acheived.

Module RST documentation guidelines
-----------------------------------

Each VHDL Entity should have a corresponding RST that documents it. Its goal is not to explain what can be obviously gleaned by looking at the code (or asking an AI to do it), but rather to describe how a user can use the module (e.g. parameters and interface) and describe any non-obvious design techniques, constraints and tradeoffs that led to this particular design.

Modules typically use vhdl:entity as a default role (backticks), except for math-heavy modules where the default role is math.  

    .. default-role:: vhdl:entity

We typically favor the following sections:

1. **Overview** — Quick summary of that the entity does.
2. **Entity documentation** —  Automatically generated API description table (using the ``autoentity`` directive)::


    .. parse:: hdl/...
    .. autoentity:: <entity_name>

3. **Parameters** — Generics/parameters used by the entity. The parameters may be grouped by function, and the amount of details should normally be sufficient to allow the user to configure the module as needed.  This should be more detailed than the "autoentity" description. Very complex parameter usage can be deferred to the "implementation details" section.

4. **Interface** — Description of the entity's ports. Here agin, descriptions can be made by group of signals, with sufficient details to allow the module to be used correctly. The clock domain on which signals and buses operate should be clear. The data format of vectors should be described. The synchronous or asynchronous nature of reset inputs should be stated.

5. **Implementation details** — Optional subsections such as **Architecture**, **Clocking**, reset/CDC, timing/placement, FIFO or primitive choices, mode-switch hazards, etc. 

6. **Memory map** — For blocks with BSB registers,  use ``.. include-docs::`` to automatically import the register map from the module's source code documentation.  Optional **Registers** subsection(s) can be added to describe register groups or bring-up workflow.


**Wrapper / platform pages** (e.g. ``chfpga``, board tops) should stress board-specific hardware and related lockic and clocking structure. Description of placement and timing constraints should be provided.






Sphinx documentation conventions
--------------------------------


http://documentation-style-guide-sphinx.readthedocs.io/en/latest/style-guide.html

* Header levels:

    - #_#, *_*, ===, ---, ^^^, """
    - Index doc - main title: no header
    - Index sections (contents, Quick links): ####_####
    - Main sections: ***_***

The `toctree` directive includes a RST file one level down from the current level, i.e. the top heading level of that document becomes a sub-heading in the master document, independent from the heading style (``**``, ``===`` etc.).  The heading levels of RST documents included `toctree` are independent from each other.

Content included with the `include` directive is as if it was typed in that document, so this is essentially a single RST document in which case the heading levels must be consistent.)




Building the documentation
--------------------------

Activate the Python environment in which the `pychfpga` docuemntation tools were installed::

    source <my_venv_path>/bin/activate

If you don't have an environment, create one with::

    python39 -m venv <my_venv_path>
    source <my_venv_path>/bin/activate
    cd chfpga/docs/
    pip install -e .

To build the documentation:

    make html

To automatically build the documentation and refresh open browser pages when a file is changed::

    ./automake.sh


==============================
Running the code style checker
==============================


We check the consistency of our code (indentation, case, etc.) using the python program `vsg` (VHDL Style Guide).
We use a configuration file (``vsg_rules.yaml``) that defines the rules that match our style.

Make sure that the python environent is activated (see section above) so we can access ``vsg``.

First ``cd`` in the source folder::

    cd chfpga/hdl

To process a single file::

    vsg -c vsg_rules.yaml -f chfpga_crs.vhd

To process all files specified in vsg_filed.yaml::

    vsg -c vsg_rules.yaml vsg_files.yaml


The checker runs in various phases. Once a phase is fixed (or has only warnings), the batch of errors from the next phase are shown etc.


===============
Version control
===============

Version control tool
--------------------

We use ``git`` to version-control the source files. ``LFS`` us used to store files that do not easily *diff* or are generally too big.
``git-lfs`` must therefore be installed and initialized before code is cloned, committed and pushed.

Branch names
------------

In general, branch names are not authoritative; tags are used instead to identify production releases. Having a flexible way of quickly indentifying pre-production versions during the various phases of firmware maturity is still very useful.

For pre-production version, we use the following rules:

- Alpha branches: Code created/modified by en author, with minimal testing.
  - Work in progress: <author_initials>/dev, or <autor_initials>/<feature _name>:  Some platforms may compile, some may not. Only the author knows.
  - Alpha release: <author_initials>/<platform>_{config}: usually points to a "build" commit containing a new bitstream that meets timing for that platform and configuration only. This is mostly for the allowing the author to keep track of all the code variations in a sane manner.

 
- Beta branches: develop/<platform>_<config>: The platform/config is released for testing

- Release branch: master/<platform>_<config>: The platform/config is released for production

The alpha branch methodology proved very convenient during th very active development phase of the code. The author always work on the /dev branch, but can fast-forward the /platform-config branch to the dev/branch with a simple click of some GIT GUI interface (like GitKraken) or with a simple command::

   git branch -f <platform>_<config> HEAD


Tagging convention
------------------


Commit messages convention
--------------------------

We try to standardize the names of the commits using the convention listed below:

https://gist.github.com/qoomon/5dfcdf8eec66a051ecd85625518cfd13

The format is::

    <type>(<optional scope>): <description>
    empty separator line
    <optional body>
    empty separator line
    <optional footer>


Of all the standard commit types proposed above, we typically use:

- 'feat': Added or removed functionalities (memory-mapped registers, new signal processing steps)
- 'fix': Fix to an existing feature. Could be code change to help meet timing.
- 'docs': Changes to the stand-alone documentation files (/docs folder), or stricly on docstrings in the source code.
- 'style': Commits that address code style (e.g., white-space, formatting, missing semi-colons) and do not affect application behavior
- 'build': project files, pipelines, git configuration files
- 'test': testbenches

``<scope>`` is typically either a VHDL module (e.g. 'SCALER') or platform name (e.g. 'CRS').



============================
Filenames and file structure
============================

The source code is located in the ``hdl`` folder, separate from the Xilinx project folder since the same HDL is used in multiple projects. This makes version control easier as well. Subfolders are used to group related files.

We most exclusively use one file per entity, which contains the entity and
architecture (we never have used more than one architecture per entity)

One package file defines all the helper functions, types, system-wide
constants and black-box component declarations for all the project. This file
is used in almost all modules. This has the disadvantage that if this file is
touched, all modules that depends on it (e.g. ``CHAN``) need to be re-
synthesized, but that does not happen often.

Another package file is used to define components representing Xilinx cores.


=================
VHDL coding style
=================

Line width
----------

The maximum line length is 256 characters, enforced as a Warning by the VSG style checker (rule ``length_001``). While this is quite generous, shorter lines are preferred for readability, especially when viewing code in web-based viewers (like BitBucket, GitHub) or in diff tools. Ideally, lines should not exceed 100 characters, but that is enforced only very loosely.  On a 16:9 monitor, editors can 
easily show 160 characters per line with a decent font size. The line length mostly matter if the code is to be viewed on 
web-based viewers (like BitBucket, GitHub), or in diff tools, so it is still worth the trouble to try and mainting a decent 
line length.

We avoided breaking down long lines of code in multiple lines if that made the code harder to read.  But maybe that is just laziness.

We certainly didn't refrain from putting comments at the end because of the line length target. Having comments is more important that having good formatting. The comment cna be modes to the previous line in a cleanup phase.

Spacing rules
-------------

The following spacing rules are enforced by VSG:

- **No space between label and colon**: This applies to signals, ports, constants, generics, instantiations, generates, attributes, and processes. 
- **No space between process and opening parenthesis**: Use ``process(all)`` not ``process (all)``.
- **Function spacing**: At most one space between 'function', the function name, and the opening parenthesis. 

File Headers
------------

All the VHDL files have a header, usually inderted by Xilinx when the module was originally created.
We tried to keep those up to date.

We used to keep an history of changes in the header, but the habit was dropped when we started to use git for code version management. However, we sometimes still felt compelled to put a history entry if big changes in the code were made.



Comments
--------

Well, of course, comments are important. Especially on a somewhat cryptic language like VHDL. We tried to comment the following:

   Entities: We tried to put blocks of comments before the entity to describe what it does (but how how it does it: that is the architecture)
   Architectures:
   Procedures:
   Assignments:
   State machine/case statements:


Indentation and alignment
-------------------------

The code tries to follow the smart tabbing convention, where:

 *  tabs are used *only* at the beginning of a line to indicate hierarchy levels
 *  any subsequent alignemnt is made with exclusively with spaces.

This approach is convenient because it makes typing the code faster (almost every line is indented) and is not impacted much if the editor tab size in changed.

Note that architecture indentation is disabled in VSG to save horizontal space, as most of the file content would be indented with little clarity benefit.

**Alignment preferences** (enforced by VSG):

   - **Entity ports/generics**: Compact alignment (colons aligned, but compact spacing).

     Rule: ``entity_018``

   - **Multiline constants**: Left alignment (subsequent lines aligned with the left edge of the assignment target).

     Rule: ``constant_012``

   - **Multiline if conditions**: Left alignment with parentheses aligned (subsequent lines aligned with the left edge, and opening/closing parentheses aligned).

     Rule: ``if_009``

Note that many alignment rules are disabled for flexibility, allowing developers to choose the most readable format for specific situations.

Allowed practices
-----------------

The following practices are explicitly allowed (corresponding VSG rules are disabled):

   - **Default values on ports**: Ports may have default values.

     Rule: ``port_012``

   - **Default assignments on signals**: Signals may have default assignments (useful for simulations).

     Rule: ``signal_007``

   - **Default assignments on variables**: Variables may have default assignments.

     Rule: ``variable_007``

   - **Comments on port maps**: Comments are allowed on port maps to improve readability.

     Rule: ``port_map_010``

   - **Label-less processes**: Processes may be declared without labels.

     Rule: ``process_016``

   - **``process (all) begin`` syntax**: The ``process (all)`` syntax is allowed.

     Rules: ``process_010``, ``process_012``

   - **Entity instantiation**: Entity instantiation is preferred over component instantiation (component instantiation rule is disabled).

     Rule: ``instantiation_034``

   - **Single-line functions with parenthesis on same line**: Functions may have the opening parenthesis on the same line as the function declaration.

     Rule: ``function_019``

   - **Short aggregates on one line**: Short aggregates may be kept on a single line.

     Rule: ``variable_assignment_001``

   - **Comments in multiline variable assignments**: Comments are allowed in multiline variable assignments to clarify assignments with many signals.

     Rule: ``variable_assignment_006``

   - **No parentheses in if statements**: Parentheses around if conditions are not required.

     Rule: ``if_002``

   - **No 'is' keyword in blocks**: The 'is' keyword is not required in block statements.

     Rule: ``block_002``

Instantiation
-------------

Whenever possible, **entity instantiation** is used as opposed to **component instantiation** so we do not have to define a ``component`` for each entity we want to instantiate. We do not use the power of VHDL configurations that are made possible by components. This reduces the redundancy in the code and make it smaller, more readable and much more maintainable.

Signal and variable names
-------------------------

    - variable and signals

        - names are lowercase, with underscores to separate words. Some early Xilix example code used all uppercase signal names (probably before there was good syntax highlighting editors), and that habit was used for a long time in our code. We converted some of the code to lowercase, but you will find modules that are still in uppercase.
        - variables are suffixed by _var.
        - signals have no suffix in our code
        - Maximum 4 consecutive signals may be declared in the same statement (Warning severity).

          Rule: ``signal_015``

        - Additional prefix/suffixes

            - _int : denote an internal signal. It is often used to represent a copy of a signal that connects to an output port so the signal can be read.
            - dly, dly1, dly2... : used for a signal registered with the specific intent to create a delay
            - reg, reg1, reg2... : indigcte registered version of a signal
            - clkxxx:  for clocks, where xxx is the frequency in MHz
            - rst or reset: for resets. We do not have prefix/suffix to distinguish sync/async reset.
            - AXI bus ports: prefixed with m_axis_function_item for master port, s_axis_function_item for slave port. Wehre function is the function of the bus, and item is tvalid, tdata, tuser, tlast, tready.
            - AXI buses between modules: no m or s prefix.

Case conventions
----------------

The following case conventions are enforced by VSG:

**Port names**: Must be lowercase (Error severity). Examples: ``clk``, ``data_in``, ``reset_n``.

   Rules: ``port_010``, ``port_map_002``

**Architecture names**: Must be lowercase (Error severity). Examples: ``rtl``, ``behavioral``.

   Rules: ``architecture_013``, ``architecture_011``

**Constants**: Must be uppercase with underscores. Examples: ``MAX_VALUE``, ``DEFAULT_WIDTH``.

   Rule: ``constant_004``

**Generics**: Must be uppercase with underscores. Examples: ``DATA_WIDTH``, ``ADDR_WIDTH``.

   Rules: ``generic_007``, ``generic_map_002``

**Entities**: Case is flexible (upper_or_lower). Examples: ``MyEntity``, ``my_entity``, ``MY_ENTITY`` are all acceptable.

   Rules: ``entity_008``, ``entity_012``, ``architecture_014``, ``instantiation_028``

**Instance names**: Case is flexible (upper_or_lower). Examples: ``inst_my_module``, ``InstMyModule``.

   Rule: ``instantiation_009``

**Attributes**: Must be uppercase. Examples: ``KEEP``, ``ASYNC_REG``.

   Rule: ``attribute_500``

**Enumeration elements**: Must be uppercase. Examples: ``IDLE``, ``RUNNING``, ``DONE``.

   Rule: ``type_500``

**USE clause ALL**: Must be uppercase. Example: ``use IEEE.STD_LOGIC_1164.ALL;``.

   Rule: ``use_clause_503``

**Bit string literals**: Must be uppercase. Examples: ``"1010"``, ``X"A5"``.

   Rule: ``bit_string_literal_500``

    - generics and constants:

        - All uppercase with underscores
        - We did not use prefix or suffix to distinguish between constants and generics.

    - entities and architectures:

        - Case is flexible (upper_or_lower), though uppercase with underscores is common
        - We did not use prefix or suffix to distinguish between constants and generics.

    - labels

        - generate (if-generate, for-generate)

            - Case and suffixing is not consistent in the current code. We tried to keep the name short because it becomes part of the netlist name of all the modules within the generate block, and very long names makes it hard to debug the netlist and implementation.
            - We tend toward all lowercase with underscores, with _gen suffix.

        - processes:

            - All lowercase with underscores with the '_proc' suffix

Blank lines
-----------

The following blank line rules are enforced by VSG:

**General rule**: Up to 2 consecutive blank lines are allowed.

   Rule: ``whitespace_200``

**No blank line below**: The following keywords must not be followed by a blank line:

   - ``begin`` (in processes)
   - ``if``
   - ``when`` (in case statements)
   - ``end if``

   Rules: ``process_022``, ``if_006``, ``case_200``, ``if_030``

**Require blank line below**: ``end case`` must be followed by a blank line.

   Rule: ``case_010``

**No blank line before**: ``end process`` must not be preceded by a blank line.

   Rule: ``process_023``

**Allow blank lines before** (with comments allowed): The following constructs may have blank lines before them (comments are also allowed):

   - ``entity``
   - ``architecture``
   - ``type``
   - ``generate``
   - ``instantiation``

   Rules: ``entity_003``, ``architecture_003``, ``type_010``, ``generate_004``, ``instantiation_019``

Array indexing
--------------

Arrays that represent numeric values are indexed with **downto**, i.e. the leftmost bit is the MSB.
Arrays representing a collection of objects are indexed with **to**.

Arrays are always indexed from zero unless very special exceptions.


Packages
--------



References
----------


svn.ohwr.org/white-rabbit/trunk/documentation/management/VHDLcoding.pdf

