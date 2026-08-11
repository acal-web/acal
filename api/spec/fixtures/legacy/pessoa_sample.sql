CREATE TABLE `pessoa` (
  `id` int(11) NOT NULL,
  `nome` varchar(255) NOT NULL,
  `sobrenome` varchar(255) NOT NULL,
  `cpf` varchar(255) DEFAULT NULL,
  `cnpj` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `telefone` varchar(255) DEFAULT NULL,
  `numeroMatricula` int(11) DEFAULT NULL,
  `sexo` varchar(255) NOT NULL,
  `status` bit(1) NOT NULL
);
INSERT INTO `pessoa` VALUES (1,'  João  ','  Silva  ','111.444.777-35',NULL,'joao@test.com','(11) 99999-9999',1001,'Masculino',1),(2,'  Maria  ','  Santos  ',NULL,'11.222.333/0001-81','maria@test.com','(11) 88888-8888',1002,'Feminino',1),(3,'  Pedro  ','  Oliveira  ','222.555.888-46',NULL,'pedro@test.com',NULL,1003,'Masculino',0);
