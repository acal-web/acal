CREATE TABLE `categoriasocio` (
  `id` int(11) NOT NULL,
  `nome` varchar(255),
  `descricao` text,
  `taxasId` int(11),
  `group_id` bigint(20)
);
INSERT INTO `categoriasocio` VALUES (1,'Normal','Regular member',5,2),(2,'Founder','Founder member',30,1),(3,'Temp NULL Group','No group assigned',1,NULL);
