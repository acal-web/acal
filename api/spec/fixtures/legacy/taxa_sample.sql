CREATE TABLE `taxa` (
  `id` int(11) NOT NULL,
  `descricao` varchar(255),
  `nome` varchar(255),
  `observacao` text,
  `valor` decimal(19,2),
  `valor_socio` decimal(10,2),
  `valor_otros` decimal(19,2)
);
INSERT INTO `taxa` VALUES (1,'Water meter','Temp rate',NULL,30.00,0.00,NULL),(5,'Regular','Regular member',NULL,27.00,3.00,NULL),(30,'Founder','Founder rate',NULL,20.00,0.00,NULL);
