# Create api_keys
# ------------------------------------------------------------

CREATE TABLE `api_keys` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `userID` varchar(36) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Create api_logging
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



# Create api_usage
# ------------------------------------------------------------

CREATE TABLE `api_usage` (
  `id` varchar(36) NOT NULL,
  `apiKey` varchar(36) DEFAULT NULL,
  `year` smallint(4) DEFAULT NULL,
  `month` tinyint(2) DEFAULT NULL,
  `count` int(11) DEFAULT NULL,
  `lastUpdated` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Create beer
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



# Create brewer
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



# Create error_log
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



# Create location
# ------------------------------------------------------------

CREATE TABLE `location` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `brewerID` varchar(36) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `countryCode` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Create privledges
# ------------------------------------------------------------

CREATE TABLE `privledges` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `userID` varchar(36) DEFAULT NULL,
  `brewerID` varchar(36) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Create subdivisions
# ------------------------------------------------------------

CREATE TABLE `subdivisions` (
  `sub_code` varchar(5) NOT NULL DEFAULT '',
  `sub_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`sub_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Create US_addresses
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



# Create users
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
