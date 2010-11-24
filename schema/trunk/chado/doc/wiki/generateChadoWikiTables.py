#! /usr/bin/python
# ------------------
"""
Generate the Chado table descriptions for the GMOD wiki.

Pseudocode:

Read Module-Table pairings

generate descriptions of every table
read them into memory.

open alltables file
for each module
  open module file
  add module header to alltables file, module file
  for each table in module
    open table file
    generate Mediawiki markup for table
    clean it up
    add table to alltables file, module file, table file

report any tables in DB that are defined as belonging to a module.


Usage:
  ./generateChadoWikiTables.py

  It does not take any parameters as all values are hard coded below.

  The script puts the output wiki files in WIKI_DIR, which by default is
  /tmp/ChadoWikiFiles/


TODO:
* Make all the values that are defined as constants in the program be
  passed in as parameters.
  
"""

import os
import json
import re


# ----------------
# DEFINITIONS
# ----------------

# UPDATE THESE 4 BEFORE RUNNING THE PROGRAM.
DB_NAME           = "testdb"
DB_USER           = "gmodhack"
MODULE_TABLE_PATH = "../../modules/module-tables.json"
WIKI_DIR          = "/tmp/ChadoWikiFiles"

# The MODULE_TABLE_PATH file may or may not define the Audit module tables.
# There definitions are large redundant with the tables they audit.

MODULES_DIR          = WIKI_DIR + "/Modules"
TABLES_DIR           = WIKI_DIR + "/Tables"
WIKI_ALL_TABLES_PATH = WIKI_DIR + "/allTables.wiki"

# Don't update these, because we don't control them.
RAW_TABLE_PATH  = DB_NAME + ".wiki"


# -------------------------
# Create needed directories
# -------------------------

if not os.path.exists(WIKI_DIR):
    os.mkdir(WIKI_DIR)
if not os.path.exists(MODULES_DIR):
    os.mkdir(MODULES_DIR)
if not os.path.exists(TABLES_DIR):
    os.mkdir(TABLES_DIR)


# -----------------------------
# Read Table to Module Mappings
# -----------------------------

# The modules are defined as a name and a list of tables.
modules = json.load(open(MODULE_TABLE_PATH, "r"))

# Create a dictionary of table name to Module mappings; used with FK pointers.
tableModuleName = {}
for module in modules["modules"]:
    moduleName = module["module"]
    for table in module["tables"]:
        tableModuleName[table] = moduleName


# -------------------------
# Create Table Descriptions
# -------------------------

# Generate descriptions of all tables.  produces file named DB_NAME.tableRefs.
# Exclude audit tables.  This takes a loooong time.  Go get some coffee.
# This takes so long that you will want to comment it out on subsequent runs.
os.system("postgresql_autodoc -d " + DB_NAME + " -u " + DB_USER +
          " -l . -t wiki") # -m '^[^a][^u][^d][^i][^t][^_]'")


# Split up entries, clean them up, save in memory
rawTableFile = open(RAW_TABLE_PATH, "r")
rawTablesAll = rawTableFile.read()
rawTableFile.close()

tablesByName = {}

rawTables = rawTablesAll.split("__TABLE_START__")[1:]
#rawTables.pop()   # getrid of bogus element at end.

for rawTable in rawTables:
    # Clean them up. Problems I know about:
    # 1. Insert Module name (Can't figure out how to get module name into
    #    autodoc)
    # 2. Any equals signs have to be HTML escaped because mediawiki
    #    templates choke on them.
    # 3. At template time we only know the FK table name; not the module
    #    the FK table belongs to.  Now we know the module.  Insert it.

    tableName = re.match(
        r"<protect><noinclude>{{ChadoTableTemplateHeader}}</noinclude>\n" + 
        "{{ChadoTableDesc\|__MODULE__\|(\w+)|", rawTable).group(1)
    if tableName not in tableModuleName:
        print("ERROR: Table '" + tableName + "' is not associated with any module.")
    else:
        # There must be a better way:
        table1 = re.sub(r"__MODULE__", tableModuleName[tableName], rawTable)
        table2 = re.sub(r"=", "&#61;", table1)

        # Replace __FK_MODULE__ with the module the FK table is in.
        pos = 0
        table3 = ""
        for fkTable in re.finditer(r"__FK_MODULE__\|(\w*)\}\}", table2):
            table3 += (
                table2[pos:fkTable.start()] +
                tableModuleName[fkTable.group(1)] +
                "|" + fkTable.group(1) + "}}")
            pos = fkTable.end()
        tablesByName[tableName] = table3 + table2[pos:]


# ----------------------
# Create MediaWiki Files
# ----------------------

# Walk through modules, creating module files and table files, and adding to
# alltables.
allTablesFile = open(WIKI_ALL_TABLES_PATH, "w")

for module in modules["modules"]:

    moduleName = module["module"]
    moduleFile = open(MODULES_DIR + "/" + moduleName + ".wiki", "w")
    allTablesFile.write(
        "== [[Chado " + moduleName + " Module|Module: " + moduleName +
        "]] ==\n\n")
    
    for table in module["tables"]:
        
        # Write to allTables page
        allTablesFile.write(
            "=== Table: {{ChadoModuleTableLink|" + moduleName + "|" + table +
            "}} ===\n\n")
        allTablesFile.write("{{ChadoTable_" + table + "}}\n\n")
        
        # write to the module file
        moduleFile.write("== Table: {{ChadoTableName|" + table + "}} ==\n\n")
        moduleFile.write("{{ChadoTable_" + table + "}}\n\n")
        moduleFile.write(
            "{{ChadoTableName|" + table +"}} '''Additional Comments:'''\n\n")

        # Originally had an "AdditionalComments" template as well, but I
        # thought it would be confusing to users when they edited the wiki
        # to just see {{AdditionalComments}}.  Showing them the text below
        # in the edit window is less confusing.
        moduleFile.write(
            "Add your comments here and they will be integrated into the " +
            "{{ChadoSchemaDocHOWTOLink|schema documentation}} " +
            "as part of the next Chado release.\n\n")

        # write to the table file.
        tableFile = open(TABLES_DIR + "/" + table + ".wiki", "w")
        tableFile.write(tablesByName[table])
        tableFile.close()

    moduleFile.close()

allTablesFile.close()
