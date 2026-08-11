CREATE TABLE `parametro_coleta` (
  `ide_parametro_coleta` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ide_tipo_parametro` int(10) unsigned NOT NULL,
  `exigido` varchar(45) NOT NULL,
  `analisado` varchar(45) NOT NULL,
  `conformidade` varchar(45) NOT NULL,
  `data` date NOT NULL,
  PRIMARY KEY (`ide_parametro_coleta`)
) ENGINE=InnoDB AUTO_INCREMENT=660 DEFAULT CHARSET=latin1;

INSERT INTO `parametro_coleta` VALUES (143,5,'10','5','5','2019-01-01'),(144,4,'10','5','5','2019-01-01'),(145,3,'10','5','5','2019-01-01');
