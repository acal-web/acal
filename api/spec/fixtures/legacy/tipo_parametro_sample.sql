CREATE TABLE `tipo_parametro` (
  `ide_tipo_parametro` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nom_parametro` varchar(45) NOT NULL,
  PRIMARY KEY (`ide_tipo_parametro`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;

INSERT INTO `tipo_parametro` VALUES (1,'Cor aparente - 15UH'),(2,'Turbidez - 5.0 UT'),(3,'Cloro - Min 0,2 mg/l'),(4,'Eschirichia Coli'),(5,'Coliformes Totais');
