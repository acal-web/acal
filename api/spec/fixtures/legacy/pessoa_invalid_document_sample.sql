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
INSERT INTO `pessoa` VALUES (99,'Test','Invalid','111.111.111-11',NULL,'test@test.com','(11) 99999-9999',9900,'Masculino',1);
