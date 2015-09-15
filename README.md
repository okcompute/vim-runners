vim-runners
===========

An improved vim compiler for *running* tests.

Introduction
============

This plugin improve on *Vim* compiler option for running tests.

Main features:

*   Isolate tests running session. Run a specific test, a test case, a test
    module or all tests inside a git repository.
*   Memorize last test ran. The last test will run if commands are called
    in `non-test` source file.
*   Improved *Vim* *errorformat* detection. *quickfix* window will show the
    correct error lines (surprisingly, it was not intuitive as one would
    think to enable!)

Supported test runners
======================

Python
------

* nose (http://nose.readthedocs.org)
* pytest (http://pytest.org)


Requirements
============

For this plugin to have some value, you need this requirement to be installed in
your environment:

- python

These requirement are optional but improve the plugin usage:

- git
- [vim-dispatch](https://github.com/tpope/vim-dispatch) by Tim Pope to run tests asynchronously

Configuration
=============

Plugin support two configuration modes.

1. Through a configuration file `.runners` (usually located at the root of your
   project).
1. Through git configuration (`vim-runners.xxxxx`) in your git repository

See the plugin documentation for more all available configurations .

Python
======

VirtualEnv Configuration
------------------------

Python virtual environment can be configured on a per-project basis through
either through a *git* option or a project configuration file. See documentation
for more details.


Usage
=====

### `:RunTest`

Run the current test surrounding the cursor position.  Otherwise, run all tests in the scope the cursor is located in (i.e. test case or module).

### `:RunCase`

Run all tests found in the test case surrounding the cursor position. If cursor is outside a test case scope, all tests for the module (buffer) are run.

### `:RunModule`

Run all tests found in the current module (buffer).

### `:RunAllTests`

Run all tests found in the git repository of the edited buffer.

### Running last test

The plugin will *memorize* the last test, case or module used for these three commands:

    :RunTest
    :RunCase
    :RunModule

If any of these commands are called outside of a python test module (any python
module name not starting with "test_...") the last test, case or module will be
used. This is really useful for example when doing TDD. You write the test. Call
`:RunTest`. It fails. Switch focus to source module. Add code. Call `:RunTest`.
etc.

### Interactive commands

All **:Run...** command can also be launched in interactive mode. This will run
tests synchronously in an external console (if possible). This is useful for
debugging your program or tests. For instance, using `ipdb` inside *gVim* or
*MacVim* basic shell does not support coloring! This is an attempt to fix this
problem.

Example:

    :RunTest!


License
=======

Copyright © Pascal Lalancette. Distributed under the same terms as Vim itself. See :help license.
