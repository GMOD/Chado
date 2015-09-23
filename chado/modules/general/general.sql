-- $Id: general.sql,v 1.31 2007-03-01 02:45:54 briano Exp $
-- ==========================================
-- Chado general module
--
-- ================================================
-- TABLE: tableinfo
-- ================================================

create table tableinfo (
    tableinfo_id bigserial not null,
    primary key (tableinfo_id),
    name varchar(30) not null,
    primary_key_column varchar(30) null,
    is_view int not null default 0,
    view_on_table_id bigint null,
    superclass_table_id bigint null,
    is_updateable int not null default 1,
    modification_date date not null default now(),
    constraint tableinfo_c1 unique (name)
);

COMMENT ON TABLE tableinfo IS NULL;

