# ************************************************************
# Host: localhost
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
  `stat_id` varchar(23) NOT NULL DEFAULT '',
  `steamID` varchar(32) NOT NULL DEFAULT '',
  `roles` int(11) NOT NULL,
  `kills` int(11) NOT NULL DEFAULT '0',
  `deaths` int(11) NOT NULL DEFAULT '0',
  UNIQUE KEY `stat_id` (`stat_id`),
  KEY `steamID` (`steamID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;



# Dump of table players
# ------------------------------------------------------------

DROP TABLE IF EXISTS `players`;

CREATE TABLE `players` (
  `player_id` int(11) NOT NULL AUTO_INCREMENT,
  `steamID` varchar(20) NOT NULL DEFAULT '',
  `lastConnect` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mew` decimal(11,8) NOT NULL DEFAULT '25.00000000',
  `sigma` decimal(11,8) NOT NULL DEFAULT '8.33333333',
  `rank` decimal(11,8) NOT NULL DEFAULT '0.00000000',
  `name` text,
  PRIMARY KEY (`player_id`),
  UNIQUE KEY `steamID` (`steamID`)
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
