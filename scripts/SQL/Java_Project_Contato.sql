CREATE SCHEMA lpoo2


DROP TABLE lpoo2.contatos

CREATE TABLE lpoo2.contatos (
	id serial,
	nome varchar(100),
	email varchar(120),
	endereco varchar(150),
	dataNasc date,
	CONSTRAINT pk_ct_id PRIMARY KEY (id)
);

INSERT INTO lpoo2.contatos (nome,email,endereco,dataNasc) values 
	('Albano Roberto','allbano@gmail.com','Rua Tibagi, 692','1981-11-29');
	
select *  from lpoo2.contatos
