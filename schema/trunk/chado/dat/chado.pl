# Schema metadata produced by ddltrans on Thu May 29 10:39:52 EDT 2003
$schema = {
            'labelmethod' => {
                               'name' => 'labelmethod',
                               'comment' => 'ok drop table if exists labelmethod;',
                               '_entity' => 'table',
                               'primarykey' => 'labelmethod_id',
                               'column' => {
                                             'labelmethod' => {
                                                                'name' => 'labelmethod',
                                                                'allownull' => 'yes',
                                                                'type' => 'varchar(1000)',
                                                                '_entity' => 'column'
                                                              },
                                             'labelused' => {
                                                              'name' => 'labelused',
                                                              'allownull' => 'yes',
                                                              'type' => 'varchar(50)',
                                                              '_entity' => 'column'
                                                            },
                                             '_order' => [
                                                           'labelmethod_id',
                                                           'protocol_id',
                                                           'channel_id',
                                                           'labelused',
                                                           'labelmethod'
                                                         ],
                                             '_entity' => 'list',
                                             'channel_id' => {
                                                               'fk_table' => 'channel',
                                                               'name' => 'channel_id',
                                                               'allownull' => 'no',
                                                               'type' => 'int',
                                                               '_entity' => 'column',
                                                               'fk_column' => 'channel_id'
                                                             },
                                             'labelmethod_id' => {
                                                                   'name' => 'labelmethod_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'serial',
                                                                   'foreign_references' => [
                                                                                             {
                                                                                               'table' => 'biomaterial',
                                                                                               'column' => 'labelmethod_id'
                                                                                             }
                                                                                           ],
                                                                   '_entity' => 'column',
                                                                   'primarykey' => 'yes'
                                                                 },
                                             'protocol_id' => {
                                                                'fk_table' => 'protocol',
                                                                'name' => 'protocol_id',
                                                                'allownull' => 'no',
                                                                'type' => 'int',
                                                                '_entity' => 'column',
                                                                'fk_column' => 'protocol_id'
                                                              }
                                           }
                             },
            'control' => {
                           'name' => 'control',
                           'comment' => 'ok drop table if exists control;',
                           '_entity' => 'table',
                           'primarykey' => 'control_id',
                           'column' => {
                                         'tableinfo_id' => {
                                                             'fk_table' => 'tableinfo',
                                                             'name' => 'tableinfo_id',
                                                             'allownull' => 'no',
                                                             'type' => 'int',
                                                             '_entity' => 'column',
                                                             'fk_column' => 'tableinfo_id'
                                                           },
                                         'name' => {
                                                     'name' => 'name',
                                                     'allownull' => 'yes',
                                                     'type' => 'varchar(100)',
                                                     '_entity' => 'column'
                                                   },
                                         'row_id' => {
                                                       'name' => 'row_id',
                                                       'allownull' => 'no',
                                                       'type' => 'int',
                                                       '_entity' => 'column'
                                                     },
                                         '_order' => [
                                                       'control_id',
                                                       'controltype_id',
                                                       'assay_id',
                                                       'tableinfo_id',
                                                       'row_id',
                                                       'name',
                                                       'value'
                                                     ],
                                         '_entity' => 'list',
                                         'value' => {
                                                      'name' => 'value',
                                                      'allownull' => 'yes',
                                                      'type' => 'varchar(255)',
                                                      '_entity' => 'column'
                                                    },
                                         'control_id' => {
                                                           'name' => 'control_id',
                                                           'allownull' => 'no',
                                                           'type' => 'serial',
                                                           '_entity' => 'column',
                                                           'primarykey' => 'yes'
                                                         },
                                         'assay_id' => {
                                                         'fk_table' => 'assay',
                                                         'name' => 'assay_id',
                                                         'allownull' => 'no',
                                                         'type' => 'int',
                                                         '_entity' => 'column',
                                                         'fk_column' => 'assay_id'
                                                       },
                                         'controltype_id' => {
                                                               'fk_table' => 'cvterm',
                                                               'name' => 'controltype_id',
                                                               'allownull' => 'no',
                                                               'type' => 'int',
                                                               '_entity' => 'column',
                                                               'fk_column' => 'cvterm_id'
                                                             }
                                       }
                         },
            'wwwuser' => {
                           'indexes' => {
                                          'wwwuser_idx1' => {
                                                              'columns' => 'username',
                                                              'name' => 'wwwuser_idx1',
                                                              '_entity' => 'index'
                                                            },
                                          '_entity' => 'set'
                                        },
                           'column' => {}
                         },
            'assay_labeledextract' => {
                                        'name' => 'assay_labeledextract',
                                        'comment' => 'ok drop table if exists assay_labeledextract;',
                                        '_entity' => 'table',
                                        'primarykey' => 'assay_labeledextract_id',
                                        'column' => {
                                                      'labeledextract_id' => {
                                                                               'fk_table' => 'biomaterial',
                                                                               'name' => 'labeledextract_id',
                                                                               'allownull' => 'no',
                                                                               'type' => 'int',
                                                                               '_entity' => 'column',
                                                                               'fk_column' => 'biomaterial_id'
                                                                             },
                                                      'assay_labeledextract_id' => {
                                                                                     'name' => 'assay_labeledextract_id',
                                                                                     'allownull' => 'no',
                                                                                     'type' => 'serial',
                                                                                     '_entity' => 'column',
                                                                                     'primarykey' => 'yes'
                                                                                   },
                                                      '_order' => [
                                                                    'assay_labeledextract_id',
                                                                    'assay_id',
                                                                    'labeledextract_id',
                                                                    'channel_id'
                                                                  ],
                                                      '_entity' => 'list',
                                                      'channel_id' => {
                                                                        'fk_table' => 'channel',
                                                                        'name' => 'channel_id',
                                                                        'allownull' => 'no',
                                                                        'type' => 'int',
                                                                        '_entity' => 'column',
                                                                        'fk_column' => 'channel_id'
                                                                      },
                                                      'assay_id' => {
                                                                      'fk_table' => 'assay',
                                                                      'name' => 'assay_id',
                                                                      'allownull' => 'no',
                                                                      'type' => 'int',
                                                                      '_entity' => 'column',
                                                                      'fk_column' => 'assay_id'
                                                                    }
                                                    }
                                      },
            'pubprop' => {
                           'indexes' => {
                                          '_entity' => 'set',
                                          'pubprop_idx1' => {
                                                              'columns' => 'pub_id',
                                                              'name' => 'pubprop_idx1',
                                                              '_entity' => 'index'
                                                            },
                                          'pubprop_idx2' => {
                                                              'columns' => 'pkey_id',
                                                              'name' => 'pubprop_idx2',
                                                              '_entity' => 'index'
                                                            }
                                        },
                           'name' => 'pubprop',
                           'comment' => 'arank: order of author in author list for this pub  editor: indicates whether the author is an editor for linked publication',
                           '_entity' => 'table',
                           'primarykey' => 'pubprop_id',
                           'column' => {
                                         'pval' => {
                                                     'name' => 'pval',
                                                     'allownull' => 'no',
                                                     'type' => 'text',
                                                     '_entity' => 'column',
                                                     'unique' => 3
                                                   },
                                         'pub_id' => {
                                                       'fk_table' => 'pub',
                                                       'name' => 'pub_id',
                                                       'allownull' => 'no',
                                                       'type' => 'int',
                                                       '_entity' => 'column',
                                                       'fk_column' => 'pub_id',
                                                       'unique' => 3
                                                     },
                                         '_order' => [
                                                       'pubprop_id',
                                                       'pub_id',
                                                       'pkey_id',
                                                       'pval',
                                                       'prank'
                                                     ],
                                         'prank' => {
                                                      'name' => 'prank',
                                                      'allownull' => 'yes',
                                                      'type' => 'integer',
                                                      '_entity' => 'column'
                                                    },
                                         'pubprop_id' => {
                                                           'name' => 'pubprop_id',
                                                           'allownull' => 'no',
                                                           'type' => 'serial',
                                                           '_entity' => 'column',
                                                           'primarykey' => 'yes'
                                                         },
                                         '_entity' => 'list',
                                         'pkey_id' => {
                                                        'fk_table' => 'cvterm',
                                                        'name' => 'pkey_id',
                                                        'allownull' => 'no',
                                                        'type' => 'int',
                                                        '_entity' => 'column',
                                                        'fk_column' => 'cvterm_id',
                                                        'unique' => 3
                                                      }
                                       },
                           'unique' => [
                                         'pub_id',
                                         'pkey_id',
                                         'pval'
                                       ]
                         },
            'eimage' => {
                          'name' => 'eimage',
                          '_entity' => 'table',
                          'primarykey' => 'eimage_id',
                          'column' => {
                                        'eimage_type' => {
                                                           'name' => 'eimage_type',
                                                           'allownull' => 'no',
                                                           'type' => 'varchar(255)',
                                                           '_entity' => 'column'
                                                         },
                                        'eimage_data' => {
                                                           'name' => 'eimage_data',
                                                           'allownull' => 'yes',
                                                           'type' => 'text',
                                                           '_entity' => 'column'
                                                         },
                                        'image_uri' => {
                                                         'name' => 'image_uri',
                                                         'allownull' => 'yes',
                                                         'type' => 'varchar(255)',
                                                         '_entity' => 'column'
                                                       },
                                        '_order' => [
                                                      'eimage_id',
                                                      'eimage_data',
                                                      'eimage_type',
                                                      'image_uri'
                                                    ],
                                        'eimage_id' => {
                                                         'name' => 'eimage_id',
                                                         'allownull' => 'no',
                                                         'type' => 'serial',
                                                         'foreign_references' => [
                                                                                   {
                                                                                     'table' => 'expression_image',
                                                                                     'column' => 'eimage_id'
                                                                                   }
                                                                                 ],
                                                         '_entity' => 'column',
                                                         'primarykey' => 'yes'
                                                       },
                                        '_entity' => 'list'
                                      }
                        },
            'assay_biomaterial' => {
                                     'name' => 'assay_biomaterial',
                                     'comment' => 'ok drop table if exists assay_biomaterial;',
                                     '_entity' => 'table',
                                     'primarykey' => 'assay_biomaterial_id',
                                     'column' => {
                                                   '_order' => [
                                                                 'assay_biomaterial_id',
                                                                 'assay_id',
                                                                 'biomaterial_id'
                                                               ],
                                                   '_entity' => 'list',
                                                   'biomaterial_id' => {
                                                                         'fk_table' => 'biomaterial',
                                                                         'name' => 'biomaterial_id',
                                                                         'allownull' => 'no',
                                                                         'type' => 'int',
                                                                         '_entity' => 'column',
                                                                         'fk_column' => 'biomaterial_id'
                                                                       },
                                                   'assay_id' => {
                                                                   'fk_table' => 'assay',
                                                                   'name' => 'assay_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'assay_id'
                                                                 },
                                                   'assay_biomaterial_id' => {
                                                                               'name' => 'assay_biomaterial_id',
                                                                               'allownull' => 'no',
                                                                               'type' => 'serial',
                                                                               '_entity' => 'column',
                                                                               'primarykey' => 'yes'
                                                                             }
                                                 }
                                   },
            'element' => {
                           'name' => 'element',
                           'comment' => 'dropped elementannotation.  use featureprop instead. ok drop table if exists element;',
                           '_entity' => 'table',
                           'primarykey' => 'element_id',
                           'column' => {
                                         'tinyint1' => {
                                                         'name' => 'tinyint1',
                                                         'allownull' => 'yes',
                                                         'type' => 'int',
                                                         '_entity' => 'column'
                                                       },
                                         'smallstring1' => {
                                                             'name' => 'smallstring1',
                                                             'allownull' => 'yes',
                                                             'type' => 'varchar(100)',
                                                             '_entity' => 'column'
                                                           },
                                         'smallstring2' => {
                                                             'name' => 'smallstring2',
                                                             'allownull' => 'yes',
                                                             'type' => 'varchar(100)',
                                                             '_entity' => 'column'
                                                           },
                                         'dbxref_id' => {
                                                          'fk_table' => 'dbxref',
                                                          'name' => 'dbxref_id',
                                                          'allownull' => 'yes',
                                                          'type' => 'int',
                                                          '_entity' => 'column',
                                                          'fk_column' => 'dbxref_id'
                                                        },
                                         'string1' => {
                                                        'name' => 'string1',
                                                        'allownull' => 'yes',
                                                        'type' => 'varchar(500)',
                                                        '_entity' => 'column'
                                                      },
                                         'string2' => {
                                                        'name' => 'string2',
                                                        'allownull' => 'yes',
                                                        'type' => 'varchar(500)',
                                                        '_entity' => 'column'
                                                      },
                                         'array_id' => {
                                                         'fk_table' => 'array',
                                                         'name' => 'array_id',
                                                         'allownull' => 'no',
                                                         'type' => 'int',
                                                         '_entity' => 'column',
                                                         'fk_column' => 'array_id'
                                                       },
                                         'tinystring1' => {
                                                            'name' => 'tinystring1',
                                                            'allownull' => 'yes',
                                                            'type' => 'varchar(50)',
                                                            '_entity' => 'column'
                                                          },
                                         'tinystring2' => {
                                                            'name' => 'tinystring2',
                                                            'allownull' => 'yes',
                                                            'type' => 'varchar(50)',
                                                            '_entity' => 'column'
                                                          },
                                         'char1' => {
                                                      'name' => 'char1',
                                                      'allownull' => 'yes',
                                                      'type' => 'varchar(5)',
                                                      '_entity' => 'column'
                                                    },
                                         'char2' => {
                                                      'name' => 'char2',
                                                      'allownull' => 'yes',
                                                      'type' => 'varchar(5)',
                                                      '_entity' => 'column'
                                                    },
                                         'char3' => {
                                                      'name' => 'char3',
                                                      'allownull' => 'yes',
                                                      'type' => 'varchar(5)',
                                                      '_entity' => 'column'
                                                    },
                                         'char4' => {
                                                      'name' => 'char4',
                                                      'allownull' => 'yes',
                                                      'type' => 'varchar(5)',
                                                      '_entity' => 'column'
                                                    },
                                         'char5' => {
                                                      'name' => 'char5',
                                                      'allownull' => 'yes',
                                                      'type' => 'varchar(5)',
                                                      '_entity' => 'column'
                                                    },
                                         'char6' => {
                                                      'name' => 'char6',
                                                      'allownull' => 'yes',
                                                      'type' => 'varchar(5)',
                                                      '_entity' => 'column'
                                                    },
                                         'char7' => {
                                                      'name' => 'char7',
                                                      'allownull' => 'yes',
                                                      'type' => 'varchar(5)',
                                                      '_entity' => 'column'
                                                    },
                                         'smallint1' => {
                                                          'name' => 'smallint1',
                                                          'allownull' => 'yes',
                                                          'type' => 'int',
                                                          '_entity' => 'column'
                                                        },
                                         'element_id' => {
                                                           'name' => 'element_id',
                                                           'allownull' => 'no',
                                                           'type' => 'serial',
                                                           'foreign_references' => [
                                                                                     {
                                                                                       'table' => 'elementresult',
                                                                                       'column' => 'element_id'
                                                                                     }
                                                                                   ],
                                                           '_entity' => 'column',
                                                           'primarykey' => 'yes'
                                                         },
                                         'element_type_id' => {
                                                                'fk_table' => 'cvterm',
                                                                'name' => 'element_type_id',
                                                                'allownull' => 'yes',
                                                                'type' => 'int',
                                                                '_entity' => 'column',
                                                                'fk_column' => 'cvterm_id'
                                                              },
                                         'feature_id' => {
                                                           'fk_table' => 'feature',
                                                           'name' => 'feature_id',
                                                           'allownull' => 'yes',
                                                           'type' => 'int',
                                                           '_entity' => 'column',
                                                           'fk_column' => 'feature_id'
                                                         },
                                         'subclass_view' => {
                                                              'name' => 'subclass_view',
                                                              'allownull' => 'no',
                                                              'type' => 'varchar(27)',
                                                              '_entity' => 'column'
                                                            },
                                         '_order' => [
                                                       'element_id',
                                                       'feature_id',
                                                       'array_id',
                                                       'element_type_id',
                                                       'dbxref_id',
                                                       'subclass_view',
                                                       'tinyint1',
                                                       'smallint1',
                                                       'char1',
                                                       'char2',
                                                       'char3',
                                                       'char4',
                                                       'char5',
                                                       'char6',
                                                       'char7',
                                                       'tinystring1',
                                                       'tinystring2',
                                                       'smallstring1',
                                                       'smallstring2',
                                                       'string1',
                                                       'string2'
                                                     ],
                                         '_entity' => 'list'
                                       }
                         },
            'cvterm_dbxref' => {
                                 'indexes' => {
                                                'cvterm_dbxref_idx1' => {
                                                                          'columns' => 'cvterm_id',
                                                                          'name' => 'cvterm_dbxref_idx1',
                                                                          '_entity' => 'index'
                                                                        },
                                                'cvterm_dbxref_idx2' => {
                                                                          'columns' => 'dbxref_id',
                                                                          'name' => 'cvterm_dbxref_idx2',
                                                                          '_entity' => 'index'
                                                                        },
                                                '_entity' => 'set'
                                              },
                                 'name' => 'cvterm_dbxref',
                                 '_entity' => 'table',
                                 'primarykey' => 'cvterm_dbxref_id',
                                 'column' => {
                                               '_order' => [
                                                             'cvterm_dbxref_id',
                                                             'cvterm_id',
                                                             'dbxref_id'
                                                           ],
                                               '_entity' => 'list',
                                               'cvterm_id' => {
                                                                'fk_table' => 'cvterm',
                                                                'name' => 'cvterm_id',
                                                                'allownull' => 'no',
                                                                'type' => 'int',
                                                                '_entity' => 'column',
                                                                'fk_column' => 'cvterm_id',
                                                                'unique' => 2
                                                              },
                                               'dbxref_id' => {
                                                                'fk_table' => 'dbxref',
                                                                'name' => 'dbxref_id',
                                                                'allownull' => 'no',
                                                                'type' => 'int',
                                                                '_entity' => 'column',
                                                                'fk_column' => 'dbxref_id',
                                                                'unique' => 2
                                                              },
                                               'cvterm_dbxref_id' => {
                                                                       'name' => 'cvterm_dbxref_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'serial',
                                                                       '_entity' => 'column',
                                                                       'primarykey' => 'yes'
                                                                     }
                                             },
                                 'unique' => [
                                               'cvterm_id',
                                               'dbxref_id'
                                             ]
                               },
            'feature' => {
                           'indexes' => {
                                          'feature_idx1' => {
                                                              'columns' => 'dbxref_id',
                                                              'name' => 'feature_idx1',
                                                              '_entity' => 'index'
                                                            },
                                          'feature_lc_name' => {
                                                                 'columns' => 'lower(name)',
                                                                 'name' => 'feature_lc_name',
                                                                 '_entity' => 'index'
                                                               },
                                          'feature_idx2' => {
                                                              'columns' => 'organism_id',
                                                              'name' => 'feature_idx2',
                                                              '_entity' => 'index'
                                                            },
                                          'feature_idx3' => {
                                                              'columns' => 'type_id',
                                                              'name' => 'feature_idx3',
                                                              '_entity' => 'index'
                                                            },
                                          'feature_idx4' => {
                                                              'columns' => 'uniquename',
                                                              'name' => 'feature_idx4',
                                                              '_entity' => 'index'
                                                            },
                                          '_entity' => 'set',
                                          'feature_name_ind1' => {
                                                                   'columns' => 'name',
                                                                   'name' => 'feature_name_ind1',
                                                                   '_entity' => 'index'
                                                                 }
                                        },
                           'name' => 'feature',
                           '_entity' => 'table',
                           'primarykey' => 'feature_id',
                           'column' => {
                                         'timeaccessioned' => {
                                                                'name' => 'timeaccessioned',
                                                                'allownull' => 'no',
                                                                'type' => 'timestamp',
                                                                'comment' => 'timeaccessioned and timelastmodified are for handling object accession/  modification timestamps (as opposed to db auditing info, handled elsewhere).  The expectation is that these fields would be available to software  interacting with chado.',
                                                                '_entity' => 'column',
                                                                'default' => 'current_timestamp'
                                                              },
                                         'name' => {
                                                     'name' => 'name',
                                                     'allownull' => 'yes',
                                                     'type' => 'varchar(255)',
                                                     '_entity' => 'column'
                                                   },
                                         'timelastmodified' => {
                                                                 'name' => 'timelastmodified',
                                                                 'allownull' => 'no',
                                                                 'type' => 'timestamp',
                                                                 '_entity' => 'column',
                                                                 'default' => 'current_timestamp'
                                                               },
                                         'residues' => {
                                                         'name' => 'residues',
                                                         'allownull' => 'yes',
                                                         'type' => 'text',
                                                         '_entity' => 'column'
                                                       },
                                         'dbxref_id' => {
                                                          'fk_table' => 'dbxref',
                                                          'name' => 'dbxref_id',
                                                          'allownull' => 'yes',
                                                          'type' => 'int',
                                                          '_entity' => 'column',
                                                          'fk_column' => 'dbxref_id'
                                                        },
                                         'feature_id' => {
                                                           'name' => 'feature_id',
                                                           'allownull' => 'no',
                                                           'type' => 'serial',
                                                           'foreign_references' => [
                                                                                     {
                                                                                       'table' => 'element',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'wwwuser_feature',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'feature_cvterm',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'featureloc',
                                                                                       'column' => 'srcfeature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'featureloc',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'featureprop',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'analysisfeature',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'feature_genotype',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'compositeelementresult',
                                                                                       'column' => 'compositeelement_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'featurepos',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'featurepos',
                                                                                       'column' => 'map_feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'feature_dbxref',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'feature_synonym',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'featurerange',
                                                                                       'column' => 'leftendf_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'featurerange',
                                                                                       'column' => 'rightendf_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'featurerange',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'featurerange',
                                                                                       'column' => 'leftstartf_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'featurerange',
                                                                                       'column' => 'rightstartf_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'feature_relationship',
                                                                                       'column' => 'objfeature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'feature_relationship',
                                                                                       'column' => 'subjfeature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'feature_phenotype',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'feature_pub',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'interaction_subj',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'interaction_obj',
                                                                                       'column' => 'feature_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'feature_expression',
                                                                                       'column' => 'feature_id'
                                                                                     }
                                                                                   ],
                                                           '_entity' => 'column',
                                                           'primarykey' => 'yes'
                                                         },
                                         'uniquename' => {
                                                           'name' => 'uniquename',
                                                           'allownull' => 'no',
                                                           'type' => 'text',
                                                           '_entity' => 'column',
                                                           'unique' => 2
                                                         },
                                         'seqlen' => {
                                                       'name' => 'seqlen',
                                                       'allownull' => 'yes',
                                                       'type' => 'int',
                                                       '_entity' => 'column'
                                                     },
                                         'md5checksum' => {
                                                            'name' => 'md5checksum',
                                                            'allownull' => 'yes',
                                                            'type' => 'char(32)',
                                                            '_entity' => 'column'
                                                          },
                                         '_order' => [
                                                       'feature_id',
                                                       'dbxref_id',
                                                       'organism_id',
                                                       'name',
                                                       'uniquename',
                                                       'residues',
                                                       'seqlen',
                                                       'md5checksum',
                                                       'type_id',
                                                       'is_analysis',
                                                       'timeaccessioned',
                                                       'timelastmodified'
                                                     ],
                                         '_entity' => 'list',
                                         'organism_id' => {
                                                            'fk_table' => 'organism',
                                                            'name' => 'organism_id',
                                                            'allownull' => 'no',
                                                            'type' => 'int',
                                                            '_entity' => 'column',
                                                            'fk_column' => 'organism_id',
                                                            'unique' => 2
                                                          },
                                         'type_id' => {
                                                        'fk_table' => 'cvterm',
                                                        'name' => 'type_id',
                                                        'allownull' => 'no',
                                                        'type' => 'int',
                                                        '_entity' => 'column',
                                                        'fk_column' => 'cvterm_id'
                                                      },
                                         'is_analysis' => {
                                                            'name' => 'is_analysis',
                                                            'allownull' => 'no',
                                                            'type' => 'boolean',
                                                            '_entity' => 'column',
                                                            'default' => '\'false\''
                                                          }
                                       },
                           'unique' => [
                                         'organism_id',
                                         'uniquename'
                                       ]
                         },
            'cvtermsynonym' => {
                                 'indexes' => {
                                                'cvtermsynonym_idx1' => {
                                                                          'columns' => 'cvterm_id',
                                                                          'name' => 'cvtermsynonym_idx1',
                                                                          '_entity' => 'index'
                                                                        },
                                                '_entity' => 'set'
                                              },
                                 'name' => 'cvtermsynonym',
                                 '_entity' => 'table',
                                 'primarykey' => 'cvtermsynonym_id',
                                 'column' => {
                                               'cvtermsynonym_id' => {
                                                                       'name' => 'cvtermsynonym_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'int',
                                                                       '_entity' => 'column',
                                                                       'primarykey' => 'yes'
                                                                     },
                                               '_order' => [
                                                             'cvtermsynonym_id',
                                                             'cvterm_id',
                                                             'termsynonym'
                                                           ],
                                               '_entity' => 'list',
                                               'termsynonym' => {
                                                                  'name' => 'termsynonym',
                                                                  'allownull' => 'no',
                                                                  'type' => 'varchar(255)',
                                                                  '_entity' => 'column',
                                                                  'unique' => 2
                                                                },
                                               'cvterm_id' => {
                                                                'fk_table' => 'cvterm',
                                                                'name' => 'cvterm_id',
                                                                'allownull' => 'no',
                                                                'type' => 'int',
                                                                '_entity' => 'column',
                                                                'fk_column' => 'cvterm_id',
                                                                'unique' => 2
                                                              }
                                             },
                                 'unique' => [
                                               'cvterm_id',
                                               'termsynonym'
                                             ]
                               },
            'wwwuser_feature' => {
                                   'indexes' => {
                                                  '_entity' => 'set',
                                                  'wwwuser_feature_idx1' => {
                                                                              'columns' => 'wwwuser_id',
                                                                              'name' => 'wwwuser_feature_idx1',
                                                                              '_entity' => 'index'
                                                                            },
                                                  'wwwuser_feature_idx2' => {
                                                                              'columns' => 'feature_id',
                                                                              'name' => 'wwwuser_feature_idx2',
                                                                              '_entity' => 'index'
                                                                            }
                                                },
                                   'name' => 'wwwuser_feature',
                                   'comment' => 'track wwwuser interest in features',
                                   '_entity' => 'table',
                                   'primarykey' => 'wwwuser_feature_id',
                                   'column' => {
                                                 'feature_id' => {
                                                                   'fk_table' => 'feature',
                                                                   'name' => 'feature_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'feature_id',
                                                                   'unique' => 2
                                                                 },
                                                 'wwwuser_id' => {
                                                                   'fk_table' => 'wwwuser',
                                                                   'name' => 'wwwuser_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'wwwuser_id',
                                                                   'unique' => 2
                                                                 },
                                                 'world_read' => {
                                                                   'name' => 'world_read',
                                                                   'allownull' => 'no',
                                                                   'type' => 'smallint',
                                                                   '_entity' => 'column',
                                                                   'default' => 1
                                                                 },
                                                 'wwwuser_feature_id' => {
                                                                           'name' => 'wwwuser_feature_id',
                                                                           'allownull' => 'no',
                                                                           'type' => 'serial',
                                                                           '_entity' => 'column',
                                                                           'primarykey' => 'yes'
                                                                         },
                                                 '_order' => [
                                                               'wwwuser_feature_id',
                                                               'wwwuser_id',
                                                               'feature_id',
                                                               'world_read'
                                                             ],
                                                 '_entity' => 'list'
                                               },
                                   'unique' => [
                                                 'wwwuser_id',
                                                 'feature_id'
                                               ]
                                 },
            'featuremap_pub' => {
                                  'indexes' => {
                                                 '_entity' => 'set',
                                                 'featuremap_pub_idx1' => {
                                                                            'columns' => 'featuremap_id',
                                                                            'name' => 'featuremap_pub_idx1',
                                                                            '_entity' => 'index'
                                                                          },
                                                 'featuremap_pub_idx2' => {
                                                                            'columns' => 'pub_id',
                                                                            'name' => 'featuremap_pub_idx2',
                                                                            '_entity' => 'index'
                                                                          }
                                               },
                                  'name' => 'featuremap_pub',
                                  'comment' => 'map_feature_id links to the feature (map) upon which the feature is  being localized',
                                  '_entity' => 'table',
                                  'primarykey' => 'featuremap_pub_id',
                                  'column' => {
                                                'pub_id' => {
                                                              'fk_table' => 'pub',
                                                              'name' => 'pub_id',
                                                              'allownull' => 'no',
                                                              'type' => 'int',
                                                              '_entity' => 'column',
                                                              'fk_column' => 'pub_id'
                                                            },
                                                '_order' => [
                                                              'featuremap_pub_id',
                                                              'featuremap_id',
                                                              'pub_id'
                                                            ],
                                                'featuremap_pub_id' => {
                                                                         'name' => 'featuremap_pub_id',
                                                                         'allownull' => 'no',
                                                                         'type' => 'serial',
                                                                         '_entity' => 'column',
                                                                         'primarykey' => 'yes'
                                                                       },
                                                '_entity' => 'list',
                                                'featuremap_id' => {
                                                                     'fk_table' => 'featuremap',
                                                                     'name' => 'featuremap_id',
                                                                     'allownull' => 'no',
                                                                     'type' => 'int',
                                                                     '_entity' => 'column',
                                                                     'fk_column' => 'featuremap_id'
                                                                   }
                                              }
                                },
            'protocol' => {
                            'name' => 'protocol',
                            'comment' => 'ok drop table if exists protocol;',
                            '_entity' => 'table',
                            'primarykey' => 'protocol_id',
                            'column' => {
                                          'uri' => {
                                                     'name' => 'uri',
                                                     'allownull' => 'yes',
                                                     'type' => 'varchar(100)',
                                                     '_entity' => 'column'
                                                   },
                                          'name' => {
                                                      'name' => 'name',
                                                      'allownull' => 'no',
                                                      'type' => 'varchar(100)',
                                                      '_entity' => 'column'
                                                    },
                                          'hardwaredescription' => {
                                                                     'name' => 'hardwaredescription',
                                                                     'allownull' => 'yes',
                                                                     'type' => 'varchar(500)',
                                                                     '_entity' => 'column'
                                                                   },
                                          'pub_id' => {
                                                        'fk_table' => 'pub',
                                                        'name' => 'pub_id',
                                                        'allownull' => 'yes',
                                                        'type' => 'int',
                                                        '_entity' => 'column',
                                                        'fk_column' => 'pub_id'
                                                      },
                                          'protocoldescription' => {
                                                                     'name' => 'protocoldescription',
                                                                     'allownull' => 'yes',
                                                                     'type' => 'varchar(4000)',
                                                                     '_entity' => 'column'
                                                                   },
                                          'dbxref_id' => {
                                                           'fk_table' => 'dbxref',
                                                           'name' => 'dbxref_id',
                                                           'allownull' => 'yes',
                                                           'type' => 'int',
                                                           '_entity' => 'column',
                                                           'fk_column' => 'dbxref_id'
                                                         },
                                          '_order' => [
                                                        'protocol_id',
                                                        'protocol_type_id',
                                                        'pub_id',
                                                        'dbxref_id',
                                                        'name',
                                                        'uri',
                                                        'protocoldescription',
                                                        'hardwaredescription',
                                                        'softwaredescription'
                                                      ],
                                          '_entity' => 'list',
                                          'protocol_id' => {
                                                             'name' => 'protocol_id',
                                                             'allownull' => 'no',
                                                             'type' => 'serial',
                                                             'foreign_references' => [
                                                                                       {
                                                                                         'table' => 'labelmethod',
                                                                                         'column' => 'protocol_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'assay',
                                                                                         'column' => 'protocol_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'treatment',
                                                                                         'column' => 'protocol_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'quantification',
                                                                                         'column' => 'protocol_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'protocolparam',
                                                                                         'column' => 'protocol_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'acquisition',
                                                                                         'column' => 'protocol_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'array',
                                                                                         'column' => 'protocol_id'
                                                                                       }
                                                                                     ],
                                                             '_entity' => 'column',
                                                             'primarykey' => 'yes'
                                                           },
                                          'softwaredescription' => {
                                                                     'name' => 'softwaredescription',
                                                                     'allownull' => 'yes',
                                                                     'type' => 'varchar(500)',
                                                                     '_entity' => 'column'
                                                                   },
                                          'protocol_type_id' => {
                                                                  'fk_table' => 'cvterm',
                                                                  'name' => 'protocol_type_id',
                                                                  'allownull' => 'no',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'cvterm_id'
                                                                }
                                        }
                          },
            'expression_image' => {
                                    'indexes' => {
                                                   'expression_image_idx2' => {
                                                                                'columns' => 'eimage_id',
                                                                                'name' => 'expression_image_idx2',
                                                                                '_entity' => 'index'
                                                                              },
                                                   '_entity' => 'set',
                                                   'expression_image_idx1' => {
                                                                                'columns' => 'expression_id',
                                                                                'name' => 'expression_image_idx1',
                                                                                '_entity' => 'index'
                                                                              }
                                                 },
                                    'name' => 'expression_image',
                                    'comment' => 'we expect images in eimage_data (eg jpegs) to be uuencoded  describes the type of data in eimage_data',
                                    '_entity' => 'table',
                                    'primarykey' => 'expression_image_id',
                                    'column' => {
                                                  '_order' => [
                                                                'expression_image_id',
                                                                'expression_id',
                                                                'eimage_id'
                                                              ],
                                                  'eimage_id' => {
                                                                   'fk_table' => 'eimage',
                                                                   'name' => 'eimage_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'eimage_id',
                                                                   'unique' => 2
                                                                 },
                                                  'expression_id' => {
                                                                       'fk_table' => 'expression',
                                                                       'name' => 'expression_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'int',
                                                                       '_entity' => 'column',
                                                                       'fk_column' => 'expression_id',
                                                                       'unique' => 2
                                                                     },
                                                  '_entity' => 'list',
                                                  'expression_image_id' => {
                                                                             'name' => 'expression_image_id',
                                                                             'allownull' => 'no',
                                                                             'type' => 'serial',
                                                                             '_entity' => 'column',
                                                                             'primarykey' => 'yes'
                                                                           }
                                                },
                                    'unique' => [
                                                  'expression_id',
                                                  'eimage_id'
                                                ]
                                  },
            'featureprop_pub' => {
                                   'indexes' => {
                                                  'featureprop_pub_idx1' => {
                                                                              'columns' => 'featureprop_id',
                                                                              'name' => 'featureprop_pub_idx1',
                                                                              '_entity' => 'index'
                                                                            },
                                                  'featureprop_pub_idx2' => {
                                                                              'columns' => 'pub_id',
                                                                              'name' => 'featureprop_pub_idx2',
                                                                              '_entity' => 'index'
                                                                            },
                                                  '_entity' => 'set'
                                                },
                                   'name' => 'featureprop_pub',
                                   '_entity' => 'table',
                                   'primarykey' => 'featureprop_pub_id',
                                   'column' => {
                                                 'featureprop_id' => {
                                                                       'fk_table' => 'featureprop',
                                                                       'name' => 'featureprop_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'int',
                                                                       '_entity' => 'column',
                                                                       'fk_column' => 'featureprop_id',
                                                                       'unique' => 2
                                                                     },
                                                 'pub_id' => {
                                                               'fk_table' => 'pub',
                                                               'name' => 'pub_id',
                                                               'allownull' => 'no',
                                                               'type' => 'int',
                                                               '_entity' => 'column',
                                                               'fk_column' => 'pub_id',
                                                               'unique' => 2
                                                             },
                                                 '_order' => [
                                                               'featureprop_pub_id',
                                                               'featureprop_id',
                                                               'pub_id'
                                                             ],
                                                 '_entity' => 'list',
                                                 'featureprop_pub_id' => {
                                                                           'name' => 'featureprop_pub_id',
                                                                           'allownull' => 'no',
                                                                           'type' => 'serial',
                                                                           '_entity' => 'column',
                                                                           'primarykey' => 'yes'
                                                                         }
                                               },
                                   'unique' => [
                                                 'featureprop_id',
                                                 'pub_id'
                                               ]
                                 },
            'author' => {
                          'name' => 'author',
                          'comment' => 'using the FB author table columns',
                          '_entity' => 'table',
                          'primarykey' => 'author_id',
                          'column' => {
                                        'surname' => {
                                                       'name' => 'surname',
                                                       'allownull' => 'no',
                                                       'type' => 'varchar(100)',
                                                       '_entity' => 'column',
                                                       'unique' => 3
                                                     },
                                        '_order' => [
                                                      'author_id',
                                                      'surname',
                                                      'givennames',
                                                      'suffix'
                                                    ],
                                        '_entity' => 'list',
                                        'suffix' => {
                                                      'name' => 'suffix',
                                                      'allownull' => 'yes',
                                                      'type' => 'varchar(100)',
                                                      '_entity' => 'column',
                                                      'unique' => 3
                                                    },
                                        'givennames' => {
                                                          'name' => 'givennames',
                                                          'allownull' => 'yes',
                                                          'type' => 'varchar(100)',
                                                          '_entity' => 'column',
                                                          'unique' => 3
                                                        },
                                        'author_id' => {
                                                         'name' => 'author_id',
                                                         'allownull' => 'no',
                                                         'type' => 'serial',
                                                         'foreign_references' => [
                                                                                   {
                                                                                     'table' => 'assay',
                                                                                     'column' => 'operator_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'wwwuser_author',
                                                                                     'column' => 'author_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'pub_author',
                                                                                     'column' => 'author_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'quantification',
                                                                                     'column' => 'operator_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'biomaterial',
                                                                                     'column' => 'biosourceprovider_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'study',
                                                                                     'column' => 'contact_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'array',
                                                                                     'column' => 'manufacturer_id'
                                                                                   }
                                                                                 ],
                                                         '_entity' => 'column',
                                                         'primarykey' => 'yes'
                                                       }
                                      },
                          'unique' => [
                                        'surname',
                                        'givennames',
                                        'suffix'
                                      ]
                        },
            'studydesign_assay' => {
                                     'name' => 'studydesign_assay',
                                     'comment' => 'ok renamed from studydesignassay to studydesign_assay drop table if exists studydesign_assay;',
                                     '_entity' => 'table',
                                     'primarykey' => 'studydesign_assay_id',
                                     'column' => {
                                                   '_order' => [
                                                                 'studydesign_assay_id',
                                                                 'studydesign_id',
                                                                 'assay_id'
                                                               ],
                                                   '_entity' => 'list',
                                                   'assay_id' => {
                                                                   'fk_table' => 'assay',
                                                                   'name' => 'assay_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'assay_id'
                                                                 },
                                                   'studydesign_id' => {
                                                                         'fk_table' => 'studydesign',
                                                                         'name' => 'studydesign_id',
                                                                         'allownull' => 'no',
                                                                         'type' => 'int',
                                                                         '_entity' => 'column',
                                                                         'fk_column' => 'studydesign_id'
                                                                       },
                                                   'studydesign_assay_id' => {
                                                                               'name' => 'studydesign_assay_id',
                                                                               'allownull' => 'no',
                                                                               'type' => 'serial',
                                                                               '_entity' => 'column',
                                                                               'primarykey' => 'yes'
                                                                             }
                                                 }
                                   },
            'mageml' => {
                          'name' => 'mageml',
                          'comment' => 'ok  warning - mage_ml does not appear in core.tableinfo drop table if exists mageml;',
                          '_entity' => 'table',
                          'primarykey' => 'mageml_id',
                          'column' => {
                                        'mage_ml' => {
                                                       'name' => 'mage_ml',
                                                       'allownull' => 'no',
                                                       'type' => 'varchar',
                                                       '_entity' => 'column'
                                                     },
                                        '_order' => [
                                                      'mageml_id',
                                                      'mage_package',
                                                      'mage_ml'
                                                    ],
                                        '_entity' => 'list',
                                        'mage_package' => {
                                                            'name' => 'mage_package',
                                                            'allownull' => 'no',
                                                            'type' => 'varchar(100)',
                                                            '_entity' => 'column'
                                                          },
                                        'mageml_id' => {
                                                         'name' => 'mageml_id',
                                                         'allownull' => 'no',
                                                         'type' => 'serial',
                                                         'foreign_references' => [
                                                                                   {
                                                                                     'table' => 'magedocumentation',
                                                                                     'column' => 'mageml_id'
                                                                                   }
                                                                                 ],
                                                         '_entity' => 'column',
                                                         'primarykey' => 'yes'
                                                       }
                                      }
                        },
            'wwwuser_cvterm' => {
                                  'indexes' => {
                                                 'wwwuser_cvterm_idx1' => {
                                                                            'columns' => 'wwwuser_id',
                                                                            'name' => 'wwwuser_cvterm_idx1',
                                                                            '_entity' => 'index'
                                                                          },
                                                 'wwwuser_cvterm_idx2' => {
                                                                            'columns' => 'cvterm_id',
                                                                            'name' => 'wwwuser_cvterm_idx2',
                                                                            '_entity' => 'index'
                                                                          },
                                                 '_entity' => 'set'
                                               },
                                  'name' => 'wwwuser_cvterm',
                                  'comment' => 'track wwwuser interest in cvterms',
                                  '_entity' => 'table',
                                  'primarykey' => 'wwwuser_cvterm_id',
                                  'column' => {
                                                'wwwuser_id' => {
                                                                  'fk_table' => 'wwwuser',
                                                                  'name' => 'wwwuser_id',
                                                                  'allownull' => 'no',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'wwwuser_id',
                                                                  'unique' => 2
                                                                },
                                                'wwwuser_cvterm_id' => {
                                                                         'name' => 'wwwuser_cvterm_id',
                                                                         'allownull' => 'no',
                                                                         'type' => 'serial',
                                                                         '_entity' => 'column',
                                                                         'primarykey' => 'yes'
                                                                       },
                                                'world_read' => {
                                                                  'name' => 'world_read',
                                                                  'allownull' => 'no',
                                                                  'type' => 'smallint',
                                                                  '_entity' => 'column',
                                                                  'default' => 1
                                                                },
                                                '_order' => [
                                                              'wwwuser_cvterm_id',
                                                              'wwwuser_id',
                                                              'cvterm_id',
                                                              'world_read'
                                                            ],
                                                '_entity' => 'list',
                                                'cvterm_id' => {
                                                                 'fk_table' => 'cvterm',
                                                                 'name' => 'cvterm_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'cvterm_id',
                                                                 'unique' => 2
                                                               }
                                              },
                                  'unique' => [
                                                'wwwuser_id',
                                                'cvterm_id'
                                              ]
                                },
            'studyfactorvalue' => {
                                    'name' => 'studyfactorvalue',
                                    'comment' => 'ok drop table if exists studyfactorvalue;',
                                    '_entity' => 'table',
                                    'primarykey' => 'studyfactorvalue_id',
                                    'column' => {
                                                  'name' => {
                                                              'name' => 'name',
                                                              'allownull' => 'yes',
                                                              'type' => 'varchar(100)',
                                                              '_entity' => 'column'
                                                            },
                                                  'studyfactorvalue_id' => {
                                                                             'name' => 'studyfactorvalue_id',
                                                                             'allownull' => 'no',
                                                                             'type' => 'serial',
                                                                             '_entity' => 'column',
                                                                             'primarykey' => 'yes'
                                                                           },
                                                  '_order' => [
                                                                'studyfactorvalue_id',
                                                                'studyfactor_id',
                                                                'assay_id',
                                                                'factorvalue',
                                                                'name'
                                                              ],
                                                  'factorvalue' => {
                                                                     'name' => 'factorvalue',
                                                                     'allownull' => 'no',
                                                                     'type' => 'varchar(100)',
                                                                     '_entity' => 'column'
                                                                   },
                                                  'studyfactor_id' => {
                                                                        'fk_table' => 'studyfactor',
                                                                        'name' => 'studyfactor_id',
                                                                        'allownull' => 'no',
                                                                        'type' => 'int',
                                                                        '_entity' => 'column',
                                                                        'fk_column' => 'studyfactor_id'
                                                                      },
                                                  '_entity' => 'list',
                                                  'assay_id' => {
                                                                  'fk_table' => 'assay',
                                                                  'name' => 'assay_id',
                                                                  'allownull' => 'no',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'assay_id'
                                                                }
                                                }
                                  },
            'processimplementationparam' => {
                                              'name' => 'processimplementationparam',
                                              'comment' => 'ok drop table if exists processimplementationparam;',
                                              '_entity' => 'table',
                                              'primarykey' => 'processimplementationparam_id',
                                              'column' => {
                                                            'name' => {
                                                                        'name' => 'name',
                                                                        'allownull' => 'no',
                                                                        'type' => 'varchar(100)',
                                                                        '_entity' => 'column'
                                                                      },
                                                            'processimplementation_id' => {
                                                                                            'fk_table' => 'processimplementation',
                                                                                            'name' => 'processimplementation_id',
                                                                                            'allownull' => 'no',
                                                                                            'type' => 'int',
                                                                                            '_entity' => 'column',
                                                                                            'fk_column' => 'processimplementation_id'
                                                                                          },
                                                            'processimplementationparam_id' => {
                                                                                                 'name' => 'processimplementationparam_id',
                                                                                                 'allownull' => 'no',
                                                                                                 'type' => 'serial',
                                                                                                 '_entity' => 'column',
                                                                                                 'primarykey' => 'yes'
                                                                                               },
                                                            '_order' => [
                                                                          'processimplementationparam_id',
                                                                          'processimplementation_id',
                                                                          'name',
                                                                          'value'
                                                                        ],
                                                            '_entity' => 'list',
                                                            'value' => {
                                                                         'name' => 'value',
                                                                         'allownull' => 'no',
                                                                         'type' => 'varchar(100)',
                                                                         '_entity' => 'column'
                                                                       }
                                                          }
                                            },
            'project' => {
                           'name' => 'project',
                           '_entity' => 'table',
                           'primarykey' => 'project_id',
                           'column' => {
                                         'name' => {
                                                     'name' => 'name',
                                                     'allownull' => 'no',
                                                     'type' => 'varchar(255)',
                                                     '_entity' => 'column'
                                                   },
                                         'project_id' => {
                                                           'name' => 'project_id',
                                                           'allownull' => 'no',
                                                           'type' => 'serial',
                                                           'foreign_references' => [
                                                                                     {
                                                                                       'table' => 'wwwuser_project',
                                                                                       'column' => 'project_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'projectlink',
                                                                                       'column' => 'project_id'
                                                                                     }
                                                                                   ],
                                                           '_entity' => 'column',
                                                           'primarykey' => 'yes'
                                                         },
                                         '_order' => [
                                                       'project_id',
                                                       'name',
                                                       'description'
                                                     ],
                                         'description' => {
                                                            'name' => 'description',
                                                            'allownull' => 'no',
                                                            'type' => 'varchar(255)',
                                                            '_entity' => 'column'
                                                          },
                                         '_entity' => 'list'
                                       }
                         },
            'pub_relationship' => {
                                    'indexes' => {
                                                   '_entity' => 'set',
                                                   'pub_relationship_idx1' => {
                                                                                'columns' => 'subj_pub_id',
                                                                                'name' => 'pub_relationship_idx1',
                                                                                '_entity' => 'index'
                                                                              },
                                                   'pub_relationship_idx2' => {
                                                                                'columns' => 'obj_pub_id',
                                                                                'name' => 'pub_relationship_idx2',
                                                                                '_entity' => 'index'
                                                                              },
                                                   'pub_relationship_idx3' => {
                                                                                'columns' => 'type_id',
                                                                                'name' => 'pub_relationship_idx3',
                                                                                '_entity' => 'index'
                                                                              }
                                                 },
                                    'name' => 'pub_relationship',
                                    'comment' => 'title: title of paper, chapter of book, journal, etc  volumetitle: title of part if one of a series  series_name: full name of (journal) series  pages: page number range[s], eg, 457--459, viii + 664pp, lv--lvii  type_id: the type of the publication (book, journal, poem, graffiti, etc)  is_obsolete: do we want this even though we have the relationship in pub_relationship?  Handle relationships between publications, eg, when one publication  makes others obsolete, when one publication contains errata with  respect to other publication(s), or when one publication also  appears in another pub (I think these three are it - at least for fb)',
                                    '_entity' => 'table',
                                    'primarykey' => 'pub_relationship_id',
                                    'column' => {
                                                  '_order' => [
                                                                'pub_relationship_id',
                                                                'subj_pub_id',
                                                                'obj_pub_id',
                                                                'type_id'
                                                              ],
                                                  'pub_relationship_id' => {
                                                                             'name' => 'pub_relationship_id',
                                                                             'allownull' => 'no',
                                                                             'type' => 'serial',
                                                                             '_entity' => 'column',
                                                                             'primarykey' => 'yes'
                                                                           },
                                                  '_entity' => 'list',
                                                  'obj_pub_id' => {
                                                                    'fk_table' => 'pub',
                                                                    'name' => 'obj_pub_id',
                                                                    'allownull' => 'no',
                                                                    'type' => 'int',
                                                                    '_entity' => 'column',
                                                                    'fk_column' => 'pub_id',
                                                                    'unique' => 3
                                                                  },
                                                  'type_id' => {
                                                                 'fk_table' => 'cvterm',
                                                                 'name' => 'type_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'cvterm_id',
                                                                 'unique' => 3
                                                               },
                                                  'subj_pub_id' => {
                                                                     'fk_table' => 'pub',
                                                                     'name' => 'subj_pub_id',
                                                                     'allownull' => 'no',
                                                                     'type' => 'int',
                                                                     '_entity' => 'column',
                                                                     'fk_column' => 'pub_id',
                                                                     'unique' => 3
                                                                   }
                                                },
                                    'unique' => [
                                                  'subj_pub_id',
                                                  'obj_pub_id',
                                                  'type_id'
                                                ]
                                  },
            'study_assay' => {
                               'name' => 'study_assay',
                               'comment' => 'ok renamed from studyassay to study_assay drop table if exists study_assay;',
                               '_entity' => 'table',
                               'primarykey' => 'study_assay_id',
                               'column' => {
                                             '_order' => [
                                                           'study_assay_id',
                                                           'study_id',
                                                           'assay_id'
                                                         ],
                                             '_entity' => 'list',
                                             'assay_id' => {
                                                             'fk_table' => 'assay',
                                                             'name' => 'assay_id',
                                                             'allownull' => 'no',
                                                             'type' => 'int',
                                                             '_entity' => 'column',
                                                             'fk_column' => 'assay_id'
                                                           },
                                             'study_id' => {
                                                             'fk_table' => 'study',
                                                             'name' => 'study_id',
                                                             'allownull' => 'no',
                                                             'type' => 'int',
                                                             '_entity' => 'column',
                                                             'fk_column' => 'study_id'
                                                           },
                                             'study_assay_id' => {
                                                                   'name' => 'study_assay_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'serial',
                                                                   '_entity' => 'column',
                                                                   'primarykey' => 'yes'
                                                                 }
                                           }
                             },
            'processinvocation' => {
                                     'name' => 'processinvocation',
                                     'comment' => 'ok drop table if exists processinvocation;',
                                     '_entity' => 'table',
                                     'primarykey' => 'processinvocation_id',
                                     'column' => {
                                                   'processimplementation_id' => {
                                                                                   'fk_table' => 'processimplementation',
                                                                                   'name' => 'processimplementation_id',
                                                                                   'allownull' => 'no',
                                                                                   'type' => 'int',
                                                                                   '_entity' => 'column',
                                                                                   'fk_column' => 'processimplementation_id'
                                                                                 },
                                                   '_order' => [
                                                                 'processinvocation_id',
                                                                 'processimplementation_id',
                                                                 'processinvocationdate',
                                                                 'description'
                                                               ],
                                                   'description' => {
                                                                      'name' => 'description',
                                                                      'allownull' => 'yes',
                                                                      'type' => 'varchar(500)',
                                                                      '_entity' => 'column'
                                                                    },
                                                   '_entity' => 'list',
                                                   'processinvocation_id' => {
                                                                               'name' => 'processinvocation_id',
                                                                               'allownull' => 'no',
                                                                               'type' => 'serial',
                                                                               'foreign_references' => [
                                                                                                         {
                                                                                                           'table' => 'processio',
                                                                                                           'column' => 'processinvocation_id'
                                                                                                         },
                                                                                                         {
                                                                                                           'table' => 'processinvocationparam',
                                                                                                           'column' => 'processinvocation_id'
                                                                                                         },
                                                                                                         {
                                                                                                           'table' => 'processinvocation_quantification',
                                                                                                           'column' => 'processinvocation_id'
                                                                                                         }
                                                                                                       ],
                                                                               '_entity' => 'column',
                                                                               'primarykey' => 'yes'
                                                                             },
                                                   'processinvocationdate' => {
                                                                                'name' => 'processinvocationdate',
                                                                                'allownull' => 'no',
                                                                                'type' => 'date',
                                                                                '_entity' => 'column'
                                                                              }
                                                 }
                                   },
            'wwwuser_project' => {
                                   'indexes' => {
                                                  'wwwuser_project_idx2' => {
                                                                              'columns' => 'project_id',
                                                                              'name' => 'wwwuser_project_idx2',
                                                                              '_entity' => 'index'
                                                                            },
                                                  '_entity' => 'set',
                                                  'wwwuser_project_idx1' => {
                                                                              'columns' => 'wwwuser_id',
                                                                              'name' => 'wwwuser_project_idx1',
                                                                              '_entity' => 'index'
                                                                            }
                                                },
                                   'name' => 'wwwuser_project',
                                   'comment' => '------------------------------ -- f_type -------------------- ------------------------------ ------------------------------ -- fnr_type ------------------ ------------------------------ ------------------------------ -- f_loc --------------------- ------------------------------ ------------------------------ -- fp_key ------------------- ------------------------------  link wwwuser accounts to projects',
                                   '_entity' => 'table',
                                   'primarykey' => 'wwwuser_project_id',
                                   'column' => {
                                                 'wwwuser_id' => {
                                                                   'fk_table' => 'wwwuser',
                                                                   'name' => 'wwwuser_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'wwwuser_id',
                                                                   'unique' => 2
                                                                 },
                                                 'world_read' => {
                                                                   'name' => 'world_read',
                                                                   'allownull' => 'no',
                                                                   'type' => 'smallint',
                                                                   '_entity' => 'column',
                                                                   'default' => 1
                                                                 },
                                                 'project_id' => {
                                                                   'fk_table' => 'project',
                                                                   'name' => 'project_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'project_id',
                                                                   'unique' => 2
                                                                 },
                                                 '_order' => [
                                                               'wwwuser_project_id',
                                                               'wwwuser_id',
                                                               'project_id',
                                                               'world_read'
                                                             ],
                                                 '_entity' => 'list',
                                                 'wwwuser_project_id' => {
                                                                           'name' => 'wwwuser_project_id',
                                                                           'allownull' => 'no',
                                                                           'type' => 'serial',
                                                                           '_entity' => 'column',
                                                                           'primarykey' => 'yes'
                                                                         }
                                               },
                                   'unique' => [
                                                 'wwwuser_id',
                                                 'project_id'
                                               ]
                                 },
            'acquisitionparam' => {
                                    'name' => 'acquisitionparam',
                                    'comment' => 'ok drop table if exists acquisitionparam;',
                                    '_entity' => 'table',
                                    'primarykey' => 'acquisitionparam_id',
                                    'column' => {
                                                  'name' => {
                                                              'name' => 'name',
                                                              'allownull' => 'no',
                                                              'type' => 'varchar(100)',
                                                              '_entity' => 'column'
                                                            },
                                                  '_order' => [
                                                                'acquisitionparam_id',
                                                                'acquisition_id',
                                                                'name',
                                                                'value'
                                                              ],
                                                  '_entity' => 'list',
                                                  'value' => {
                                                               'name' => 'value',
                                                               'allownull' => 'no',
                                                               'type' => 'varchar(50)',
                                                               '_entity' => 'column'
                                                             },
                                                  'acquisition_id' => {
                                                                        'fk_table' => 'acquisition',
                                                                        'name' => 'acquisition_id',
                                                                        'allownull' => 'no',
                                                                        'type' => 'int',
                                                                        '_entity' => 'column',
                                                                        'fk_column' => 'acquisition_id'
                                                                      },
                                                  'acquisitionparam_id' => {
                                                                             'name' => 'acquisitionparam_id',
                                                                             'allownull' => 'no',
                                                                             'type' => 'serial',
                                                                             '_entity' => 'column',
                                                                             'primarykey' => 'yes'
                                                                           }
                                                }
                                  },
            'dbxref' => {
                          'name' => 'dbxref',
                          '_entity' => 'table',
                          'primarykey' => 'dbxref_id',
                          'column' => {
                                        'accession' => {
                                                         'name' => 'accession',
                                                         'allownull' => 'no',
                                                         'type' => 'varchar(255)',
                                                         '_entity' => 'column',
                                                         'unique' => 3
                                                       },
                                        '_order' => [
                                                      'dbxref_id',
                                                      'dbname',
                                                      'accession',
                                                      'version',
                                                      'dbxrefdescription'
                                                    ],
                                        '_entity' => 'list',
                                        'version' => {
                                                       'name' => 'version',
                                                       'allownull' => 'no',
                                                       'type' => 'varchar(255)',
                                                       '_entity' => 'column',
                                                       'default' => '\'\'',
                                                       'unique' => 3
                                                     },
                                        'dbxrefdescription' => {
                                                                 'name' => 'dbxrefdescription',
                                                                 'allownull' => 'yes',
                                                                 'type' => 'text',
                                                                 '_entity' => 'column'
                                                               },
                                        'dbname' => {
                                                      'fk_table' => 'db',
                                                      'name' => 'dbname',
                                                      'allownull' => 'no',
                                                      'type' => 'varchar(255)',
                                                      '_entity' => 'column',
                                                      'fk_column' => 'db_id',
                                                      'unique' => 3
                                                    },
                                        'dbxref_id' => {
                                                         'name' => 'dbxref_id',
                                                         'allownull' => 'no',
                                                         'type' => 'serial',
                                                         'foreign_references' => [
                                                                                   {
                                                                                     'table' => 'element',
                                                                                     'column' => 'dbxref_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'cvterm_dbxref',
                                                                                     'column' => 'dbxref_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'feature',
                                                                                     'column' => 'dbxref_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'protocol',
                                                                                     'column' => 'dbxref_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'assay',
                                                                                     'column' => 'dbxref_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'dbxrefprop',
                                                                                     'column' => 'dbxref_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'pub_dbxref',
                                                                                     'column' => 'dbxref_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'feature_dbxref',
                                                                                     'column' => 'dbxref_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'biomaterial',
                                                                                     'column' => 'dbxref_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'cvterm',
                                                                                     'column' => 'dbxref_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'study',
                                                                                     'column' => 'dbxref_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'organism_dbxref',
                                                                                     'column' => 'dbxref_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'array',
                                                                                     'column' => 'dbxref_id'
                                                                                   }
                                                                                 ],
                                                         '_entity' => 'column',
                                                         'primarykey' => 'yes'
                                                       }
                                      },
                          'unique' => [
                                        'dbname',
                                        'accession',
                                        'version'
                                      ]
                        },
            'analysisimplementationparam' => {
                                               'name' => 'analysisimplementationparam',
                                               'comment' => 'ok drop table if exists analysisimplementationparam;',
                                               '_entity' => 'table',
                                               'primarykey' => 'analysisimplementationparam_id',
                                               'column' => {
                                                             'name' => {
                                                                         'name' => 'name',
                                                                         'allownull' => 'no',
                                                                         'type' => 'varchar(100)',
                                                                         '_entity' => 'column'
                                                                       },
                                                             '_order' => [
                                                                           'analysisimplementationparam_id',
                                                                           'analysisimplementation_id',
                                                                           'name',
                                                                           'value'
                                                                         ],
                                                             '_entity' => 'list',
                                                             'value' => {
                                                                          'name' => 'value',
                                                                          'allownull' => 'no',
                                                                          'type' => 'varchar(100)',
                                                                          '_entity' => 'column'
                                                                        },
                                                             'analysisimplementation_id' => {
                                                                                              'fk_table' => 'analysisimplementation',
                                                                                              'name' => 'analysisimplementation_id',
                                                                                              'allownull' => 'no',
                                                                                              'type' => 'int',
                                                                                              '_entity' => 'column',
                                                                                              'fk_column' => 'analysisimplementation_id'
                                                                                            },
                                                             'analysisimplementationparam_id' => {
                                                                                                   'name' => 'analysisimplementationparam_id',
                                                                                                   'allownull' => 'no',
                                                                                                   'type' => 'serial',
                                                                                                   '_entity' => 'column',
                                                                                                   'primarykey' => 'yes'
                                                                                                 }
                                                           }
                                             },
            'feature_cvterm' => {
                                  'indexes' => {
                                                 'feature_cvterm_idx1' => {
                                                                            'columns' => 'feature_id',
                                                                            'name' => 'feature_cvterm_idx1',
                                                                            '_entity' => 'index'
                                                                          },
                                                 'feature_cvterm_idx2' => {
                                                                            'columns' => 'cvterm_id',
                                                                            'name' => 'feature_cvterm_idx2',
                                                                            '_entity' => 'index'
                                                                          },
                                                 'feature_cvterm_idx3' => {
                                                                            'columns' => 'pub_id',
                                                                            'name' => 'feature_cvterm_idx3',
                                                                            '_entity' => 'index'
                                                                          },
                                                 '_entity' => 'set'
                                               },
                                  'name' => 'feature_cvterm',
                                  '_entity' => 'table',
                                  'primarykey' => 'feature_cvterm_id',
                                  'column' => {
                                                'feature_id' => {
                                                                  'fk_table' => 'feature',
                                                                  'name' => 'feature_id',
                                                                  'allownull' => 'no',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'feature_id',
                                                                  'unique' => 3
                                                                },
                                                'feature_cvterm_id' => {
                                                                         'name' => 'feature_cvterm_id',
                                                                         'allownull' => 'no',
                                                                         'type' => 'serial',
                                                                         '_entity' => 'column',
                                                                         'primarykey' => 'yes'
                                                                       },
                                                'pub_id' => {
                                                              'fk_table' => 'pub',
                                                              'name' => 'pub_id',
                                                              'allownull' => 'no',
                                                              'type' => 'int',
                                                              '_entity' => 'column',
                                                              'fk_column' => 'pub_id',
                                                              'unique' => 3
                                                            },
                                                '_order' => [
                                                              'feature_cvterm_id',
                                                              'feature_id',
                                                              'cvterm_id',
                                                              'pub_id'
                                                            ],
                                                '_entity' => 'list',
                                                'cvterm_id' => {
                                                                 'fk_table' => 'cvterm',
                                                                 'name' => 'cvterm_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'cvterm_id',
                                                                 'unique' => 3
                                                               }
                                              },
                                  'unique' => [
                                                'feature_id',
                                                'cvterm_id',
                                                'pub_id'
                                              ]
                                },
            'phenotype' => {
                             'indexes' => {
                                            'phenotype_idx1' => {
                                                                  'columns' => 'statement_type',
                                                                  'name' => 'phenotype_idx1',
                                                                  '_entity' => 'index'
                                                                },
                                            'phenotype_idx2' => {
                                                                  'columns' => 'pub_id',
                                                                  'name' => 'phenotype_idx2',
                                                                  '_entity' => 'index'
                                                                },
                                            'phenotype_idx3' => {
                                                                  'columns' => 'background_genotype_id',
                                                                  'name' => 'phenotype_idx3',
                                                                  '_entity' => 'index'
                                                                },
                                            '_entity' => 'set'
                                          },
                             'name' => 'phenotype',
                             '_entity' => 'table',
                             'primarykey' => 'phenotype_id',
                             'column' => {
                                           'phenotype_id' => {
                                                               'name' => 'phenotype_id',
                                                               'allownull' => 'no',
                                                               'type' => 'serial',
                                                               'foreign_references' => [
                                                                                         {
                                                                                           'table' => 'phenotype_cvterm',
                                                                                           'column' => 'phenotype_id'
                                                                                         },
                                                                                         {
                                                                                           'table' => 'interaction',
                                                                                           'column' => 'phenotype_id'
                                                                                         },
                                                                                         {
                                                                                           'table' => 'wwwuser_phenotype',
                                                                                           'column' => 'phenotype_id'
                                                                                         },
                                                                                         {
                                                                                           'table' => 'feature_phenotype',
                                                                                           'column' => 'phenotype_id'
                                                                                         }
                                                                                       ],
                                                               '_entity' => 'column',
                                                               'primarykey' => 'yes'
                                                             },
                                           'pub_id' => {
                                                         'fk_table' => 'pub',
                                                         'name' => 'pub_id',
                                                         'allownull' => 'no',
                                                         'type' => 'int',
                                                         '_entity' => 'column',
                                                         'fk_column' => 'pub_id'
                                                       },
                                           '_order' => [
                                                         'phenotype_id',
                                                         'description',
                                                         'statement_type',
                                                         'pub_id',
                                                         'background_genotype_id'
                                                       ],
                                           'description' => {
                                                              'name' => 'description',
                                                              'allownull' => 'yes',
                                                              'type' => 'text',
                                                              '_entity' => 'column'
                                                            },
                                           '_entity' => 'list',
                                           'background_genotype_id' => {
                                                                         'fk_table' => 'genotype',
                                                                         'name' => 'background_genotype_id',
                                                                         'allownull' => 'yes',
                                                                         'type' => 'int',
                                                                         '_entity' => 'column',
                                                                         'fk_column' => 'genotype_id'
                                                                       },
                                           'statement_type' => {
                                                                 'fk_table' => 'cvterm',
                                                                 'name' => 'statement_type',
                                                                 'allownull' => 'no',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'cvterm_id'
                                                               }
                                         }
                           },
            '_entity' => 'set',
            'relatedquantification' => {
                                         'name' => 'relatedquantification',
                                         'comment' => 'ok drop table if exists relatedquantification;',
                                         '_entity' => 'table',
                                         'primarykey' => 'relatedquantification_id',
                                         'column' => {
                                                       'name' => {
                                                                   'name' => 'name',
                                                                   'allownull' => 'yes',
                                                                   'type' => 'varchar(100)',
                                                                   '_entity' => 'column'
                                                                 },
                                                       'associatedquantification_id' => {
                                                                                          'fk_table' => 'quantification',
                                                                                          'name' => 'associatedquantification_id',
                                                                                          'allownull' => 'no',
                                                                                          'type' => 'int',
                                                                                          '_entity' => 'column',
                                                                                          'fk_column' => 'quantification_id'
                                                                                        },
                                                       'quantification_id' => {
                                                                                'fk_table' => 'quantification',
                                                                                'name' => 'quantification_id',
                                                                                'allownull' => 'no',
                                                                                'type' => 'int',
                                                                                '_entity' => 'column',
                                                                                'fk_column' => 'quantification_id'
                                                                              },
                                                       '_order' => [
                                                                     'relatedquantification_id',
                                                                     'quantification_id',
                                                                     'associatedquantification_id',
                                                                     'name',
                                                                     'designation',
                                                                     'associateddesignation'
                                                                   ],
                                                       'relatedquantification_id' => {
                                                                                       'name' => 'relatedquantification_id',
                                                                                       'allownull' => 'no',
                                                                                       'type' => 'serial',
                                                                                       '_entity' => 'column',
                                                                                       'primarykey' => 'yes'
                                                                                     },
                                                       '_entity' => 'list',
                                                       'associateddesignation' => {
                                                                                    'name' => 'associateddesignation',
                                                                                    'allownull' => 'yes',
                                                                                    'type' => 'varchar(50)',
                                                                                    '_entity' => 'column'
                                                                                  },
                                                       'designation' => {
                                                                          'name' => 'designation',
                                                                          'allownull' => 'yes',
                                                                          'type' => 'varchar(50)',
                                                                          '_entity' => 'column'
                                                                        }
                                                     }
                                       },
            'assay' => {
                         'name' => 'assay',
                         'comment' => 'ok drop table if exists assay;',
                         '_entity' => 'table',
                         'primarykey' => 'assay_id',
                         'column' => {
                                       'name' => {
                                                   'name' => 'name',
                                                   'allownull' => 'yes',
                                                   'type' => 'varchar(100)',
                                                   '_entity' => 'column'
                                                 },
                                       'arrayidentifier' => {
                                                              'name' => 'arrayidentifier',
                                                              'allownull' => 'yes',
                                                              'type' => 'varchar(100)',
                                                              '_entity' => 'column'
                                                            },
                                       'description' => {
                                                          'name' => 'description',
                                                          'allownull' => 'yes',
                                                          'type' => 'varchar(500)',
                                                          '_entity' => 'column'
                                                        },
                                       'arraybatchidentifier' => {
                                                                   'name' => 'arraybatchidentifier',
                                                                   'allownull' => 'yes',
                                                                   'type' => 'varchar(100)',
                                                                   '_entity' => 'column'
                                                                 },
                                       'dbxref_id' => {
                                                        'fk_table' => 'dbxref',
                                                        'name' => 'dbxref_id',
                                                        'allownull' => 'yes',
                                                        'type' => 'int',
                                                        '_entity' => 'column',
                                                        'fk_column' => 'dbxref_id'
                                                      },
                                       'operator_id' => {
                                                          'fk_table' => 'author',
                                                          'name' => 'operator_id',
                                                          'allownull' => 'no',
                                                          'type' => 'int',
                                                          '_entity' => 'column',
                                                          'fk_column' => 'author_id'
                                                        },
                                       '_order' => [
                                                     'assay_id',
                                                     'array_id',
                                                     'protocol_id',
                                                     'assaydate',
                                                     'arrayidentifier',
                                                     'arraybatchidentifier',
                                                     'operator_id',
                                                     'dbxref_id',
                                                     'name',
                                                     'description'
                                                   ],
                                       'array_id' => {
                                                       'fk_table' => 'array',
                                                       'name' => 'array_id',
                                                       'allownull' => 'no',
                                                       'type' => 'int',
                                                       '_entity' => 'column',
                                                       'fk_column' => 'array_id'
                                                     },
                                       '_entity' => 'list',
                                       'assay_id' => {
                                                       'name' => 'assay_id',
                                                       'allownull' => 'no',
                                                       'type' => 'serial',
                                                       'foreign_references' => [
                                                                                 {
                                                                                   'table' => 'control',
                                                                                   'column' => 'assay_id'
                                                                                 },
                                                                                 {
                                                                                   'table' => 'assay_labeledextract',
                                                                                   'column' => 'assay_id'
                                                                                 },
                                                                                 {
                                                                                   'table' => 'assay_biomaterial',
                                                                                   'column' => 'assay_id'
                                                                                 },
                                                                                 {
                                                                                   'table' => 'studydesign_assay',
                                                                                   'column' => 'assay_id'
                                                                                 },
                                                                                 {
                                                                                   'table' => 'studyfactorvalue',
                                                                                   'column' => 'assay_id'
                                                                                 },
                                                                                 {
                                                                                   'table' => 'study_assay',
                                                                                   'column' => 'assay_id'
                                                                                 },
                                                                                 {
                                                                                   'table' => 'acquisition',
                                                                                   'column' => 'assay_id'
                                                                                 }
                                                                               ],
                                                       '_entity' => 'column',
                                                       'primarykey' => 'yes'
                                                     },
                                       'protocol_id' => {
                                                          'fk_table' => 'protocol',
                                                          'name' => 'protocol_id',
                                                          'allownull' => 'yes',
                                                          'type' => 'int',
                                                          '_entity' => 'column',
                                                          'fk_column' => 'protocol_id'
                                                        },
                                       'assaydate' => {
                                                        'name' => 'assaydate',
                                                        'allownull' => 'yes',
                                                        'type' => 'date',
                                                        '_entity' => 'column'
                                                      }
                                     }
                       },
            'wwwuser_organism' => {
                                    'indexes' => {
                                                   'wwwuser_organism_idx1' => {
                                                                                'columns' => 'wwwuser_id',
                                                                                'name' => 'wwwuser_organism_idx1',
                                                                                '_entity' => 'index'
                                                                              },
                                                   'wwwuser_organism_idx2' => {
                                                                                'columns' => 'organism_id',
                                                                                'name' => 'wwwuser_organism_idx2',
                                                                                '_entity' => 'index'
                                                                              },
                                                   '_entity' => 'set'
                                                 },
                                    'name' => 'wwwuser_organism',
                                    'comment' => 'track wwwuser interest in organisms',
                                    '_entity' => 'table',
                                    'primarykey' => 'wwwuser_organism_id',
                                    'column' => {
                                                  'wwwuser_id' => {
                                                                    'fk_table' => 'wwwuser',
                                                                    'name' => 'wwwuser_id',
                                                                    'allownull' => 'no',
                                                                    'type' => 'int',
                                                                    '_entity' => 'column',
                                                                    'fk_column' => 'wwwuser_id',
                                                                    'unique' => 2
                                                                  },
                                                  'world_read' => {
                                                                    'name' => 'world_read',
                                                                    'allownull' => 'no',
                                                                    'type' => 'smallint',
                                                                    '_entity' => 'column',
                                                                    'default' => 1
                                                                  },
                                                  '_order' => [
                                                                'wwwuser_organism_id',
                                                                'wwwuser_id',
                                                                'organism_id',
                                                                'world_read'
                                                              ],
                                                  'organism_id' => {
                                                                     'fk_table' => 'organism',
                                                                     'name' => 'organism_id',
                                                                     'allownull' => 'no',
                                                                     'type' => 'int',
                                                                     '_entity' => 'column',
                                                                     'fk_column' => 'organism_id',
                                                                     'unique' => 2
                                                                   },
                                                  '_entity' => 'list',
                                                  'wwwuser_organism_id' => {
                                                                             'name' => 'wwwuser_organism_id',
                                                                             'allownull' => 'no',
                                                                             'type' => 'serial',
                                                                             '_entity' => 'column',
                                                                             'primarykey' => 'yes'
                                                                           }
                                                },
                                    'unique' => [
                                                  'wwwuser_id',
                                                  'organism_id'
                                                ]
                                  },
            'synonym_pub' => {
                               'indexes' => {
                                              'synonym_pub_idx1' => {
                                                                      'columns' => 'synonym_id',
                                                                      'name' => 'synonym_pub_idx1',
                                                                      '_entity' => 'index'
                                                                    },
                                              'synonym_pub_idx2' => {
                                                                      'columns' => 'pub_id',
                                                                      'name' => 'synonym_pub_idx2',
                                                                      '_entity' => 'index'
                                                                    },
                                              '_entity' => 'set'
                                            },
                               'name' => 'synonym_pub',
                               'comment' => 'pub_id: the pub_id link is for relating the usage of a given synonym to the  publication in which it was used  is_current: the is_current bit indicates whether the linked synonym is the  current -official- symbol for the linked feature  is_internal: typically a synonym exists so that somebody querying the db with an  obsolete name can find the object they\'re looking for (under its current  name.  If the synonym has been used publicly & deliberately (eg in a  paper), it my also be listed in reports as a synonym.   If the synonym  was not used deliberately (eg, there was a typo which went public), then  the is_internal bit may be set to \'true\' so that it is known that the  synonym is "internal" and should be queryable but should not be listed  in reports as a valid synonym.',
                               '_entity' => 'table',
                               'primarykey' => 'synonym_pub_id',
                               'column' => {
                                             'synonym_id' => {
                                                               'fk_table' => 'synonym',
                                                               'name' => 'synonym_id',
                                                               'allownull' => 'no',
                                                               'type' => 'int',
                                                               '_entity' => 'column',
                                                               'fk_column' => 'synonym_id',
                                                               'unique' => 2
                                                             },
                                             'pub_id' => {
                                                           'fk_table' => 'pub',
                                                           'name' => 'pub_id',
                                                           'allownull' => 'no',
                                                           'type' => 'int',
                                                           '_entity' => 'column',
                                                           'fk_column' => 'pub_id',
                                                           'unique' => 2
                                                         },
                                             '_order' => [
                                                           'synonym_pub_id',
                                                           'synonym_id',
                                                           'pub_id'
                                                         ],
                                             '_entity' => 'list',
                                             'synonym_pub_id' => {
                                                                   'name' => 'synonym_pub_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'serial',
                                                                   '_entity' => 'column',
                                                                   'primarykey' => 'yes'
                                                                 }
                                           },
                               'unique' => [
                                             'synonym_id',
                                             'pub_id'
                                           ]
                             },
            'analysis' => {
                            'name' => 'analysis',
                            'comment' => 'ok drop table if exists analysis;',
                            '_entity' => 'table',
                            'primarykey' => 'analysis_id',
                            'column' => {
                                          'analysis_id' => {
                                                             'name' => 'analysis_id',
                                                             'allownull' => 'no',
                                                             'type' => 'serial',
                                                             'foreign_references' => [
                                                                                       {
                                                                                         'table' => 'analysisfeature',
                                                                                         'column' => 'analysis_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'analysisprop',
                                                                                         'column' => 'analysis_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'analysisimplementation',
                                                                                         'column' => 'analysis_id'
                                                                                       }
                                                                                     ],
                                                             '_entity' => 'column',
                                                             'primarykey' => 'yes'
                                                           },
                                          'name' => {
                                                      'name' => 'name',
                                                      'allownull' => 'no',
                                                      'type' => 'varchar(100)',
                                                      '_entity' => 'column'
                                                    },
                                          '_order' => [
                                                        'analysis_id',
                                                        'name',
                                                        'description'
                                                      ],
                                          'description' => {
                                                             'name' => 'description',
                                                             'allownull' => 'yes',
                                                             'type' => 'varchar(500)',
                                                             '_entity' => 'column'
                                                           },
                                          '_entity' => 'list'
                                        }
                          },
            'cvpath' => {
                          'indexes' => {
                                         'cvpath_idx1' => {
                                                            'columns' => 'reltype_id',
                                                            'name' => 'cvpath_idx1',
                                                            '_entity' => 'index'
                                                          },
                                         'cvpath_idx2' => {
                                                            'columns' => 'subjterm_id',
                                                            'name' => 'cvpath_idx2',
                                                            '_entity' => 'index'
                                                          },
                                         '_entity' => 'set',
                                         'cvpath_idx3' => {
                                                            'columns' => 'objterm_id',
                                                            'name' => 'cvpath_idx3',
                                                            '_entity' => 'index'
                                                          },
                                         'cvpath_idx4' => {
                                                            'columns' => 'cv_id',
                                                            'name' => 'cvpath_idx4',
                                                            '_entity' => 'index'
                                                          }
                                       },
                          'name' => 'cvpath',
                          '_entity' => 'table',
                          'primarykey' => 'cvpath_id',
                          'column' => {
                                        'pathdistance' => {
                                                            'name' => 'pathdistance',
                                                            'allownull' => 'yes',
                                                            'type' => 'int',
                                                            '_entity' => 'column'
                                                          },
                                        'subjterm_id' => {
                                                           'fk_table' => 'cvterm',
                                                           'name' => 'subjterm_id',
                                                           'allownull' => 'no',
                                                           'type' => 'int',
                                                           '_entity' => 'column',
                                                           'fk_column' => 'cvterm_id',
                                                           'unique' => 2
                                                         },
                                        'reltype_id' => {
                                                          'fk_table' => 'cvterm',
                                                          'name' => 'reltype_id',
                                                          'allownull' => 'yes',
                                                          'type' => 'int',
                                                          '_entity' => 'column',
                                                          'fk_column' => 'cvterm_id'
                                                        },
                                        'cvpath_id' => {
                                                         'name' => 'cvpath_id',
                                                         'allownull' => 'no',
                                                         'type' => 'serial',
                                                         '_entity' => 'column',
                                                         'primarykey' => 'yes'
                                                       },
                                        '_order' => [
                                                      'cvpath_id',
                                                      'reltype_id',
                                                      'subjterm_id',
                                                      'objterm_id',
                                                      'cv_id',
                                                      'pathdistance'
                                                    ],
                                        '_entity' => 'list',
                                        'cv_id' => {
                                                     'fk_table' => 'cv',
                                                     'name' => 'cv_id',
                                                     'allownull' => 'no',
                                                     'type' => 'int',
                                                     '_entity' => 'column',
                                                     'fk_column' => 'cv_id'
                                                   },
                                        'objterm_id' => {
                                                          'fk_table' => 'cvterm',
                                                          'name' => 'objterm_id',
                                                          'allownull' => 'no',
                                                          'type' => 'int',
                                                          '_entity' => 'column',
                                                          'fk_column' => 'cvterm_id',
                                                          'unique' => 2
                                                        }
                                      },
                          'unique' => [
                                        'subjterm_id',
                                        'objterm_id'
                                      ]
                        },
            'featureloc' => {
                              'indexes' => {
                                             'featureloc_idx2' => {
                                                                    'columns' => 'srcfeature_id',
                                                                    'name' => 'featureloc_idx2',
                                                                    '_entity' => 'index'
                                                                  },
                                             'featureloc_idx3' => {
                                                                    'columns' => 'srcfeature_id,nbeg,nend',
                                                                    'name' => 'featureloc_idx3',
                                                                    '_entity' => 'index'
                                                                  },
                                             '_entity' => 'set',
                                             'featureloc_idx1' => {
                                                                    'columns' => 'feature_id',
                                                                    'name' => 'featureloc_idx1',
                                                                    '_entity' => 'index'
                                                                  }
                                           },
                              'name' => 'featureloc',
                              'comment' => 'dbxref_id here is intended for the primary dbxref for this feature.  Additional dbxref links are made via feature_dbxref  name: the human-readable common name for a feature, for display  uniquename: the unique name for a feature; may not be particularly human-readable  timeaccessioned and timelastmodified are for handling object accession/  modification timestamps (as opposed to db auditing info, handled elsewhere).  The expectation is that these fields would be available to software  interacting with chado.  each feature can have 0 or more locations.  multiple locations do NOT indicate non-contiguous locations.  instead they designate alternate locations or grouped locations;  for instance, a feature designating a blast hit or hsp will have two  locations, one on the query feature, one on the subject feature.  features representing sequence variation could have alternate locations  instantiated on a feature on the mutant strain.  the field "rank" is used to differentiate these different locations.  the default rank \'0\' is used for the main/primary location (eg in  similarity features, 0 is query, 1 is subject), although sometimes  this will be symmeytical and there is no primary location.   redundant locations can also be stored - for instance, the position  of an exon on a BAC and in global coordinates. the field "locgroup"  is used to differentiate these groupings of locations. the default  locgroup \'0\' is used for the main/primary location, from which the  others can be derived via coordinate transformations. another  example of redundant locations is storing ORF coordinates relative  to both transcript and genome. redundant locations open the possibility  of the database getting into inconsistent states; this schema gives  us the flexibility of both \'warehouse\' instantiations with redundant  locations (easier for querying) and \'management\' instantiations with  no redundant locations.  most features (exons, transcripts, etc) will have 1 location, with  locgroup and rank equal to 0   an example of using both locgroup and rank:  imagine a feature indicating a conserved region between the chromosomes  of two different species. we may want to keep redundant locations on  both contigs and chromosomes. we would thus have 4 locations for the  single conserved region feature - two distinct locgroups (contig level  and chromosome level) and two distinct ranks (for the two species).  altresidues is used to store alternate residues of a feature, when these  differ from feature.residues. for instance, a SNP feature located on  a wild and mutant protein would have different alresidues.  for alignment/similarity features, the altresidues is used to represent  the alignment string.  note on variation features; even if we don\'t want to instantiate a mutant  chromosome/contig feature, we can still represent a SNP etc with 2 locations,  one (rank 0) on the genome, the other (rank 1) would have most fields null,  except for altresidues  IMPORTANT: fnbeg and fnend are space-based (INTERBASE) coordinates  this is vital as it allows us to represent zero-length  features eg splice sites, insertion points without  an awkward fuzzy system  nbeg, nend are for feature natural begin/end  by natural begin, end we mean these are the actual  beginning (5\' position) and actual end (3\' position)  rather than the low position and high position, as  these terms are sometimes erroneously used',
                              '_entity' => 'table',
                              'primarykey' => 'featureloc_id',
                              'column' => {
                                            'srcfeature_id' => {
                                                                 'fk_table' => 'feature',
                                                                 'name' => 'srcfeature_id',
                                                                 'allownull' => 'yes',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'feature_id'
                                                               },
                                            'phase' => {
                                                         'name' => 'phase',
                                                         'allownull' => 'yes',
                                                         'type' => 'int',
                                                         '_entity' => 'column'
                                                       },
                                            'is_nbeg_partial' => {
                                                                   'name' => 'is_nbeg_partial',
                                                                   'allownull' => 'no',
                                                                   'type' => 'boolean',
                                                                   '_entity' => 'column',
                                                                   'default' => '\'false\''
                                                                 },
                                            'nend' => {
                                                        'name' => 'nend',
                                                        'allownull' => 'yes',
                                                        'type' => 'int',
                                                        '_entity' => 'column'
                                                      },
                                            'featureloc_id' => {
                                                                 'name' => 'featureloc_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'serial',
                                                                 '_entity' => 'column',
                                                                 'primarykey' => 'yes'
                                                               },
                                            'feature_id' => {
                                                              'fk_table' => 'feature',
                                                              'name' => 'feature_id',
                                                              'allownull' => 'no',
                                                              'type' => 'int',
                                                              '_entity' => 'column',
                                                              'fk_column' => 'feature_id',
                                                              'unique' => 3
                                                            },
                                            'locgroup' => {
                                                            'name' => 'locgroup',
                                                            'allownull' => 'no',
                                                            'type' => 'int',
                                                            '_entity' => 'column',
                                                            'default' => '0',
                                                            'unique' => 3
                                                          },
                                            '_order' => [
                                                          'featureloc_id',
                                                          'feature_id',
                                                          'srcfeature_id',
                                                          'nbeg',
                                                          'is_nbeg_partial',
                                                          'nend',
                                                          'is_nend_partial',
                                                          'strand',
                                                          'phase',
                                                          'residue_info',
                                                          'locgroup',
                                                          'rank'
                                                        ],
                                            'rank' => {
                                                        'name' => 'rank',
                                                        'allownull' => 'no',
                                                        'type' => 'int',
                                                        '_entity' => 'column',
                                                        'default' => '0',
                                                        'unique' => 3
                                                      },
                                            'residue_info' => {
                                                                'name' => 'residue_info',
                                                                'allownull' => 'yes',
                                                                'type' => 'text',
                                                                '_entity' => 'column'
                                                              },
                                            'strand' => {
                                                          'name' => 'strand',
                                                          'allownull' => 'yes',
                                                          'type' => 'smallint',
                                                          '_entity' => 'column'
                                                        },
                                            'is_nend_partial' => {
                                                                   'name' => 'is_nend_partial',
                                                                   'allownull' => 'no',
                                                                   'type' => 'boolean',
                                                                   '_entity' => 'column',
                                                                   'default' => '\'false\''
                                                                 },
                                            '_entity' => 'list',
                                            'nbeg' => {
                                                        'name' => 'nbeg',
                                                        'allownull' => 'yes',
                                                        'type' => 'int',
                                                        '_entity' => 'column'
                                                      }
                                          },
                              'unique' => [
                                            'feature_id',
                                            'locgroup',
                                            'rank'
                                          ]
                            },
            'featuremap' => {
                              'name' => 'featuremap',
                              'comment' => 'NOTE: this module is all due for revision...  A possibly problematic case is where we want to localize an object  to the left or right of a feature (but not within it):                       |---------|  feature-to-map         ------------------------------------------------- map                 |------|         |----------|   features to map wrt   How do we map the 3\' end of the feature-to-map?  TODO:  Get a comprehensive set of mapping use-cases  one set of use-cases is aberrations (which will all be involved with this  module).   Simple aberrations should be do-able, but what about cases where  a breakpoint interrupts a gene?  This would be an example of the problematic  case above...  (or?)',
                              '_entity' => 'table',
                              'primarykey' => 'featuremap_id',
                              'column' => {
                                            '_order' => [
                                                          'featuremap_id',
                                                          'mapname',
                                                          'mapdesc',
                                                          'mapunit'
                                                        ],
                                            '_entity' => 'list',
                                            'mapdesc' => {
                                                           'name' => 'mapdesc',
                                                           'allownull' => 'yes',
                                                           'type' => 'varchar(255)',
                                                           '_entity' => 'column'
                                                         },
                                            'mapunit' => {
                                                           'name' => 'mapunit',
                                                           'allownull' => 'yes',
                                                           'type' => 'varchar(255)',
                                                           '_entity' => 'column'
                                                         },
                                            'featuremap_id' => {
                                                                 'name' => 'featuremap_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'serial',
                                                                 'foreign_references' => [
                                                                                           {
                                                                                             'table' => 'featuremap_pub',
                                                                                             'column' => 'featuremap_id'
                                                                                           },
                                                                                           {
                                                                                             'table' => 'featurepos',
                                                                                             'column' => 'featuremap_id'
                                                                                           },
                                                                                           {
                                                                                             'table' => 'featurerange',
                                                                                             'column' => 'featuremap_id'
                                                                                           }
                                                                                         ],
                                                                 '_entity' => 'column',
                                                                 'primarykey' => 'yes'
                                                               },
                                            'mapname' => {
                                                           'name' => 'mapname',
                                                           'allownull' => 'yes',
                                                           'type' => 'varchar(255)',
                                                           '_entity' => 'column',
                                                           'unique' => 1
                                                         }
                                          },
                              'unique' => [
                                            'mapname'
                                          ]
                            },
            'cvrelationship' => {
                                  'indexes' => {
                                                 'cvrelationship_idx1' => {
                                                                            'columns' => 'reltype_id',
                                                                            'name' => 'cvrelationship_idx1',
                                                                            '_entity' => 'index'
                                                                          },
                                                 'cvrelationship_idx2' => {
                                                                            'columns' => 'subjterm_id',
                                                                            'name' => 'cvrelationship_idx2',
                                                                            '_entity' => 'index'
                                                                          },
                                                 'cvrelationship_idx3' => {
                                                                            'columns' => 'objterm_id',
                                                                            'name' => 'cvrelationship_idx3',
                                                                            '_entity' => 'index'
                                                                          },
                                                 '_entity' => 'set'
                                               },
                                  'name' => 'cvrelationship',
                                  'comment' => 'the primary dbxref for this term.  Other dbxrefs may be cvterm_dbxref  The unique key on termname, cv_id ensures that all terms are  unique within a given cv',
                                  '_entity' => 'table',
                                  'primarykey' => 'cvrelationship_id',
                                  'column' => {
                                                'subjterm_id' => {
                                                                   'fk_table' => 'cvterm',
                                                                   'name' => 'subjterm_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'cvterm_id',
                                                                   'unique' => 3
                                                                 },
                                                'reltype_id' => {
                                                                  'fk_table' => 'cvterm',
                                                                  'name' => 'reltype_id',
                                                                  'allownull' => 'no',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'cvterm_id',
                                                                  'unique' => 3
                                                                },
                                                '_order' => [
                                                              'cvrelationship_id',
                                                              'reltype_id',
                                                              'subjterm_id',
                                                              'objterm_id'
                                                            ],
                                                '_entity' => 'list',
                                                'objterm_id' => {
                                                                  'fk_table' => 'cvterm',
                                                                  'name' => 'objterm_id',
                                                                  'allownull' => 'no',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'cvterm_id',
                                                                  'unique' => 3
                                                                },
                                                'cvrelationship_id' => {
                                                                         'name' => 'cvrelationship_id',
                                                                         'allownull' => 'no',
                                                                         'type' => 'serial',
                                                                         '_entity' => 'column',
                                                                         'primarykey' => 'yes'
                                                                       }
                                              },
                                  'unique' => [
                                                'reltype_id',
                                                'subjterm_id',
                                                'objterm_id'
                                              ]
                                },
            'phenotype_cvterm' => {
                                    'indexes' => {
                                                   'phenotype_cvterm_idx1' => {
                                                                                'columns' => 'phenotype_id',
                                                                                'name' => 'phenotype_cvterm_idx1',
                                                                                '_entity' => 'index'
                                                                              },
                                                   'phenotype_cvterm_idx2' => {
                                                                                'columns' => 'cvterm_id',
                                                                                'name' => 'phenotype_cvterm_idx2',
                                                                                '_entity' => 'index'
                                                                              },
                                                   '_entity' => 'set'
                                                 },
                                    'name' => 'phenotype_cvterm',
                                    '_entity' => 'table',
                                    'primarykey' => 'phenotype_cvterm_id',
                                    'column' => {
                                                  'phenotype_id' => {
                                                                      'fk_table' => 'phenotype',
                                                                      'name' => 'phenotype_id',
                                                                      'allownull' => 'no',
                                                                      'type' => 'int',
                                                                      '_entity' => 'column',
                                                                      'fk_column' => 'phenotype_id',
                                                                      'unique' => 3
                                                                    },
                                                  'phenotype_cvterm_id' => {
                                                                             'name' => 'phenotype_cvterm_id',
                                                                             'allownull' => 'no',
                                                                             'type' => 'serial',
                                                                             '_entity' => 'column',
                                                                             'primarykey' => 'yes'
                                                                           },
                                                  '_order' => [
                                                                'phenotype_cvterm_id',
                                                                'phenotype_id',
                                                                'cvterm_id',
                                                                'prank'
                                                              ],
                                                  'prank' => {
                                                               'name' => 'prank',
                                                               'allownull' => 'no',
                                                               'type' => 'int',
                                                               '_entity' => 'column',
                                                               'unique' => 3
                                                             },
                                                  '_entity' => 'list',
                                                  'cvterm_id' => {
                                                                   'fk_table' => 'cvterm',
                                                                   'name' => 'cvterm_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'cvterm_id',
                                                                   'unique' => 3
                                                                 }
                                                },
                                    'unique' => [
                                                  'phenotype_id',
                                                  'cvterm_id',
                                                  'prank'
                                                ]
                                  },
            'featureprop' => {
                               'indexes' => {
                                              'featureprop_idx1' => {
                                                                      'columns' => 'feature_id',
                                                                      'name' => 'featureprop_idx1',
                                                                      '_entity' => 'index'
                                                                    },
                                              'featureprop_idx2' => {
                                                                      'columns' => 'pkey_id',
                                                                      'name' => 'featureprop_idx2',
                                                                      '_entity' => 'index'
                                                                    },
                                              '_entity' => 'set'
                                            },
                               'name' => 'featureprop',
                               '_entity' => 'table',
                               'primarykey' => 'featureprop_id',
                               'column' => {
                                             'feature_id' => {
                                                               'fk_table' => 'feature',
                                                               'name' => 'feature_id',
                                                               'allownull' => 'no',
                                                               'type' => 'int',
                                                               '_entity' => 'column',
                                                               'fk_column' => 'feature_id',
                                                               'unique' => 4
                                                             },
                                             'featureprop_id' => {
                                                                   'name' => 'featureprop_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'serial',
                                                                   'foreign_references' => [
                                                                                             {
                                                                                               'table' => 'featureprop_pub',
                                                                                               'column' => 'featureprop_id'
                                                                                             }
                                                                                           ],
                                                                   '_entity' => 'column',
                                                                   'primarykey' => 'yes'
                                                                 },
                                             'pval' => {
                                                         'name' => 'pval',
                                                         'allownull' => 'no',
                                                         'type' => 'text',
                                                         '_entity' => 'column',
                                                         'default' => '\'\'',
                                                         'unique' => 4
                                                       },
                                             '_order' => [
                                                           'featureprop_id',
                                                           'feature_id',
                                                           'pkey_id',
                                                           'pval',
                                                           'prank'
                                                         ],
                                             'prank' => {
                                                          'name' => 'prank',
                                                          'allownull' => 'no',
                                                          'type' => 'int',
                                                          '_entity' => 'column',
                                                          'default' => '0',
                                                          'unique' => 4
                                                        },
                                             '_entity' => 'list',
                                             'pkey_id' => {
                                                            'fk_table' => 'cvterm',
                                                            'name' => 'pkey_id',
                                                            'allownull' => 'no',
                                                            'type' => 'int',
                                                            '_entity' => 'column',
                                                            'fk_column' => 'cvterm_id',
                                                            'unique' => 4
                                                          }
                                           },
                               'unique' => [
                                             'feature_id',
                                             'pkey_id',
                                             'pval',
                                             'prank'
                                           ]
                             },
            'wwwuser_genotype' => {
                                    'indexes' => {
                                                   'wwwuser_genotype_idx1' => {
                                                                                'columns' => 'wwwuser_id',
                                                                                'name' => 'wwwuser_genotype_idx1',
                                                                                '_entity' => 'index'
                                                                              },
                                                   'wwwuser_genotype_idx2' => {
                                                                                'columns' => 'genotype_id',
                                                                                'name' => 'wwwuser_genotype_idx2',
                                                                                '_entity' => 'index'
                                                                              },
                                                   '_entity' => 'set'
                                                 },
                                    'name' => 'wwwuser_genotype',
                                    'comment' => 'track wwwuser interest in genotypes',
                                    '_entity' => 'table',
                                    'primarykey' => 'wwwuser_genotype_id',
                                    'column' => {
                                                  'wwwuser_id' => {
                                                                    'fk_table' => 'wwwuser',
                                                                    'name' => 'wwwuser_id',
                                                                    'allownull' => 'no',
                                                                    'type' => 'int',
                                                                    '_entity' => 'column',
                                                                    'fk_column' => 'wwwuser_id',
                                                                    'unique' => 2
                                                                  },
                                                  'wwwuser_genotype_id' => {
                                                                             'name' => 'wwwuser_genotype_id',
                                                                             'allownull' => 'no',
                                                                             'type' => 'serial',
                                                                             '_entity' => 'column',
                                                                             'primarykey' => 'yes'
                                                                           },
                                                  'world_read' => {
                                                                    'name' => 'world_read',
                                                                    'allownull' => 'no',
                                                                    'type' => 'smallint',
                                                                    '_entity' => 'column',
                                                                    'default' => 1
                                                                  },
                                                  '_order' => [
                                                                'wwwuser_genotype_id',
                                                                'wwwuser_id',
                                                                'genotype_id',
                                                                'world_read'
                                                              ],
                                                  '_entity' => 'list',
                                                  'genotype_id' => {
                                                                     'fk_table' => 'genotype',
                                                                     'name' => 'genotype_id',
                                                                     'allownull' => 'no',
                                                                     'type' => 'int',
                                                                     '_entity' => 'column',
                                                                     'fk_column' => 'genotype_id',
                                                                     'unique' => 2
                                                                   }
                                                },
                                    'unique' => [
                                                  'wwwuser_id',
                                                  'genotype_id'
                                                ]
                                  },
            'analysisfeature' => {
                                   'indexes' => {
                                                  '_entity' => 'set',
                                                  'analysisfeature_idx1' => {
                                                                              'columns' => 'feature_id',
                                                                              'name' => 'analysisfeature_idx1',
                                                                              '_entity' => 'index'
                                                                            },
                                                  'analysisfeature_idx2' => {
                                                                              'columns' => 'analysis_id',
                                                                              'name' => 'analysisfeature_idx2',
                                                                              '_entity' => 'index'
                                                                            }
                                                },
                                   'name' => 'analysisfeature',
                                   'comment' => 'computational analyses generate features (eg genscan generates  transcripts and exons; sim4 alignments generate similarity/match  features)  analysisfeatures are stored using the feature table from  the sequence module. the analysisfeature table is used to  decorate these features, with analysis specific attributes.   a feature is an analysisfeature if and only if there is  a corresponding entry in the analysisfeature table   analysisfeatures will have two or more featureloc entries,  with rank indicating query/subject   analysis_id:     scoredsets are grouped into analyses    rawscore:     this is the native score generated by the program; for example,     the bitscore generated by blast, sim4 or genscan scores.     one should not assume that high is necessarily better than low.    normscore:     this is the rawscore but semi-normalized. complete normalization     to allow comparison of features generated by different programs     would be nice but too difficult. instead the normalization should     strive to enforce the following semantics:      * normscores are floating point numbers >= 0     * high normscores are better than low one.      for most programs, it would be sufficient to make the normscore     the same as this rawscore, providing these semantics are     satisfied.    significance:     this is some kind of expectation or probability metric,     representing the probability that the scoredset would appear     randomly given the model.     as such, any program or person querying this table can assume     the following semantics:      * 0 <= significance <= n, where n is a positive number, theoretically        unbounded but unlikely to be more than 10      * low numbers are better than high numbers.    identity:     percent identity between the locations compared    note that these 4 metrics do not cover the full range of scores   possible; it would be undesirable to list every score possible, as   this should be kept extensible. instead, for non-standard scores, use   the scoredsetprop table.',
                                   '_entity' => 'table',
                                   'primarykey' => 'analysisfeature_id',
                                   'column' => {
                                                 'analysis_id' => {
                                                                    'fk_table' => 'analysis',
                                                                    'name' => 'analysis_id',
                                                                    'allownull' => 'no',
                                                                    'type' => 'int',
                                                                    '_entity' => 'column',
                                                                    'fk_column' => 'analysis_id',
                                                                    'unique' => 2
                                                                  },
                                                 'significance' => {
                                                                     'name' => 'significance',
                                                                     'allownull' => 'yes',
                                                                     'type' => 'double',
                                                                     '_entity' => 'column'
                                                                   },
                                                 'rawscore' => {
                                                                 'name' => 'rawscore',
                                                                 'allownull' => 'yes',
                                                                 'type' => 'double',
                                                                 '_entity' => 'column'
                                                               },
                                                 'feature_id' => {
                                                                   'fk_table' => 'feature',
                                                                   'name' => 'feature_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'feature_id',
                                                                   'unique' => 2
                                                                 },
                                                 'normscore' => {
                                                                  'name' => 'normscore',
                                                                  'allownull' => 'yes',
                                                                  'type' => 'double',
                                                                  '_entity' => 'column'
                                                                },
                                                 'identity' => {
                                                                 'name' => 'identity',
                                                                 'allownull' => 'yes',
                                                                 'type' => 'double',
                                                                 '_entity' => 'column'
                                                               },
                                                 '_order' => [
                                                               'analysisfeature_id',
                                                               'feature_id',
                                                               'analysis_id',
                                                               'rawscore',
                                                               'normscore',
                                                               'significance',
                                                               'identity'
                                                             ],
                                                 '_entity' => 'list',
                                                 'analysisfeature_id' => {
                                                                           'name' => 'analysisfeature_id',
                                                                           'allownull' => 'no',
                                                                           'type' => 'serial',
                                                                           '_entity' => 'column',
                                                                           'primarykey' => 'yes'
                                                                         }
                                               },
                                   'unique' => [
                                                 'feature_id',
                                                 'analysis_id'
                                               ]
                                 },
            'tableinfo' => {
                             'name' => 'tableinfo',
                             '_entity' => 'table',
                             'primarykey' => 'tableinfo_id',
                             'column' => {
                                           'tableinfo_id' => {
                                                               'name' => 'tableinfo_id',
                                                               'allownull' => 'no',
                                                               'type' => 'serial',
                                                               'foreign_references' => [
                                                                                         {
                                                                                           'table' => 'control',
                                                                                           'column' => 'tableinfo_id'
                                                                                         },
                                                                                         {
                                                                                           'table' => 'analysisinput',
                                                                                           'column' => 'tableinfo_id'
                                                                                         },
                                                                                         {
                                                                                           'table' => 'processio',
                                                                                           'column' => 'inputtable_id'
                                                                                         },
                                                                                         {
                                                                                           'table' => 'projectlink',
                                                                                           'column' => 'tableinfo_id'
                                                                                         },
                                                                                         {
                                                                                           'table' => 'magedocumentation',
                                                                                           'column' => 'tableinfo_id'
                                                                                         },
                                                                                         {
                                                                                           'table' => 'quantification',
                                                                                           'column' => 'resulttable_id'
                                                                                         }
                                                                                       ],
                                                               '_entity' => 'column',
                                                               'primarykey' => 'yes'
                                                             },
                                           'database_id' => {
                                                              'name' => 'database_id',
                                                              'allownull' => 'no',
                                                              'type' => 'int',
                                                              '_entity' => 'column'
                                                            },
                                           'name' => {
                                                       'name' => 'name',
                                                       'allownull' => 'no',
                                                       'type' => 'varchar(30)',
                                                       '_entity' => 'column'
                                                     },
                                           'is_updateable' => {
                                                                'name' => 'is_updateable',
                                                                'allownull' => 'no',
                                                                'type' => 'int',
                                                                '_entity' => 'column'
                                                              },
                                           'modification_date' => {
                                                                    'name' => 'modification_date',
                                                                    'allownull' => 'no',
                                                                    'type' => 'date',
                                                                    '_entity' => 'column'
                                                                  },
                                           'is_view' => {
                                                          'name' => 'is_view',
                                                          'allownull' => 'no',
                                                          'type' => 'int',
                                                          '_entity' => 'column'
                                                        },
                                           'superclass_table_id' => {
                                                                      'name' => 'superclass_table_id',
                                                                      'allownull' => 'yes',
                                                                      'type' => 'int',
                                                                      '_entity' => 'column'
                                                                    },
                                           'table_type' => {
                                                             'name' => 'table_type',
                                                             'allownull' => 'no',
                                                             'type' => 'varchar(40)',
                                                             '_entity' => 'column'
                                                           },
                                           'primary_key_column' => {
                                                                     'name' => 'primary_key_column',
                                                                     'allownull' => 'yes',
                                                                     'type' => 'varchar(30)',
                                                                     '_entity' => 'column'
                                                                   },
                                           'view_on_table_id' => {
                                                                   'name' => 'view_on_table_id',
                                                                   'allownull' => 'yes',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column'
                                                                 },
                                           'is_versioned' => {
                                                               'name' => 'is_versioned',
                                                               'allownull' => 'no',
                                                               'type' => 'int',
                                                               '_entity' => 'column'
                                                             },
                                           '_order' => [
                                                         'tableinfo_id',
                                                         'name',
                                                         'table_type',
                                                         'primary_key_column',
                                                         'database_id',
                                                         'is_versioned',
                                                         'is_view',
                                                         'view_on_table_id',
                                                         'superclass_table_id',
                                                         'is_updateable',
                                                         'modification_date'
                                                       ],
                                           '_entity' => 'list'
                                         }
                           },
            'analysisinput' => {
                                 'name' => 'analysisinput',
                                 'comment' => 'ok drop table if exists analysisinput;',
                                 '_entity' => 'table',
                                 'primarykey' => 'analysisinput_id',
                                 'column' => {
                                               'tableinfo_id' => {
                                                                   'fk_table' => 'tableinfo',
                                                                   'name' => 'tableinfo_id',
                                                                   'allownull' => 'yes',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'tableinfo_id'
                                                                 },
                                               'analysisinput_id' => {
                                                                       'name' => 'analysisinput_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'serial',
                                                                       '_entity' => 'column',
                                                                       'primarykey' => 'yes'
                                                                     },
                                               'analysisinvocation_id' => {
                                                                            'fk_table' => 'analysisinvocation',
                                                                            'name' => 'analysisinvocation_id',
                                                                            'allownull' => 'no',
                                                                            'type' => 'int',
                                                                            '_entity' => 'column',
                                                                            'fk_column' => 'analysisinvocation_id'
                                                                          },
                                               '_order' => [
                                                             'analysisinput_id',
                                                             'analysisinvocation_id',
                                                             'tableinfo_id',
                                                             'inputrow_id',
                                                             'inputvalue'
                                                           ],
                                               'inputrow_id' => {
                                                                  'name' => 'inputrow_id',
                                                                  'allownull' => 'yes',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column'
                                                                },
                                               '_entity' => 'list',
                                               'inputvalue' => {
                                                                 'name' => 'inputvalue',
                                                                 'allownull' => 'yes',
                                                                 'type' => 'varchar(50)',
                                                                 '_entity' => 'column'
                                                               }
                                             }
                               },
            'wwwuser_author' => {
                                  'indexes' => {
                                                 'wwwuser_author_idx1' => {
                                                                            'columns' => 'wwwuser_id',
                                                                            'name' => 'wwwuser_author_idx1',
                                                                            '_entity' => 'index'
                                                                          },
                                                 'wwwuser_author_idx2' => {
                                                                            'columns' => 'author_id',
                                                                            'name' => 'wwwuser_author_idx2',
                                                                            '_entity' => 'index'
                                                                          },
                                                 '_entity' => 'set'
                                               },
                                  'name' => 'wwwuser_author',
                                  'comment' => 'track wwwuser interest in authors',
                                  '_entity' => 'table',
                                  'primarykey' => 'wwwuser_author_id',
                                  'column' => {
                                                'wwwuser_id' => {
                                                                  'fk_table' => 'wwwuser',
                                                                  'name' => 'wwwuser_id',
                                                                  'allownull' => 'no',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'wwwuser_id',
                                                                  'unique' => 2
                                                                },
                                                'wwwuser_author_id' => {
                                                                         'name' => 'wwwuser_author_id',
                                                                         'allownull' => 'no',
                                                                         'type' => 'serial',
                                                                         '_entity' => 'column',
                                                                         'primarykey' => 'yes'
                                                                       },
                                                'world_read' => {
                                                                  'name' => 'world_read',
                                                                  'allownull' => 'no',
                                                                  'type' => 'smallint',
                                                                  '_entity' => 'column',
                                                                  'default' => 1
                                                                },
                                                '_order' => [
                                                              'wwwuser_author_id',
                                                              'wwwuser_id',
                                                              'author_id',
                                                              'world_read'
                                                            ],
                                                '_entity' => 'list',
                                                'author_id' => {
                                                                 'fk_table' => 'author',
                                                                 'name' => 'author_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'author_id',
                                                                 'unique' => 2
                                                               }
                                              },
                                  'unique' => [
                                                'wwwuser_id',
                                                'author_id'
                                              ]
                                },
            'feature_genotype' => {
                                    'indexes' => {
                                                   'feature_genotype_idx1' => {
                                                                                'columns' => 'feature_id',
                                                                                'name' => 'feature_genotype_idx1',
                                                                                '_entity' => 'index'
                                                                              },
                                                   'feature_genotype_idx2' => {
                                                                                'columns' => 'genotype_id',
                                                                                'name' => 'feature_genotype_idx2',
                                                                                '_entity' => 'index'
                                                                              },
                                                   '_entity' => 'set'
                                                 },
                                    'name' => 'feature_genotype',
                                    '_entity' => 'table',
                                    'primarykey' => 'feature_genotype_id',
                                    'column' => {
                                                  'feature_id' => {
                                                                    'fk_table' => 'feature',
                                                                    'name' => 'feature_id',
                                                                    'allownull' => 'no',
                                                                    'type' => 'int',
                                                                    '_entity' => 'column',
                                                                    'fk_column' => 'feature_id',
                                                                    'unique' => 2
                                                                  },
                                                  'feature_genotype_id' => {
                                                                             'name' => 'feature_genotype_id',
                                                                             'allownull' => 'no',
                                                                             'type' => 'serial',
                                                                             '_entity' => 'column',
                                                                             'primarykey' => 'yes'
                                                                           },
                                                  '_order' => [
                                                                'feature_genotype_id',
                                                                'feature_id',
                                                                'genotype_id'
                                                              ],
                                                  '_entity' => 'list',
                                                  'genotype_id' => {
                                                                     'fk_table' => 'genotype',
                                                                     'name' => 'genotype_id',
                                                                     'allownull' => 'no',
                                                                     'type' => 'int',
                                                                     '_entity' => 'column',
                                                                     'fk_column' => 'genotype_id',
                                                                     'unique' => 2
                                                                   }
                                                },
                                    'unique' => [
                                                  'feature_id',
                                                  'genotype_id'
                                                ]
                                  },
            'expression_pub' => {
                                  'indexes' => {
                                                 'expression_pub_idx1' => {
                                                                            'columns' => 'expression_id',
                                                                            'name' => 'expression_pub_idx1',
                                                                            '_entity' => 'index'
                                                                          },
                                                 'expression_pub_idx2' => {
                                                                            'columns' => 'pub_id',
                                                                            'name' => 'expression_pub_idx2',
                                                                            '_entity' => 'index'
                                                                          },
                                                 '_entity' => 'set'
                                               },
                                  'name' => 'expression_pub',
                                  '_entity' => 'table',
                                  'primarykey' => 'expression_pub_id',
                                  'column' => {
                                                'expression_pub_id' => {
                                                                         'name' => 'expression_pub_id',
                                                                         'allownull' => 'no',
                                                                         'type' => 'serial',
                                                                         '_entity' => 'column',
                                                                         'primarykey' => 'yes'
                                                                       },
                                                'pub_id' => {
                                                              'fk_table' => 'pub',
                                                              'name' => 'pub_id',
                                                              'allownull' => 'no',
                                                              'type' => 'int',
                                                              '_entity' => 'column',
                                                              'fk_column' => 'pub_id',
                                                              'unique' => 2
                                                            },
                                                '_order' => [
                                                              'expression_pub_id',
                                                              'expression_id',
                                                              'pub_id'
                                                            ],
                                                'expression_id' => {
                                                                     'fk_table' => 'expression',
                                                                     'name' => 'expression_id',
                                                                     'allownull' => 'no',
                                                                     'type' => 'int',
                                                                     '_entity' => 'column',
                                                                     'fk_column' => 'expression_id',
                                                                     'unique' => 2
                                                                   },
                                                '_entity' => 'list'
                                              },
                                  'unique' => [
                                                'expression_id',
                                                'pub_id'
                                              ]
                                },
            'studydesigndescription' => {
                                          'name' => 'studydesigndescription',
                                          'comment' => 'ok drop table if exists studydesigndescription;',
                                          '_entity' => 'table',
                                          'primarykey' => 'studydesigndescription_id',
                                          'column' => {
                                                        'descriptiontype_id' => {
                                                                                  'fk_table' => 'cvterm',
                                                                                  'name' => 'descriptiontype_id',
                                                                                  'allownull' => 'no',
                                                                                  'type' => 'int',
                                                                                  '_entity' => 'column',
                                                                                  'fk_column' => 'cvterm_id'
                                                                                },
                                                        'studydesigndescription_id' => {
                                                                                         'name' => 'studydesigndescription_id',
                                                                                         'allownull' => 'no',
                                                                                         'type' => 'serial',
                                                                                         '_entity' => 'column',
                                                                                         'primarykey' => 'yes'
                                                                                       },
                                                        '_order' => [
                                                                      'studydesigndescription_id',
                                                                      'studydesign_id',
                                                                      'descriptiontype_id',
                                                                      'description'
                                                                    ],
                                                        'description' => {
                                                                           'name' => 'description',
                                                                           'allownull' => 'no',
                                                                           'type' => 'varchar(4000)',
                                                                           '_entity' => 'column'
                                                                         },
                                                        '_entity' => 'list',
                                                        'studydesign_id' => {
                                                                              'fk_table' => 'studydesign',
                                                                              'name' => 'studydesign_id',
                                                                              'allownull' => 'no',
                                                                              'type' => 'int',
                                                                              '_entity' => 'column',
                                                                              'fk_column' => 'studydesign_id'
                                                                            }
                                                      }
                                        },
            'processio' => {
                             'name' => 'processio',
                             'comment' => 'ok drop table if exists processio;',
                             '_entity' => 'table',
                             'primarykey' => 'processio_id',
                             'column' => {
                                           'input_role' => {
                                                             'name' => 'input_role',
                                                             'allownull' => 'yes',
                                                             'type' => 'varchar(50)',
                                                             '_entity' => 'column'
                                                           },
                                           'processio_id' => {
                                                               'name' => 'processio_id',
                                                               'allownull' => 'no',
                                                               'type' => 'serial',
                                                               '_entity' => 'column',
                                                               'primarykey' => 'yes'
                                                             },
                                           '_order' => [
                                                         'processio_id',
                                                         'processinvocation_id',
                                                         'inputtable_id',
                                                         'inputrow_id',
                                                         'input_role',
                                                         'outputrow_id'
                                                       ],
                                           'inputrow_id' => {
                                                              'name' => 'inputrow_id',
                                                              'allownull' => 'no',
                                                              'type' => 'int',
                                                              '_entity' => 'column'
                                                            },
                                           'inputtable_id' => {
                                                                'fk_table' => 'tableinfo',
                                                                'name' => 'inputtable_id',
                                                                'allownull' => 'no',
                                                                'type' => 'int',
                                                                '_entity' => 'column',
                                                                'fk_column' => 'tableinfo_id'
                                                              },
                                           '_entity' => 'list',
                                           'outputrow_id' => {
                                                               'fk_table' => 'processresult',
                                                               'name' => 'outputrow_id',
                                                               'allownull' => 'no',
                                                               'type' => 'int',
                                                               '_entity' => 'column',
                                                               'fk_column' => 'processresult_id'
                                                             },
                                           'processinvocation_id' => {
                                                                       'fk_table' => 'processinvocation',
                                                                       'name' => 'processinvocation_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'int',
                                                                       '_entity' => 'column',
                                                                       'fk_column' => 'processinvocation_id'
                                                                     }
                                         }
                           },
            'pub_author' => {
                              'indexes' => {
                                             '_entity' => 'set',
                                             'pub_author_idx1' => {
                                                                    'columns' => 'author_id',
                                                                    'name' => 'pub_author_idx1',
                                                                    '_entity' => 'index'
                                                                  },
                                             'pub_author_idx2' => {
                                                                    'columns' => 'pub_id',
                                                                    'name' => 'pub_author_idx2',
                                                                    '_entity' => 'index'
                                                                  }
                                           },
                              'name' => 'pub_author',
                              'comment' => 'givennames: first name, initials  suffix: Jr., Sr., etc',
                              '_entity' => 'table',
                              'primarykey' => 'pub_author_id',
                              'column' => {
                                            'pub_id' => {
                                                          'fk_table' => 'pub',
                                                          'name' => 'pub_id',
                                                          'allownull' => 'no',
                                                          'type' => 'int',
                                                          '_entity' => 'column',
                                                          'fk_column' => 'pub_id',
                                                          'unique' => 2
                                                        },
                                            '_order' => [
                                                          'pub_author_id',
                                                          'author_id',
                                                          'pub_id',
                                                          'arank',
                                                          'editor'
                                                        ],
                                            '_entity' => 'list',
                                            'arank' => {
                                                         'name' => 'arank',
                                                         'allownull' => 'no',
                                                         'type' => 'int',
                                                         '_entity' => 'column'
                                                       },
                                            'pub_author_id' => {
                                                                 'name' => 'pub_author_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'serial',
                                                                 '_entity' => 'column',
                                                                 'primarykey' => 'yes'
                                                               },
                                            'editor' => {
                                                          'name' => 'editor',
                                                          'allownull' => 'yes',
                                                          'type' => 'boolean',
                                                          '_entity' => 'column',
                                                          'default' => '\'false\''
                                                        },
                                            'author_id' => {
                                                             'fk_table' => 'author',
                                                             'name' => 'author_id',
                                                             'allownull' => 'no',
                                                             'type' => 'int',
                                                             '_entity' => 'column',
                                                             'fk_column' => 'author_id',
                                                             'unique' => 2
                                                           }
                                          },
                              'unique' => [
                                            'author_id',
                                            'pub_id'
                                          ]
                            },
            'cv' => {
                      'name' => 'cv',
                      'comment' => '- term - term_definition - term2term - graph_path - term_synonym - term_dbxref -- dbxref - tricky, namespace clash...  The cvterm module design is based on the ontology',
                      '_entity' => 'table',
                      'primarykey' => 'cv_id',
                      'column' => {
                                    'cvdefinition' => {
                                                        'name' => 'cvdefinition',
                                                        'allownull' => 'yes',
                                                        'type' => 'text',
                                                        '_entity' => 'column'
                                                      },
                                    'cvname' => {
                                                  'name' => 'cvname',
                                                  'allownull' => 'no',
                                                  'type' => 'varchar(255)',
                                                  '_entity' => 'column',
                                                  'unique' => 1
                                                },
                                    '_order' => [
                                                  'cv_id',
                                                  'cvname',
                                                  'cvdefinition'
                                                ],
                                    '_entity' => 'list',
                                    'cv_id' => {
                                                 'name' => 'cv_id',
                                                 'allownull' => 'no',
                                                 'type' => 'serial',
                                                 'foreign_references' => [
                                                                           {
                                                                             'table' => 'cvpath',
                                                                             'column' => 'cv_id'
                                                                           },
                                                                           {
                                                                             'table' => 'cvterm',
                                                                             'column' => 'cv_id'
                                                                           }
                                                                         ],
                                                 '_entity' => 'column',
                                                 'primarykey' => 'yes'
                                               }
                                  },
                      'unique' => [
                                    'cvname'
                                  ]
                    },
            'arrayannotation' => {
                                   'name' => 'arrayannotation',
                                   'comment' => 'ok drop table if exists arrayannotation;',
                                   '_entity' => 'table',
                                   'primarykey' => 'arrayannotation_id',
                                   'column' => {
                                                 'name' => {
                                                             'name' => 'name',
                                                             'allownull' => 'no',
                                                             'type' => 'varchar(500)',
                                                             '_entity' => 'column'
                                                           },
                                                 'array_id' => {
                                                                 'fk_table' => 'array',
                                                                 'name' => 'array_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'array_id'
                                                               },
                                                 '_order' => [
                                                               'arrayannotation_id',
                                                               'array_id',
                                                               'name',
                                                               'value'
                                                             ],
                                                 '_entity' => 'list',
                                                 'value' => {
                                                              'name' => 'value',
                                                              'allownull' => 'no',
                                                              'type' => 'varchar(100)',
                                                              '_entity' => 'column'
                                                            },
                                                 'arrayannotation_id' => {
                                                                           'name' => 'arrayannotation_id',
                                                                           'allownull' => 'no',
                                                                           'type' => 'int',
                                                                           '_entity' => 'column',
                                                                           'primarykey' => 'yes'
                                                                         }
                                               }
                                 },
            'dbxrefprop' => {
                              'indexes' => {
                                             'dbxrefprop_idx1' => {
                                                                    'columns' => 'dbxref_id',
                                                                    'name' => 'dbxrefprop_idx1',
                                                                    '_entity' => 'index'
                                                                  },
                                             'dbxrefprop_idx2' => {
                                                                    'columns' => 'pkey_id',
                                                                    'name' => 'dbxrefprop_idx2',
                                                                    '_entity' => 'index'
                                                                  },
                                             '_entity' => 'set'
                                           },
                              'name' => 'dbxrefprop',
                              '_entity' => 'table',
                              'primarykey' => 'dbxrefprop_id',
                              'column' => {
                                            'dbxrefprop_id' => {
                                                                 'name' => 'dbxrefprop_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'serial',
                                                                 '_entity' => 'column',
                                                                 'primarykey' => 'yes'
                                                               },
                                            'pval' => {
                                                        'name' => 'pval',
                                                        'allownull' => 'no',
                                                        'type' => 'text',
                                                        '_entity' => 'column',
                                                        'default' => '\'\'',
                                                        'unique' => 4
                                                      },
                                            '_order' => [
                                                          'dbxrefprop_id',
                                                          'dbxref_id',
                                                          'pkey_id',
                                                          'pval',
                                                          'prank'
                                                        ],
                                            'prank' => {
                                                         'name' => 'prank',
                                                         'allownull' => 'no',
                                                         'type' => 'int',
                                                         '_entity' => 'column',
                                                         'default' => '0',
                                                         'unique' => 4
                                                       },
                                            '_entity' => 'list',
                                            'pkey_id' => {
                                                           'fk_table' => 'cvterm',
                                                           'name' => 'pkey_id',
                                                           'allownull' => 'no',
                                                           'type' => 'int',
                                                           '_entity' => 'column',
                                                           'fk_column' => 'cvterm_id',
                                                           'unique' => 4
                                                         },
                                            'dbxref_id' => {
                                                             'fk_table' => 'dbxref',
                                                             'name' => 'dbxref_id',
                                                             'allownull' => 'no',
                                                             'type' => 'int',
                                                             '_entity' => 'column',
                                                             'fk_column' => 'dbxref_id',
                                                             'unique' => 4
                                                           }
                                          },
                              'unique' => [
                                            'dbxref_id',
                                            'pkey_id',
                                            'pval',
                                            'prank'
                                          ]
                            },
            'compositeelementresult' => {
                                          'name' => 'compositeelementresult',
                                          'comment' => 'dropped compositeelementannotation.  use featureprop instead. dropped compositeelementgus.         use feature instead. dropped compositeelement.            use feature instead. ok drop table if exists compositeelementresult;',
                                          '_entity' => 'table',
                                          'primarykey' => 'compositeelementresult_id',
                                          'column' => {
                                                        'tinyint1' => {
                                                                        'name' => 'tinyint1',
                                                                        'allownull' => 'yes',
                                                                        'type' => 'int',
                                                                        '_entity' => 'column'
                                                                      },
                                                        'tinyint2' => {
                                                                        'name' => 'tinyint2',
                                                                        'allownull' => 'yes',
                                                                        'type' => 'int',
                                                                        '_entity' => 'column'
                                                                      },
                                                        'tinyint3' => {
                                                                        'name' => 'tinyint3',
                                                                        'allownull' => 'yes',
                                                                        'type' => 'int',
                                                                        '_entity' => 'column'
                                                                      },
                                                        'float1' => {
                                                                      'name' => 'float1',
                                                                      'allownull' => 'yes',
                                                                      'type' => 'float(15)',
                                                                      '_entity' => 'column'
                                                                    },
                                                        'string1' => {
                                                                       'name' => 'string1',
                                                                       'allownull' => 'yes',
                                                                       'type' => 'varchar(500)',
                                                                       '_entity' => 'column'
                                                                     },
                                                        'compositeelementresult_id' => {
                                                                                         'name' => 'compositeelementresult_id',
                                                                                         'allownull' => 'no',
                                                                                         'type' => 'serial',
                                                                                         'foreign_references' => [
                                                                                                                   {
                                                                                                                     'table' => 'elementresult',
                                                                                                                     'column' => 'compositeelementresult_id'
                                                                                                                   }
                                                                                                                 ],
                                                                                         '_entity' => 'column',
                                                                                         'primarykey' => 'yes'
                                                                                       },
                                                        'float2' => {
                                                                      'name' => 'float2',
                                                                      'allownull' => 'yes',
                                                                      'type' => 'float(15)',
                                                                      '_entity' => 'column'
                                                                    },
                                                        'string2' => {
                                                                       'name' => 'string2',
                                                                       'allownull' => 'yes',
                                                                       'type' => 'varchar(500)',
                                                                       '_entity' => 'column'
                                                                     },
                                                        'compositeelement_id' => {
                                                                                   'fk_table' => 'feature',
                                                                                   'name' => 'compositeelement_id',
                                                                                   'allownull' => 'no',
                                                                                   'type' => 'int',
                                                                                   '_entity' => 'column',
                                                                                   'fk_column' => 'feature_id'
                                                                                 },
                                                        'float3' => {
                                                                      'name' => 'float3',
                                                                      'allownull' => 'yes',
                                                                      'type' => 'float(15)',
                                                                      '_entity' => 'column'
                                                                    },
                                                        'float4' => {
                                                                      'name' => 'float4',
                                                                      'allownull' => 'yes',
                                                                      'type' => 'float(15)',
                                                                      '_entity' => 'column'
                                                                    },
                                                        'quantification_id' => {
                                                                                 'fk_table' => 'quantification',
                                                                                 'name' => 'quantification_id',
                                                                                 'allownull' => 'no',
                                                                                 'type' => 'int',
                                                                                 '_entity' => 'column',
                                                                                 'fk_column' => 'quantification_id'
                                                                               },
                                                        'char1' => {
                                                                     'name' => 'char1',
                                                                     'allownull' => 'yes',
                                                                     'type' => 'varchar(5)',
                                                                     '_entity' => 'column'
                                                                   },
                                                        'char2' => {
                                                                     'name' => 'char2',
                                                                     'allownull' => 'yes',
                                                                     'type' => 'varchar(5)',
                                                                     '_entity' => 'column'
                                                                   },
                                                        'char3' => {
                                                                     'name' => 'char3',
                                                                     'allownull' => 'yes',
                                                                     'type' => 'varchar(5)',
                                                                     '_entity' => 'column'
                                                                   },
                                                        'smallint1' => {
                                                                         'name' => 'smallint1',
                                                                         'allownull' => 'yes',
                                                                         'type' => 'int',
                                                                         '_entity' => 'column'
                                                                       },
                                                        'smallint2' => {
                                                                         'name' => 'smallint2',
                                                                         'allownull' => 'yes',
                                                                         'type' => 'int',
                                                                         '_entity' => 'column'
                                                                       },
                                                        'smallint3' => {
                                                                         'name' => 'smallint3',
                                                                         'allownull' => 'yes',
                                                                         'type' => 'int',
                                                                         '_entity' => 'column'
                                                                       },
                                                        'subclass_view' => {
                                                                             'name' => 'subclass_view',
                                                                             'allownull' => 'no',
                                                                             'type' => 'varchar(27)',
                                                                             '_entity' => 'column'
                                                                           },
                                                        '_order' => [
                                                                      'compositeelementresult_id',
                                                                      'compositeelement_id',
                                                                      'quantification_id',
                                                                      'subclass_view',
                                                                      'float1',
                                                                      'float2',
                                                                      'float3',
                                                                      'float4',
                                                                      'int1',
                                                                      'smallint1',
                                                                      'smallint2',
                                                                      'smallint3',
                                                                      'tinyint1',
                                                                      'tinyint2',
                                                                      'tinyint3',
                                                                      'char1',
                                                                      'char2',
                                                                      'char3',
                                                                      'string1',
                                                                      'string2'
                                                                    ],
                                                        'int1' => {
                                                                    'name' => 'int1',
                                                                    'allownull' => 'yes',
                                                                    'type' => 'int',
                                                                    '_entity' => 'column'
                                                                  },
                                                        '_entity' => 'list'
                                                      }
                                        },
            'synonym' => {
                           'indexes' => {
                                          'synonym_idx1' => {
                                                              'columns' => 'type_id',
                                                              'name' => 'synonym_idx1',
                                                              '_entity' => 'index'
                                                            },
                                          '_entity' => 'set'
                                        },
                           'name' => 'synonym',
                           '_entity' => 'table',
                           'primarykey' => 'synonym_id',
                           'column' => {
                                         'name' => {
                                                     'name' => 'name',
                                                     'allownull' => 'no',
                                                     'type' => 'varchar(255)',
                                                     '_entity' => 'column',
                                                     'unique' => 2
                                                   },
                                         'synonym_id' => {
                                                           'name' => 'synonym_id',
                                                           'allownull' => 'no',
                                                           'type' => 'serial',
                                                           'foreign_references' => [
                                                                                     {
                                                                                       'table' => 'synonym_pub',
                                                                                       'column' => 'synonym_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'feature_synonym',
                                                                                       'column' => 'synonym_id'
                                                                                     }
                                                                                   ],
                                                           '_entity' => 'column',
                                                           'primarykey' => 'yes'
                                                         },
                                         '_order' => [
                                                       'synonym_id',
                                                       'name',
                                                       'type_id',
                                                       'synonym_sgml'
                                                     ],
                                         '_entity' => 'list',
                                         'type_id' => {
                                                        'fk_table' => 'cvterm',
                                                        'name' => 'type_id',
                                                        'allownull' => 'no',
                                                        'type' => 'int',
                                                        '_entity' => 'column',
                                                        'fk_column' => 'cvterm_id',
                                                        'unique' => 2
                                                      },
                                         'synonym_sgml' => {
                                                             'name' => 'synonym_sgml',
                                                             'allownull' => 'no',
                                                             'type' => 'varchar(255)',
                                                             '_entity' => 'column'
                                                           }
                                       },
                           'unique' => [
                                         'name',
                                         'type_id'
                                       ]
                         },
            'featurepos' => {
                              'indexes' => {
                                             'featurepos_idx1' => {
                                                                    'columns' => 'featuremap_id',
                                                                    'name' => 'featurepos_idx1',
                                                                    '_entity' => 'index'
                                                                  },
                                             'featurepos_idx2' => {
                                                                    'columns' => 'feature_id',
                                                                    'name' => 'featurepos_idx2',
                                                                    '_entity' => 'index'
                                                                  },
                                             '_entity' => 'set',
                                             'featurepos_idx3' => {
                                                                    'columns' => 'map_feature_id',
                                                                    'name' => 'featurepos_idx3',
                                                                    '_entity' => 'index'
                                                                  }
                                           },
                              'name' => 'featurepos',
                              '_entity' => 'table',
                              'primarykey' => 'featurepos_id',
                              'column' => {
                                            'mappos' => {
                                                          'name' => 'mappos',
                                                          'allownull' => 'no',
                                                          'type' => 'float',
                                                          '_entity' => 'column'
                                                        },
                                            'feature_id' => {
                                                              'fk_table' => 'feature',
                                                              'name' => 'feature_id',
                                                              'allownull' => 'no',
                                                              'type' => 'int',
                                                              '_entity' => 'column',
                                                              'fk_column' => 'feature_id'
                                                            },
                                            'featurepos_id' => {
                                                                 'name' => 'featurepos_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'serial',
                                                                 '_entity' => 'column',
                                                                 'primarykey' => 'yes'
                                                               },
                                            '_order' => [
                                                          'featurepos_id',
                                                          'featuremap_id',
                                                          'feature_id',
                                                          'map_feature_id',
                                                          'mappos'
                                                        ],
                                            '_entity' => 'list',
                                            'map_feature_id' => {
                                                                  'fk_table' => 'feature',
                                                                  'name' => 'map_feature_id',
                                                                  'allownull' => 'no',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'feature_id'
                                                                },
                                            'featuremap_id' => {
                                                                 'fk_table' => 'featuremap',
                                                                 'name' => 'featuremap_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'serial',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'featuremap_id'
                                                               }
                                          }
                            },
            'organism' => {
                            'name' => 'organism',
                            '_entity' => 'table',
                            'primarykey' => 'organism_id',
                            'column' => {
                                          'genus' => {
                                                       'name' => 'genus',
                                                       'allownull' => 'no',
                                                       'type' => 'varchar(255)',
                                                       '_entity' => 'column',
                                                       'unique' => 3
                                                     },
                                          'abbrev' => {
                                                        'name' => 'abbrev',
                                                        'allownull' => 'yes',
                                                        'type' => 'varchar(255)',
                                                        '_entity' => 'column'
                                                      },
                                          'comment' => {
                                                         'name' => 'comment',
                                                         'allownull' => 'yes',
                                                         'type' => 'text',
                                                         '_entity' => 'column'
                                                       },
                                          'common_name' => {
                                                             'name' => 'common_name',
                                                             'allownull' => 'yes',
                                                             'type' => 'varchar(255)',
                                                             '_entity' => 'column'
                                                           },
                                          'taxgroup' => {
                                                          'name' => 'taxgroup',
                                                          'allownull' => 'no',
                                                          'type' => 'varchar(255)',
                                                          '_entity' => 'column',
                                                          'unique' => 3
                                                        },
                                          '_order' => [
                                                        'organism_id',
                                                        'abbrev',
                                                        'genus',
                                                        'taxgroup',
                                                        'species',
                                                        'common_name',
                                                        'comment'
                                                      ],
                                          '_entity' => 'list',
                                          'organism_id' => {
                                                             'name' => 'organism_id',
                                                             'allownull' => 'no',
                                                             'type' => 'serial',
                                                             'foreign_references' => [
                                                                                       {
                                                                                         'table' => 'feature',
                                                                                         'column' => 'organism_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'wwwuser_organism',
                                                                                         'column' => 'organism_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'biomaterial',
                                                                                         'column' => 'taxon_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'organism_dbxref',
                                                                                         'column' => 'organism_id'
                                                                                       }
                                                                                     ],
                                                             '_entity' => 'column',
                                                             'primarykey' => 'yes'
                                                           },
                                          'species' => {
                                                         'name' => 'species',
                                                         'allownull' => 'no',
                                                         'type' => 'varchar(255)',
                                                         '_entity' => 'column',
                                                         'unique' => 3
                                                       }
                                        },
                            'unique' => [
                                          'taxgroup',
                                          'genus',
                                          'species'
                                        ]
                          },
            'interaction' => {
                               'indexes' => {
                                              '_entity' => 'set',
                                              'interaction_idx1' => {
                                                                      'columns' => 'pub_id',
                                                                      'name' => 'interaction_idx1',
                                                                      '_entity' => 'index'
                                                                    },
                                              'interaction_idx2' => {
                                                                      'columns' => 'background_genotype_id',
                                                                      'name' => 'interaction_idx2',
                                                                      '_entity' => 'index'
                                                                    },
                                              'interaction_idx3' => {
                                                                      'columns' => 'phenotype_id',
                                                                      'name' => 'interaction_idx3',
                                                                      '_entity' => 'index'
                                                                    }
                                            },
                               'name' => 'interaction',
                               '_entity' => 'table',
                               'primarykey' => 'interaction_id',
                               'column' => {
                                             'phenotype_id' => {
                                                                 'fk_table' => 'phenotype',
                                                                 'name' => 'phenotype_id',
                                                                 'allownull' => 'yes',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'phenotype_id'
                                                               },
                                             'pub_id' => {
                                                           'fk_table' => 'pub',
                                                           'name' => 'pub_id',
                                                           'allownull' => 'no',
                                                           'type' => 'int',
                                                           '_entity' => 'column',
                                                           'fk_column' => 'pub_id'
                                                         },
                                             '_order' => [
                                                           'interaction_id',
                                                           'description',
                                                           'pub_id',
                                                           'background_genotype_id',
                                                           'phenotype_id'
                                                         ],
                                             'description' => {
                                                                'name' => 'description',
                                                                'allownull' => 'yes',
                                                                'type' => 'text',
                                                                '_entity' => 'column'
                                                              },
                                             'interaction_id' => {
                                                                   'name' => 'interaction_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'serial',
                                                                   'foreign_references' => [
                                                                                             {
                                                                                               'table' => 'wwwuser_interaction',
                                                                                               'column' => 'interaction_id'
                                                                                             },
                                                                                             {
                                                                                               'table' => 'interaction_subj',
                                                                                               'column' => 'interaction_id'
                                                                                             },
                                                                                             {
                                                                                               'table' => 'interaction_obj',
                                                                                               'column' => 'interaction_id'
                                                                                             }
                                                                                           ],
                                                                   '_entity' => 'column',
                                                                   'primarykey' => 'yes'
                                                                 },
                                             '_entity' => 'list',
                                             'background_genotype_id' => {
                                                                           'fk_table' => 'genotype',
                                                                           'name' => 'background_genotype_id',
                                                                           'allownull' => 'yes',
                                                                           'type' => 'int',
                                                                           'comment' => 'Do we want to call this simply genotype_id to allow natural joins?',
                                                                           '_entity' => 'column',
                                                                           'fk_column' => 'genotype_id'
                                                                         }
                                           }
                             },
            'pub_dbxref' => {
                              'indexes' => {
                                             '_entity' => 'set',
                                             'pub_dbxref_idx1' => {
                                                                    'columns' => 'pub_id',
                                                                    'name' => 'pub_dbxref_idx1',
                                                                    '_entity' => 'index'
                                                                  },
                                             'pub_dbxref_idx2' => {
                                                                    'columns' => 'dbxref_id',
                                                                    'name' => 'pub_dbxref_idx2',
                                                                    '_entity' => 'index'
                                                                  }
                                           },
                              'name' => 'pub_dbxref',
                              'comment' => 'Handle links to eg, pubmed, biosis, zoorec, OCLC, mdeline, ISSN, coden...',
                              '_entity' => 'table',
                              'primarykey' => 'pub_dbxref_id',
                              'column' => {
                                            'pub_id' => {
                                                          'fk_table' => 'pub',
                                                          'name' => 'pub_id',
                                                          'allownull' => 'no',
                                                          'type' => 'int',
                                                          '_entity' => 'column',
                                                          'fk_column' => 'pub_id',
                                                          'unique' => 2
                                                        },
                                            '_order' => [
                                                          'pub_dbxref_id',
                                                          'pub_id',
                                                          'dbxref_id'
                                                        ],
                                            '_entity' => 'list',
                                            'pub_dbxref_id' => {
                                                                 'name' => 'pub_dbxref_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'serial',
                                                                 '_entity' => 'column',
                                                                 'primarykey' => 'yes'
                                                               },
                                            'dbxref_id' => {
                                                             'fk_table' => 'dbxref',
                                                             'name' => 'dbxref_id',
                                                             'allownull' => 'no',
                                                             'type' => 'int',
                                                             '_entity' => 'column',
                                                             'fk_column' => 'dbxref_id',
                                                             'unique' => 2
                                                           }
                                          },
                              'unique' => [
                                            'pub_id',
                                            'dbxref_id'
                                          ]
                            },
            'wwwuser_interaction' => {
                                       'indexes' => {
                                                      'wwwuser_interaction_idx1' => {
                                                                                      'columns' => 'wwwuser_id',
                                                                                      'name' => 'wwwuser_interaction_idx1',
                                                                                      '_entity' => 'index'
                                                                                    },
                                                      'wwwuser_interaction_idx2' => {
                                                                                      'columns' => 'interaction_id',
                                                                                      'name' => 'wwwuser_interaction_idx2',
                                                                                      '_entity' => 'index'
                                                                                    },
                                                      '_entity' => 'set'
                                                    },
                                       'name' => 'wwwuser_interaction',
                                       'comment' => 'track wwwuser interest in interactions',
                                       '_entity' => 'table',
                                       'primarykey' => 'wwwuser_interaction_id',
                                       'column' => {
                                                     'wwwuser_id' => {
                                                                       'fk_table' => 'wwwuser',
                                                                       'name' => 'wwwuser_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'int',
                                                                       '_entity' => 'column',
                                                                       'fk_column' => 'wwwuser_id',
                                                                       'unique' => 2
                                                                     },
                                                     'world_read' => {
                                                                       'name' => 'world_read',
                                                                       'allownull' => 'no',
                                                                       'type' => 'smallint',
                                                                       '_entity' => 'column',
                                                                       'default' => 1
                                                                     },
                                                     '_order' => [
                                                                   'wwwuser_interaction_id',
                                                                   'wwwuser_id',
                                                                   'interaction_id',
                                                                   'world_read'
                                                                 ],
                                                     'interaction_id' => {
                                                                           'fk_table' => 'interaction',
                                                                           'name' => 'interaction_id',
                                                                           'allownull' => 'no',
                                                                           'type' => 'int',
                                                                           '_entity' => 'column',
                                                                           'fk_column' => 'interaction_id',
                                                                           'unique' => 2
                                                                         },
                                                     '_entity' => 'list',
                                                     'wwwuser_interaction_id' => {
                                                                                   'name' => 'wwwuser_interaction_id',
                                                                                   'allownull' => 'no',
                                                                                   'type' => 'serial',
                                                                                   '_entity' => 'column',
                                                                                   'primarykey' => 'yes'
                                                                                 }
                                                   },
                                       'unique' => [
                                                     'wwwuser_id',
                                                     'interaction_id'
                                                   ]
                                     },
            'analysisprop' => {
                                'indexes' => {
                                               'analysisprop_idx1' => {
                                                                        'columns' => 'analysis_id',
                                                                        'name' => 'analysisprop_idx1',
                                                                        '_entity' => 'index'
                                                                      },
                                               'analysisprop_idx2' => {
                                                                        'columns' => 'pkey_id',
                                                                        'name' => 'analysisprop_idx2',
                                                                        '_entity' => 'index'
                                                                      },
                                               '_entity' => 'set'
                                             },
                                'name' => 'analysisprop',
                                'comment' => 'analyses can have various properties attached - eg the parameters  used in running a blast',
                                '_entity' => 'table',
                                'primarykey' => 'analysisprop_id',
                                'column' => {
                                              'analysis_id' => {
                                                                 'fk_table' => 'analysis',
                                                                 'name' => 'analysis_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'analysis_id',
                                                                 'unique' => 3
                                                               },
                                              'analysisprop_id' => {
                                                                     'name' => 'analysisprop_id',
                                                                     'allownull' => 'no',
                                                                     'type' => 'serial',
                                                                     '_entity' => 'column',
                                                                     'primarykey' => 'yes'
                                                                   },
                                              'pval' => {
                                                          'name' => 'pval',
                                                          'allownull' => 'yes',
                                                          'type' => 'text',
                                                          '_entity' => 'column',
                                                          'unique' => 3
                                                        },
                                              '_order' => [
                                                            'analysisprop_id',
                                                            'analysis_id',
                                                            'pkey_id',
                                                            'pval'
                                                          ],
                                              '_entity' => 'list',
                                              'pkey_id' => {
                                                             'fk_table' => 'cvterm',
                                                             'name' => 'pkey_id',
                                                             'allownull' => 'no',
                                                             'type' => 'int',
                                                             '_entity' => 'column',
                                                             'fk_column' => 'cvterm_id',
                                                             'unique' => 3
                                                           }
                                            },
                                'unique' => [
                                              'analysis_id',
                                              'pkey_id',
                                              'pval'
                                            ]
                              },
            'projectlink' => {
                               'name' => 'projectlink',
                               'comment' => 'ok drop table if exists projectlink;',
                               '_entity' => 'table',
                               'primarykey' => 'projectlink_id',
                               'column' => {
                                             'tableinfo_id' => {
                                                                 'fk_table' => 'tableinfo',
                                                                 'name' => 'tableinfo_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'tableinfo_id'
                                                               },
                                             'currentversion' => {
                                                                   'name' => 'currentversion',
                                                                   'allownull' => 'yes',
                                                                   'type' => 'varchar(4)',
                                                                   '_entity' => 'column'
                                                                 },
                                             'projectlink_id' => {
                                                                   'name' => 'projectlink_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'serial',
                                                                   '_entity' => 'column',
                                                                   'primarykey' => 'yes'
                                                                 },
                                             'project_id' => {
                                                               'fk_table' => 'project',
                                                               'name' => 'project_id',
                                                               'allownull' => 'no',
                                                               'type' => 'int',
                                                               '_entity' => 'column',
                                                               'fk_column' => 'project_id'
                                                             },
                                             '_order' => [
                                                           'projectlink_id',
                                                           'project_id',
                                                           'tableinfo_id',
                                                           'id',
                                                           'currentversion'
                                                         ],
                                             '_entity' => 'list',
                                             'id' => {
                                                       'name' => 'id',
                                                       'allownull' => 'no',
                                                       'type' => 'int',
                                                       '_entity' => 'column'
                                                     }
                                           }
                             },
            'feature_dbxref' => {
                                  'indexes' => {
                                                 'feature_dbxref_idx1' => {
                                                                            'columns' => 'feature_id',
                                                                            'name' => 'feature_dbxref_idx1',
                                                                            '_entity' => 'index'
                                                                          },
                                                 'feature_dbxref_idx2' => {
                                                                            'columns' => 'dbxref_id',
                                                                            'name' => 'feature_dbxref_idx2',
                                                                            '_entity' => 'index'
                                                                          },
                                                 '_entity' => 'set'
                                               },
                                  'name' => 'feature_dbxref',
                                  'comment' => 'links a feature to dbxrefs.  Note that there is also feature.dbxref_id  link for the primary dbxref link.',
                                  '_entity' => 'table',
                                  'primarykey' => 'feature_dbxref_id',
                                  'column' => {
                                                'feature_id' => {
                                                                  'fk_table' => 'feature',
                                                                  'name' => 'feature_id',
                                                                  'allownull' => 'no',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'feature_id',
                                                                  'unique' => 2
                                                                },
                                                'feature_dbxref_id' => {
                                                                         'name' => 'feature_dbxref_id',
                                                                         'allownull' => 'no',
                                                                         'type' => 'serial',
                                                                         '_entity' => 'column',
                                                                         'primarykey' => 'yes'
                                                                       },
                                                '_order' => [
                                                              'feature_dbxref_id',
                                                              'feature_id',
                                                              'dbxref_id',
                                                              'is_current'
                                                            ],
                                                '_entity' => 'list',
                                                'is_current' => {
                                                                  'name' => 'is_current',
                                                                  'allownull' => 'no',
                                                                  'type' => 'boolean',
                                                                  '_entity' => 'column',
                                                                  'default' => '\'true\''
                                                                },
                                                'dbxref_id' => {
                                                                 'fk_table' => 'dbxref',
                                                                 'name' => 'dbxref_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'dbxref_id',
                                                                 'unique' => 2
                                                               }
                                              },
                                  'unique' => [
                                                'feature_id',
                                                'dbxref_id'
                                              ]
                                },
            'db' => {
                      'name' => 'db',
                      '_entity' => 'table',
                      'primarykey' => 'db_id',
                      'column' => {
                                    'name' => {
                                                'name' => 'name',
                                                'allownull' => 'no',
                                                'type' => 'varchar(255)',
                                                '_entity' => 'column',
                                                'unique' => 1
                                              },
                                    'db_id' => {
                                                 'name' => 'db_id',
                                                 'allownull' => 'no',
                                                 'type' => 'varchar(255)',
                                                 'foreign_references' => [
                                                                           {
                                                                             'table' => 'dbxref',
                                                                             'column' => 'dbname'
                                                                           }
                                                                         ],
                                                 '_entity' => 'column',
                                                 'primarykey' => 'yes'
                                               },
                                    'url' => {
                                               'name' => 'url',
                                               'allownull' => 'yes',
                                               'type' => 'varchar(255)',
                                               '_entity' => 'column'
                                             },
                                    '_order' => [
                                                  'db_id',
                                                  'name',
                                                  'description',
                                                  'url'
                                                ],
                                    'description' => {
                                                       'name' => 'description',
                                                       'allownull' => 'yes',
                                                       'type' => 'varchar(255)',
                                                       '_entity' => 'column'
                                                     },
                                    '_entity' => 'list'
                                  },
                      'unique' => [
                                    'name'
                                  ]
                    },
            'feature_synonym' => {
                                   'indexes' => {
                                                  '_entity' => 'set',
                                                  'feature_synonym_idx1' => {
                                                                              'columns' => 'synonym_id',
                                                                              'name' => 'feature_synonym_idx1',
                                                                              '_entity' => 'index'
                                                                            },
                                                  'feature_synonym_idx2' => {
                                                                              'columns' => 'feature_id',
                                                                              'name' => 'feature_synonym_idx2',
                                                                              '_entity' => 'index'
                                                                            },
                                                  'feature_synonym_idx3' => {
                                                                              'columns' => 'pub_id',
                                                                              'name' => 'feature_synonym_idx3',
                                                                              '_entity' => 'index'
                                                                            }
                                                },
                                   'name' => 'feature_synonym',
                                   'comment' => 'type_id: types would be symbol and fullname for now  synonym_sgml: sgml-ized version of symbols',
                                   '_entity' => 'table',
                                   'primarykey' => 'feature_synonym_id',
                                   'column' => {
                                                 'is_internal' => {
                                                                    'name' => 'is_internal',
                                                                    'allownull' => 'no',
                                                                    'type' => 'boolean',
                                                                    '_entity' => 'column',
                                                                    'default' => '\'false\''
                                                                  },
                                                 'feature_id' => {
                                                                   'fk_table' => 'feature',
                                                                   'name' => 'feature_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'feature_id',
                                                                   'unique' => 3
                                                                 },
                                                 'synonym_id' => {
                                                                   'fk_table' => 'synonym',
                                                                   'name' => 'synonym_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'synonym_id',
                                                                   'unique' => 3
                                                                 },
                                                 'pub_id' => {
                                                               'fk_table' => 'pub',
                                                               'name' => 'pub_id',
                                                               'allownull' => 'no',
                                                               'type' => 'int',
                                                               '_entity' => 'column',
                                                               'fk_column' => 'pub_id',
                                                               'unique' => 3
                                                             },
                                                 '_order' => [
                                                               'feature_synonym_id',
                                                               'synonym_id',
                                                               'feature_id',
                                                               'pub_id',
                                                               'is_current',
                                                               'is_internal'
                                                             ],
                                                 'feature_synonym_id' => {
                                                                           'name' => 'feature_synonym_id',
                                                                           'allownull' => 'no',
                                                                           'type' => 'serial',
                                                                           '_entity' => 'column',
                                                                           'primarykey' => 'yes'
                                                                         },
                                                 '_entity' => 'list',
                                                 'is_current' => {
                                                                   'name' => 'is_current',
                                                                   'allownull' => 'no',
                                                                   'type' => 'boolean',
                                                                   '_entity' => 'column'
                                                                 }
                                               },
                                   'unique' => [
                                                 'synonym_id',
                                                 'feature_id',
                                                 'pub_id'
                                               ]
                                 },
            'elementresult' => {
                                 'name' => 'elementresult',
                                 'comment' => 'ok drop table if exists elementresult;',
                                 '_entity' => 'table',
                                 'primarykey' => 'elementresult_id',
                                 'column' => {
                                               'background' => {
                                                                 'name' => 'background',
                                                                 'allownull' => 'yes',
                                                                 'type' => 'float(15)',
                                                                 '_entity' => 'column'
                                                               },
                                               'string1' => {
                                                              'name' => 'string1',
                                                              'allownull' => 'yes',
                                                              'type' => 'varchar(500)',
                                                              '_entity' => 'column'
                                                            },
                                               'compositeelementresult_id' => {
                                                                                'fk_table' => 'compositeelementresult',
                                                                                'name' => 'compositeelementresult_id',
                                                                                'allownull' => 'yes',
                                                                                'type' => 'int',
                                                                                '_entity' => 'column',
                                                                                'fk_column' => 'compositeelementresult_id'
                                                                              },
                                               'string2' => {
                                                              'name' => 'string2',
                                                              'allownull' => 'yes',
                                                              'type' => 'varchar(500)',
                                                              '_entity' => 'column'
                                                            },
                                               'quantification_id' => {
                                                                        'fk_table' => 'quantification',
                                                                        'name' => 'quantification_id',
                                                                        'allownull' => 'no',
                                                                        'type' => 'int',
                                                                        '_entity' => 'column',
                                                                        'fk_column' => 'quantification_id'
                                                                      },
                                               'tinystring1' => {
                                                                  'name' => 'tinystring1',
                                                                  'allownull' => 'yes',
                                                                  'type' => 'varchar(50)',
                                                                  '_entity' => 'column'
                                                                },
                                               'int10' => {
                                                            'name' => 'int10',
                                                            'allownull' => 'yes',
                                                            'type' => 'int',
                                                            '_entity' => 'column'
                                                          },
                                               'tinystring2' => {
                                                                  'name' => 'tinystring2',
                                                                  'allownull' => 'yes',
                                                                  'type' => 'varchar(50)',
                                                                  '_entity' => 'column'
                                                                },
                                               'int11' => {
                                                            'name' => 'int11',
                                                            'allownull' => 'yes',
                                                            'type' => 'int',
                                                            '_entity' => 'column'
                                                          },
                                               'tinystring3' => {
                                                                  'name' => 'tinystring3',
                                                                  'allownull' => 'yes',
                                                                  'type' => 'varchar(50)',
                                                                  '_entity' => 'column'
                                                                },
                                               'int12' => {
                                                            'name' => 'int12',
                                                            'allownull' => 'yes',
                                                            'type' => 'int',
                                                            '_entity' => 'column'
                                                          },
                                               'char1' => {
                                                            'name' => 'char1',
                                                            'allownull' => 'yes',
                                                            'type' => 'varchar(5)',
                                                            '_entity' => 'column'
                                                          },
                                               'int13' => {
                                                            'name' => 'int13',
                                                            'allownull' => 'yes',
                                                            'type' => 'int',
                                                            '_entity' => 'column'
                                                          },
                                               'char2' => {
                                                            'name' => 'char2',
                                                            'allownull' => 'yes',
                                                            'type' => 'varchar(5)',
                                                            '_entity' => 'column'
                                                          },
                                               'int14' => {
                                                            'name' => 'int14',
                                                            'allownull' => 'yes',
                                                            'type' => 'int',
                                                            '_entity' => 'column'
                                                          },
                                               'char3' => {
                                                            'name' => 'char3',
                                                            'allownull' => 'yes',
                                                            'type' => 'varchar(5)',
                                                            '_entity' => 'column'
                                                          },
                                               'int15' => {
                                                            'name' => 'int15',
                                                            'allownull' => 'yes',
                                                            'type' => 'int',
                                                            '_entity' => 'column'
                                                          },
                                               'char4' => {
                                                            'name' => 'char4',
                                                            'allownull' => 'yes',
                                                            'type' => 'varchar(5)',
                                                            '_entity' => 'column'
                                                          },
                                               'smallint1' => {
                                                                'name' => 'smallint1',
                                                                'allownull' => 'yes',
                                                                'type' => 'int',
                                                                '_entity' => 'column'
                                                              },
                                               'smallint2' => {
                                                                'name' => 'smallint2',
                                                                'allownull' => 'yes',
                                                                'type' => 'int',
                                                                '_entity' => 'column'
                                                              },
                                               'element_id' => {
                                                                 'fk_table' => 'element',
                                                                 'name' => 'element_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'element_id'
                                                               },
                                               'background_sd' => {
                                                                    'name' => 'background_sd',
                                                                    'allownull' => 'yes',
                                                                    'type' => 'float(15)',
                                                                    '_entity' => 'column'
                                                                  },
                                               'smallint3' => {
                                                                'name' => 'smallint3',
                                                                'allownull' => 'yes',
                                                                'type' => 'int',
                                                                '_entity' => 'column'
                                                              },
                                               'subclass_view' => {
                                                                    'name' => 'subclass_view',
                                                                    'allownull' => 'no',
                                                                    'type' => 'varchar(27)',
                                                                    '_entity' => 'column'
                                                                  },
                                               'int1' => {
                                                           'name' => 'int1',
                                                           'allownull' => 'yes',
                                                           'type' => 'int',
                                                           '_entity' => 'column'
                                                         },
                                               '_entity' => 'list',
                                               'int2' => {
                                                           'name' => 'int2',
                                                           'allownull' => 'yes',
                                                           'type' => 'int',
                                                           '_entity' => 'column'
                                                         },
                                               'int3' => {
                                                           'name' => 'int3',
                                                           'allownull' => 'yes',
                                                           'type' => 'int',
                                                           '_entity' => 'column'
                                                         },
                                               'int4' => {
                                                           'name' => 'int4',
                                                           'allownull' => 'yes',
                                                           'type' => 'int',
                                                           '_entity' => 'column'
                                                         },
                                               'tinyint1' => {
                                                               'name' => 'tinyint1',
                                                               'allownull' => 'yes',
                                                               'type' => 'int',
                                                               '_entity' => 'column'
                                                             },
                                               'int5' => {
                                                           'name' => 'int5',
                                                           'allownull' => 'yes',
                                                           'type' => 'int',
                                                           '_entity' => 'column'
                                                         },
                                               'smallstring1' => {
                                                                   'name' => 'smallstring1',
                                                                   'allownull' => 'yes',
                                                                   'type' => 'varchar(100)',
                                                                   '_entity' => 'column'
                                                                 },
                                               'tinyint2' => {
                                                               'name' => 'tinyint2',
                                                               'allownull' => 'yes',
                                                               'type' => 'int',
                                                               '_entity' => 'column'
                                                             },
                                               'int6' => {
                                                           'name' => 'int6',
                                                           'allownull' => 'yes',
                                                           'type' => 'int',
                                                           '_entity' => 'column'
                                                         },
                                               'smallstring2' => {
                                                                   'name' => 'smallstring2',
                                                                   'allownull' => 'yes',
                                                                   'type' => 'varchar(100)',
                                                                   '_entity' => 'column'
                                                                 },
                                               'tinyint3' => {
                                                               'name' => 'tinyint3',
                                                               'allownull' => 'yes',
                                                               'type' => 'int',
                                                               '_entity' => 'column'
                                                             },
                                               'int7' => {
                                                           'name' => 'int7',
                                                           'allownull' => 'yes',
                                                           'type' => 'int',
                                                           '_entity' => 'column'
                                                         },
                                               'int8' => {
                                                           'name' => 'int8',
                                                           'allownull' => 'yes',
                                                           'type' => 'int',
                                                           '_entity' => 'column'
                                                         },
                                               'int9' => {
                                                           'name' => 'int9',
                                                           'allownull' => 'yes',
                                                           'type' => 'int',
                                                           '_entity' => 'column'
                                                         },
                                               'float1' => {
                                                             'name' => 'float1',
                                                             'allownull' => 'yes',
                                                             'type' => 'float(15)',
                                                             '_entity' => 'column'
                                                           },
                                               'float2' => {
                                                             'name' => 'float2',
                                                             'allownull' => 'yes',
                                                             'type' => 'float(15)',
                                                             '_entity' => 'column'
                                                           },
                                               'float3' => {
                                                             'name' => 'float3',
                                                             'allownull' => 'yes',
                                                             'type' => 'float(15)',
                                                             '_entity' => 'column'
                                                           },
                                               'float4' => {
                                                             'name' => 'float4',
                                                             'allownull' => 'yes',
                                                             'type' => 'float(15)',
                                                             '_entity' => 'column'
                                                           },
                                               'float5' => {
                                                             'name' => 'float5',
                                                             'allownull' => 'yes',
                                                             'type' => 'float(15)',
                                                             '_entity' => 'column'
                                                           },
                                               'float6' => {
                                                             'name' => 'float6',
                                                             'allownull' => 'yes',
                                                             'type' => 'float(15)',
                                                             '_entity' => 'column'
                                                           },
                                               'float7' => {
                                                             'name' => 'float7',
                                                             'allownull' => 'yes',
                                                             'type' => 'float(15)',
                                                             '_entity' => 'column'
                                                           },
                                               'float8' => {
                                                             'name' => 'float8',
                                                             'allownull' => 'yes',
                                                             'type' => 'float(15)',
                                                             '_entity' => 'column'
                                                           },
                                               'float9' => {
                                                             'name' => 'float9',
                                                             'allownull' => 'yes',
                                                             'type' => 'float(15)',
                                                             '_entity' => 'column'
                                                           },
                                               'foreground_sd' => {
                                                                    'name' => 'foreground_sd',
                                                                    'allownull' => 'yes',
                                                                    'type' => 'float(15)',
                                                                    '_entity' => 'column'
                                                                  },
                                               'elementresult_id' => {
                                                                       'name' => 'elementresult_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'serial',
                                                                       '_entity' => 'column',
                                                                       'primarykey' => 'yes'
                                                                     },
                                               'float10' => {
                                                              'name' => 'float10',
                                                              'allownull' => 'yes',
                                                              'type' => 'float(15)',
                                                              '_entity' => 'column'
                                                            },
                                               'float11' => {
                                                              'name' => 'float11',
                                                              'allownull' => 'yes',
                                                              'type' => 'float(15)',
                                                              '_entity' => 'column'
                                                            },
                                               'float12' => {
                                                              'name' => 'float12',
                                                              'allownull' => 'yes',
                                                              'type' => 'float(15)',
                                                              '_entity' => 'column'
                                                            },
                                               'float13' => {
                                                              'name' => 'float13',
                                                              'allownull' => 'yes',
                                                              'type' => 'float(15)',
                                                              '_entity' => 'column'
                                                            },
                                               '_order' => [
                                                             'elementresult_id',
                                                             'element_id',
                                                             'compositeelementresult_id',
                                                             'quantification_id',
                                                             'subclass_view',
                                                             'foreground',
                                                             'background',
                                                             'foreground_sd',
                                                             'background_sd',
                                                             'float1',
                                                             'float2',
                                                             'float3',
                                                             'float4',
                                                             'float5',
                                                             'float6',
                                                             'float7',
                                                             'float8',
                                                             'float9',
                                                             'float10',
                                                             'float11',
                                                             'float12',
                                                             'float13',
                                                             'float14',
                                                             'int1',
                                                             'int2',
                                                             'int3',
                                                             'int4',
                                                             'int5',
                                                             'int6',
                                                             'int7',
                                                             'int8',
                                                             'int9',
                                                             'int10',
                                                             'int11',
                                                             'int12',
                                                             'int13',
                                                             'int14',
                                                             'int15',
                                                             'tinyint1',
                                                             'tinyint2',
                                                             'tinyint3',
                                                             'smallint1',
                                                             'smallint2',
                                                             'smallint3',
                                                             'char1',
                                                             'char2',
                                                             'char3',
                                                             'char4',
                                                             'tinystring1',
                                                             'tinystring2',
                                                             'tinystring3',
                                                             'smallstring1',
                                                             'smallstring2',
                                                             'string1',
                                                             'string2'
                                                           ],
                                               'foreground' => {
                                                                 'name' => 'foreground',
                                                                 'allownull' => 'yes',
                                                                 'type' => 'float(15)',
                                                                 '_entity' => 'column'
                                                               },
                                               'float14' => {
                                                              'name' => 'float14',
                                                              'allownull' => 'yes',
                                                              'type' => 'float(15)',
                                                              '_entity' => 'column'
                                                            }
                                             }
                               },
            'analysisimplementation' => {
                                          'name' => 'analysisimplementation',
                                          'comment' => 'ok drop table if exists analysisimplementation;',
                                          '_entity' => 'table',
                                          'primarykey' => 'analysisimplementation_id',
                                          'column' => {
                                                        'analysis_id' => {
                                                                           'fk_table' => 'analysis',
                                                                           'name' => 'analysis_id',
                                                                           'allownull' => 'no',
                                                                           'type' => 'int',
                                                                           '_entity' => 'column',
                                                                           'fk_column' => 'analysis_id'
                                                                         },
                                                        'name' => {
                                                                    'name' => 'name',
                                                                    'allownull' => 'no',
                                                                    'type' => 'varchar(100)',
                                                                    '_entity' => 'column'
                                                                  },
                                                        '_order' => [
                                                                      'analysisimplementation_id',
                                                                      'analysis_id',
                                                                      'name',
                                                                      'description'
                                                                    ],
                                                        'description' => {
                                                                           'name' => 'description',
                                                                           'allownull' => 'yes',
                                                                           'type' => 'varchar(500)',
                                                                           '_entity' => 'column'
                                                                         },
                                                        '_entity' => 'list',
                                                        'analysisimplementation_id' => {
                                                                                         'name' => 'analysisimplementation_id',
                                                                                         'allownull' => 'no',
                                                                                         'type' => 'serial',
                                                                                         'foreign_references' => [
                                                                                                                   {
                                                                                                                     'table' => 'analysisimplementationparam',
                                                                                                                     'column' => 'analysisimplementation_id'
                                                                                                                   },
                                                                                                                   {
                                                                                                                     'table' => 'analysisinvocation',
                                                                                                                     'column' => 'analysisimplementation_id'
                                                                                                                   }
                                                                                                                 ],
                                                                                         '_entity' => 'column',
                                                                                         'primarykey' => 'yes'
                                                                                       }
                                                      }
                                        },
            'processinvocationparam' => {
                                          'name' => 'processinvocationparam',
                                          'comment' => 'ok drop table if exists processinvocationparam;',
                                          '_entity' => 'table',
                                          'primarykey' => 'processinvocationparam_id',
                                          'column' => {
                                                        'name' => {
                                                                    'name' => 'name',
                                                                    'allownull' => 'no',
                                                                    'type' => 'varchar(100)',
                                                                    '_entity' => 'column'
                                                                  },
                                                        '_order' => [
                                                                      'processinvocationparam_id',
                                                                      'processinvocation_id',
                                                                      'name',
                                                                      'value'
                                                                    ],
                                                        '_entity' => 'list',
                                                        'value' => {
                                                                     'name' => 'value',
                                                                     'allownull' => 'no',
                                                                     'type' => 'varchar(100)',
                                                                     '_entity' => 'column'
                                                                   },
                                                        'processinvocation_id' => {
                                                                                    'fk_table' => 'processinvocation',
                                                                                    'name' => 'processinvocation_id',
                                                                                    'allownull' => 'no',
                                                                                    'type' => 'int',
                                                                                    '_entity' => 'column',
                                                                                    'fk_column' => 'processinvocation_id'
                                                                                  },
                                                        'processinvocationparam_id' => {
                                                                                         'name' => 'processinvocationparam_id',
                                                                                         'allownull' => 'no',
                                                                                         'type' => 'serial',
                                                                                         '_entity' => 'column',
                                                                                         'primarykey' => 'yes'
                                                                                       }
                                                      }
                                        },
            'relatedacquisition' => {
                                      'name' => 'relatedacquisition',
                                      'comment' => 'ok drop table if exists relatedacquisition;',
                                      '_entity' => 'table',
                                      'primarykey' => 'relatedacquisition_id',
                                      'column' => {
                                                    'name' => {
                                                                'name' => 'name',
                                                                'allownull' => 'yes',
                                                                'type' => 'varchar(100)',
                                                                '_entity' => 'column'
                                                              },
                                                    '_order' => [
                                                                  'relatedacquisition_id',
                                                                  'acquisition_id',
                                                                  'associatedacquisition_id',
                                                                  'name',
                                                                  'designation',
                                                                  'associateddesignation'
                                                                ],
                                                    '_entity' => 'list',
                                                    'associateddesignation' => {
                                                                                 'name' => 'associateddesignation',
                                                                                 'allownull' => 'yes',
                                                                                 'type' => 'varchar(50)',
                                                                                 '_entity' => 'column'
                                                                               },
                                                    'designation' => {
                                                                       'name' => 'designation',
                                                                       'allownull' => 'yes',
                                                                       'type' => 'varchar(50)',
                                                                       '_entity' => 'column'
                                                                     },
                                                    'associatedacquisition_id' => {
                                                                                    'fk_table' => 'acquisition',
                                                                                    'name' => 'associatedacquisition_id',
                                                                                    'allownull' => 'no',
                                                                                    'type' => 'int',
                                                                                    '_entity' => 'column',
                                                                                    'fk_column' => 'acquisition_id'
                                                                                  },
                                                    'acquisition_id' => {
                                                                          'fk_table' => 'acquisition',
                                                                          'name' => 'acquisition_id',
                                                                          'allownull' => 'no',
                                                                          'type' => 'int',
                                                                          '_entity' => 'column',
                                                                          'fk_column' => 'acquisition_id'
                                                                        },
                                                    'relatedacquisition_id' => {
                                                                                 'name' => 'relatedacquisition_id',
                                                                                 'allownull' => 'no',
                                                                                 'type' => 'serial',
                                                                                 '_entity' => 'column',
                                                                                 'primarykey' => 'yes'
                                                                               }
                                                  }
                                    },
            'genotype' => {
                            'name' => 'genotype',
                            'comment' => 'This module depends on the sequence, pub, and cv modules  18-JAN-03 (DE): This module is unfinished and due for schema review (Bill  Gelbart will be leading the charge)',
                            '_entity' => 'table',
                            'primarykey' => 'genotype_id',
                            'column' => {
                                          '_order' => [
                                                        'genotype_id',
                                                        'description'
                                                      ],
                                          'description' => {
                                                             'name' => 'description',
                                                             'allownull' => 'yes',
                                                             'type' => 'varchar(255)',
                                                             '_entity' => 'column'
                                                           },
                                          '_entity' => 'list',
                                          'genotype_id' => {
                                                             'name' => 'genotype_id',
                                                             'allownull' => 'no',
                                                             'type' => 'serial',
                                                             'foreign_references' => [
                                                                                       {
                                                                                         'table' => 'phenotype',
                                                                                         'column' => 'background_genotype_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'wwwuser_genotype',
                                                                                         'column' => 'genotype_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'feature_genotype',
                                                                                         'column' => 'genotype_id'
                                                                                       },
                                                                                       {
                                                                                         'table' => 'interaction',
                                                                                         'column' => 'background_genotype_id'
                                                                                       }
                                                                                     ],
                                                             '_entity' => 'column',
                                                             'primarykey' => 'yes'
                                                           }
                                        }
                          },
            'analysisinvocationparam' => {
                                           'name' => 'analysisinvocationparam',
                                           'comment' => 'ok drop table if exists analysisinvocationparam;',
                                           '_entity' => 'table',
                                           'primarykey' => 'analysisinvocationparam_id',
                                           'column' => {
                                                         'name' => {
                                                                     'name' => 'name',
                                                                     'allownull' => 'no',
                                                                     'type' => 'varchar(100)',
                                                                     '_entity' => 'column'
                                                                   },
                                                         'analysisinvocation_id' => {
                                                                                      'fk_table' => 'analysisinvocation',
                                                                                      'name' => 'analysisinvocation_id',
                                                                                      'allownull' => 'no',
                                                                                      'type' => 'int',
                                                                                      '_entity' => 'column',
                                                                                      'fk_column' => 'analysisinvocation_id'
                                                                                    },
                                                         'analysisinvocationparam_id' => {
                                                                                           'name' => 'analysisinvocationparam_id',
                                                                                           'allownull' => 'no',
                                                                                           'type' => 'serial',
                                                                                           '_entity' => 'column',
                                                                                           'primarykey' => 'yes'
                                                                                         },
                                                         '_order' => [
                                                                       'analysisinvocationparam_id',
                                                                       'analysisinvocation_id',
                                                                       'name',
                                                                       'value'
                                                                     ],
                                                         '_entity' => 'list',
                                                         'value' => {
                                                                      'name' => 'value',
                                                                      'allownull' => 'no',
                                                                      'type' => 'varchar(100)',
                                                                      '_entity' => 'column'
                                                                    }
                                                       }
                                         },
            'biomaterialmeasurement' => {
                                          'name' => 'biomaterialmeasurement',
                                          'comment' => 'ok drop table if exists biomaterialmeasurement;',
                                          '_entity' => 'table',
                                          'primarykey' => 'biomaterialmeasurement_id',
                                          'column' => {
                                                        'treatment_id' => {
                                                                            'fk_table' => 'treatment',
                                                                            'name' => 'treatment_id',
                                                                            'allownull' => 'no',
                                                                            'type' => 'int',
                                                                            '_entity' => 'column',
                                                                            'fk_column' => 'treatment_id'
                                                                          },
                                                        'biomaterialmeasurement_id' => {
                                                                                         'name' => 'biomaterialmeasurement_id',
                                                                                         'allownull' => 'no',
                                                                                         'type' => 'serial',
                                                                                         '_entity' => 'column',
                                                                                         'primarykey' => 'yes'
                                                                                       },
                                                        '_order' => [
                                                                      'biomaterialmeasurement_id',
                                                                      'treatment_id',
                                                                      'biomaterial_id',
                                                                      'value',
                                                                      'unittype_id'
                                                                    ],
                                                        '_entity' => 'list',
                                                        'value' => {
                                                                     'name' => 'value',
                                                                     'allownull' => 'yes',
                                                                     'type' => 'float(15)',
                                                                     '_entity' => 'column'
                                                                   },
                                                        'biomaterial_id' => {
                                                                              'fk_table' => 'biomaterial',
                                                                              'name' => 'biomaterial_id',
                                                                              'allownull' => 'no',
                                                                              'type' => 'int',
                                                                              '_entity' => 'column',
                                                                              'fk_column' => 'biomaterial_id'
                                                                            },
                                                        'unittype_id' => {
                                                                           'fk_table' => 'cvterm',
                                                                           'name' => 'unittype_id',
                                                                           'allownull' => 'yes',
                                                                           'type' => 'int',
                                                                           '_entity' => 'column',
                                                                           'fk_column' => 'cvterm_id'
                                                                         }
                                                      }
                                        },
            'expression' => {
                              'name' => 'expression',
                              'comment' => 'This module is totally dependant on the sequence module.  Objects in the  genetic module cannot connect to expression data except by going via the  sequence module  We assume that we\'ll *always* have a controlled vocabulary for expression  data.   If an experiment used a set of cv terms different from the ones  FlyBase uses (bodypart cv, bodypart qualifier cv, and the temporal cv  (which is stored in the curaton.doc under GAT6 btw)), they\'d have to give  us the cv terms, which we could load into the cv module',
                              '_entity' => 'table',
                              'primarykey' => 'expression_id',
                              'column' => {
                                            '_order' => [
                                                          'expression_id',
                                                          'description'
                                                        ],
                                            'description' => {
                                                               'name' => 'description',
                                                               'allownull' => 'yes',
                                                               'type' => 'text',
                                                               '_entity' => 'column'
                                                             },
                                            'expression_id' => {
                                                                 'name' => 'expression_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'serial',
                                                                 'foreign_references' => [
                                                                                           {
                                                                                             'table' => 'expression_image',
                                                                                             'column' => 'expression_id'
                                                                                           },
                                                                                           {
                                                                                             'table' => 'expression_pub',
                                                                                             'column' => 'expression_id'
                                                                                           },
                                                                                           {
                                                                                             'table' => 'expression_cvterm',
                                                                                             'column' => 'expression_id'
                                                                                           },
                                                                                           {
                                                                                             'table' => 'wwwuser_expression',
                                                                                             'column' => 'expression_id'
                                                                                           },
                                                                                           {
                                                                                             'table' => 'feature_expression',
                                                                                             'column' => 'expression_id'
                                                                                           }
                                                                                         ],
                                                                 '_entity' => 'column',
                                                                 'primarykey' => 'yes'
                                                               },
                                            '_entity' => 'list'
                                          }
                            },
            'quantificationparam' => {
                                       'name' => 'quantificationparam',
                                       'comment' => 'ok drop table if exists quantificationparam;',
                                       '_entity' => 'table',
                                       'primarykey' => 'quantificationparam_id',
                                       'column' => {
                                                     'name' => {
                                                                 'name' => 'name',
                                                                 'allownull' => 'no',
                                                                 'type' => 'varchar(100)',
                                                                 '_entity' => 'column'
                                                               },
                                                     'quantification_id' => {
                                                                              'fk_table' => 'quantification',
                                                                              'name' => 'quantification_id',
                                                                              'allownull' => 'no',
                                                                              'type' => 'int',
                                                                              '_entity' => 'column',
                                                                              'fk_column' => 'quantification_id'
                                                                            },
                                                     '_order' => [
                                                                   'quantificationparam_id',
                                                                   'quantification_id',
                                                                   'name',
                                                                   'value'
                                                                 ],
                                                     'quantificationparam_id' => {
                                                                                   'name' => 'quantificationparam_id',
                                                                                   'allownull' => 'no',
                                                                                   'type' => 'serial',
                                                                                   '_entity' => 'column',
                                                                                   'primarykey' => 'yes'
                                                                                 },
                                                     '_entity' => 'list',
                                                     'value' => {
                                                                  'name' => 'value',
                                                                  'allownull' => 'no',
                                                                  'type' => 'varchar(50)',
                                                                  '_entity' => 'column'
                                                                }
                                                   }
                                     },
            'magedocumentation' => {
                                     'name' => 'magedocumentation',
                                     'comment' => 'ok drop table if exists magedocumentation;',
                                     '_entity' => 'table',
                                     'primarykey' => 'magedocumentation_id',
                                     'column' => {
                                                   'tableinfo_id' => {
                                                                       'fk_table' => 'tableinfo',
                                                                       'name' => 'tableinfo_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'int',
                                                                       '_entity' => 'column',
                                                                       'fk_column' => 'tableinfo_id'
                                                                     },
                                                   'magedocumentation_id' => {
                                                                               'name' => 'magedocumentation_id',
                                                                               'allownull' => 'no',
                                                                               'type' => 'serial',
                                                                               '_entity' => 'column',
                                                                               'primarykey' => 'yes'
                                                                             },
                                                   '_order' => [
                                                                 'magedocumentation_id',
                                                                 'mageml_id',
                                                                 'tableinfo_id',
                                                                 'row_id',
                                                                 'mageidentifier'
                                                               ],
                                                   'row_id' => {
                                                                 'name' => 'row_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column'
                                                               },
                                                   '_entity' => 'list',
                                                   'mageidentifier' => {
                                                                         'name' => 'mageidentifier',
                                                                         'allownull' => 'no',
                                                                         'type' => 'varchar(100)',
                                                                         '_entity' => 'column'
                                                                       },
                                                   'mageml_id' => {
                                                                    'fk_table' => 'mageml',
                                                                    'name' => 'mageml_id',
                                                                    'allownull' => 'no',
                                                                    'type' => 'int',
                                                                    '_entity' => 'column',
                                                                    'fk_column' => 'mageml_id'
                                                                  }
                                                 }
                                   },
            'treatment' => {
                             'name' => 'treatment',
                             'comment' => 'ok drop table if exists treatment;',
                             '_entity' => 'table',
                             'primarykey' => 'treatment_id',
                             'column' => {
                                           'treatment_id' => {
                                                               'name' => 'treatment_id',
                                                               'allownull' => 'no',
                                                               'type' => 'serial',
                                                               'foreign_references' => [
                                                                                         {
                                                                                           'table' => 'biomaterialmeasurement',
                                                                                           'column' => 'treatment_id'
                                                                                         }
                                                                                       ],
                                                               '_entity' => 'column',
                                                               'primarykey' => 'yes'
                                                             },
                                           'name' => {
                                                       'name' => 'name',
                                                       'allownull' => 'yes',
                                                       'type' => 'varchar(100)',
                                                       '_entity' => 'column'
                                                     },
                                           'treatmenttype_id' => {
                                                                   'fk_table' => 'cvterm',
                                                                   'name' => 'treatmenttype_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'cvterm_id'
                                                                 },
                                           'biomaterial_id' => {
                                                                 'fk_table' => 'biomaterial',
                                                                 'name' => 'biomaterial_id',
                                                                 'allownull' => 'no',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'biomaterial_id'
                                                               },
                                           '_order' => [
                                                         'treatment_id',
                                                         'ordernum',
                                                         'biomaterial_id',
                                                         'treatmenttype_id',
                                                         'protocol_id',
                                                         'name'
                                                       ],
                                           '_entity' => 'list',
                                           'ordernum' => {
                                                           'name' => 'ordernum',
                                                           'allownull' => 'no',
                                                           'type' => 'int',
                                                           '_entity' => 'column'
                                                         },
                                           'protocol_id' => {
                                                              'fk_table' => 'protocol',
                                                              'name' => 'protocol_id',
                                                              'allownull' => 'yes',
                                                              'type' => 'int',
                                                              '_entity' => 'column',
                                                              'fk_column' => 'protocol_id'
                                                            }
                                         }
                           },
            'analysisoutput' => {
                                  'name' => 'analysisoutput',
                                  'comment' => 'ok drop table if exists analysisoutput;',
                                  '_entity' => 'table',
                                  'primarykey' => 'analysisoutput_id',
                                  'column' => {
                                                'name' => {
                                                            'name' => 'name',
                                                            'allownull' => 'no',
                                                            'type' => 'varchar(100)',
                                                            '_entity' => 'column'
                                                          },
                                                'analysisoutput_id' => {
                                                                         'name' => 'analysisoutput_id',
                                                                         'allownull' => 'no',
                                                                         'type' => 'serial',
                                                                         '_entity' => 'column',
                                                                         'primarykey' => 'yes'
                                                                       },
                                                'type' => {
                                                            'name' => 'type',
                                                            'allownull' => 'no',
                                                            'type' => 'varchar(50)',
                                                            '_entity' => 'column'
                                                          },
                                                'analysisinvocation_id' => {
                                                                             'fk_table' => 'analysisinvocation',
                                                                             'name' => 'analysisinvocation_id',
                                                                             'allownull' => 'no',
                                                                             'type' => 'int',
                                                                             '_entity' => 'column',
                                                                             'fk_column' => 'analysisinvocation_id'
                                                                           },
                                                '_order' => [
                                                              'analysisoutput_id',
                                                              'analysisinvocation_id',
                                                              'name',
                                                              'type',
                                                              'value'
                                                            ],
                                                '_entity' => 'list',
                                                'value' => {
                                                             'name' => 'value',
                                                             'allownull' => 'no',
                                                             'type' => 'int',
                                                             '_entity' => 'column'
                                                           }
                                              }
                                },
            'featurerange' => {
                                'indexes' => {
                                               'featurerange_idx3' => {
                                                                        'columns' => 'leftstartf_id',
                                                                        'name' => 'featurerange_idx3',
                                                                        '_entity' => 'index'
                                                                      },
                                               'featurerange_idx4' => {
                                                                        'columns' => 'leftendf_id',
                                                                        'name' => 'featurerange_idx4',
                                                                        '_entity' => 'index'
                                                                      },
                                               'featurerange_idx5' => {
                                                                        'columns' => 'rightstartf_id',
                                                                        'name' => 'featurerange_idx5',
                                                                        '_entity' => 'index'
                                                                      },
                                               'featurerange_idx6' => {
                                                                        'columns' => 'rightendf_id',
                                                                        'name' => 'featurerange_idx6',
                                                                        '_entity' => 'index'
                                                                      },
                                               '_entity' => 'set',
                                               'featurerange_idx1' => {
                                                                        'columns' => 'featuremap_id',
                                                                        'name' => 'featurerange_idx1',
                                                                        '_entity' => 'index'
                                                                      },
                                               'featurerange_idx2' => {
                                                                        'columns' => 'feature_id',
                                                                        'name' => 'featurerange_idx2',
                                                                        '_entity' => 'index'
                                                                      }
                                             },
                                'name' => 'featurerange',
                                'comment' => 'In cases where the start and end of a mapped feature is a range, leftendf  and rightstartf are populated.  featuremap_id is the id of the feature being mapped  leftstartf_id, leftendf_id, rightstartf_id, rightendf_id are the ids of  features with respect to with the feature is being mapped.  These may  be cytological bands.',
                                '_entity' => 'table',
                                'primarykey' => 'featurerange_id',
                                'column' => {
                                              'leftendf_id' => {
                                                                 'fk_table' => 'feature',
                                                                 'name' => 'leftendf_id',
                                                                 'allownull' => 'yes',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column',
                                                                 'fk_column' => 'feature_id'
                                                               },
                                              'featurerange_id' => {
                                                                     'name' => 'featurerange_id',
                                                                     'allownull' => 'no',
                                                                     'type' => 'serial',
                                                                     '_entity' => 'column',
                                                                     'primarykey' => 'yes'
                                                                   },
                                              'rangestr' => {
                                                              'name' => 'rangestr',
                                                              'allownull' => 'yes',
                                                              'type' => 'varchar(255)',
                                                              '_entity' => 'column'
                                                            },
                                              'featuremap_id' => {
                                                                   'fk_table' => 'featuremap',
                                                                   'name' => 'featuremap_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'featuremap_id'
                                                                 },
                                              'rightendf_id' => {
                                                                  'fk_table' => 'feature',
                                                                  'name' => 'rightendf_id',
                                                                  'allownull' => 'no',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'feature_id'
                                                                },
                                              'feature_id' => {
                                                                'fk_table' => 'feature',
                                                                'name' => 'feature_id',
                                                                'allownull' => 'no',
                                                                'type' => 'int',
                                                                '_entity' => 'column',
                                                                'fk_column' => 'feature_id'
                                                              },
                                              '_order' => [
                                                            'featurerange_id',
                                                            'featuremap_id',
                                                            'feature_id',
                                                            'leftstartf_id',
                                                            'leftendf_id',
                                                            'rightstartf_id',
                                                            'rightendf_id',
                                                            'rangestr'
                                                          ],
                                              'leftstartf_id' => {
                                                                   'fk_table' => 'feature',
                                                                   'name' => 'leftstartf_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'feature_id'
                                                                 },
                                              '_entity' => 'list',
                                              'rightstartf_id' => {
                                                                    'fk_table' => 'feature',
                                                                    'name' => 'rightstartf_id',
                                                                    'allownull' => 'yes',
                                                                    'type' => 'int',
                                                                    '_entity' => 'column',
                                                                    'fk_column' => 'feature_id'
                                                                  }
                                            }
                              },
            'biomaterial_cvterm' => {
                                      'name' => 'biomaterial_cvterm',
                                      'comment' => 'ok renamed biomaterialcharacteristic to biomaterial_cvterm drop table if exists biomaterial_cvterm;',
                                      '_entity' => 'table',
                                      'primarykey' => 'biomaterial_cvterm_id',
                                      'column' => {
                                                    '_order' => [
                                                                  'biomaterial_cvterm_id',
                                                                  'biomaterial_id',
                                                                  'cvterm_id',
                                                                  'value'
                                                                ],
                                                    '_entity' => 'list',
                                                    'value' => {
                                                                 'name' => 'value',
                                                                 'allownull' => 'yes',
                                                                 'type' => 'varchar(100)',
                                                                 '_entity' => 'column'
                                                               },
                                                    'cvterm_id' => {
                                                                     'fk_table' => 'cvterm',
                                                                     'name' => 'cvterm_id',
                                                                     'allownull' => 'no',
                                                                     'type' => 'int',
                                                                     '_entity' => 'column',
                                                                     'fk_column' => 'cvterm_id'
                                                                   },
                                                    'biomaterial_id' => {
                                                                          'fk_table' => 'biomaterial',
                                                                          'name' => 'biomaterial_id',
                                                                          'allownull' => 'no',
                                                                          'type' => 'int',
                                                                          '_entity' => 'column',
                                                                          'fk_column' => 'biomaterial_id'
                                                                        },
                                                    'biomaterial_cvterm_id' => {
                                                                                 'name' => 'biomaterial_cvterm_id',
                                                                                 'allownull' => 'no',
                                                                                 'type' => 'serial',
                                                                                 '_entity' => 'column',
                                                                                 'primarykey' => 'yes'
                                                                               }
                                                  }
                                    },
            'feature_relationship' => {
                                        'indexes' => {
                                                       'feature_relationship_idx1' => {
                                                                                        'columns' => 'subjfeature_id',
                                                                                        'name' => 'feature_relationship_idx1',
                                                                                        '_entity' => 'index'
                                                                                      },
                                                       'feature_relationship_idx2' => {
                                                                                        'columns' => 'objfeature_id',
                                                                                        'name' => 'feature_relationship_idx2',
                                                                                        '_entity' => 'index'
                                                                                      },
                                                       'feature_relationship_idx3' => {
                                                                                        'columns' => 'type_id',
                                                                                        'name' => 'feature_relationship_idx3',
                                                                                        '_entity' => 'index'
                                                                                      },
                                                       '_entity' => 'set'
                                                     },
                                        'name' => 'feature_relationship',
                                        'comment' => 'features can be arranged in graphs, eg exon partof transcript  partof gene; translation madeby transcript  if type is thought of as a verb, each arc makes a statement  [SUBJECT VERB OBJECT]  object can also be thought of as parent, and subject as child   we include the relationship rank/order, because even though  most of the time we can order things implicitly by sequence  coordinates, we can\'t always do this - eg transpliced genes.  it\'s also useful for quickly getting implicit introns',
                                        '_entity' => 'table',
                                        'primarykey' => 'feature_relationship_id',
                                        'column' => {
                                                      'feature_relationship_id' => {
                                                                                     'name' => 'feature_relationship_id',
                                                                                     'allownull' => 'no',
                                                                                     'type' => 'serial',
                                                                                     '_entity' => 'column',
                                                                                     'primarykey' => 'yes'
                                                                                   },
                                                      'objfeature_id' => {
                                                                           'fk_table' => 'feature',
                                                                           'name' => 'objfeature_id',
                                                                           'allownull' => 'no',
                                                                           'type' => 'int',
                                                                           '_entity' => 'column',
                                                                           'fk_column' => 'feature_id',
                                                                           'unique' => 3
                                                                         },
                                                      '_order' => [
                                                                    'feature_relationship_id',
                                                                    'subjfeature_id',
                                                                    'objfeature_id',
                                                                    'type_id',
                                                                    'relrank'
                                                                  ],
                                                      'subjfeature_id' => {
                                                                            'fk_table' => 'feature',
                                                                            'name' => 'subjfeature_id',
                                                                            'allownull' => 'no',
                                                                            'type' => 'int',
                                                                            '_entity' => 'column',
                                                                            'fk_column' => 'feature_id',
                                                                            'unique' => 3
                                                                          },
                                                      '_entity' => 'list',
                                                      'type_id' => {
                                                                     'fk_table' => 'cvterm',
                                                                     'name' => 'type_id',
                                                                     'allownull' => 'no',
                                                                     'type' => 'int',
                                                                     '_entity' => 'column',
                                                                     'fk_column' => 'cvterm_id',
                                                                     'unique' => 3
                                                                   },
                                                      'relrank' => {
                                                                     'name' => 'relrank',
                                                                     'allownull' => 'yes',
                                                                     'type' => 'int',
                                                                     '_entity' => 'column'
                                                                   }
                                                    },
                                        'unique' => [
                                                      'subjfeature_id',
                                                      'objfeature_id',
                                                      'type_id'
                                                    ]
                                      },
            'wwwuser_phenotype' => {
                                     'indexes' => {
                                                    '_entity' => 'set',
                                                    'wwwuser_phenotype_idx1' => {
                                                                                  'columns' => 'wwwuser_id',
                                                                                  'name' => 'wwwuser_phenotype_idx1',
                                                                                  '_entity' => 'index'
                                                                                },
                                                    'wwwuser_phenotype_idx2' => {
                                                                                  'columns' => 'phenotype_id',
                                                                                  'name' => 'wwwuser_phenotype_idx2',
                                                                                  '_entity' => 'index'
                                                                                }
                                                  },
                                     'name' => 'wwwuser_phenotype',
                                     'comment' => 'track wwwuser interest in phenotypes',
                                     '_entity' => 'table',
                                     'primarykey' => 'wwwuser_phenotype_id',
                                     'column' => {
                                                   'phenotype_id' => {
                                                                       'fk_table' => 'phenotype',
                                                                       'name' => 'phenotype_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'int',
                                                                       '_entity' => 'column',
                                                                       'fk_column' => 'phenotype_id',
                                                                       'unique' => 2
                                                                     },
                                                   'wwwuser_id' => {
                                                                     'fk_table' => 'wwwuser',
                                                                     'name' => 'wwwuser_id',
                                                                     'allownull' => 'no',
                                                                     'type' => 'int',
                                                                     '_entity' => 'column',
                                                                     'fk_column' => 'wwwuser_id',
                                                                     'unique' => 2
                                                                   },
                                                   'world_read' => {
                                                                     'name' => 'world_read',
                                                                     'allownull' => 'no',
                                                                     'type' => 'smallint',
                                                                     '_entity' => 'column',
                                                                     'default' => 1
                                                                   },
                                                   'wwwuser_phenotype_id' => {
                                                                               'name' => 'wwwuser_phenotype_id',
                                                                               'allownull' => 'no',
                                                                               'type' => 'serial',
                                                                               '_entity' => 'column',
                                                                               'primarykey' => 'yes'
                                                                             },
                                                   '_order' => [
                                                                 'wwwuser_phenotype_id',
                                                                 'wwwuser_id',
                                                                 'phenotype_id',
                                                                 'world_read'
                                                               ],
                                                   '_entity' => 'list'
                                                 },
                                     'unique' => [
                                                   'wwwuser_id',
                                                   'phenotype_id'
                                                 ]
                                   },
            'quantification' => {
                                  'name' => 'quantification',
                                  'comment' => 'ok drop table if exists quantification;',
                                  '_entity' => 'table',
                                  'primarykey' => 'quantification_id',
                                  'column' => {
                                                'uri' => {
                                                           'name' => 'uri',
                                                           'allownull' => 'yes',
                                                           'type' => 'varchar(500)',
                                                           '_entity' => 'column'
                                                         },
                                                'name' => {
                                                            'name' => 'name',
                                                            'allownull' => 'yes',
                                                            'type' => 'varchar(100)',
                                                            '_entity' => 'column'
                                                          },
                                                'resulttable_id' => {
                                                                      'fk_table' => 'tableinfo',
                                                                      'name' => 'resulttable_id',
                                                                      'allownull' => 'yes',
                                                                      'type' => 'int',
                                                                      '_entity' => 'column',
                                                                      'fk_column' => 'tableinfo_id'
                                                                    },
                                                'acquisition_id' => {
                                                                      'fk_table' => 'acquisition',
                                                                      'name' => 'acquisition_id',
                                                                      'allownull' => 'no',
                                                                      'type' => 'int',
                                                                      '_entity' => 'column',
                                                                      'fk_column' => 'acquisition_id'
                                                                    },
                                                'operator_id' => {
                                                                   'fk_table' => 'author',
                                                                   'name' => 'operator_id',
                                                                   'allownull' => 'yes',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'author_id'
                                                                 },
                                                '_order' => [
                                                              'quantification_id',
                                                              'acquisition_id',
                                                              'operator_id',
                                                              'protocol_id',
                                                              'resulttable_id',
                                                              'quantificationdate',
                                                              'name',
                                                              'uri'
                                                            ],
                                                'quantification_id' => {
                                                                         'name' => 'quantification_id',
                                                                         'allownull' => 'no',
                                                                         'type' => 'serial',
                                                                         'foreign_references' => [
                                                                                                   {
                                                                                                     'table' => 'relatedquantification',
                                                                                                     'column' => 'associatedquantification_id'
                                                                                                   },
                                                                                                   {
                                                                                                     'table' => 'relatedquantification',
                                                                                                     'column' => 'quantification_id'
                                                                                                   },
                                                                                                   {
                                                                                                     'table' => 'compositeelementresult',
                                                                                                     'column' => 'quantification_id'
                                                                                                   },
                                                                                                   {
                                                                                                     'table' => 'elementresult',
                                                                                                     'column' => 'quantification_id'
                                                                                                   },
                                                                                                   {
                                                                                                     'table' => 'quantificationparam',
                                                                                                     'column' => 'quantification_id'
                                                                                                   },
                                                                                                   {
                                                                                                     'table' => 'processinvocation_quantification',
                                                                                                     'column' => 'quantification_id'
                                                                                                   }
                                                                                                 ],
                                                                         '_entity' => 'column',
                                                                         'primarykey' => 'yes'
                                                                       },
                                                '_entity' => 'list',
                                                'quantificationdate' => {
                                                                          'name' => 'quantificationdate',
                                                                          'allownull' => 'yes',
                                                                          'type' => 'date',
                                                                          '_entity' => 'column'
                                                                        },
                                                'protocol_id' => {
                                                                   'fk_table' => 'protocol',
                                                                   'name' => 'protocol_id',
                                                                   'allownull' => 'yes',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'protocol_id'
                                                                 }
                                              }
                                },
            'expression_cvterm' => {
                                     'indexes' => {
                                                    '_entity' => 'set',
                                                    'expression_cvterm_idx1' => {
                                                                                  'columns' => 'expression_id',
                                                                                  'name' => 'expression_cvterm_idx1',
                                                                                  '_entity' => 'index'
                                                                                },
                                                    'expression_cvterm_idx2' => {
                                                                                  'columns' => 'cvterm_id',
                                                                                  'name' => 'expression_cvterm_idx2',
                                                                                  '_entity' => 'index'
                                                                                }
                                                  },
                                     'name' => 'expression_cvterm',
                                     'comment' => 'What are the possibities of combination when more than one cvterm is used  in a field?   For eg (in <p> here):   <t> E | early <a> <p> anterior & dorsal  If the two terms used in a particular field are co-equal (both from the  same CV, is the relation always "&"?   May we find "or"?   Obviously another case is when a bodypart term and a bodypart qualifier  term are used in a specific field, eg:    <t> L | third instar <a> larval antennal segment sensilla | subset <p   WRT the three-part <t><a><p> statements, are the values in the different  parts *always* from different vocabularies in proforma.CV?   If not,  we\'ll need to have some kind of type qualifier telling us whether the  cvterm used is <t>, <a>, or <p>',
                                     '_entity' => 'table',
                                     'primarykey' => 'expression_cvterm_id',
                                     'column' => {
                                                   '_order' => [
                                                                 'expression_cvterm_id',
                                                                 'expression_id',
                                                                 'cvterm_id',
                                                                 'rank'
                                                               ],
                                                   'rank' => {
                                                               'name' => 'rank',
                                                               'allownull' => 'no',
                                                               'type' => 'int',
                                                               '_entity' => 'column'
                                                             },
                                                   'expression_id' => {
                                                                        'fk_table' => 'expression',
                                                                        'name' => 'expression_id',
                                                                        'allownull' => 'no',
                                                                        'type' => 'int',
                                                                        '_entity' => 'column',
                                                                        'fk_column' => 'expression_id',
                                                                        'unique' => 2
                                                                      },
                                                   'expression_cvterm_id' => {
                                                                               'name' => 'expression_cvterm_id',
                                                                               'allownull' => 'no',
                                                                               'type' => 'serial',
                                                                               '_entity' => 'column',
                                                                               'primarykey' => 'yes'
                                                                             },
                                                   '_entity' => 'list',
                                                   'cvterm_id' => {
                                                                    'fk_table' => 'cvterm',
                                                                    'name' => 'cvterm_id',
                                                                    'allownull' => 'no',
                                                                    'type' => 'int',
                                                                    '_entity' => 'column',
                                                                    'fk_column' => 'cvterm_id',
                                                                    'unique' => 2
                                                                  }
                                                 },
                                     'unique' => [
                                                   'expression_id',
                                                   'cvterm_id'
                                                 ]
                                   },
            'protocolparam' => {
                                 'name' => 'protocolparam',
                                 'comment' => 'ok drop table if exists protocolparam;',
                                 '_entity' => 'table',
                                 'primarykey' => 'protocolparam_id',
                                 'column' => {
                                               'name' => {
                                                           'name' => 'name',
                                                           'allownull' => 'no',
                                                           'type' => 'varchar(100)',
                                                           '_entity' => 'column'
                                                         },
                                               'datatype_id' => {
                                                                  'fk_table' => 'cvterm',
                                                                  'name' => 'datatype_id',
                                                                  'allownull' => 'yes',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'cvterm_id'
                                                                },
                                               '_order' => [
                                                             'protocolparam_id',
                                                             'protocol_id',
                                                             'name',
                                                             'datatype_id',
                                                             'unittype_id',
                                                             'value'
                                                           ],
                                               '_entity' => 'list',
                                               'value' => {
                                                            'name' => 'value',
                                                            'allownull' => 'yes',
                                                            'type' => 'varchar(100)',
                                                            '_entity' => 'column'
                                                          },
                                               'protocol_id' => {
                                                                  'fk_table' => 'protocol',
                                                                  'name' => 'protocol_id',
                                                                  'allownull' => 'no',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'protocol_id'
                                                                },
                                               'unittype_id' => {
                                                                  'fk_table' => 'cvterm',
                                                                  'name' => 'unittype_id',
                                                                  'allownull' => 'yes',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'cvterm_id'
                                                                },
                                               'protocolparam_id' => {
                                                                       'name' => 'protocolparam_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'serial',
                                                                       '_entity' => 'column',
                                                                       'primarykey' => 'yes'
                                                                     }
                                             }
                               },
            'processimplementation' => {
                                         'name' => 'processimplementation',
                                         'comment' => 'ok drop table if exists processimplementation;',
                                         '_entity' => 'table',
                                         'primarykey' => 'processimplementation_id',
                                         'column' => {
                                                       'name' => {
                                                                   'name' => 'name',
                                                                   'allownull' => 'yes',
                                                                   'type' => 'varchar(100)',
                                                                   '_entity' => 'column'
                                                                 },
                                                       'processimplementation_id' => {
                                                                                       'name' => 'processimplementation_id',
                                                                                       'allownull' => 'no',
                                                                                       'type' => 'serial',
                                                                                       'foreign_references' => [
                                                                                                                 {
                                                                                                                   'table' => 'processimplementationparam',
                                                                                                                   'column' => 'processimplementation_id'
                                                                                                                 },
                                                                                                                 {
                                                                                                                   'table' => 'processinvocation',
                                                                                                                   'column' => 'processimplementation_id'
                                                                                                                 }
                                                                                                               ],
                                                                                       '_entity' => 'column',
                                                                                       'primarykey' => 'yes'
                                                                                     },
                                                       '_order' => [
                                                                     'processimplementation_id',
                                                                     'processtype_id',
                                                                     'name'
                                                                   ],
                                                       '_entity' => 'list',
                                                       'processtype_id' => {
                                                                             'fk_table' => 'cvterm',
                                                                             'name' => 'processtype_id',
                                                                             'allownull' => 'no',
                                                                             'type' => 'int',
                                                                             '_entity' => 'column',
                                                                             'fk_column' => 'cvterm_id'
                                                                           }
                                                     }
                                       },
            'pub' => {
                       'indexes' => {
                                      '_entity' => 'set',
                                      'pub_idx1' => {
                                                      'columns' => 'type_id',
                                                      'name' => 'pub_idx1',
                                                      '_entity' => 'index'
                                                    }
                                    },
                       'name' => 'pub',
                       'comment' => 'We should take a look in OMG for a standard representation we might use  instead of this.',
                       '_entity' => 'table',
                       'primarykey' => 'pub_id',
                       'column' => {
                                     'pages' => {
                                                  'name' => 'pages',
                                                  'allownull' => 'yes',
                                                  'type' => 'varchar(255)',
                                                  '_entity' => 'column'
                                                },
                                     'pyear' => {
                                                  'name' => 'pyear',
                                                  'allownull' => 'yes',
                                                  'type' => 'varchar(255)',
                                                  '_entity' => 'column'
                                                },
                                     'title' => {
                                                  'name' => 'title',
                                                  'allownull' => 'yes',
                                                  'type' => 'text',
                                                  '_entity' => 'column'
                                                },
                                     'pub_id' => {
                                                   'name' => 'pub_id',
                                                   'allownull' => 'no',
                                                   'type' => 'serial',
                                                   'foreign_references' => [
                                                                             {
                                                                               'table' => 'pubprop',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'featuremap_pub',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'protocol',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'featureprop_pub',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'pub_relationship',
                                                                               'column' => 'obj_pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'pub_relationship',
                                                                               'column' => 'subj_pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'feature_cvterm',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'phenotype',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'synonym_pub',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'expression_pub',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'pub_author',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'interaction',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'pub_dbxref',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'feature_synonym',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'wwwuser_pub',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'feature_pub',
                                                                               'column' => 'pub_id'
                                                                             },
                                                                             {
                                                                               'table' => 'study',
                                                                               'column' => 'pub_id'
                                                                             }
                                                                           ],
                                                   '_entity' => 'column',
                                                   'primarykey' => 'yes'
                                                 },
                                     'is_obsolete' => {
                                                        'name' => 'is_obsolete',
                                                        'allownull' => 'yes',
                                                        'type' => 'boolean',
                                                        '_entity' => 'column',
                                                        'default' => '\'false\''
                                                      },
                                     'volume' => {
                                                   'name' => 'volume',
                                                   'allownull' => 'yes',
                                                   'type' => 'varchar(255)',
                                                   '_entity' => 'column'
                                                 },
                                     'issue' => {
                                                  'name' => 'issue',
                                                  'allownull' => 'yes',
                                                  'type' => 'varchar(255)',
                                                  '_entity' => 'column'
                                                },
                                     'miniref' => {
                                                    'name' => 'miniref',
                                                    'allownull' => 'no',
                                                    'type' => 'varchar(255)',
                                                    '_entity' => 'column',
                                                    'unique' => 1
                                                  },
                                     'volumetitle' => {
                                                        'name' => 'volumetitle',
                                                        'allownull' => 'yes',
                                                        'type' => 'text',
                                                        '_entity' => 'column'
                                                      },
                                     '_order' => [
                                                   'pub_id',
                                                   'title',
                                                   'volumetitle',
                                                   'volume',
                                                   'series_name',
                                                   'issue',
                                                   'pyear',
                                                   'pages',
                                                   'miniref',
                                                   'type_id',
                                                   'is_obsolete',
                                                   'publisher',
                                                   'pubplace'
                                                 ],
                                     'series_name' => {
                                                        'name' => 'series_name',
                                                        'allownull' => 'yes',
                                                        'type' => 'varchar(255)',
                                                        '_entity' => 'column'
                                                      },
                                     'pubplace' => {
                                                     'name' => 'pubplace',
                                                     'allownull' => 'yes',
                                                     'type' => 'varchar(255)',
                                                     '_entity' => 'column'
                                                   },
                                     '_entity' => 'list',
                                     'publisher' => {
                                                      'name' => 'publisher',
                                                      'allownull' => 'yes',
                                                      'type' => 'varchar(255)',
                                                      '_entity' => 'column'
                                                    },
                                     'type_id' => {
                                                    'fk_table' => 'cvterm',
                                                    'name' => 'type_id',
                                                    'allownull' => 'no',
                                                    'type' => 'int',
                                                    '_entity' => 'column',
                                                    'fk_column' => 'cvterm_id'
                                                  }
                                   },
                       'unique' => [
                                     'miniref'
                                   ]
                     },
            'feature_phenotype' => {
                                     'indexes' => {
                                                    '_entity' => 'set',
                                                    'feature_phenotype_idx1' => {
                                                                                  'columns' => 'feature_id',
                                                                                  'name' => 'feature_phenotype_idx1',
                                                                                  '_entity' => 'index'
                                                                                },
                                                    'feature_phenotype_idx2' => {
                                                                                  'columns' => 'phenotype_id',
                                                                                  'name' => 'feature_phenotype_idx2',
                                                                                  '_entity' => 'index'
                                                                                }
                                                  },
                                     'name' => 'feature_phenotype',
                                     'comment' => 'type of phenotypic statement  [Chris, we need this or something like it  for FB where we have three types of statement in *k: "Phenotypic class:",  "Phenotype manifest in:", and free-text]  Do we want to call this simply genotype_id to allow natural joins?',
                                     '_entity' => 'table',
                                     'primarykey' => 'feature_phenotype_id',
                                     'column' => {
                                                   'phenotype_id' => {
                                                                       'fk_table' => 'phenotype',
                                                                       'name' => 'phenotype_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'int',
                                                                       '_entity' => 'column',
                                                                       'fk_column' => 'phenotype_id',
                                                                       'unique' => 2
                                                                     },
                                                   'feature_id' => {
                                                                     'fk_table' => 'feature',
                                                                     'name' => 'feature_id',
                                                                     'allownull' => 'no',
                                                                     'type' => 'int',
                                                                     '_entity' => 'column',
                                                                     'fk_column' => 'feature_id',
                                                                     'unique' => 2
                                                                   },
                                                   'feature_phenotype_id' => {
                                                                               'name' => 'feature_phenotype_id',
                                                                               'allownull' => 'no',
                                                                               'type' => 'serial',
                                                                               '_entity' => 'column',
                                                                               'primarykey' => 'yes'
                                                                             },
                                                   '_order' => [
                                                                 'feature_phenotype_id',
                                                                 'feature_id',
                                                                 'phenotype_id'
                                                               ],
                                                   '_entity' => 'list'
                                                 },
                                     'unique' => [
                                                   'feature_id',
                                                   'phenotype_id'
                                                 ]
                                   },
            'biomaterial' => {
                               'name' => 'biomaterial',
                               'comment' => 'ok renamed from biomaterialimp drop table if exists biomaterial;',
                               '_entity' => 'table',
                               'primarykey' => 'biomaterial_id',
                               'column' => {
                                             'biosourceprovider_id' => {
                                                                         'fk_table' => 'author',
                                                                         'name' => 'biosourceprovider_id',
                                                                         'allownull' => 'yes',
                                                                         'type' => 'int',
                                                                         '_entity' => 'column',
                                                                         'fk_column' => 'author_id'
                                                                       },
                                             'biomaterial_id' => {
                                                                   'name' => 'biomaterial_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'serial',
                                                                   'foreign_references' => [
                                                                                             {
                                                                                               'table' => 'assay_labeledextract',
                                                                                               'column' => 'labeledextract_id'
                                                                                             },
                                                                                             {
                                                                                               'table' => 'assay_biomaterial',
                                                                                               'column' => 'biomaterial_id'
                                                                                             },
                                                                                             {
                                                                                               'table' => 'biomaterialmeasurement',
                                                                                               'column' => 'biomaterial_id'
                                                                                             },
                                                                                             {
                                                                                               'table' => 'treatment',
                                                                                               'column' => 'biomaterial_id'
                                                                                             },
                                                                                             {
                                                                                               'table' => 'biomaterial_cvterm',
                                                                                               'column' => 'biomaterial_id'
                                                                                             }
                                                                                           ],
                                                                   '_entity' => 'column',
                                                                   'primarykey' => 'yes'
                                                                 },
                                             'taxon_id' => {
                                                             'fk_table' => 'organism',
                                                             'name' => 'taxon_id',
                                                             'allownull' => 'yes',
                                                             'type' => 'int',
                                                             '_entity' => 'column',
                                                             'fk_column' => 'organism_id'
                                                           },
                                             'dbxref_id' => {
                                                              'fk_table' => 'dbxref',
                                                              'name' => 'dbxref_id',
                                                              'allownull' => 'yes',
                                                              'type' => 'varchar(50)',
                                                              '_entity' => 'column',
                                                              'fk_column' => 'dbxref_id'
                                                            },
                                             'string1' => {
                                                            'name' => 'string1',
                                                            'allownull' => 'yes',
                                                            'type' => 'varchar(100)',
                                                            '_entity' => 'column'
                                                          },
                                             'string2' => {
                                                            'name' => 'string2',
                                                            'allownull' => 'yes',
                                                            'type' => 'varchar(500)',
                                                            '_entity' => 'column'
                                                          },
                                             'subclass_view' => {
                                                                  'name' => 'subclass_view',
                                                                  'allownull' => 'no',
                                                                  'type' => 'varchar(27)',
                                                                  '_entity' => 'column'
                                                                },
                                             '_order' => [
                                                           'biomaterial_id',
                                                           'labelmethod_id',
                                                           'taxon_id',
                                                           'biosourceprovider_id',
                                                           'subclass_view',
                                                           'dbxref_id',
                                                           'string1',
                                                           'string2'
                                                         ],
                                             '_entity' => 'list',
                                             'labelmethod_id' => {
                                                                   'fk_table' => 'labelmethod',
                                                                   'name' => 'labelmethod_id',
                                                                   'allownull' => 'yes',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'labelmethod_id'
                                                                 }
                                           }
                             },
            'acquisition' => {
                               'name' => 'acquisition',
                               'comment' => 'changed some of the pk/fk names to conform to chado conventions (removed _) changed field names (removed _s) changed some tablenames by adding _ to link tables, dropping _ where no link. dropped trailing \'-imp\' off some tablenames dropped external_database_release_id fields mapped contact links to author table mapped bibliographic references to pub table source_id changed to dbxref_id ok drop table acquisition;',
                               '_entity' => 'table',
                               'primarykey' => 'acquisition_id',
                               'column' => {
                                             'uri' => {
                                                        'name' => 'uri',
                                                        'allownull' => 'yes',
                                                        'type' => 'varchar(255)',
                                                        '_entity' => 'column'
                                                      },
                                             'name' => {
                                                         'name' => 'name',
                                                         'allownull' => 'yes',
                                                         'type' => 'varchar(100)',
                                                         '_entity' => 'column'
                                                       },
                                             'channel_id' => {
                                                               'fk_table' => 'channel',
                                                               'name' => 'channel_id',
                                                               'allownull' => 'yes',
                                                               'type' => 'int',
                                                               '_entity' => 'column',
                                                               'fk_column' => 'channel_id'
                                                             },
                                             'acquisition_id' => {
                                                                   'name' => 'acquisition_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'serial',
                                                                   'foreign_references' => [
                                                                                             {
                                                                                               'table' => 'acquisitionparam',
                                                                                               'column' => 'acquisition_id'
                                                                                             },
                                                                                             {
                                                                                               'table' => 'relatedacquisition',
                                                                                               'column' => 'associatedacquisition_id'
                                                                                             },
                                                                                             {
                                                                                               'table' => 'relatedacquisition',
                                                                                               'column' => 'acquisition_id'
                                                                                             },
                                                                                             {
                                                                                               'table' => 'quantification',
                                                                                               'column' => 'acquisition_id'
                                                                                             }
                                                                                           ],
                                                                   '_entity' => 'column',
                                                                   'primarykey' => 'yes'
                                                                 },
                                             'acquisitiondate' => {
                                                                    'name' => 'acquisitiondate',
                                                                    'allownull' => 'yes',
                                                                    'type' => 'date',
                                                                    '_entity' => 'column'
                                                                  },
                                             '_order' => [
                                                           'acquisition_id',
                                                           'assay_id',
                                                           'protocol_id',
                                                           'channel_id',
                                                           'acquisitiondate',
                                                           'name',
                                                           'uri'
                                                         ],
                                             '_entity' => 'list',
                                             'assay_id' => {
                                                             'fk_table' => 'assay',
                                                             'name' => 'assay_id',
                                                             'allownull' => 'no',
                                                             'type' => 'int',
                                                             '_entity' => 'column',
                                                             'fk_column' => 'assay_id'
                                                           },
                                             'protocol_id' => {
                                                                'fk_table' => 'protocol',
                                                                'name' => 'protocol_id',
                                                                'allownull' => 'yes',
                                                                'type' => 'int',
                                                                '_entity' => 'column',
                                                                'fk_column' => 'protocol_id'
                                                              }
                                           }
                             },
            'wwwuser_pub' => {
                               'indexes' => {
                                              'wwwuser_pub_idx2' => {
                                                                      'columns' => 'pub_id',
                                                                      'name' => 'wwwuser_pub_idx2',
                                                                      '_entity' => 'index'
                                                                    },
                                              '_entity' => 'set',
                                              'wwwuser_pub_idx1' => {
                                                                      'columns' => 'wwwuser_id',
                                                                      'name' => 'wwwuser_pub_idx1',
                                                                      '_entity' => 'index'
                                                                    }
                                            },
                               'name' => 'wwwuser_pub',
                               'comment' => 'track wwwuser interest in publications',
                               '_entity' => 'table',
                               'primarykey' => 'wwwuser_pub_id',
                               'column' => {
                                             'wwwuser_id' => {
                                                               'fk_table' => 'wwwuser',
                                                               'name' => 'wwwuser_id',
                                                               'allownull' => 'no',
                                                               'type' => 'int',
                                                               '_entity' => 'column',
                                                               'fk_column' => 'wwwuser_id',
                                                               'unique' => 2
                                                             },
                                             'world_read' => {
                                                               'name' => 'world_read',
                                                               'allownull' => 'no',
                                                               'type' => 'smallint',
                                                               '_entity' => 'column',
                                                               'default' => 1
                                                             },
                                             'pub_id' => {
                                                           'fk_table' => 'pub',
                                                           'name' => 'pub_id',
                                                           'allownull' => 'no',
                                                           'type' => 'int',
                                                           '_entity' => 'column',
                                                           'fk_column' => 'pub_id',
                                                           'unique' => 2
                                                         },
                                             '_order' => [
                                                           'wwwuser_pub_id',
                                                           'wwwuser_id',
                                                           'pub_id',
                                                           'world_read'
                                                         ],
                                             '_entity' => 'list',
                                             'wwwuser_pub_id' => {
                                                                   'name' => 'wwwuser_pub_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'serial',
                                                                   '_entity' => 'column',
                                                                   'primarykey' => 'yes'
                                                                 }
                                           },
                               'unique' => [
                                             'wwwuser_id',
                                             'pub_id'
                                           ]
                             },
            'cvterm' => {
                          'indexes' => {
                                         '_entity' => 'set',
                                         'cvterm_idx1' => {
                                                            'columns' => 'cv_id',
                                                            'name' => 'cvterm_idx1',
                                                            '_entity' => 'index'
                                                          }
                                       },
                          'name' => 'cvterm',
                          '_entity' => 'table',
                          'primarykey' => 'cvterm_id',
                          'column' => {
                                        'termdefinition' => {
                                                              'name' => 'termdefinition',
                                                              'allownull' => 'yes',
                                                              'type' => 'text',
                                                              '_entity' => 'column'
                                                            },
                                        'name' => {
                                                    'name' => 'name',
                                                    'allownull' => 'no',
                                                    'type' => 'varchar(255)',
                                                    '_entity' => 'column',
                                                    'unique' => 2
                                                  },
                                        '_order' => [
                                                      'cvterm_id',
                                                      'cv_id',
                                                      'name',
                                                      'termdefinition',
                                                      'dbxref_id'
                                                    ],
                                        '_entity' => 'list',
                                        'cv_id' => {
                                                     'fk_table' => 'cv',
                                                     'name' => 'cv_id',
                                                     'allownull' => 'no',
                                                     'type' => 'int',
                                                     '_entity' => 'column',
                                                     'fk_column' => 'cv_id',
                                                     'unique' => 2
                                                   },
                                        'cvterm_id' => {
                                                         'name' => 'cvterm_id',
                                                         'allownull' => 'no',
                                                         'type' => 'serial',
                                                         'foreign_references' => [
                                                                                   {
                                                                                     'table' => 'control',
                                                                                     'column' => 'controltype_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'pubprop',
                                                                                     'column' => 'pkey_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'element',
                                                                                     'column' => 'element_type_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'cvterm_dbxref',
                                                                                     'column' => 'cvterm_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'feature',
                                                                                     'column' => 'type_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'cvtermsynonym',
                                                                                     'column' => 'cvterm_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'protocol',
                                                                                     'column' => 'protocol_type_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'wwwuser_cvterm',
                                                                                     'column' => 'cvterm_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'pub_relationship',
                                                                                     'column' => 'type_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'feature_cvterm',
                                                                                     'column' => 'cvterm_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'phenotype',
                                                                                     'column' => 'statement_type'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'cvpath',
                                                                                     'column' => 'subjterm_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'cvpath',
                                                                                     'column' => 'reltype_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'cvpath',
                                                                                     'column' => 'objterm_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'cvrelationship',
                                                                                     'column' => 'subjterm_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'cvrelationship',
                                                                                     'column' => 'reltype_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'cvrelationship',
                                                                                     'column' => 'objterm_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'phenotype_cvterm',
                                                                                     'column' => 'cvterm_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'featureprop',
                                                                                     'column' => 'pkey_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'studydesigndescription',
                                                                                     'column' => 'descriptiontype_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'dbxrefprop',
                                                                                     'column' => 'pkey_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'synonym',
                                                                                     'column' => 'type_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'analysisprop',
                                                                                     'column' => 'pkey_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'biomaterialmeasurement',
                                                                                     'column' => 'unittype_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'treatment',
                                                                                     'column' => 'treatmenttype_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'biomaterial_cvterm',
                                                                                     'column' => 'cvterm_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'feature_relationship',
                                                                                     'column' => 'type_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'expression_cvterm',
                                                                                     'column' => 'cvterm_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'protocolparam',
                                                                                     'column' => 'datatype_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'protocolparam',
                                                                                     'column' => 'unittype_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'processimplementation',
                                                                                     'column' => 'processtype_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'pub',
                                                                                     'column' => 'type_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'studydesign',
                                                                                     'column' => 'studydesigntype_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'studyfactor',
                                                                                     'column' => 'studyfactortype_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'processresult',
                                                                                     'column' => 'unittype_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'array',
                                                                                     'column' => 'substrate_type_id'
                                                                                   },
                                                                                   {
                                                                                     'table' => 'array',
                                                                                     'column' => 'platformtype_id'
                                                                                   }
                                                                                 ],
                                                         '_entity' => 'column',
                                                         'primarykey' => 'yes'
                                                       },
                                        'dbxref_id' => {
                                                         'fk_table' => 'dbxref',
                                                         'name' => 'dbxref_id',
                                                         'allownull' => 'yes',
                                                         'type' => 'int',
                                                         '_entity' => 'column',
                                                         'fk_column' => 'dbxref_id'
                                                       }
                                      },
                          'unique' => [
                                        'name',
                                        'cv_id'
                                      ]
                        },
            'feature_pub' => {
                               'indexes' => {
                                              'feature_pub_idx2' => {
                                                                      'columns' => 'pub_id',
                                                                      'name' => 'feature_pub_idx2',
                                                                      '_entity' => 'index'
                                                                    },
                                              '_entity' => 'set',
                                              'feature_pub_idx1' => {
                                                                      'columns' => 'feature_id',
                                                                      'name' => 'feature_pub_idx1',
                                                                      '_entity' => 'index'
                                                                    }
                                            },
                               'name' => 'feature_pub',
                               'comment' => 'phase: phase of translation wrt srcfeature_id.  Values are 0,1,2',
                               '_entity' => 'table',
                               'primarykey' => 'feature_pub_id',
                               'column' => {
                                             'feature_id' => {
                                                               'fk_table' => 'feature',
                                                               'name' => 'feature_id',
                                                               'allownull' => 'no',
                                                               'type' => 'int',
                                                               '_entity' => 'column',
                                                               'fk_column' => 'feature_id',
                                                               'unique' => 2
                                                             },
                                             'pub_id' => {
                                                           'fk_table' => 'pub',
                                                           'name' => 'pub_id',
                                                           'allownull' => 'no',
                                                           'type' => 'int',
                                                           '_entity' => 'column',
                                                           'fk_column' => 'pub_id',
                                                           'unique' => 2
                                                         },
                                             '_order' => [
                                                           'feature_pub_id',
                                                           'feature_id',
                                                           'pub_id'
                                                         ],
                                             '_entity' => 'list',
                                             'feature_pub_id' => {
                                                                   'name' => 'feature_pub_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'serial',
                                                                   '_entity' => 'column',
                                                                   'primarykey' => 'yes'
                                                                 }
                                           },
                               'unique' => [
                                             'feature_id',
                                             'pub_id'
                                           ]
                             },
            'wwwuser_expression' => {
                                      'indexes' => {
                                                     'wwwuser_expression_idx1' => {
                                                                                    'columns' => 'wwwuser_id',
                                                                                    'name' => 'wwwuser_expression_idx1',
                                                                                    '_entity' => 'index'
                                                                                  },
                                                     'wwwuser_expression_idx2' => {
                                                                                    'columns' => 'expression_id',
                                                                                    'name' => 'wwwuser_expression_idx2',
                                                                                    '_entity' => 'index'
                                                                                  },
                                                     '_entity' => 'set'
                                                   },
                                      'name' => 'wwwuser_expression',
                                      'comment' => 'track wwwuser interest in expressions',
                                      '_entity' => 'table',
                                      'primarykey' => 'wwwuser_expression_id',
                                      'column' => {
                                                    'wwwuser_id' => {
                                                                      'fk_table' => 'wwwuser',
                                                                      'name' => 'wwwuser_id',
                                                                      'allownull' => 'no',
                                                                      'type' => 'int',
                                                                      '_entity' => 'column',
                                                                      'fk_column' => 'wwwuser_id',
                                                                      'unique' => 2
                                                                    },
                                                    'world_read' => {
                                                                      'name' => 'world_read',
                                                                      'allownull' => 'no',
                                                                      'type' => 'smallint',
                                                                      '_entity' => 'column',
                                                                      'default' => 1
                                                                    },
                                                    '_order' => [
                                                                  'wwwuser_expression_id',
                                                                  'wwwuser_id',
                                                                  'expression_id',
                                                                  'world_read'
                                                                ],
                                                    'expression_id' => {
                                                                         'fk_table' => 'expression',
                                                                         'name' => 'expression_id',
                                                                         'allownull' => 'no',
                                                                         'type' => 'int',
                                                                         '_entity' => 'column',
                                                                         'fk_column' => 'expression_id',
                                                                         'unique' => 2
                                                                       },
                                                    '_entity' => 'list',
                                                    'wwwuser_expression_id' => {
                                                                                 'name' => 'wwwuser_expression_id',
                                                                                 'allownull' => 'no',
                                                                                 'type' => 'serial',
                                                                                 '_entity' => 'column',
                                                                                 'primarykey' => 'yes'
                                                                               }
                                                  },
                                      'unique' => [
                                                    'wwwuser_id',
                                                    'expression_id'
                                                  ]
                                    },
            'interaction_subj' => {
                                    'indexes' => {
                                                   'interaction_subj_idx1' => {
                                                                                'columns' => 'feature_id',
                                                                                'name' => 'interaction_subj_idx1',
                                                                                '_entity' => 'index'
                                                                              },
                                                   'interaction_subj_idx2' => {
                                                                                'columns' => 'interaction_id',
                                                                                'name' => 'interaction_subj_idx2',
                                                                                '_entity' => 'index'
                                                                              },
                                                   '_entity' => 'set'
                                                 },
                                    'name' => 'interaction_subj',
                                    '_entity' => 'table',
                                    'primarykey' => 'interaction_subj_id',
                                    'column' => {
                                                  'feature_id' => {
                                                                    'fk_table' => 'feature',
                                                                    'name' => 'feature_id',
                                                                    'allownull' => 'no',
                                                                    'type' => 'int',
                                                                    '_entity' => 'column',
                                                                    'fk_column' => 'feature_id',
                                                                    'unique' => 2
                                                                  },
                                                  '_order' => [
                                                                'interaction_subj_id',
                                                                'feature_id',
                                                                'interaction_id'
                                                              ],
                                                  'interaction_id' => {
                                                                        'fk_table' => 'interaction',
                                                                        'name' => 'interaction_id',
                                                                        'allownull' => 'no',
                                                                        'type' => 'int',
                                                                        '_entity' => 'column',
                                                                        'fk_column' => 'interaction_id',
                                                                        'unique' => 2
                                                                      },
                                                  '_entity' => 'list',
                                                  'interaction_subj_id' => {
                                                                             'name' => 'interaction_subj_id',
                                                                             'allownull' => 'no',
                                                                             'type' => 'serial',
                                                                             '_entity' => 'column',
                                                                             'primarykey' => 'yes'
                                                                           }
                                                },
                                    'unique' => [
                                                  'feature_id',
                                                  'interaction_id'
                                                ]
                                  },
            'studydesign' => {
                               'name' => 'studydesign',
                               'comment' => 'ok drop table if exists studydesign;',
                               '_entity' => 'table',
                               'primarykey' => 'studydesign_id',
                               'column' => {
                                             'studydesigntype_id' => {
                                                                       'fk_table' => 'cvterm',
                                                                       'name' => 'studydesigntype_id',
                                                                       'allownull' => 'yes',
                                                                       'type' => 'int  null',
                                                                       '_entity' => 'column',
                                                                       'fk_column' => 'cvterm_id'
                                                                     },
                                             '_order' => [
                                                           'studydesign_id',
                                                           'study_id',
                                                           'studydesigntype_id',
                                                           'description'
                                                         ],
                                             'description' => {
                                                                'name' => 'description',
                                                                'allownull' => 'yes',
                                                                'type' => 'varchar(4000)',
                                                                '_entity' => 'column'
                                                              },
                                             '_entity' => 'list',
                                             'study_id' => {
                                                             'fk_table' => 'study',
                                                             'name' => 'study_id',
                                                             'allownull' => 'no',
                                                             'type' => 'int',
                                                             '_entity' => 'column',
                                                             'fk_column' => 'study_id'
                                                           },
                                             'studydesign_id' => {
                                                                   'name' => 'studydesign_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'serial',
                                                                   'foreign_references' => [
                                                                                             {
                                                                                               'table' => 'studydesign_assay',
                                                                                               'column' => 'studydesign_id'
                                                                                             },
                                                                                             {
                                                                                               'table' => 'studydesigndescription',
                                                                                               'column' => 'studydesign_id'
                                                                                             },
                                                                                             {
                                                                                               'table' => 'studyfactor',
                                                                                               'column' => 'studydesign_id'
                                                                                             }
                                                                                           ],
                                                                   '_entity' => 'column',
                                                                   'primarykey' => 'yes'
                                                                 }
                                           }
                             },
            'wwwuserrelationship' => {
                                       'indexes' => {
                                                      'wwwuserrelationship_idx1' => {
                                                                                      'columns' => 'subjwwwuser_id',
                                                                                      'name' => 'wwwuserrelationship_idx1',
                                                                                      '_entity' => 'index'
                                                                                    },
                                                      'wwwuserrelationship_idx2' => {
                                                                                      'columns' => 'objwwwuser_id',
                                                                                      'name' => 'wwwuserrelationship_idx2',
                                                                                      '_entity' => 'index'
                                                                                    },
                                                      '_entity' => 'set'
                                                    },
                                       'name' => 'wwwuserrelationship',
                                       'comment' => 'track wwwuser interest in other wwwusers',
                                       '_entity' => 'table',
                                       'primarykey' => 'wwwuserrelationship_id',
                                       'column' => {
                                                     'wwwuserrelationship_id' => {
                                                                                   'name' => 'wwwuserrelationship_id',
                                                                                   'allownull' => 'no',
                                                                                   'type' => 'serial',
                                                                                   '_entity' => 'column',
                                                                                   'primarykey' => 'yes'
                                                                                 },
                                                     'world_read' => {
                                                                       'name' => 'world_read',
                                                                       'allownull' => 'no',
                                                                       'type' => 'smallint',
                                                                       '_entity' => 'column',
                                                                       'default' => 1
                                                                     },
                                                     'objwwwuser_id' => {
                                                                          'fk_table' => 'wwwuser',
                                                                          'name' => 'objwwwuser_id',
                                                                          'allownull' => 'no',
                                                                          'type' => 'int',
                                                                          '_entity' => 'column',
                                                                          'fk_column' => 'wwwuser_id',
                                                                          'unique' => 2
                                                                        },
                                                     '_order' => [
                                                                   'wwwuserrelationship_id',
                                                                   'objwwwuser_id',
                                                                   'subjwwwuser_id',
                                                                   'world_read'
                                                                 ],
                                                     'subjwwwuser_id' => {
                                                                           'fk_table' => 'wwwuser',
                                                                           'name' => 'subjwwwuser_id',
                                                                           'allownull' => 'no',
                                                                           'type' => 'int',
                                                                           '_entity' => 'column',
                                                                           'fk_column' => 'wwwuser_id',
                                                                           'unique' => 2
                                                                         },
                                                     '_entity' => 'list'
                                                   },
                                       'unique' => [
                                                     'objwwwuser_id',
                                                     'subjwwwuser_id'
                                                   ]
                                     },
            'processinvocation_quantification' => {
                                                    'name' => 'processinvocation_quantification',
                                                    'comment' => 'ok renamed from processinv_quantification to processinvocation_quantification drop table if exists processinvocation_quantification;',
                                                    '_entity' => 'table',
                                                    'primarykey' => 'processinvocation_quantification_id',
                                                    'column' => {
                                                                  'quantification_id' => {
                                                                                           'fk_table' => 'quantification',
                                                                                           'name' => 'quantification_id',
                                                                                           'allownull' => 'no',
                                                                                           'type' => 'int',
                                                                                           '_entity' => 'column',
                                                                                           'fk_column' => 'quantification_id'
                                                                                         },
                                                                  'processinvocation_quantification_id' => {
                                                                                                             'name' => 'processinvocation_quantification_id',
                                                                                                             'allownull' => 'no',
                                                                                                             'type' => 'serial',
                                                                                                             '_entity' => 'column',
                                                                                                             'primarykey' => 'yes'
                                                                                                           },
                                                                  '_order' => [
                                                                                'processinvocation_quantification_id',
                                                                                'processinvocation_id',
                                                                                'quantification_id'
                                                                              ],
                                                                  '_entity' => 'list',
                                                                  'processinvocation_id' => {
                                                                                              'fk_table' => 'processinvocation',
                                                                                              'name' => 'processinvocation_id',
                                                                                              'allownull' => 'no',
                                                                                              'type' => 'int',
                                                                                              '_entity' => 'column',
                                                                                              'fk_column' => 'processinvocation_id'
                                                                                            }
                                                                }
                                                  },
            'studyfactor' => {
                               'name' => 'studyfactor',
                               'comment' => 'ok drop table if exists studyfactor;',
                               '_entity' => 'table',
                               'primarykey' => 'studyfactor_id',
                               'column' => {
                                             'name' => {
                                                         'name' => 'name',
                                                         'allownull' => 'no',
                                                         'type' => 'varchar(100)',
                                                         '_entity' => 'column'
                                                       },
                                             '_order' => [
                                                           'studyfactor_id',
                                                           'studydesign_id',
                                                           'studyfactortype_id',
                                                           'name',
                                                           'description'
                                                         ],
                                             'description' => {
                                                                'name' => 'description',
                                                                'allownull' => 'yes',
                                                                'type' => 'varchar(500)',
                                                                '_entity' => 'column'
                                                              },
                                             'studyfactor_id' => {
                                                                   'name' => 'studyfactor_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'serial',
                                                                   'foreign_references' => [
                                                                                             {
                                                                                               'table' => 'studyfactorvalue',
                                                                                               'column' => 'studyfactor_id'
                                                                                             }
                                                                                           ],
                                                                   '_entity' => 'column',
                                                                   'primarykey' => 'yes'
                                                                 },
                                             '_entity' => 'list',
                                             'studyfactortype_id' => {
                                                                       'fk_table' => 'cvterm',
                                                                       'name' => 'studyfactortype_id',
                                                                       'allownull' => 'yes',
                                                                       'type' => 'int',
                                                                       '_entity' => 'column',
                                                                       'fk_column' => 'cvterm_id'
                                                                     },
                                             'studydesign_id' => {
                                                                   'fk_table' => 'studydesign',
                                                                   'name' => 'studydesign_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'studydesign_id'
                                                                 }
                                           }
                             },
            'channel' => {
                           'name' => 'channel',
                           'comment' => 'ok drop table if exists channel;',
                           '_entity' => 'table',
                           'primarykey' => 'channel_id',
                           'column' => {
                                         'definition' => {
                                                           'name' => 'definition',
                                                           'allownull' => 'no',
                                                           'type' => 'varchar(500)',
                                                           '_entity' => 'column'
                                                         },
                                         'name' => {
                                                     'name' => 'name',
                                                     'allownull' => 'no',
                                                     'type' => 'varchar(100)',
                                                     '_entity' => 'column'
                                                   },
                                         '_order' => [
                                                       'channel_id',
                                                       'name',
                                                       'definition'
                                                     ],
                                         '_entity' => 'list',
                                         'channel_id' => {
                                                           'name' => 'channel_id',
                                                           'allownull' => 'no',
                                                           'type' => 'serial',
                                                           'foreign_references' => [
                                                                                     {
                                                                                       'table' => 'labelmethod',
                                                                                       'column' => 'channel_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'assay_labeledextract',
                                                                                       'column' => 'channel_id'
                                                                                     },
                                                                                     {
                                                                                       'table' => 'acquisition',
                                                                                       'column' => 'channel_id'
                                                                                     }
                                                                                   ],
                                                           '_entity' => 'column',
                                                           'primarykey' => 'yes'
                                                         }
                                       }
                         },
            'study' => {
                         'name' => 'study',
                         'comment' => 'ok drop table if exists study;',
                         '_entity' => 'table',
                         'primarykey' => 'study_id',
                         'column' => {
                                       'contact_id' => {
                                                         'fk_table' => 'author',
                                                         'name' => 'contact_id',
                                                         'allownull' => 'no',
                                                         'type' => 'int',
                                                         '_entity' => 'column',
                                                         'fk_column' => 'author_id'
                                                       },
                                       'name' => {
                                                   'name' => 'name',
                                                   'allownull' => 'no',
                                                   'type' => 'varchar(100)',
                                                   '_entity' => 'column'
                                                 },
                                       'pub_id' => {
                                                     'fk_table' => 'pub',
                                                     'name' => 'pub_id',
                                                     'allownull' => 'yes',
                                                     'type' => 'int',
                                                     '_entity' => 'column',
                                                     'fk_column' => 'pub_id'
                                                   },
                                       '_order' => [
                                                     'study_id',
                                                     'contact_id',
                                                     'pub_id',
                                                     'dbxref_id',
                                                     'name',
                                                     'description'
                                                   ],
                                       'description' => {
                                                          'name' => 'description',
                                                          'allownull' => 'yes',
                                                          'type' => 'varchar(4000)',
                                                          '_entity' => 'column'
                                                        },
                                       '_entity' => 'list',
                                       'study_id' => {
                                                       'name' => 'study_id',
                                                       'allownull' => 'no',
                                                       'type' => 'serial',
                                                       'foreign_references' => [
                                                                                 {
                                                                                   'table' => 'study_assay',
                                                                                   'column' => 'study_id'
                                                                                 },
                                                                                 {
                                                                                   'table' => 'studydesign',
                                                                                   'column' => 'study_id'
                                                                                 }
                                                                               ],
                                                       '_entity' => 'column',
                                                       'primarykey' => 'yes'
                                                     },
                                       'dbxref_id' => {
                                                        'fk_table' => 'dbxref',
                                                        'name' => 'dbxref_id',
                                                        'allownull' => 'yes',
                                                        'type' => 'int',
                                                        '_entity' => 'column',
                                                        'fk_column' => 'dbxref_id'
                                                      }
                                     }
                       },
            'organism_dbxref' => {
                                   'indexes' => {
                                                  'organism_dbxref_idx2' => {
                                                                              'columns' => 'dbxref_id',
                                                                              'name' => 'organism_dbxref_idx2',
                                                                              '_entity' => 'index'
                                                                            },
                                                  '_entity' => 'set',
                                                  'organism_dbxref_idx1' => {
                                                                              'columns' => 'organism_id',
                                                                              'name' => 'organism_dbxref_idx1',
                                                                              '_entity' => 'index'
                                                                            }
                                                },
                                   'name' => 'organism_dbxref',
                                   'comment' => 'Compared to mol5..Species, organism table lacks "approved char(1) null".  We need to work w/ Aubrey & Michael to ensure that we don\'t need this in  future [dave]   in response: this is very specific to a limited use case I think;  if it\'s really necessary we can have an organismprop table  for adding internal project specific data  [cjm]',
                                   '_entity' => 'table',
                                   'primarykey' => 'organism_dbxref_id',
                                   'column' => {
                                                 '_order' => [
                                                               'organism_dbxref_id',
                                                               'organism_id',
                                                               'dbxref_id'
                                                             ],
                                                 'organism_id' => {
                                                                    'fk_table' => 'organism',
                                                                    'name' => 'organism_id',
                                                                    'allownull' => 'no',
                                                                    'type' => 'int',
                                                                    '_entity' => 'column',
                                                                    'fk_column' => 'organism_id',
                                                                    'unique' => 2
                                                                  },
                                                 '_entity' => 'list',
                                                 'organism_dbxref_id' => {
                                                                           'name' => 'organism_dbxref_id',
                                                                           'allownull' => 'no',
                                                                           'type' => 'serial',
                                                                           '_entity' => 'column',
                                                                           'primarykey' => 'yes'
                                                                         },
                                                 'dbxref_id' => {
                                                                  'fk_table' => 'dbxref',
                                                                  'name' => 'dbxref_id',
                                                                  'allownull' => 'no',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'dbxref_id',
                                                                  'unique' => 2
                                                                }
                                               },
                                   'unique' => [
                                                 'organism_id',
                                                 'dbxref_id'
                                               ]
                                 },
            'interaction_obj' => {
                                   'indexes' => {
                                                  'interaction_obj_idx2' => {
                                                                              'columns' => 'interaction_id',
                                                                              'name' => 'interaction_obj_idx2',
                                                                              '_entity' => 'index'
                                                                            },
                                                  '_entity' => 'set',
                                                  'interaction_obj_idx1' => {
                                                                              'columns' => 'feature_id',
                                                                              'name' => 'interaction_obj_idx1',
                                                                              '_entity' => 'index'
                                                                            }
                                                },
                                   'name' => 'interaction_obj',
                                   '_entity' => 'table',
                                   'primarykey' => 'interaction_obj_id',
                                   'column' => {
                                                 'feature_id' => {
                                                                   'fk_table' => 'feature',
                                                                   'name' => 'feature_id',
                                                                   'allownull' => 'no',
                                                                   'type' => 'int',
                                                                   '_entity' => 'column',
                                                                   'fk_column' => 'feature_id',
                                                                   'unique' => 2
                                                                 },
                                                 '_order' => [
                                                               'interaction_obj_id',
                                                               'feature_id',
                                                               'interaction_id'
                                                             ],
                                                 'interaction_id' => {
                                                                       'fk_table' => 'interaction',
                                                                       'name' => 'interaction_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'int',
                                                                       '_entity' => 'column',
                                                                       'fk_column' => 'interaction_id',
                                                                       'unique' => 2
                                                                     },
                                                 '_entity' => 'list',
                                                 'interaction_obj_id' => {
                                                                           'name' => 'interaction_obj_id',
                                                                           'allownull' => 'no',
                                                                           'type' => 'serial',
                                                                           '_entity' => 'column',
                                                                           'primarykey' => 'yes'
                                                                         }
                                               },
                                   'unique' => [
                                                 'feature_id',
                                                 'interaction_id'
                                               ]
                                 },
            'feature_expression' => {
                                      'indexes' => {
                                                     'feature_expression_idx1' => {
                                                                                    'columns' => 'expression_id',
                                                                                    'name' => 'feature_expression_idx1',
                                                                                    '_entity' => 'index'
                                                                                  },
                                                     'feature_expression_idx2' => {
                                                                                    'columns' => 'feature_id',
                                                                                    'name' => 'feature_expression_idx2',
                                                                                    '_entity' => 'index'
                                                                                  },
                                                     '_entity' => 'set'
                                                   },
                                      'name' => 'feature_expression',
                                      '_entity' => 'table',
                                      'primarykey' => 'feature_expression_id',
                                      'column' => {
                                                    'feature_id' => {
                                                                      'fk_table' => 'feature',
                                                                      'name' => 'feature_id',
                                                                      'allownull' => 'no',
                                                                      'type' => 'int',
                                                                      '_entity' => 'column',
                                                                      'fk_column' => 'feature_id',
                                                                      'unique' => 2
                                                                    },
                                                    '_order' => [
                                                                  'feature_expression_id',
                                                                  'expression_id',
                                                                  'feature_id'
                                                                ],
                                                    'expression_id' => {
                                                                         'fk_table' => 'expression',
                                                                         'name' => 'expression_id',
                                                                         'allownull' => 'no',
                                                                         'type' => 'int',
                                                                         '_entity' => 'column',
                                                                         'fk_column' => 'expression_id',
                                                                         'unique' => 2
                                                                       },
                                                    '_entity' => 'list',
                                                    'feature_expression_id' => {
                                                                                 'name' => 'feature_expression_id',
                                                                                 'allownull' => 'no',
                                                                                 'type' => 'serial',
                                                                                 '_entity' => 'column',
                                                                                 'primarykey' => 'yes'
                                                                               }
                                                  },
                                      'unique' => [
                                                    'expression_id',
                                                    'feature_id'
                                                  ]
                                    },
            'analysisinvocation' => {
                                      'name' => 'analysisinvocation',
                                      'comment' => 'ok drop table if exists analysisinvocation;',
                                      '_entity' => 'table',
                                      'primarykey' => 'analysisinvocation_id',
                                      'column' => {
                                                    'name' => {
                                                                'name' => 'name',
                                                                'allownull' => 'no',
                                                                'type' => 'varchar(100)',
                                                                '_entity' => 'column'
                                                              },
                                                    'analysisinvocation_id' => {
                                                                                 'name' => 'analysisinvocation_id',
                                                                                 'allownull' => 'no',
                                                                                 'type' => 'serial',
                                                                                 'foreign_references' => [
                                                                                                           {
                                                                                                             'table' => 'analysisinput',
                                                                                                             'column' => 'analysisinvocation_id'
                                                                                                           },
                                                                                                           {
                                                                                                             'table' => 'analysisinvocationparam',
                                                                                                             'column' => 'analysisinvocation_id'
                                                                                                           },
                                                                                                           {
                                                                                                             'table' => 'analysisoutput',
                                                                                                             'column' => 'analysisinvocation_id'
                                                                                                           }
                                                                                                         ],
                                                                                 '_entity' => 'column',
                                                                                 'primarykey' => 'yes'
                                                                               },
                                                    '_order' => [
                                                                  'analysisinvocation_id',
                                                                  'analysisimplementation_id',
                                                                  'name',
                                                                  'description'
                                                                ],
                                                    'description' => {
                                                                       'name' => 'description',
                                                                       'allownull' => 'yes',
                                                                       'type' => 'varchar(500)',
                                                                       '_entity' => 'column'
                                                                     },
                                                    '_entity' => 'list',
                                                    'analysisimplementation_id' => {
                                                                                     'fk_table' => 'analysisimplementation',
                                                                                     'name' => 'analysisimplementation_id',
                                                                                     'allownull' => 'no',
                                                                                     'type' => 'int',
                                                                                     '_entity' => 'column',
                                                                                     'fk_column' => 'analysisimplementation_id'
                                                                                   }
                                                  }
                                    },
            'processresult' => {
                                 'name' => 'processresult',
                                 'comment' => 'ok drop table if exists processresult;',
                                 '_entity' => 'table',
                                 'primarykey' => 'processresult_id',
                                 'column' => {
                                               'processresult_id' => {
                                                                       'name' => 'processresult_id',
                                                                       'allownull' => 'no',
                                                                       'type' => 'serial',
                                                                       'foreign_references' => [
                                                                                                 {
                                                                                                   'table' => 'processio',
                                                                                                   'column' => 'outputrow_id'
                                                                                                 }
                                                                                               ],
                                                                       '_entity' => 'column',
                                                                       'primarykey' => 'yes'
                                                                     },
                                               '_order' => [
                                                             'processresult_id',
                                                             'value',
                                                             'unittype_id'
                                                           ],
                                               '_entity' => 'list',
                                               'value' => {
                                                            'name' => 'value',
                                                            'allownull' => 'no',
                                                            'type' => 'float(15)',
                                                            '_entity' => 'column'
                                                          },
                                               'unittype_id' => {
                                                                  'fk_table' => 'cvterm',
                                                                  'name' => 'unittype_id',
                                                                  'allownull' => 'yes',
                                                                  'type' => 'int',
                                                                  '_entity' => 'column',
                                                                  'fk_column' => 'cvterm_id'
                                                                }
                                             }
                               },
            'array' => {
                         'name' => 'array',
                         'comment' => 'ok drop table if exists array;',
                         '_entity' => 'table',
                         'primarykey' => 'array_id',
                         'column' => {
                                       'name' => {
                                                   'name' => 'name',
                                                   'allownull' => 'no',
                                                   'type' => 'varchar(100)',
                                                   '_entity' => 'column'
                                                 },
                                       'element_dimensions' => {
                                                                 'name' => 'element_dimensions',
                                                                 'allownull' => 'yes',
                                                                 'type' => 'varchar(50)',
                                                                 '_entity' => 'column'
                                                               },
                                       'num_sub_rows' => {
                                                           'name' => 'num_sub_rows',
                                                           'allownull' => 'yes',
                                                           'type' => 'int',
                                                           '_entity' => 'column'
                                                         },
                                       'description' => {
                                                          'name' => 'description',
                                                          'allownull' => 'yes',
                                                          'type' => 'varchar(500)',
                                                          '_entity' => 'column'
                                                        },
                                       'version' => {
                                                      'name' => 'version',
                                                      'allownull' => 'yes',
                                                      'type' => 'varchar(50)  null',
                                                      '_entity' => 'column'
                                                    },
                                       'dbxref_id' => {
                                                        'fk_table' => 'dbxref',
                                                        'name' => 'dbxref_id',
                                                        'allownull' => 'yes',
                                                        'type' => 'int',
                                                        '_entity' => 'column',
                                                        'fk_column' => 'dbxref_id'
                                                      },
                                       'substrate_type_id' => {
                                                                'fk_table' => 'cvterm',
                                                                'name' => 'substrate_type_id',
                                                                'allownull' => 'yes',
                                                                'type' => 'int',
                                                                '_entity' => 'column',
                                                                'fk_column' => 'cvterm_id'
                                                              },
                                       'array_id' => {
                                                       'name' => 'array_id',
                                                       'allownull' => 'no',
                                                       'type' => 'serial',
                                                       'foreign_references' => [
                                                                                 {
                                                                                   'table' => 'element',
                                                                                   'column' => 'array_id'
                                                                                 },
                                                                                 {
                                                                                   'table' => 'assay',
                                                                                   'column' => 'array_id'
                                                                                 },
                                                                                 {
                                                                                   'table' => 'arrayannotation',
                                                                                   'column' => 'array_id'
                                                                                 }
                                                                               ],
                                                       '_entity' => 'column',
                                                       'primarykey' => 'yes'
                                                     },
                                       'num_array_columns' => {
                                                                'name' => 'num_array_columns',
                                                                'allownull' => 'yes',
                                                                'type' => 'int',
                                                                '_entity' => 'column'
                                                              },
                                       'platformtype_id' => {
                                                              'fk_table' => 'cvterm',
                                                              'name' => 'platformtype_id',
                                                              'allownull' => 'no',
                                                              'type' => 'int',
                                                              '_entity' => 'column',
                                                              'fk_column' => 'cvterm_id'
                                                            },
                                       'num_grid_columns' => {
                                                               'name' => 'num_grid_columns',
                                                               'allownull' => 'yes',
                                                               'type' => 'int',
                                                               '_entity' => 'column'
                                                             },
                                       'array_dimensions' => {
                                                               'name' => 'array_dimensions',
                                                               'allownull' => 'yes',
                                                               'type' => 'varchar(50)',
                                                               '_entity' => 'column'
                                                             },
                                       'num_array_rows' => {
                                                             'name' => 'num_array_rows',
                                                             'allownull' => 'yes',
                                                             'type' => 'int',
                                                             '_entity' => 'column'
                                                           },
                                       'num_sub_columns' => {
                                                              'name' => 'num_sub_columns',
                                                              'allownull' => 'yes',
                                                              'type' => 'int',
                                                              '_entity' => 'column'
                                                            },
                                       'manufacturer_id' => {
                                                              'fk_table' => 'author',
                                                              'name' => 'manufacturer_id',
                                                              'allownull' => 'no',
                                                              'type' => 'int',
                                                              '_entity' => 'column',
                                                              'fk_column' => 'author_id'
                                                            },
                                       'number_of_elements' => {
                                                                 'name' => 'number_of_elements',
                                                                 'allownull' => 'yes',
                                                                 'type' => 'int',
                                                                 '_entity' => 'column'
                                                               },
                                       '_order' => [
                                                     'array_id',
                                                     'manufacturer_id',
                                                     'platformtype_id',
                                                     'substrate_type_id',
                                                     'protocol_id',
                                                     'dbxref_id',
                                                     'name',
                                                     'version',
                                                     'description',
                                                     'array_dimensions',
                                                     'element_dimensions',
                                                     'number_of_elements',
                                                     'num_array_columns',
                                                     'num_array_rows',
                                                     'num_grid_columns',
                                                     'num_grid_rows',
                                                     'num_sub_columns',
                                                     'num_sub_rows'
                                                   ],
                                       '_entity' => 'list',
                                       'protocol_id' => {
                                                          'fk_table' => 'protocol',
                                                          'name' => 'protocol_id',
                                                          'allownull' => 'yes',
                                                          'type' => 'int',
                                                          '_entity' => 'column',
                                                          'fk_column' => 'protocol_id'
                                                        },
                                       'num_grid_rows' => {
                                                            'name' => 'num_grid_rows',
                                                            'allownull' => 'yes',
                                                            'type' => 'int',
                                                            '_entity' => 'column'
                                                          }
                                     }
                       }
          };

