# ************************************************************
# Sequel Pro SQL dump
# Version 4541
#
# http://www.sequelpro.com/
# https://github.com/sequelpro/sequelpro
#
# Host: 127.0.0.1 (MySQL 5.7.20-0ubuntu0.16.04.1)
# Database: catalogbeer
# Generation Time: 2017-11-23 22:45:26 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table api_keys
# ------------------------------------------------------------

CREATE TABLE `api_keys` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `userID` varchar(36) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table api_logging
# ------------------------------------------------------------

CREATE TABLE `api_logging` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `apiKey` varchar(36) DEFAULT NULL,
  `timestamp` int(11) DEFAULT NULL,
  `ipAddress` varchar(45) DEFAULT NULL,
  `method` varchar(4) DEFAULT NULL,
  `uri` varchar(255) DEFAULT NULL,
  `body` text,
  `response` text,
  `responseCode` int(3) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table beer
# ------------------------------------------------------------

CREATE TABLE `beer` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `brewerID` varchar(36) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `style` varchar(255) DEFAULT NULL,
  `description` text,
  `abv` decimal(4,1) DEFAULT NULL,
  `ibu` int(4) DEFAULT NULL,
  `cbVerified` tinyint(1) DEFAULT '0',
  `brewerVerified` tinyint(1) DEFAULT '0',
  `lastModified` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table brewer
# ------------------------------------------------------------

CREATE TABLE `brewer` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `name` varchar(255) DEFAULT NULL,
  `description` text,
  `shortDescription` varchar(160) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `cbVerified` tinyint(1) DEFAULT '0',
  `brewerVerified` tinyint(1) DEFAULT '0',
  `facebookURL` varchar(255) DEFAULT NULL,
  `twitterURL` varchar(255) DEFAULT NULL,
  `instagramURL` varchar(255) DEFAULT NULL,
  `lastModified` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table error_log
# ------------------------------------------------------------

CREATE TABLE `error_log` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `errorNumber` varchar(255) DEFAULT NULL,
  `errorMessage` text,
  `badData` blob,
  `userID` varchar(36) DEFAULT NULL,
  `URI` varchar(255) DEFAULT NULL,
  `ipAddress` varchar(45) DEFAULT NULL,
  `timestamp` int(11) DEFAULT NULL,
  `filename` varchar(255) DEFAULT NULL,
  `resolved` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table location
# ------------------------------------------------------------

CREATE TABLE `location` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `brewerID` varchar(36) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `countryCode` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table privledges
# ------------------------------------------------------------

CREATE TABLE `privledges` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `userID` varchar(36) DEFAULT NULL,
  `brewerID` varchar(36) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table subdivisions
# ------------------------------------------------------------

CREATE TABLE `subdivisions` (
  `sub_code` varchar(5) NOT NULL DEFAULT '',
  `sub_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`sub_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table US_addresses
# ------------------------------------------------------------

CREATE TABLE `US_addresses` (
  `locationID` varchar(36) NOT NULL DEFAULT '',
  `address1` varchar(255) DEFAULT NULL,
  `address2` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `sub_code` varchar(5) DEFAULT NULL,
  `zip5` int(5) DEFAULT NULL,
  `zip4` int(4) DEFAULT NULL,
  `telephone` bigint(11) DEFAULT NULL,
  PRIMARY KEY (`locationID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table users
# ------------------------------------------------------------

CREATE TABLE `users` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `email` varchar(255) DEFAULT NULL,
  `passwordHash` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `emailAuth` varchar(36) DEFAULT NULL,
  `emailAuthSent` int(11) DEFAULT NULL,
  `emailVerified` tinyint(1) DEFAULT '0',
  `admin` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
