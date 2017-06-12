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

Python, Sphinx
Use our own VHDLDomain

Used Doxygen in the past, but now moved to Sphinx.

Python packages
- parsimonious 0.7.0 (pip install parsimonious). Used to parse VHDL code to autodocument
- sphinx 1.5.5-1: Documentation builder
	- sphinx-rtd-theme 0.2.4-1 (seems to come as a sphinx dependancy)
	- pygments (sphinx dependency)


Compiling
=========

clone repo::

git clone ...

Make sure LFS files were pulled (not just pointers). git-lfs ls-files should show stars ('*') before the filename

Open project. A bit slow the first time, as it builds its cache (for the IP. Something appears in .cache).

Start implementation. On 2016.4, Vivado automatically generates the core products, and churns along until routing is done.

Vivado 2016.4 will sometimes crash after routing during the final Methodology check, after the routed database was created and saved. In this case, to complete the bitstream generation:
	- kill the zombie Vivado process, which is locking files such as logs and will prevent other Vivado steps to execute
	- In the implementation folder, create a ".route_design.end.rst" file to make Vivado beleive implementation is completed (copy ".route_design.begin.rst" and rename it)
	- in the GUI, click generate Bitstream

Notes:
	- timing summary was not generated since Vivado crashed before it could generate it.
	- opening the implemented design after this trick make Vivado crash, maybe because some expected files and reports are missing. Restarting Vivado does not help.

Alternative:
	- Open routed checkpoint in Vivado (file -> Open Checkpoint)
	- In the tcl console, cd to the implementation dir. The name of the folder can be cut-and-pasted from messages in the TCL   console window. e.g.::
		cd ...
	- Generate bitstream with the following command::
		write_bitstream -force -no_partial_bitfile SIFPGA_MGK7MB.bit