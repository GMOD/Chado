CREATE SCHEMA genetic_code;
SET search_path = genetic_code,public;

CREATE TABLE gencode (
        gencode_id      INTEGER PRIMARY KEY NOT NULL,
        organismstr     VARCHAR(512) NOT NULL
);

CREATE TABLE gencode_codon_aa (
        gencode_id      INTEGER NOT NULL REFERENCES gencode(gencode_id),
        codon           CHAR(3) NOT NULL,
        aa              CHAR(1) NOT NULL
);
CREATE INDEX gencode_codon_aa_i1 ON gencode_codon_aa(gencode_id,codon,aa);

CREATE TABLE gencode_startcodon (
        gencode_id      INTEGER NOT NULL REFERENCES gencode(gencode_id),
        codon           CHAR(3)
);
SET search_path = public;
