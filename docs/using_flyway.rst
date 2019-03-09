Using Flyway
===============

What is Flyway?
----------------

Flyway is a database migration tool.  As of Chado 1.4, the schema is distributed and updated via Flyway.

Flyway creates a ``flyway_schema_history`` table in your Chado database.  Once Flyway is configured, it will look for migrations (versioned SQL scripts) in your specified migration folder(s).  These migrations are tracked in the ``flyway_schema_history`` table, and will be run in order when you run the migrate command.  As the Chado schema is updated with new migrations, they can be tracked and updated with Flyway.


.. note::

	Please read the `Flyway getting started guide <https://flywaydb.org/getstarted/>`_ for more details before continuing.


Adding Flyway integration to an existing site
------------------------------------------------

First, follow the `instructions for installing Flyway <https://flywaydb.org/getstarted/firststeps/commandline>`_ using your distribution method of choice. You'll need to provide a ``flyway.conf`` file in your home directory which describes the connection details to your chado database.  Here is an example configuration file:

.. code-block:: bash

  flyway.url=jdbc:postgresql://localhost:5432/drupal
  flyway.user=user
  flyway.password=secret
  flyway.schemas=chado
  flyway.locations=filesystem:/path/to/Chado/chado/migrations
  flyway.validateOnMigrate=false


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

.. note::

    Flyway will search for and automatically load the following config files if present:

        - ``<install-dir>/conf/flyway.conf``
        - ``<user-home>/flyway.conf``
        - ``<current-dir>/flyway.conf``

    For managing multiple development Chado databases on a single machine, we recommend placing your application-specific ``flyway.conf`` in the application root directory and then running Flyway commands from there.

Updating a Chado database with Flyway
-----------------------------------------------

Once your migrations appear in Flyway, you can run ``flyway migrate`` to execute all new migrations.  By default, Flyway will run all pending Migrations greater than your current version.  When updates are pushed to Chado, you can simply update your Chado install (``git pull``) and run ``flyway migrate``.  Once a migration is run, ``flyway info`` will update the **State** of the migration from **Pending** to **Success**.


Writing new migrations
--------------------------------

Writing new migrations is easy.  Simply create a new ``.sql`` file in the migration folder.  The file can just contain plain SQL to make your proposed changes.  The file name is important:  our first migration, for example, is ``V1.3.3.001__add_stock_biomat_table.sql``.  Subsequent migrations should follow ``V1.3.3.002__brief_description``, ``V1.3.3.003__brief_description``, etc, until the next release of Chado.
Please note that proposed changes to the Chado schema should follow the project contribution guidelines.  You can have multiple migration folders to allow for site-specific migrations.
