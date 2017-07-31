# vim-dn-markdown #

A vim markdown ftplugin providing some output (re)generation and viewing
options. Can generate and view the following formats:

* Kindle Format 8 (azw3)
* ConTeXt (tex)
* Microsoft Word (docx)
* Electronic publication (epub)
* HyperText Markup Language (html)
* LaTeX (tex)
* Mobipocket e-book (mobi)
* OpenDocument Text (odt)
* Portable Document Format (pdf)

## Requires ##

Pandoc: To generate output files.

LaTeX, ConTeXt or wkhtmltopdf: To generate pdf output files. If using LaTeX can use XeLaTeX (default), LuaLaTeX or pdfLaTeX engines.

Ebook-convert: To generate azw3 or mobi output.

Vim plugin: [dn-utils](https://github.com/dnebauer/dn-vim-utils).

System default viewers: Output files are displayed using default system
applications for each file type.

## Further documentation ##

See ftplugin documentation.

## Credit ##

The ftplugin includes a default stylesheet for incorporation into html output
files. This style file is a thin wrapping of Ryan Gray's buttondown css
stylesheet hosted at [github](https://github.com/ryangray/buttondown).
