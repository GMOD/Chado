CREATE TABLE contact_dbxref (
    contact_dbxref_id BIGSERIAL NOT NULL,
    contact_id BIGINT NOT NULL,
    dbxref_id BIGINT NOT NULL,
    is_current INT NOT NULL,
    PRIMARY KEY (contact_dbxref_id),
    FOREIGN KEY (dbxref_id) REFERENCES dbxref (dbxref_id) ON DELETE CASCADE INITIALLY DEFERRED,
    CONSTRAINT contact_dbxref_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES contact (contact_id) ON DELETE CASCADE INITIALLY DEFERRED,
);

create index contact_dbxref_idx1 on contact_dbxref (contact_id);
create index contact_dbxref_idx2 on contact_dbxref (dbxref_id);

COMMENT ON TABLE contact_dbxref IS 'A contact_dbxref is a dbxref associated with a contact.
A contact can have many dbxrefs associated with it, and a dbxref can be associated with many contacts.'