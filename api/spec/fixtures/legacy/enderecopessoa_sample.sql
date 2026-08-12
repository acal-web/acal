CREATE TABLE `enderecopessoa` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Numero` varchar(255) NOT NULL,
  `idEndereco` int(11) NOT NULL,
  `idPessoa` int(11) NOT NULL,
  `datamatricula` date,
  `idCategoriaSocio` int(11) NOT NULL,
  `inativo` bit(1) NOT NULL DEFAULT b'0',
  `socioExclusivo` bit(1) NOT NULL DEFAULT b'0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=latin1;

INSERT INTO `enderecopessoa` VALUES
(1,'123',1,1,'2024-01-15',1,'\0','\0'),
(2,'456',1,2,'2024-02-20',1,'\0','\x01'),
(3,'123',1,3,NULL,1,'\x01','\0'),
(4,'Umbaumba',2,4,'2024-03-10',2,'\0','\0'),
(5,'789',1,99,'2024-01-15',1,'\0','\0'),
(6,'999',99,5,'2024-04-01',2,'\x01','\0'),
(7,'111',4,6,NULL,99,'\0','\0'),
(8,'200',1,7,'2024-05-10',2,'\0','\0'),
(9,'123',2,8,'2024-06-15',1,'\0','\0');
