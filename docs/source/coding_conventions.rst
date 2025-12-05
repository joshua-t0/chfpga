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

We use a hybrid document methodology, where short descriptions and memory map tables that are tightly coupled to the code is placed in the VHDL source files as comment blocks, but longer descriptions on principle of operations and graphics are written in standalone Restructuredtext files.

We use Sphinx and a custom-made Sphinx extension to semi-automatically fetch the documentation form the VHDL source files and combine them in the RestructuredText files using special directives.   The user is responsible for manually creating a master file for each module (we don't have a autodoc-like capability).

Sphinx is used to compile the documentation into stand-alone HTML files. A Bitbucket continuous integration pipeline script automatically builds and publishes the documentation whenver select branches are pushed to the repository. Howver, local building is preferred when working on documentation so almost-instantaneous feedback can be acheived.







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

Commit names
------------

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

Ideally, lines should not exceed 100 characters, but that is enforced only very loosely.  On a 16:9 monitor, editors can easily show 160 characters per line with a decent font size. The line length mostly matter if the code is to be viewed on web-based viewers (like BitBucket, GitHub), or in diff tools, so it is still worth the trouble to try and mainting a decent line length.

We avoided breaking down long lines of code in multiple lines if that made the code harder to read.  But maybe that is just lazyness.

We certainly didn't refrain from putting comments at the end because of the line length target. Having comments is more important that having good formatting. The comment cna be modes to the previous line in a cleanup phase.

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

Arrays that represent numeric values are indexed with **downto**, i.e. the leftmost bit is the MSB.
Arrays representing a collection of objects are indexed with **to**.

Arrays are always indexed from zero unless very special exceptions.


Packages
--------



References
----------


svn.ohwr.org/white-rabbit/trunk/documentation/management/VHDLcoding.pdf

