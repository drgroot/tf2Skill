# ************************************************************
# Sequel Pro SQL dump
# Version 4096
#
# http://www.sequelpro.com/
# http://code.google.com/p/sequel-pro/
#
# Host: localhost (MySQL 5.5.38-0+wheezy1)
# Database: rankingsystem
# Generation Time: 2014-10-08 20:34:35 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table player_stats
# ------------------------------------------------------------

DROP TABLE IF EXISTS `player_stats`;

CREATE TABLE `player_stats` (
  `stat_id` tinytext NOT NULL,
  `steamID` tinytext NOT NULL,
  `roles` int(11) NOT NULL,
  `kills` int(11) NOT NULL DEFAULT '0',
  `deaths` int(11) NOT NULL DEFAULT '0',
  UNIQUE KEY `stat_id` (`stat_id`(100)),
  KEY `steamID` (`steamID`(100))
) ENGINE=MyISAM DEFAULT CHARSET=latin1;



# Dump of table players
# ------------------------------------------------------------

DROP TABLE IF EXISTS `players`;

CREATE TABLE `players` (
  `player_id` int(11) NOT NULL AUTO_INCREMENT,
  `steamID` text NOT NULL,
  `lastConnect` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `mew` decimal(20,17) NOT NULL DEFAULT '25.00000000000000000',
  `sigma` decimal(20,17) NOT NULL DEFAULT '8.33330000000000000',
  `rank` decimal(20,15) NOT NULL DEFAULT '-100.000000000000000',
  `name` text,
  `averageRank` decimal(15,10) DEFAULT '1.0000000000',
  PRIMARY KEY (`player_id`),
  UNIQUE KEY `steamID` (`steamID`(100))
) ENGINE=MyISAM DEFAULT CHARSET=latin1;



# Dump of table temp
# ------------------------------------------------------------

DROP TABLE IF EXISTS `temp`;

CREATE TABLE `temp` (
  `steamid` mediumtext NOT NULL,
  `time_blue` decimal(11,10) NOT NULL,
  `time_red` decimal(11,10) NOT NULL,
  `result` int(1) NOT NULL,
  `random` int(6) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
