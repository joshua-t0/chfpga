About this documentation
========================

This documentation was generated using Sphinx, which is typically used to document Python code, but can also support other languages. We use the home-made vhdl_sphinx_domain extension to parse the VHDL source file and automatically include documentation found in the source files themselves.


Sphinx documentation conventions
********************************


http://documentation-style-guide-sphinx.readthedocs.io/en/latest/style-guide.html

* Header levels:

    - #_#, *_*, ===, ---, ^^^, """
    - Index doc - main title: no header
    - Index sections (contents, Quick links): ####_####
    - Main sections: ***_***

The `toctree` directive includes a RST file one level down from the current level, i.e. the top heading level of that document becomes a sub-heading in the master document, independent from the heading style (``**``, ``===`` etc.).  The heading levels of RST documents included `toctree` are independent from each other.

Content included with the `include` directive is as if it was typed in that document, so this is essentially a single RST document in which case the heading levels must be consistent.)




Documenting VHDL in Sphinx
**************************

We have been looking at the best approach to document this VHDL project with the following objective:

   - We want to avoid documentation duplication, i.e. have good docs in the source code but not have to duplicate it in the manuals
   - We want the HDL code to be self-documented as much as possible without drowning it in implementation and philosophical details, but we want to put these details somewhere
   - We want to include figures (block diagram) as those can often convey the most information with the minimal reader effort
   - We want for the documentation to be generated in HTML pages we can put on the lab server
   - We want to use  standard tools and language to generate the documentation.
   - We want the server (a linux virtual machine in the cloud) to be able to regenerate the docs whenever the source code has been pushed to its git repository

doxygen is the tool we originally used to create a detailed documentation of the whole HDL project, and it does a pretty decent job at it. Most of the HDL project has been commented using the doxygen syntax. Comments are therefore written using the markdown markup syntax. The code uses emphasis, lists and tables. Other features like figures, references etc. are not used.

In some ways, doxygen output is a bit too detailed. Many HDL modules are just plumbing, and lots of signals are just used for interconnecting instances. Although our firmware uses a large numbe rof gates, it is relatively simple, consisting or a large number of instances of a small number of modules. doxygen also uses the 'C' paradigm (classes, modules) and tried to fit the VHDL model, which makes the navigation awkward.

Sphinx is the platform used to document all the other aspects of the project in which the HDL is used. We were wondering if there was a way to reasonably document the HDL project using Sphinx. That is, we<d like the top level structure of the documentation to be in Sphinx, and be able to pull  HDL self-documentation into Sphinx. Ideally, we would not need docygen at all.

We looked at various options to acheive this.

Breathe
-------

Breathe (https://breathe.readthedocs.io/en/latest/) provides a bridge between the Sphinx and Doxygen documentation systems. Docygen is used to generate the documentation in xml, the breathe gives access to it.

That looked nice, but we'd prefer not to use doxygen at all since doxygen is a bit overkill.

Fully automatic vs semi-automatic documentation
-----------------------------------------------

Do we want to duplicate docygen fully auto-documenting functionality into Sphinx? Shpinx is good at autodocumenting Python code, and the autodic featre is extensible, but there is no official Sphinx autodoc module that could understand VHDL projects. We would have to write our own extension if we wanted to go that way.

But we have to be careful. First, just re-doing what doxygen does well is wasted effort. Second, autodocumenting might be overdocumenting and drown the key information in too much details. And there is still a lots of information and figures we want to add manually, not in the HDL source code.

In other words, we might not want fully automated documentation.

We probably prefer to manually create the documentation structure (e.g. manually create a page for each key module), but then use tools that import the documentation from the HDL files where we need it along additional prose and figures. This is what we call semi-automatic documentation.

Full Python VHDL parsers
------------------------
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


References
----------

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


markdown-python ElementTree
----------------------------

.. code-block:: python

  def convert(self, source):

        # Fixup the source text
        if not source.strip():
            return ''  # a blank unicode string
        try:
            source = util.text_type(source)
        except UnicodeDecodeError as e:
            # Customise error message while maintaining original trackback
            e.reason += '. -- Note: Markdown only accepts unicode input!'
            raise

        # Split into lines and run the line preprocessors.
        self.lines = source.split("\n")
        for prep in self.preprocessors.values():
            self.lines = prep.run(self.lines)
        # Parse the high-level elements.
        root = self.parser.parseDocument(self.lines).getroot()

        # Run the tree-processors
        for treeprocessor in self.treeprocessors.values():
            newRoot = treeprocessor.run(root)
            if newRoot is not None:
                root = newRoot
        return root


Common Markim - Sphinx

https://gist.github.com/dupuy/1855764


.. code-block:: python

      s2 = """
      | Tables        | Are           | Cool  |
      | ------------- |:-------------:| -----:|
      | col 3 is      | right-aligned | $1600 |
      | col 2 is      | centered      |   $12 |
      | zebra stripes | are neat      |    $1 |
      """

      r=convert(m,s2)




