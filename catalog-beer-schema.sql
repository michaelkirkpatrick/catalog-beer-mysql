CREATE TABLE `api_keys` (
  `id` varchar(36) NOT NULL,
  `userID` varchar(36) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_userID` (`userID`) USING BTREE,
  CONSTRAINT `api_keys_ibfk_1` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `api_logging` (
  `id` varchar(36) NOT NULL,
  `apiKey` varchar(36) DEFAULT NULL,
  `timestamp` int(11) DEFAULT NULL,
  `ipAddress` varchar(45) DEFAULT NULL,
  `method` varchar(6) DEFAULT NULL,
  `uri` varchar(255) DEFAULT NULL,
  `body` text,
  `response` text,
  `responseCode` int(3) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `api_usage` (
  `id` varchar(36) NOT NULL,
  `apiKey` varchar(36) NOT NULL,
  `year` smallint(4) NOT NULL,
  `month` tinyint(2) NOT NULL,
  `count` int(11) NOT NULL,
  `lastUpdated` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `beer` (
  `id` varchar(36) NOT NULL,
  `brewerID` varchar(36) NOT NULL,
  `name` varchar(255) NOT NULL,
  `style` varchar(255) NOT NULL,
  `description` text,
  `abv` decimal(4,1) NOT NULL,
  `ibu` int(4) DEFAULT NULL,
  `cbVerified` bit(1) DEFAULT b'0',
  `brewerVerified` bit(1) DEFAULT b'0',
  `lastModified` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_brewerID` (`brewerID`) USING BTREE,
  CONSTRAINT `beer_ibfk_1` FOREIGN KEY (`brewerID`) REFERENCES `brewer` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `brewer` (
  `id` varchar(36) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `shortDescription` varchar(160) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `domainName` varchar(255) DEFAULT NULL,
  `cbVerified` bit(1) DEFAULT b'0',
  `brewerVerified` bit(1) DEFAULT b'0',
  `facebookURL` varchar(255) DEFAULT NULL,
  `twitterURL` varchar(255) DEFAULT NULL,
  `instagramURL` varchar(255) DEFAULT NULL,
  `lastModified` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_url` (`url`) USING BTREE,
  UNIQUE KEY `unique_domain` (`domainName`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `error_log` (
  `id` varchar(36) NOT NULL,
  `errorNumber` varchar(255) DEFAULT NULL,
  `errorMessage` text,
  `badData` blob,
  `userID` varchar(36) DEFAULT NULL,
  `URI` varchar(255) DEFAULT NULL,
  `ipAddress` varchar(45) DEFAULT NULL,
  `timestamp` int(11) DEFAULT NULL,
  `filename` varchar(255) DEFAULT NULL,
  `resolved` bit(1) DEFAULT b'0',
  PRIMARY KEY (`id`),
  KEY `fk_userID` (`userID`) USING BTREE,
  CONSTRAINT `error_log_ibfk_1` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `location` (
  `id` varchar(36) NOT NULL,
  `brewerID` varchar(36) NOT NULL,
  `name` varchar(255) NOT NULL,
  `url` varchar(255) DEFAULT NULL,
  `countryCode` varchar(2) NOT NULL,
  `latitude` float(9,7) DEFAULT NULL,
  `longitude` float(10,7) DEFAULT NULL,
  `cbVerified` bit(1) DEFAULT b'0',
  `brewerVerified` bit(1) DEFAULT b'0',
  `lastModified` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_brewerID` (`brewerID`),
  CONSTRAINT `fk_brewerID` FOREIGN KEY (`brewerID`) REFERENCES `brewer` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `privileges` (
  `id` varchar(36) NOT NULL,
  `userID` varchar(36) NOT NULL,
  `brewerID` varchar(36) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_userID` (`userID`) USING BTREE,
  KEY `fk_brewerID` (`brewerID`) USING BTREE,
  CONSTRAINT `privileges_ibfk_1` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `privileges_ibfk_2` FOREIGN KEY (`brewerID`) REFERENCES `brewer` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `subdivisions` (
  `sub_code` varchar(5) NOT NULL,
  `sub_name` varchar(255) NOT NULL,
  PRIMARY KEY (`sub_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `US_addresses` (
  `locationID` varchar(36) NOT NULL,
  `address1` varchar(255) DEFAULT NULL,
  `address2` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `sub_code` varchar(5) DEFAULT NULL,
  `zip5` int(5) DEFAULT NULL,
  `zip4` int(4) DEFAULT NULL,
  `telephone` bigint(10) DEFAULT NULL,
  PRIMARY KEY (`locationID`),
  KEY `fk_sub_code` (`sub_code`),
  CONSTRAINT `fk_locationID` FOREIGN KEY (`locationID`) REFERENCES `location` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sub_code` FOREIGN KEY (`sub_code`) REFERENCES `subdivisions` (`sub_code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `users` (
  `id` varchar(36) NOT NULL,
  `email` varchar(255) NOT NULL,
  `passwordHash` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `emailVerified` bit(1) NOT NULL DEFAULT b'0',
  `emailAuth` varchar(36) DEFAULT NULL,
  `emailAuthSent` int(11) DEFAULT NULL,
  `admin` bit(1) NOT NULL DEFAULT b'0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_email` (`email`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;