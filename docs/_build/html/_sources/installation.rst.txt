Installation
============


Installing Chado
-----------------

First you will need database software, or Relational Database Management System (RDBMS). The recommended RDBMS for Chado currently is `Postgres <http://www.postgresql.org/>`_. Postgres is free software, usually used on a Unix operating system such as Linux or Mac OS X. You can also install Postgres, and Chado, on Windows but most Chado installations are found on some version of Unix - you'll probably get the best support by choosing Unix. (See `Databases and GMOD <http://gmod.org/wiki/Databases_and_GMOD>`_ for more discussion.) Once you've installed your RDBMS you can install Chado.


Download a Stable Release of Chado
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

See Downloads


Chado From SVN
~~~~~~~~~~~~~~

You can get the most up-to-date, not even released yet, version of Chado from `Subversion <http://gmod.org/wiki/Subversion>`_. To get a copy of the latest Chado source, enter this at the command line:

.. code-block:: shell

  svn co https://svn.code.sf.net/p/gmod/svn/schema/trunk

Once the package has been downloaded cd to the ``trunk/chado`` directory.

Follow the instructions in the ``INSTALL.Chado`` file, including the installation of the prerequisites. Or, `read the file online <http://gmod.svn.sourceforge.net/viewvc/gmod/schema/trunk/chado/INSTALL.Chado>`_.

Loading Data
-------------

After completing these steps, you can load your Chado schema with data in a number of ways:

Load RefSeq into Chado HOWTO http://gmod.org/wiki/Load_RefSeq_Into_Chado
Load GFF into Chado HOWTO http://gmod.org/wiki/Load_GFF_Into_Chado
Using XORT http://gmod.org/wiki/XORT

You can also use the application `Apollo <http://gmod.org/wiki/Apollo>`_ to curate data in Chado.
