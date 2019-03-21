Using Flyway
============

What is Flyway?
---------------

Flyway is a database migration tool.  As of Chado 1.4, the schema is distributed and updated via Flyway.

Flyway creates a ``flyway_schema_history`` table in your Chado database.  Once Flyway is configured, it will look for migrations (versioned SQL scripts) in your specified migration folder(s).  These migrations are tracked in the ``flyway_schema_history`` table, and will be run in order when you run the migrate command.  As the Chado schema is updated with new migrations, they can be tracked and updated with Flyway.


.. note::

	Please read the `Flyway getting started guide <https://flywaydb.org/getstarted/>`_ for more details before continuing.


Adding Flyway integration to an existing site
---------------------------------------------

First, follow the `instructions for installing Flyway <https://flywaydb.org/getstarted/firststeps/commandline>`_ using your distribution method of choice. You'll need to provide a ``flyway.conf`` file which describes the connection details to your Chado database.  For quick testing, place one in your home directory

.. note::

    Flyway will search for and automatically load config files from the following paths if present:

        - ``<install-dir>/conf/flyway.conf``
        - ``<user-home>/flyway.conf``
        - ``<current-dir>/flyway.conf``

    For managing multiple development Chado databases on a single machine, we recommend placing your application-specific ``flyway.conf`` in the application root directory and then running Flyway commands from there.

Here is an example configuration file where the PostgreSQL server is on the same machine as Flyway (i.e. localhost) and Chado is installed inside a database named ``drupal`` and a schema named ``chado`` (a typical arrangement for a Tripal-installed instance of Chado):

.. code-block:: bash

  flyway.url=jdbc:postgresql://localhost:5432/drupal
  flyway.user=user
  flyway.password=secret`
  flyway.schemas=chado
  flyway.locations=filesystem:/path/to/Chado/chado/migrations
  flyway.validateOnMigrate=false

For your setup, replace ``drupal`` in the ``flyway.url`` setting with the name of the database where Chado is installed, and change the ``flyway.schemas`` setting to the schema where Chado is installed.  If Chado was installed using the Perl-based installer this will be ``public``.

Once Flyway is configured properly, running ``flyway info`` should report a connected database.  The first step is to run ``flyway baseline``.  This tells Flyway what version of Chado to start at.  Chado switched to Flyway prior to ``1.4``, so specifying ``flyway baselineVersion=1.3 baseline``, or just ``flyway baseline`` (defaults to ``1.0``) should be appropriate for your pre-existing database.  Now, running ``flyway info`` should list all of the migrations available to your database with their state as **Pending**.


.. code-block:: bash


    flyway info
    Flyway Community Edition 5.2.4 by Boxfuse
    Database: jdbc:postgresql://localhost:5432/drupal (PostgreSQL 10.5)
    Schema version: 1

    +-----------+---------+-----------------------+----------+---------------------+----------+
    | Category  | Version | Description           | Type     | Installed On        | State    |
    +-----------+---------+-----------------------+----------+---------------------+----------+
    |           | 1       |  Flyway Baseline      | BASELINE | 2018-12-20 14:31:32 | Baseline |
    | Versioned | 1.3.3.001 | add stock biomat table | SQL      |                     | Pending  |
    +-----------+---------+-----------------------+----------+---------------------+----------+



Updating a Chado database with Flyway
-------------------------------------

Once your migrations appear in Flyway, you can run ``flyway migrate`` to execute all new migrations.  By default, Flyway will run all pending Migrations greater than your current version.  Afterwards, when new updates are added to Chado, you can update the Chado codebase on your server to an official tagged release or to the development branch and run ``flyway migrate``.  Once a migration is completed, ``flyway info`` will update the **State** of the migration from **Pending** to **Success**.


Writing new migrations
----------------------

To create a new migration, create a new ``.sql`` file in the migration folder.  The file should  contain plain SQL that performs the proposed changes.  However, the file name is important:  the first migration, for example, is ``V1.3.3.001__add_stock_biomat_table.sql``.  Subsequent migrations should follow the schema: `V{version}{increment}__{description}`` where:
- {version}: is the current version of chado
- {increment}: is a number that should be incremented for each new migration
- {desrciption}: a very brief description of what the migration changes.

Please note that proposed changes to the Chado schema should follow the project contribution guidelines.  You can have multiple migration folders to allow for site-specific migrations.
