
import os
import time
from xml.etree import ElementTree, ElementPath
import textwrap

from parsimonious.grammar import rule_grammar, RuleVisitor, evaluate_string, LazyReference
from parsimonious.expressions import Literal, Sequence, Node
from parsimonious.nodes import NodeVisitor


class CaselessLiteral(Literal):
    def _uncached_match(self, text, pos, cache, error):
        if text[pos:pos+len(self.literal)].lower() == self.literal.lower():
            #name = self.name or ("'" + self.literal + "'")
            name = 'literal'
            return Node(name, text, pos, pos + len(self.literal))


class VHDLRuleVisitor(RuleVisitor):
    """ Visitor used to convert the node tree resulting from the parsed VHDL syntax into Expression objects"""
    grammar = rule_grammar

    def visit_spaceless_literal(self, spaceless_literal, visited_children):
        """Turn a string literal into a ``Literal`` that recognizes it."""
        return CaselessLiteral(evaluate_string(spaceless_literal.text))

    def visit_rule(self, node, rule):
        """Assign a name to the Expression and return it."""
        label, equals, expression = rule
        if isinstance(expression, LazyReference):  # wrap a simple assignment to a reference in a Sequence so we don't lose the reference hierarchy.
            # print 'Rule ', label, '=', expression, ': target wrapped in a Sequence(...)'
            expression = Sequence(expression)
        expression.name = label  # Assign a name to the expr.
        return expression

class Namespace(object):
    def __init__(self, **kwargs): vars(self).update(**kwargs)

class VHDLElement(ElementTree.Element):
    """ ElementTree Element that represents a parsed VHDL object.


    """
    #def __init__(self, tag, full_text, start, end, attrib={}, **extra):
        #super(VHDLElement, self).__init__(tag, attrib=attrib, start=str(start), end=str(end), **extra)
        #self.full_text = full_text
        #self.start=start
        #self.end=end
    #start = property(lambda self:self.attrib['start'])
    #end = property(lambda self:self.attrib['end'])
    #text = property(lambda self:self.full_text[self.start:self.end])
#    @property
#    def text(self):
#        """Return the text this node matched."""
#        return self.full_text[self.start:self.end] if not len(self) else None
#
    @property
    def subtext(self):
        """Return the text of this element and all its subelements."""
        return ''.join(n.text for n in self.iter() if n.text)


    # Do not define __eq__ or __ne__ to handle strings : this breaks elem.remove()

    # Some additional method that are specifically useful to query VHDL parse trees

    def iterskip(self):
        for elem in self:
            skip=yield elem
            if not skip:
                # yield from elem.iterskip()  # in python 3.3

                g = elem.iterskip()
                s=None
                while True:
                    try:
                        s=yield g.send(s)
                    except StopIteration:
                        break

    def index(self, children):
        """ Returns the the index of a children within this element"""
        return self._children.index(children)

    def findindex(self, elem_or_path):
        if isinstance(elem_or_path, str):
            child = self.find(elem_or_path)
        else:
            child = elem_or_path
        for parent in self.iter():
            if child in parent:
                return (parent, parent.index(child))

    def findsibling(self, elem_or_path, offset=1):
        (p,i) = self.findindex(elem_or_path)
        if i < len(p) - offset:
            return p[i + offset]

    #def findafter(self, path):

    def findwithtext(self, path, text, caseless=False):
        if caseless:
            text = text.upper()
        for e in self.iterfind(path):
            if e.text and (e.text.upper() if caseless else e.text) == text:
                return e

    def findwithsubtext(self, path, text, caseless=False):
        if caseless:
            text = text.upper()
        for e in self.iterfind(path):
            if e.subtext and (e.subtext.upper() if caseless else e.subtext) == text:
                return e

    def findall(self, paths, namespaces=None):
        """ Extend findall to accept multiple paths"""
        if isinstance(paths, str):
            return ElementPath.findall(self, paths, namespaces)
        nodes = []
        for path in paths:
            nodes.extend(ElementPath.findall(self, path, namespaces))
        return nodes

    def iterbetween(self, start_before=None, start_after=None, end_before=None, end_after=None):
        if start_before is not None and start_after is not None:
            raise TypeError('Both start_before and start_after cannot be provided')
        elif start_before is not None:
            start = start_before
            is_start_after = False
        elif start_after is not None:
            start = start_after
            is_start_after = True
        else:
            is_start_after = False
            start = self

        if end_before is not None and end_after is not None:
            raise TypeError('Both end_before and end_after cannot be provided')
        elif end_before is not None:
            end = end_before
            is_end_before = True
        elif end_after is not None:
            end = end_after
            is_end_before = False
        else:
            is_end_before = False
            end = None

        it = self.iterskip()
        #print 'looking for start=', start
        for e in it:
            if e == start:
                #print 'found start'
                if is_start_after:
                    #print 'skipping', e
                    e = it.send(True) # skip this node and its children completely
                yield e
                for ee in it:
                    #print 'testing ', ee
                    if  ee == end_before:
                        return
                    yield ee
                    if ee is end_after:
                        for eee in ee.iter():
                            yield eee
                        return

    def textbetween(self, start_before=None, start_after=None, end_before=None, end_after=None):
        return ''.join(n.text or '' for n in self.iterbetween(start_before=start_before, start_after=start_after, end_before=end_before, end_after=end_after))

    def findsubtext(self, path, default=None, namespaces=None):
        elem = self.find(path, namespaces)
        return default if elem is None else elem.subtext or default

    def pp(self, level=0, collapsed_expr=['comment', 'target', 'name', 'expression', 'simple_expression', 'simple_name',  'association_element'], max_depth=0, width=80):
        #skip = ((not t.expr_name or (t.expr_name.startswith('_') and 1)) and t.children) or not t.text
        collapsed =  self.tag in collapsed_expr or (max_depth and level>=max_depth)
        #skip = bool(t.children) or not t.text
        #skip = False
        #if not collapsed:
        print  '%s<%s>(%x) %s%s' % ('   '*level, self.tag, id(self), '(collapsed) ' if collapsed else '', ('' if len(self) and not collapsed else '='+repr(self.subtext) if collapsed else '='+repr(self.text))[:width])

            #print  '%s%s' % ('   '*(level+1), )
        if not collapsed:
            for elem in self:
                elem.pp(level=(level+1), collapsed_expr=collapsed_expr, max_depth=max_depth)

class VHDLBlockCommentTransform(object):

    def __init__(self, elem):
        """ Scan the node tree for comments and move comment blocks immediately preceding the target expressions and their trailing comment line into that expression node.
        """
        self.block_comment_elements = []
        self.elems_to_delete = []
        self.line = 0
        self.col = 0
        self.n = 0
        original_subtext = elem.subtext
        self.visit(elem, None) # no parent on the first call, we assume we will never have to move the 'elem' node.

        # Remove elements that were scheduled for deletion.
        for (parent_elem, child_elem) in self.elems_to_delete:
            #print 'removing', child_elem, 'from', parent_elem, 'text=', repr(child_elem.subtext)
            parent_elem.remove(child_elem)
        assert elem.subtext == original_subtext  # This should have only moved block around without changing the code. If not, that is a problem

    def visit(self, elem, parent):
        #   1) scan the children to find consecutine line comments (unbroken by blank lines), and store them in block_comment_elements
        #   2) if  a comment in not a a new line and we just left an element to comment (last_commentd_elem is not None), then move the comment to it
        #if elem == '_': # contains spaces, newline and comment in any number or order
        #    self.block_comment_elements = []

        # step over nodes we just added
        assert elem.tag != 'block_comment', 'Encounterred a BlockComment while processing comments!'

        #if self.n < 200:
        #    print 'processing element ', elem.tag, ' on line=%i, col=%i' % (self.line+1, self.col+1), '=', repr(elem.text[:80] if elem.text else '')
        #    self.n += 1
        if elem.tag == 'comment':
            c_spaces, c_tag, c_text, c_newline = elem  # split comment children
            comment_col = self.col + len(c_spaces.text) # column of the comment tag ('--' or '--!')
            #print 'Comment line on line %i, col %i' % (self.line +1, comment_col+1), repr(elem.subtext[:80])

        # Start capturing block comment elements when a comment line is seen, and stop when anything but comments and spaces is found
        if not self.block_comment_elements:
            if elem.tag == 'comment':
                # print 'capturing', elem, 'text=', repr(elem.subtext)
                self.block_comment_elements.append((parent, elem))
                self.block_comment_col = comment_col
        # If we have already started capturing elements, continue adding as long as we get 'comments' and 'spaces' on newlines, otherwise cancel the whole thing
        else:
            # if we havea comment element started on a new line, add it to the list
            if (elem.tag=='comment' and comment_col==self.block_comment_col) or elem.tag == 'spaces':
                #print 'capturing', elem, 'text=', repr(elem.subtext)
                self.block_comment_elements.append((parent, elem))

            else: # we reached the end of the block comment
                # move the comment elements accumulated so far to target element.
                block_comment_elem = VHDLElement('block_comment')
                block_comment_elem.extend(n for p,n in self.block_comment_elements)
                # for (parent_elem, child_elem) in self.block_comment_elements: # move comments to this element
                #    print 'Moving block comment', child_elem, 'text=', repr(child_elem.subtext)
                    # print 'Free bock comment', block_comment_elem.subtext
                comment_parent, comment_child = self.block_comment_elements[0]
                index = comment_parent.index(comment_child) # location of first comment in parent
                comment_parent.insert(index, block_comment_elem)
                self.elems_to_delete.extend(self.block_comment_elements)

                #print 'New block comment', block_comment_elem.pp()
                self.block_comment_elements = [] # Stop capture

        # Process subnodes except comment
        if elem.tag != 'comment':
            for e in list(elem):  # visit all children. MUST ake a copy of te children list because we are modifying it in place (otherwise comments are processed twice!)
                self.visit(e, elem)


        # Update the status of the newline flag
        if elem.tag in ['newline', 'comment']: # newlines occur only in 'newline' and 'comment' objects
            self.col = 0
            self.line += 1
        elif elem.text:
            self.col += len(elem.text)
            # assert '\t' not in elem.text


class VHDLMoveHeadComments(object):

    def __init__(self, elem, commented_expr):
        """ Scan the node tree for comments and move comment blocks immediately preceding the target expressions and their trailing comment line into that expression node.
        """
        self.commented_expr = commented_expr
        self.last_block_comment = None
        self.last_commented_elem = None
        self.tail_comment_elements = []
        self.tail_comment_target = None

        self.elems_to_delete = []
        original_subtext = elem.subtext

        self.visit(elem, None) # no parent on the first call, we assume we will never have to move the 'elem' node.

        for (parent_elem, child_elem) in self.elems_to_delete:
            # print 'removing', child_elem, 'from', parent_elem, 'text=', repr(child_elem.subtext)[:80]
            parent_elem.remove(child_elem)

        assert elem.subtext == original_subtext  # This should have only moved block around without changing the code. If not, that is a problem

    def visit(self, elem, parent):

        ###############################
        #  Head comment processing
        ###############################
        # Move comments block preceding targets to be commented as the first element of those targets


        is_commented_expr = elem.tag in self.commented_expr

        # If we encounter a block comment, store it to signal we are looking for a recipient element
        if elem.tag == 'block_comment':
            # print 'trying to assing head comment', elem
            self.last_block_comment = (parent, elem)

        if self.last_block_comment: # If we have a comment to assign
            if is_commented_expr: # If this is a valid comment recipient
                # move the comment elements accumulated so far to target element.
                # print 'Assigning head comment', self.last_block_comment, 'to', elem
                comment_parent, comment_child = self.last_block_comment
                head_comment_node = VHDLElement('head_comment')
                head_comment_node.append(comment_child)
                elem.insert(0, head_comment_node)
                # print 'head elem to delete: ', self.last_block_comment
                self.elems_to_delete.append(self.last_block_comment)
                #print 'New block comment', block_comment_elem.pp()
                self.last_block_comment = None # No comment to assign anymore
            elif elem.text: # is a tail node with contents, we can't carry the comment forward anymore
                self.last_block_comment = None # No comment to assign anymore


        # Process subnodes except comment
        if elem.tag != 'block_comment':
            for e in list(elem):  # visit all children
                self.visit(e, elem)

class VHDLMoveTailComments(object):

    def __init__(self, elem, commented_expr):
        """ Scan the node tree for comments and move comment blocks immediately preceding the target expressions and their trailing comment line into that expression node.
        """
        self.commented_expr = commented_expr
        self.tail_comment_elements = []
        self.tail_comment_target = None

        self.elems_to_delete = []
        original_subtext = elem.subtext

        self.visit(elem, None) # no parent on the first call, we assume we will never have to move the 'elem' node.

        for (parent_elem, child_elem) in self.elems_to_delete:
            # print 'removing', child_elem, 'from', parent_elem, 'text=', repr(child_elem.subtext)[:80]
            parent_elem.remove(child_elem)

        assert elem.subtext == original_subtext  # This should have only moved block around without changing the code. If not, that is a problem

    def visit(self, elem, parent):

        is_commented_expr = elem.tag in self.commented_expr

        # Process subnodes except comment
        if elem.tag != 'block_comment':
            for e in list(elem):  # visit all children
                self.visit(e, elem)

        # Before exiting the node, setup the capture for trailing comments
        if is_commented_expr:
            #print 'Starting to look for tail comments for', elem
            self.tail_comment_target = elem
            self.tail_comment_elements = []  # start capturing elements

        # if the comment follows some elment without a newline and we just came out of a element to be commented, move comment bact to its end
        if self.tail_comment_target is not None:
            #print 'Checking element', elem, 'text=', repr(elem.text), 'tail=', self.tail_comment_elements
            if elem.tag == 'literal' and elem.text==';':
                #print 'Adding trailing element', elem, 'text=', repr(elem.subtext)
                self.tail_comment_elements.append((parent, elem))
            elif elem.tag == 'block_comment':
                #print 'Moving trailing comments', self.tail_comment_elements, 'text=', repr(elem.subtext)
                # Create new block which includes the elements between the target and the comment, and the contents of the comment
                tail_comment_elem = VHDLElement('tail_comment')
                tail_comment_elem.extend(n for p,n in self.tail_comment_elements) # Add all elements that prededed the comment
                tail_comment_elem.extend(elem)
                # Append the new extended block comment to the taret
                self.tail_comment_target.append(tail_comment_elem)
                # print 'tail elem to delete:', self.tail_comment_elements
                # print 'and ', (parent, elem)
                # Schedule the removal of the original block comment and the preceding elements
                self.elems_to_delete.extend(self.tail_comment_elements)
                self.elems_to_delete.append((parent, elem))
                # #print 'Will now be deleting', self.elems_to_delete

                self.tail_comment_target = None
                self.tail_comments_elements = []
            elif elem.text:
                #print 'Stopping to look for tail comments for', self.tail_comment_target, 'because we encountered', elem
                self.tail_comment_target = None
                self.tail_comment_elements = []

class VHDLParser(object):
    """ Creates a parser that parses VHDL files into ElementTree from which any language constrict can be queried"""

    commented_expr = ['entity_declaration', 'generic_element', 'interface_element', 'library_clause', 'use_clause']

    def __init__(self):
        """ Initializes the VHDL parser """
        # Load and parse the VHDLsyntax file
        t0 = time.time()
        print 'VHDL Parser: loading VHDL syntax file'
        vhdl_grammar_filename = os.path.join(os.path.dirname(__file__), 'vhdl_grammar.txt')
        with open(vhdl_grammar_filename) as f:
            self.vhdl_grammar=f.read()
        self.vhdl_rules = None  # for now don't parse the rules, in case we don't need to

    def parse_vhdl_syntax(self):
        """ Convert the VHDL syntax file into Expression tree, which are objects that will recursively look at the VHDL code to recognize the language element and return a Parse Tree. """
        if self.vhdl_rules:
            return
        t0 = time.time()
        print 'VHDL Parser: Processing VHDL syntax file'
        self.vhdl_rules, self.vhdl = VHDLRuleVisitor().parse(self.vhdl_grammar)
        print 'VHDL Parser: finished processing VHDL rules. Loading and processing took %0.3f seconds.' % (time.time()-t0)

    def parse_to_node_tree(self, code, pos=0, rule_name='statements'):
        #  if code hash not in cache, parse
        self.parse_vhdl_syntax() # make sure the parser exist
        return self.vhdl_rules[rule_name].parse(code, pos=pos)

    def parse(self, code, pos=0, rule_name='statements'):
        elem = self.node_to_element(self.parse_to_node_tree(code, pos=pos, rule_name=rule_name))

        # fix empty tags
        for e in elem.iter():
            if not e.tag:
                e.tag = 'tag'

        # Fix comments (move surrounding comment lines back into their associated elements)
        self.fix_comments(elem)


        return elem


    #def node_to_element_tree(self, node):
    #    return self.node_to_element(node)

    def node_to_element(self, node):
        """ Convert  parsimonious parse Node (and its children) into ElementTree Element"""

        tag = node.expr_name
        #if not node.expr_name and not node.children:
        #    tag = 'regex'
        #if not tag and len(node.children)!=1:
        #    raise RuntimeError('tagless node has %i children (text= %s)'% (len(node.children), node.text))
        e = VHDLElement(tag=tag, start=str(node.start), end=str(node.end))
        if node.children:
            for child in node.children:
                elem = self.node_to_element(child)
                if not elem.tag and not elem.text: # if the element has no tag and no contents of its own, just promote the childrens up
                    e.extend(elem)
                else:
                    e.append(elem)
        else:
            e.text = node.text
        return e

    def parse_file(self, filename):
        t0 = time.time()
        print 'VHDL Parser: loading %s' % os.path.abspath(filename)
        with open(filename) as f:
            code = f.read()
        load_time = time.time() - t0
        t0 = time.time()
        self._last_code = code  # save for debugging
        print 'VHDL Parser: parsing %s' % filename
        nodes = self.parse(code)
        parsing_time = time.time() - t0
        print 'VHDL Parser: Finished processing %s. Loading took %0.3f s, parsing took %0.3f s.' % (filename, load_time, parsing_time)
        return nodes

    def fix_comments(self, elem):
        """ Scan the parsed code and move block comments and trailing line comments back into the associated element.

        Arguments:
            elem (VHDLElement (ElementTree.Element)): The parsed tree to process

        Returns:
            Nothing. The Element Tree is modified in-place.

        Note:
            The nodes of the element tree are moved in a way that the source code it represents is not modified.
        """
        print 'VHDL Parser: Identifying block comments'
        VHDLBlockCommentTransform(elem)
        print 'VHDL Parser: Assigning block comments to their associated VHDL elements'
        VHDLMoveHeadComments(elem, self.commented_expr)
        print 'VHDL Parser: Assigning trailing end-of-line comments to their associated VHDL elements'
        VHDLMoveTailComments(elem, self.commented_expr)
        return


    def add_label(self, label_list, typ, label, obj):
        if not isinstance(label, list):
            label = [label]
        for lab in label:
            if (typ, lab) in label_list:
                raise ValueError("%s label '%s' is already defined" % (typ, lab))
            label_list[(typ, lab)] = obj

    def get_comments(self, node):
        head_comments = [n.text for n in node.findall('.//head_comment//comment_text')]
        tail_comments = [n.text for n in node.findall('.//tail_comment//comment_text')]
        return dict(head_comments=head_comments, tail_comments=tail_comments)



    def analyze(self, top_elem, filename=''):
        """
        Process a parsed VHDL file and extract key information from it for easy access through
        standard namespace objects.

        Arguments:
            - elem (VHDLElement): The root node of the element tree containing the parsed VHDL

        Returns:
            Namespace object.


            labels:
                - {name, type, object}  # type= generic, port, signal, attribute, instance

            entities:
                generics:
                    - generic1 : {name: [], dir: str, type: str, default:str, pre_comment:str, post_comment: str}
                port:
                    -
                architecture:
                    signal:
                    constant:
                    attribute:
                    instances:
                    process:
                    variables:

            entity2:
        Note:
            The analysis code is dependent in the VHDL sytax definition file structure.

        """
        # summary = ElementTree.Element
        # def get_node(node, tag):
        #     n = node.find('tag')
        #     if not n:
        #         n = ElementTree.Element
        #         node.append(n)
        #     return n

        labels = {}
        libraries = self.analyze_libraries(top_elem, labels, filename=filename)
        entities = self.analyze_entities(top_elem, labels, filename=filename)

        return dict(libraries=libraries, entities=entities,  labels=labels)


    def analyze_libraries(self, top_elem, label_list, filename):
        # Analyze LIBRARY clauses
        libraries = {}  # get_node(summary, 'library')
        libraries['work'] = Namespace(name='work', use=[], block_comment=[], tail_comment=[], node=None, source_file='')

        for lib_node in top_elem.findall('.//library_clause'):
            for id_node in lib_node.findall('.//identifier'):
                lib_name = id_node.subtext
                lib_info = Namespace(name=lib_name, node=lib_node, use=[], source_file=filename, **self.get_comments(lib_node))
                libraries[lib_name.lower()] = lib_info
                self.add_label(label_list, 'library', lib_name, lib_info)
                print 'Added library', lib_name

        # Analyze USE clauses
        for use_node in top_elem.findall('.//use_clause'):
            for selected_name in use_node.findall('.//selected_name'):
                name_node = selected_name.find('.//name')
                if name_node is None or len(name_node) < 2:
                    raise RuntimeError('Use clause must have a prefix and one or more suffixes')
                lib_name = name_node[0].subtext
                sel_name = ''.join(n.subtext for n in name_node[1:])
                use_info = Namespace(label=sel_name, node=use_node, **self.get_comments(use_node))
                print 'Use lib', lib_name
                if lib_name.lower() not in libraries:
                    print use_node.subtext
                    raise RuntimeError("Use of library '%s' before it is defined" % lib_name);
                libraries[lib_name.lower()].use.append(use_info)

        return libraries

    def analyze_entity_interface(self, entity_elem, list_name, element_name):
        """
        Extract port or generics information from an entity element `entity_elem`.

        Arguments:
            line_name (str): Xpath used to find the element list
            element_name (str): Xpath used to find the element within the list

        Return:
            (list): list of dicts containing:

                name_list (list of str): list of port/generic identifier names. Is empty if the entry is for an isolated (sectionning) comment.
                definition (str): rest of the port/generics definition
                comments (str): Single newline-separated string containing both the head and tail comment for that interface element
    """
        interface_list_node = entity_elem.find(list_name)
        if interface_list_node is None: return []
        interface_list = []
        for elem in interface_list_node:
            if elem.tag == element_name:
                name_list = [ n.subtext for n in elem.findall('.//identifier_list//identifier')]
                # names = ','.join(name_list)
                colon = elem.findwithtext('.//literal', ':')
                head_comment = elem.find('.//head_comment')
                tail_comment = elem.find('.//tail_comment')
                # tail_comment= elem[-1] if elem[-1].tag == 'block_comment' else None
                definition = elem.textbetween(start_after=colon, end_before=tail_comment)
                comments = '\n'.join(n.subtext for n in elem.findall('.//comment_text'))
                interface_info = Namespace(names=name_list, definition=definition, comments=comments)
                interface_list.append(interface_info)
            elif elem.tag == '_':
                comment_nodes = elem.findall('.//comment_text')
                if comment_nodes:
                    comments = '\n'.join(e.subtext for e in comment_nodes)
                    interface_list.append(Namespace(names=[], definition=None, comments=comments))
        return interface_list

    def analyze_entities(self, top_elem, label_list, filename):
        # Analyze entities
        entities = {}
        for entity_node in top_elem.findall('.//entity_declaration'):
            entity_name = entity_node.find('.//identifier').subtext

            # Analyze ports and generics
            generics = self.analyze_entity_interface(entity_node,'.//generic_list',  'generic_element')
            ports = self.analyze_entity_interface(entity_node, './/interface_list', 'interface_element')

            # Analyze entity comments
            #block_comment=textwrap.dedent('\n'.join(n.text for n in entity_node.findall('.//block_comment//comment_text'))).splitlines()
            block_comments = [n.text for n in entity_node.findall('head_comment//comment_text')]
            brief, details = self.split_block_comments(block_comments)
            entity_info = Namespace(name=entity_name, ports=ports, generics=generics, brief=brief, details=details, source_file=filename)
            entities[entity_name.lower()] = entity_info

            # Add labels to the label list
            self.add_label(label_list, 'entity', entity_name, entity_info)
            for port in ports:
                self.add_label(label_list, 'entity.port', port.names, port)
            for gen in generics:
                self.add_label(label_list, 'entity.generic', gen.names, port)
        return entities

    def split_block_comments(self, block_comments, dedent_details = True):
        """
        Split a comment block in two parts: the first paragraph is stripped of spaces and is return
        as a first list, while the rest of the comment block is in the second list and is dedented
        as a block.
        """
        brief = []
        details = []
        is_brief = True
        for line in block_comments:
            stripped_line = line.strip()
            if stripped_line.startswith('@brief'):
                stripped_line = stripped_line[6:].strip()
                is_brief = True
            elif not stripped_line or stripped_line.startswith('@details'):
                line = stripped_line[8:]
                is_brief = False

            if is_brief:
                brief.append(stripped_line)
            else:
                details.append(line)

        if dedent_details:
            details = textwrap.dedent('\n'.join(details)).splitlines()  # dedent details
        return brief, details




class VHDLFiles(ElementTree.ElementTree):
    """ ElementTree object representing a set of VHDL files and allows loading and parsing VHDL files, and provides direct access to entity, architectures,
    variables etc across the project"""

    def __init__(self):
        super(VHDLFiles, self).__init__(VHDLElement('project'))
        self.vhdl_parser = VHDLParser()
        self.summaries={}
        self.entities={}
        self.labels=[]

    def parse_file(self, filename):
        if filename in self.summaries:
            raise RuntimeError("File '%s' has already been parsed" % filename)

        parse_elem = self.vhdl_parser.parse_file(filename)
        summary = self.vhdl_parser.analyze(parse_elem, filename=filename)

        # Add Element to this ElementTree
        file_element = VHDLElement('file', filename=filename)
        file_element.append(parse_elem)
        self.getroot().append(file_element)

        # Add summary info
        self.summaries[filename] = summary

        # Add found entities to global entity list
        for entity_key, entity in summary['entities'].items():
            if entity_key in self.entities:
                raise RuntimeError("Entity '%s' has already been parsed" % entity['name'])
            self.entities[entity_key] = entity

    def get_entity(self, entity_name):
        # for entity_node in self.findall('.//entity_declaration'):
        #     if entity_node is not None and entity_node.findsubtext('identifier').upper() == name.upper():
        #         return entity_node
        if entity_name.lower() in self.entities:
            return self.entities[entity_name.lower()]
        raise RuntimeError('Could not find entity %s in the current file set. Was the VHDL file parsed?' % entity_name)

    def get_file_with_entity(self, name):
        # entity = self.get_entity(entity_name)
        # return self.find(entity.source_file)
        for file in self.findall('.//file'):
            if file.get('filename')==name or file.findwithsubtext('.//entity_declaration/identifier', name, caseless=True) is not None:
                return file



    # def get_entity_summary(self, entity_name):
    #     return self.get_entity(entity_name)

    def get_comments(self, entity, start_before=None, start_after=None, end_before=None, end_after=None, dedent=True):
        def match(source, target):
            if not target: return False
            r = source.find(target)
            return r >= 0

        file = self.get_file_with_entity(entity)
        if file is None:
            raise ValueError('get_comments: Cannot find entity %s' % entity)
        lines = []
        capture = False
        for bc in file.iterfind('.//block_comment'):
            for c in bc.iterfind('.//comment_text'):
                s = c.subtext
                if match(s, start_before):
                    capture = True
                if match(s, start_after):
                    capture = True
                    continue
                if match(s, end_before):
                    break
                if capture:
                    lines.append(s)
                if match(s, end_after):
                    break
            if lines:
                break

        if dedent:
            lines=textwrap.dedent('\n'.join(lines)).splitlines()  # dedent captured text
        return lines

def pp(t, level=0, collapsed_expr=['target', 'name', 'expression', 'simple_expression', 'simple_name']):
    skip = ((not t.expr_name or (t.expr_name.startswith('_') and 1)) and t.children) or not t.text
    collapsed =  t.expr_name in collapsed_expr
    #skip = bool(t.children) or not t.text
    #skip = False
    if not skip or collapsed:
        print '   '*level, '[%s] (%i-%i) %s' % (t.expr_name, t.start, t.end, ('=' + repr(t.text)) if (not t.children or collapsed) else '')
    if not collapsed:
        for c in t.children:
            pp(c, (level+1) if not skip else level, collapsed_expr)



if __name__ == '__main__':
    v = VHDLFiles()
    v.parse_file('../../../hdl/chan/FFT.vhd')
    e = v.get_entity('FFT')
    f = v.get_file_with_entity('FFT')