# -*- coding: utf-8 -*-
"""
    sphinxcontrib
    ~~~~~~~~~~~~~

    This package is a namespace package that contains all extensions
    distributed in the ``sphinx-contrib`` distribution.

    :copyright: Copyright 2007-2012 by the Sphinx team, see AUTHORS.
    :license: BSD, see LICENSE for details.
"""

__import__('pkg_resources').declare_namespace(__name__)


def setup(app):
    # from include_vhdl_docs import IncludeVhdlDocsDirective, strongref_role
    from vhdl_domain import VHDLDomain
    # from sphinx.roles import XRefRole
    # from docutils import nodes

    # class YXRefRole(XRefRole):
    #     # def process_link(self, env, refnode, has_explicit_title, title, target):
    #     #     # refnode['refexplicit'] = True  # to prevent that Sphinx overwrites
    #     #     #                          # the title you set
    #     #     return '[['+title+']]','prefix.'+target
    #     def result_nodes(self, document, env, node, is_ref):
    #         node['reftype'] = 'ref'
    #         # node['refexplicit'] = True
    #         # innernode =
    #         # innernode += node.pop()
    #         print('original node is:', node)
    #         newnode = nodes.strong('','',node)
    #         # newnode += node
    #         print('new node is:', newnode)
    #         return [newnode], []

    print 'VHDLDomain: Setting up VHDL Domain'
    # app.add_directive('include_vhdl_docs', IncludeVhdlDocsDirective)
    # app.add_role_to_domain('std','strongref', YXRefRole(lowercase=True, innernodeclass=nodes.strong))
    # app.add_role_to_domain('std', 'strongref', strongref_role)
    app.add_domain(VHDLDomain)
    # app.add_role('bbchangeset', bbchangeset_role)
    # app.add_config_value('bitbucket_project_url', None, 'env')
    print 'VHDLDomain: adding stylesheet vhdl.css'
    app.add_stylesheet('vhdl.css')
    app.add_config_value('vhdl_root', '', 'env')
