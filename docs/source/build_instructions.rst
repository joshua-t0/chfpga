******************
Build Inctructions
******************

Gotchas
*******



Bad cell path/name in constraints
---------------------------------

When synthesizing and implementing, check for critical warnings.

- Object not found in the constraint file. This can be caused by hierarchical paths that have changed name because labels have been changed, or some code has been encapsulated in block or generate statements. Open the synthesized or implemented design and look at the ectual path of the object. Test the constraint in the TCL console.

not-found objects will cause timing and placement constraints nott be applied properly. This, for example, will likely cause the placer to fail for some obscure reason .

Incremental reuse overrides
---------------------------



Disable incremental reuse on implementation if physical constraints (e.g. PBLOCKS) are changes, otherwise the new constrains will be ignored.

This may apply to syhthesis as well.



