CREATE DATABASE presto;
USE presto;

-- copied from mysql/FunctionNamespaceDao.java from the Presto sources
CREATE TABLE IF NOT EXISTS function_namespaces (
    catalog_name varchar(128) NOT NULL,
    schema_name  varchar(128) NOT NULL,
    PRIMARY KEY (catalog_name, schema_name));

INSERT INTO function_namespaces (catalog_name, schema_name)
    VALUES('mysql', 'default');
