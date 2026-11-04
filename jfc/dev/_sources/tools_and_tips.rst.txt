.. title:: Tools and Tips

**************
Tools and Tips
**************

VHDL Editor
===========

A good text editor with VHDL syntax highlighting is recommended. Here are a few we have used:

Editor selection
----------------

Vivado can be configured to use any external editor.


Vivado integrated editor
------------------------

The internal Vivado text editor is not bad. It lacks advanced editing functions (column editor, multi-cursor, code alignment) but it has a live checker that will highlight  in real time not only syntax errors, but undefined signals/variables and type/dimensions mismatches. This live checking is very useful and allow reducing the number of synthesis-error-fix loops.

We often do large edits in a good editor, nd then re-open the file in the Vinado editor to check for errors before launching systhesis.


Sublime Text
------------

The chFPGA code was written mainly using Sublime Text (https://www.sublimetext.com/), which is free, works on any platform, and has a large ecosystem of plug-ins that are useful for VHDL source file and documentation editing. Sublime Text significant increases productivity. The interface is clean, minimalist and snappy. One of its best feature is the multi-cursor which allows for editing multiple lines at once, which happens a lot when working on port assignments in VHDL. The following Sublime Text packages were used:

   * VHDL: provides syntax highlighting of VHDL code
   * Alignment: (:kbd:`control-alt-a`): allows block of code to be aligned to ``<=``, ``:`` or other key characters with a single keystroke, making the code easier to read.
   * WrapPlus (:kbd:`alt-q`): nicely reformat comment blocks, even in in VHDL
   * TrailingSpaces: removes any trailing spaces when the file is saved

Sublime Text also has modules for writing and building reStructeredText, LaTeX documents, Vivado TCL files etc. This all-in-one character made it our daily editor.

What Sublime Text lacks is a VHDL linting tool, which would interactively show us syntax errors, unused variables etc. We have not found good, free VHDL linting tools. That would be very useful. VSCode has an edge on this.

Sigasi offer a non-free specialized HDL editor that seems very good and offers many advanced features (like linting), but we have not tried it out.

Visual Studio Code
------------------

It is free and open source. It has a large ecosystem of extensions and plug-ins and multicursor editing. It is a good alternative to Sublime Text, but is less snappy and the UI is a bit overloaded and distracting.

TherosHDL extension is a good VHDL syntax highlighting and linting tool. It is a bit complicated to set it up to get all the features, but it still does great out of the box.



Cursor
------

Cursor is a VSCode IDE with focus on tight AI integration. We started to use it in 2025, and the AI agent was great for restructuring the documentation will keeping all the references synchronized. The UI is a bit overloaded and laggy, but it's worth it for the time saving.






Git
===

GIT LFS
-------

We use git LFT to store large files, including:

- bitstream files
- drawings and images (SVG, PNG etc)
- Simulation waveform configurations



Online repository
-----------------

We currently use Bitbucket to store our repository.


Git GUI
-------

Using a GUI for managing git repositories is convenient and can be useful for simple tasks. A good tool allows to see side-by-side diffs and make live rorrections and partial line hor hunk staging to we can make more significant commits.


We have used many tools over the years. SmartGit was great until it required payment. GitKraken is our curren t preferred tool, but we still use command lines for push/pull from private repos and for specific commands.



SSH
===


SSH keys.
	- Create keypair for user/computer/repo
	- Instal .pub in bitbucket
	- copy private in /progam files (86)/git/.ssh

The key will be used automatically with SmartGit:




VHDL Documentation tools
========================

Requirements
------------

We have been looking at the best approach to document this VHDL project with the following objective:

- We want to avoid documentation duplication, i.e. have good docs in the source code but not have to duplicate it in the manuals
- We want the HDL code to be self-documented as much as possible without drowning it in implementation and philosophical details, but we want to put these details somewhere
- We want to include figures (block diagram) as those can often convey the most information with the minimal reader effort
- We want for the documentation to be generated in HTML pages we can put on the lab server
- We want to use  standard tools and language to generate the documentation.
- We want the server (a linux virtual machine in the cloud) to be able to regenerate the docs whenever the source code has been pushed to its git repository


Do we want to duplicate docygen fully auto-documenting functionality into Sphinx? Sph

In other words, we might not want fully automated documentation.

We probably prefer to manually create the documentation structure (e.g. manually create a page for each key module), but then use tools that import the documentation from the HDL files where we need it along additional prose and figures. This is what we call semi-automatic documentation.


Tool selection
--------------

We have considered the following tools:

- doxygen: This is the tool we originally used to create a detailed documentation of the whole HDL project, and it does a pretty decent job at it. Most of the HDL project has originally been commented using the doxygen syntax. There might be traces of this left in the code.

   In some ways, doxygen output is a bit too detailed. Many HDL modules are just plumbing, and lots of signals are just used for interconnecting instances. Although our firmware uses a large numbe rof gates, it is relatively simple, consisting or a large number of instances of a small number of modules. doxygen also uses the 'C' paradigm (classes, modules) and tried to fit the VHDL model, which makes the navigation awkward.

- breathe: (https://breathe.readthedocs.io/en/latest/) provides a bridge between the Sphinx and Doxygen documentation systems. Docygen is used to generate the documentation in xml, the breathe gives access to it.

That looked nice, but we'd prefer not to use doxygen at all since doxygen is a bit overkill.

- Sphinx: This is the platform used to document all the other aspects of the project in which the HDL is used. We were wondering if there was a way to reasonably document the HDL project using Sphinx. That is, we'd like the top level structure of the documentation to be in Sphinx, and be able to pull  HDL self-documentation into Sphinx. Ideally, we would not need doxygen at all.

- vhdocl: (https://www.volkerschatz.com/hardware/vhdocl.html). This is a newer tool that did not exist when we chose our documentation tool. We have not investigated it yet, but we mention it here in case it might fit other people's needs.

We decided to go with Sphinx since we have invested time learning RestructuredText, but there is the challenge of making Sphinx understand VHDL.

Sphinx is good at autodocumenting Python code, and the autodoc feature is extensible, but there was no official Sphinx autodoc module that could understand VHDL projects at the time of choosing a tool. We would have to write our own extension if we wanted to go that way.

But we have to be careful. First, just re-doing what doxygen does well is wasted effort. Second, fully auto-documenting might be overkill drown the key information in unnecessary details . We want to give enough context so the user can make general structural changes to the code, and no more. Will assume the user can figure out the details by looking at the code (or have AI summarize it). There are often enough comments in the code to allor a human or AI to figure it out. Our docs will focus on  figures, block diagrams and conceptual information that does not have its place in the HDL source code.


VHDL Domain extensions for Sphinx
---------------------------------




Full Python VHDL parsers
------------------------

Sphinx is typically used to document Python code, but can also support other languages with language extensions called Domains. We need to  create use the home-made vhdl_sphinx_domain extension to parse the VHDL source file and automatically include documentation found in the source files themselves.

An autodocumented extension would need a python VHDL parser. Here are possible resources that could be used:

	- vhdl_analyzer (https://bitbucket.org/AngelEzquerra/vhdl_analyzer) generates graphs from VHDL. Maybe the parser can be used to extract structure and documentation. Its parser is minimalist but probably covers all the constructs we need.

	- https://github.com/arunenigma/Python-based-VHDL-Parser-for-hierarchy-extraction/blob/master/project.py  Another parser that might provide code to extract VHDL

Or we write our own from scratch.

In any case, this seems to involve significant programming effort that might end up to be overkill anyway.

Documentation extractor
-----------------------

If we decide to manually create the overall structure of the documentation, we do not need code that  understand the VHDL code hierarchy to extract the documentation blocks. And life becomes much easier. All is needed is look for the file for simple keywords or labels that already exist or that we put in intentionally.

Since our HDL project was documented using doxygen, block comments use ''@ '' directives, are contiguous, ans always precede the documented element (entity, architecture, process). It is therefore easy to scan the file and extract specific blocks of comments.

Sphinx already provide directives that allow parts of hdl to be embedded in documents. For example, the following embeds a section of the VHDL code and even syntax-highlighut it properly for VHDL ::

	.. literalinclude:: ../../hdl/chfpga.vhd
	    :language: vhdl
	    :start-after: --startLiteralInclude
	    :end-before: --stopLiteralInclude

This is great for embedding snippets of code. Comment blocks could be embedded the same way, but there are two problems:

	1) every line is preceded by the comment directive '--' (or then docygen-specific '--!'), and
	2) the comments (and tables) are in the markdown syntax, and it would be nice for the rendered documentation to include all the  formatting that was conveyed in markdown.

To solve 1) , it is easy to create a Sphinx directive that does the same as ``litteralinclude`` but removes the preceding comment mark, but we are still stuck with the problem that the resulting text is markdown.

One option is to convert all the documentation to RestructuredText and abandon Doxygen compatibility.

The markdown comments could be parsed as restructuredText, and most of the markdown features that we use (emphasis and lists) would work. But not tables. And tables are important.

Comment blocks could also be imported verbatim and still look nice (that is the point of markdown). Tables then look good, but then we don't have the nice formatting of the preceding and following text.

So, since we can write an extension that extract comments from VHDL, can we have it convert the markdown into native Sphinx documentation elements?

Sphinx is based on docutils, which read restructuredText and convert it into a doctree (a hierarchical list of nodes defining section, text, lists, emphasis, tables etc). docutils can then render the doctree in any format (html, latex).

All we need is a parser that convert markdown into a list of docutil nodes. Ideally, it would be a docutil Parser object.

One thing: tables are not part of the markdown syntax. Tables have been added by third parties (github, etc) and are semi-standard.

	- python-markdown (markdown): converts to an elementTree of HTML elements, which is converted to an HTML string. Has extensions to process tables. Has hooks to its internal parser.

  - https://github.com/tk0miya/sphinxcontrib-markdown/blob/master/sphinxcontrib/markdown.py . markdown docutil Parser. Uses python-markdown. Implements a Serializer that take the ElementTree elements and convert then into doctree elements. No specific conversion is provided for tables.

  - CommonMark-py (commonmark) (https://github.com/rtfd/CommonMark-py). Follows markdown reference doc. COnverts to abstract syntax tree (ast). Tables are not supported.

  - recommonmark  Basec on commonmark-py. Converts markdown into doctree. But tables are not supported and there are no extensions for it yet.

  - mistune: Supports tables. Blocks are converted into a list of dict entries, but inline is converted straight to html tags. No real tap into inline elements.

  - remarkdown (https://github.com/sgenoud/remarkdown) a markdown parser for docutils. All native, does not use other packeges, uses parsley . Simple.  But does not support tables.

  - pandoc: external library, with Python bindings. We want to avoid external libraries.

The only markdown interpreters with table support are python-markdown (generates ElementTree and HTML) and mistune (generates HTML). Modifying those to generate table-supported doctrees would require some work.

The alternative is to use python-markdown or mistune to generate HTML and embed the HTML directly into a raw doctree node. This would work only for HTML documentation.

We didn't find obvious packages for converting HTML back into doctree.


VHDL auto-documentation
-----------------------



Our approach fror parsing VHDL was to take vhdl_analyzer and modify it. We wanted a stand-alone, small, single-module parser that does not have non-standard dependencies beyond what accompanies Sphinx for easy install on servers.

Once we have that, we can have a directive that invokes the parser on the target files (or maybe have that done in the config file), and have directive that display the data such as vhdl:autoentity <entity_name>, etc.

Modifying the parser was an interesting project, and turned out to take longer than expected (3-4 days), in part because we ended up refactoring and eventually change the design philosophy compared to vhdl-analyzer. We now use a single object to represent the parsed data, and various methods parse various language constructs. We usually use regexes to identify the constructs and extract interesting fields, but we short-circuit the parsing and jump directly to the closing brace or keyword when there is no more useful information in a block. We just want the name of the main constructs (entities, architectures, instances, processes) that require documentation, and we want their associated doctrings.


References:
~~~~~~~~~~~


Someone managed to create a Sphinx autodoc module:
http://stackoverflow.com/questions/39020530/is-it-possible-to-extend-sphinx-automodule-to-domains-other-than-python


VHDL parsers in Python

python-parsing: uses an object-oriented description of the language lexical elements
parcimonious: faster implementation, based on text file definition of the language
vhdl_analyzer (https://bitbucket.org/AngelEzquerra/vhdl_analyzer): regex-based structural parsing. Does not parse comments and dosctrings.
PyPEG: other parser, uses objects. some VHDL PEG files can be found for other PEG parsers, syntax would have to be changed.
VHDL syntax summary in one web page: https://tams.informatik.uni-hamburg.de/vhdl/tools/grammar/vhdl93-bnf.html#choices


pygments comes with a VHDL lexer, which slices down source code in a flat list of tokens (keywords, comments arguments). So a lot of the hard work of chopping the language into bits is done, but that does not give us a hierarchical view of the main elements, or at least an association between elements and theyr key parameters and comments.

http://pygments.org/docs/lexerdevelopment/ explains how to develop a lexer. We already have one, but it shows how the internals work.



A summary of markdown implementations is here: https://github.com/markdown/markdown.github.com/wiki/Implementations, http://lepture.com/en/2014/markdown-parsers-in-python

Commonalities between md and rst:
https://gist.github.com/dupuy/1855764
http://www.unexpected-vortices.com/doc-notes/markdown-and-rest-compared.html

Discussion on why markdown-python does not use docutils
https://github.com/waylan/Python-Markdown/issues/420

List of Python parsers:
https://wiki.python.org/moin/LanguageParsing

parcimonious: https://github.com/erikrose/parsimonious

VHDL Language Reference Manual: http://www.dacya.ucm.es/dani/manual.pdf

VHDL PEG file: https://github.com/philtomson/vhdl_parser/blob/master/aurochs/vhdl.peg

Create a new domain for Sphinx:
http://samprocter.com/2014/06/documenting-a-language-using-a-custom-sphinx-domain-and-pygments-lexer/





Common Markim - Sphinx

https://gist.github.com/dupuy/1855764




Documentation
=============

This documentation is generated using Sphinx, since the firmware control software and the telescope operation software is all written in Python and is therefore also documentd in Sphinx. We used to use Doxygen, but preferred not to have an additional tool, and wanted to have more flexibility in structuring the documentation and extending the source code with figures, variable references etc. And since we invested time learning RestucturedText, we preferred to avoid having the documenter to learn Markdown as well.

The tricky part is to document VHDL code. Sphinx does not natively support extracting docs from the VHDL language. We try to put lots of comments in the VHDL source code and didn't want to be led away from that good practice. We ended up writing our own Sphinx Domain extension, ``VHDLDomain``, which includes our own a full VHDL language parser that allows us to to extract the main VHDL elements from the code and extract the accompanying *docstrings*, and provide a functionality akin to the Sphinx ``autodoc`` module, except for VHDL.


Python packages

- parsimonious 0.7.0 (pip install parsimonious). Used to parse VHDL code to autodocument
- sphinx 1.5.5-1: Documentation builder

	* sphinx-rtd-theme 0.2.4-1 (seems to come as a sphinx dependancy)
	* pygments (sphinx dependency)


Other auto-documentation tools
------------------------------

Long time ago we used ``doxygen`` to automatically generate documentation based on the content of the source files. For this reason, you might still find some Doxygen-style comments in the source code.

We liked that the tool automatically generated hiearchy diagrams and hyperlinked entities/signals etc. But adding custom information to the pages was a bit tedious.

In the end, we favored Restructuredtext over Markdown as a documentation format because of its ability to add extensions and language-specific roles and directives. We also favored Sphinx because we already used it to document the closely inter-related Python package ``pychfpga`` and we try to minimize the number of tools and text format that we need to use.



Vivado
======


Compiling issues
----------------

Abnormal program termination (EXCEPTION_ACCESS_VIOLATION)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Vivado 2016.4 will sometimes (often) crash after routing during the final Methodology check, after the routed database was created and saved. The implementation log (log tab, implementation sub-tab) will end with::

	INFO: [DRC 23-133] Running Methodology with 8 threads
	Abnormal program termination (EXCEPTION_ACCESS_VIOLATION)
	Please check 'C:/Users/jfcliche/workspace/CHIME/chfpgalite/xilinx_projects/CHFPGA_MGK7MB_REV2/CHFPGA_MGK7MB_REV2.runs/impl_Rev2/hs_err_pid5248.log' for details


In this case, to complete the bitstream generation:
	- kill the zombie Vivado process, which is locking files such as logs and will prevent other Vivado steps to execute
	- In the implementation folder, create a ".route_design.end.rst" file to make Vivado beleive implementation is completed (copy ".route_design.begin.rst" and rename it)
	- in the GUI, click generate Bitstream

Notes:
	- timing summary was not generated since Vivado crashed before it could generate it.
	- opening the implemented design after this trick make Vivado crash, maybe because some expected files and reports are missing. Restarting Vivado does not help.

Alternative:
	- Open routed checkpoint in Vivado (file -> Open Checkpoint), under the folder:

			chfpgalite/xilinx_projects/CHFPGA_MGK7MB_REV2/CHFPGA_MGK7MB_REV2.runs/impl_Rev2/chFPGA_MGK7MB_Rev2_routed.dcp

	- In the tcl console, cd to the implementation dir. The name of the folder can be cut-and-pasted from messages in the TCL   console window. e.g.::

		cd ...

	- Generate bitstream with the following command::

		write_bitstream -force -no_partial_bitfile CHFPGA_MGK7MB_REV2.bit

Missing CHAN_ooc.xdc
~~~~~~~~~~~~~~~~~~~~

This file is probably created when CHAN was made an out-of-context module with a stub. In any case, the file is all commented out, so we don't need it. To fix, go in project manager Source window, library tab, and delete the reference to the file (it will be in red) under ``Design Sources -> Block Sources -> XDC``

Other tips
~~~~~~~~~~

- Unset CHAN as an out-of-context module, and re-set it again. You don't want a stub file. One is included in ``top chfpga_package.vhd``.
- Reset and re-generate IP Sources.
- Sometimes the IP references gets confused in the CHAN Module.  It seems normal that the same IP appears twice (the IP related to the control system is used both inside and outside the CHAN module). In that case, problems are solved by unsetting CHAN as an OOC module, *then* regenerating the cores, and then set again CHAN as OOC module.


