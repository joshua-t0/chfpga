Tools
*****

Git
===

We use bitbucket repository.

SSH keys.
	- Create keypair for user/computer/repo
	- Instal .pub in bitbucket
	- copy private in /progam files (86)/git/.ssh

The key will be used automatically with SmartGit:


Git GUI
=======

We use SmartGit. Free for academia.
SourceTree is from Atlassian

Still use command line for a few specific things.


Vivado
======


Text Editor
===========


Documentation
=============

This documentation is generated using Sphinx, since the firmware control software and the telescope operation software is all written in Python and is therefore also documentd in Sphinx. We used to use Doxygen, but preferred not to have an additional tool, and wanted to have more flexibility in structuring the documentation and extending the source code with figures, variable references etc. And since we invested time learning RestucturedText, we preferred to avoid having the documenter to learn Markdown as well.

The tricky part is to document VHDL code. Sphinx does not natively support extracting docs from the VHDL language. We try to put lots of comments in the VHDL source code and didn't want to be led away from that good practice. We ended up writing our own Sphinx Domain extension, `VHDLDomain`, which includes our own a full VHDL language parser that allows us to to extract the main VHDL elements from the code and extract the accompanying *docstrings*, and provide a functionality akin to the Sphinx ``autodoc`` module, except for VHDL.


Python packages
- parsimonious 0.7.0 (pip install parsimonious). Used to parse VHDL code to autodocument
- sphinx 1.5.5-1: Documentation builder

	* sphinx-rtd-theme 0.2.4-1 (seems to come as a sphinx dependancy)
	* pygments (sphinx dependency)


Compiling
=========

clone repo::

	git clone ...

Make sure LFS files were pulled (not just pointers). git-lfs ls-files should show stars ('*') before the filename

Open project. A bit slow the first time, as it builds its cache (for the IP. Something appears in .cache).

Start implementation. On 2016.4, Vivado automatically generates the core products, and churns along until routing is done.

Compiling issues
================

Abnormal program termination (EXCEPTION_ACCESS_VIOLATION)
*********************************************************

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
********************

This file is probably created when CHAN was made an out-of-context module with a stub. In any case, the file is all commented out, so we don't need it. To fix, go in project manager Source window, library tab, and delete the reference to the file (it will be in red) under ``Design Sources -> Block Sources -> XDC``

Other tips
**********

- Unset CHAN as an out-of-context module, and re-set it again. You don't want a stub file. One is included in ``top chfpga_package.vhd``.
- Reset and re-generate IP Sources.
- Sometimes the IP references gets confused in the CHAN Module.  It seems normal that the same IP appears twice (the IP related to the control system is used both inside and outside the CHAN module). In that case, problems are solved by unsetting CHAN as an OOC module, *then* regenerating the cores, and then set again CHAN as OOC module.


