-- ================================================
-- TABLE: contactprop
-- ================================================

-- contactprop models person/lab properties, such as email, phone, etc.
-- the cvterms come from FOAF project, see the spec at http://xmlns.com/foaf/spec/

create table contactprop (
	contactprop_id serial not null,
	primary key (contactprop_id),
	contact_id int not null,
	foreign key (contact_id) references contact (contact_id) on delete cascade,
	type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
	value text,

	unique (contact_id, type_id, value)
);
create index contactprop_idx1 on contactprop (contactprop_id);
create index contactprop_idx2 on contactprop (type_id);
