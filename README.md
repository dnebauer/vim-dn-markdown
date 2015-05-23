vim-dn-markdown
===============

An auxiliary vim ftplugin for markdown providing some output and viewing commands.

Installation
------------

Install using vundle or pathogen.

Requires
--------

Pandoc: To generate html and pdf output files.

Lualatex: To generate pdf output files.

Vim plugin: [dn-utils](https://github.com/dnebauer/dn-vim-utils).

System default viewers: html and pdf output files are displayed using default system applications.

Provides
--------

This filetype plugin automates the following tasks:

###Generating html output using pandoc

*   mapping: `<LocalLeader>gh`

*   command: `GenerateHTML`

###Viewing html output with system default html viewer

*   mapping: `<LocalLeader>vh`

*   command: `ViewHTML`

###Generating pdf output using pandoc and lualatex

*   mapping: `<LocalLeader>gp`

*   command: `GeneratePDF`

###Viewing pdf output with system default pdf viewer

*   mapping: `<LocalLeader>vp`

*   command: `ViewPDF`

Credit
------

The style file is a thin wrapping of Ryan Gray's buttondown css stylesheet hosted at [github](https://github.com/ryangray/buttondown).
