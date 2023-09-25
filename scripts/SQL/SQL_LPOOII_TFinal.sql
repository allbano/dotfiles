CREATE DATABASE tflpoo2;


CREATE SCHEMA lpoo2
DROP SCHEMA lpoo2;

DROP TABLE lpoo2.clientes;

CREATE TABLE lpoo2.clientes (
	id integer DEFAULT nextval('lpoo2.cliente_sq') NOT NULL,
	nome varchar(20),
	sobrenome varchar(80),
	rg varchar(15),
	cpf varchar(11),
	endereco varchar(150),
	CONSTRAINT pk_ct_id PRIMARY KEY (id),
	CONSTRAINT uk_ct_id	UNIQUE (id),
	CONSTRAINT uk_ct_id	UNIQUE (cpf)
);

INSERT INTO lpoo2.clientes (nome,sobrenome,cpf,rg,endereco) values 
	('Albano','Maywitz','55555555555','41462428','Rua Tibagi, 692');

DELETE FROM lpoo2.clientes
	WHERE id = 10000001;
	
SELECT * FROM lpoo2.clientes c;

CREATE SEQUENCE IF NOT EXISTS lpoo2.cliente_sq
    INCREMENT BY 1
    MINVALUE 10000000 MAXVALUE 99999999
    START  10000001;

DROP SEQUENCE public.cliente_sq;
































































































