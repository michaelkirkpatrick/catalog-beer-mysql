CREATE TABLE `algolia` (
  `algolia_id` varchar(36) NOT NULL,
  `beer_id` varchar(36) DEFAULT NULL,
  `brewer_id` varchar(36) DEFAULT NULL,
  `location_id` varchar(36) DEFAULT NULL,
  PRIMARY KEY (`algolia_id`),
  KEY `idx_beer_id` (`beer_id`),
  KEY `idx_brewer_id` (`brewer_id`),
  KEY `idx_location_id` (`location_id`),
  CONSTRAINT `algolia_ibfk_1` FOREIGN KEY (`beer_id`) REFERENCES `beer` (`id`) ON DELETE CASCADE,
  CONSTRAINT `algolia_ibfk_2` FOREIGN KEY (`brewer_id`) REFERENCES `brewer` (`id`) ON DELETE CASCADE,
  CONSTRAINT `algolia_ibfk_3` FOREIGN KEY (`location_id`) REFERENCES `location` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `api_keys` (
  `id` varchar(36) NOT NULL,
  `userID` varchar(36) NOT NULL,
  `requestLimit` int NOT NULL DEFAULT '1000',
  `requestBuffer` int NOT NULL DEFAULT '50',
  PRIMARY KEY (`id`),
  KEY `fk_userID` (`userID`) USING BTREE,
  CONSTRAINT `api_keys_ibfk_1` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `api_logging` (
  `id` varchar(36) NOT NULL,
  `apiKey` varchar(36) DEFAULT NULL,
  `timestamp` int DEFAULT NULL,
  `ipAddress` varchar(45) DEFAULT NULL,
  `method` varchar(6) DEFAULT NULL,
  `uri` varchar(255) DEFAULT NULL,
  `body` text,
  `response` text,
  `responseCode` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `api_usage` (
  `id` varchar(36) NOT NULL,
  `apiKey` varchar(36) NOT NULL,
  `year` smallint NOT NULL,
  `month` tinyint NOT NULL,
  `count` int NOT NULL,
  `lastUpdated` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_apiKey_year_month` (`apiKey`,`year`,`month`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `beer` (
  `id` varchar(36) NOT NULL,
  `brewerID` varchar(36) NOT NULL,
  `name` varchar(255) NOT NULL,
  `style` varchar(255) NOT NULL,
  `style_id` varchar(64) DEFAULT NULL,
  `parent` varchar(64) DEFAULT NULL,
  `class` varchar(64) DEFAULT NULL,
  `style_label` varchar(255) DEFAULT NULL,
  `beverage_type` enum('beer','cider','perry','mead') NOT NULL DEFAULT 'beer',
  `style_confidence` varchar(16) DEFAULT NULL,
  `description` text,
  `abv` decimal(4,1) NOT NULL,
  `ibu` int DEFAULT NULL,
  `cbVerified` bit(1) NOT NULL DEFAULT b'0',
  `brewerVerified` bit(1) NOT NULL DEFAULT b'0',
  `lastModified` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_brewerID` (`brewerID`) USING BTREE,
  KEY `idx_beverage_type` (`beverage_type`),
  KEY `idx_parent` (`parent`),
  KEY `idx_class` (`class`),
  KEY `fk_beer_style` (`style_id`),
  FULLTEXT KEY `ft_beer_search` (`name`,`style_label`,`description`),
  CONSTRAINT `beer_ibfk_1` FOREIGN KEY (`brewerID`) REFERENCES `brewer` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_beer_class` FOREIGN KEY (`class`) REFERENCES `style_class` (`slug`),
  CONSTRAINT `fk_beer_parent` FOREIGN KEY (`parent`) REFERENCES `style_parent` (`slug`),
  CONSTRAINT `fk_beer_style` FOREIGN KEY (`style_id`) REFERENCES `style` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `brewer` (
  `id` varchar(36) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `shortDescription` varchar(160) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `domainName` varchar(255) DEFAULT NULL,
  `cbVerified` bit(1) NOT NULL DEFAULT b'0',
  `brewerVerified` bit(1) NOT NULL DEFAULT b'0',
  `lastModified` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_url` (`url`) USING BTREE,
  UNIQUE KEY `unique_domain` (`domainName`) USING BTREE,
  FULLTEXT KEY `ft_brewer_search` (`name`,`description`,`shortDescription`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `error_log` (
  `id` varchar(36) NOT NULL,
  `errorNumber` varchar(255) DEFAULT NULL,
  `errorMessage` text,
  `badData` blob,
  `userID` varchar(36) DEFAULT NULL,
  `URI` varchar(255) DEFAULT NULL,
  `ipAddress` varchar(45) DEFAULT NULL,
  `timestamp` int DEFAULT NULL,
  `filename` varchar(255) DEFAULT NULL,
  `resolved` bit(1) DEFAULT b'0',
  PRIMARY KEY (`id`),
  KEY `fk_userID` (`userID`) USING BTREE,
  KEY `idx_resolved_timestamp` (`resolved`,`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `location` (
  `id` varchar(36) NOT NULL,
  `brewerID` varchar(36) NOT NULL,
  `name` varchar(255) NOT NULL,
  `url` varchar(255) DEFAULT NULL,
  `countryCode` varchar(2) NOT NULL,
  `latitude` float(9,7) DEFAULT NULL,
  `longitude` float(10,7) DEFAULT NULL,
  `cbVerified` bit(1) NOT NULL DEFAULT b'0',
  `brewerVerified` bit(1) NOT NULL DEFAULT b'0',
  `lastModified` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_brewerID` (`brewerID`),
  CONSTRAINT `fk_brewerID` FOREIGN KEY (`brewerID`) REFERENCES `brewer` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `privileges` (
  `id` varchar(36) NOT NULL,
  `userID` varchar(36) NOT NULL,
  `brewerID` varchar(36) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_userID` (`userID`) USING BTREE,
  KEY `fk_brewerID` (`brewerID`) USING BTREE,
  CONSTRAINT `privileges_ibfk_1` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `privileges_ibfk_2` FOREIGN KEY (`brewerID`) REFERENCES `brewer` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `subdivisions` (
  `sub_code` varchar(5) NOT NULL,
  `sub_name` varchar(255) NOT NULL,
  PRIMARY KEY (`sub_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `US_addresses` (
  `locationID` varchar(36) NOT NULL,
  `address1` varchar(255) DEFAULT NULL,
  `address2` varchar(255) NOT NULL,
  `city` varchar(255) NOT NULL,
  `sub_code` varchar(5) NOT NULL,
  `zip5` int NOT NULL,
  `zip4` int DEFAULT NULL,
  `telephone` bigint DEFAULT NULL,
  PRIMARY KEY (`locationID`),
  KEY `fk_sub_code` (`sub_code`),
  CONSTRAINT `fk_locationID` FOREIGN KEY (`locationID`) REFERENCES `location` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sub_code` FOREIGN KEY (`sub_code`) REFERENCES `subdivisions` (`sub_code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `users` (
  `id` varchar(36) NOT NULL,
  `email` varchar(255) NOT NULL,
  `passwordHash` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `emailVerified` bit(1) NOT NULL DEFAULT b'0',
  `emailAuth` varchar(36) DEFAULT NULL,
  `emailAuthSent` int DEFAULT NULL,
  `passwordResetSent` int DEFAULT NULL,
  `passwordResetKey` varchar(36) DEFAULT NULL,
  `admin` bit(1) NOT NULL DEFAULT b'0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_email` (`email`) USING BTREE,
  UNIQUE KEY `unique_passwordResetKey` (`passwordResetKey`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `style_class` (
  `slug` varchar(64) NOT NULL,
  `name` varchar(255) NOT NULL,
  `beverage_type` enum('beer','cider','perry','mead') NOT NULL DEFAULT 'beer',
  `sort_order` int DEFAULT NULL,
  PRIMARY KEY (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `style_parent` (
  `slug` varchar(64) NOT NULL,
  `name` varchar(255) NOT NULL,
  `beverage_type` enum('beer','cider','perry','mead') NOT NULL DEFAULT 'beer',
  `class` varchar(64) DEFAULT NULL,
  `description` text,
  `sort_order` int DEFAULT NULL,
  PRIMARY KEY (`slug`),
  KEY `idx_beverage_type` (`beverage_type`),
  KEY `idx_class` (`class`),
  CONSTRAINT `fk_parent_class` FOREIGN KEY (`class`) REFERENCES `style_class` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `style` (
  `id` varchar(64) NOT NULL,
  `canonical_name` varchar(255) NOT NULL,
  `beverage_type` enum('beer','cider','perry','mead') NOT NULL DEFAULT 'beer',
  `parent` varchar(64) NOT NULL,
  `source` varchar(32) NOT NULL,
  `is_catch_all` tinyint(1) NOT NULL DEFAULT '0',
  `abv_min` decimal(4,1) DEFAULT NULL,
  `abv_max` decimal(4,1) DEFAULT NULL,
  `ibu_min` int DEFAULT NULL,
  `ibu_max` int DEFAULT NULL,
  `srm_min` decimal(4,1) DEFAULT NULL,
  `srm_max` decimal(4,1) DEFAULT NULL,
  `og_min` decimal(5,3) DEFAULT NULL,
  `og_max` decimal(5,3) DEFAULT NULL,
  `fg_min` decimal(5,3) DEFAULT NULL,
  `fg_max` decimal(5,3) DEFAULT NULL,
  `sort_order` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_beverage_type` (`beverage_type`),
  KEY `idx_parent` (`parent`),
  CONSTRAINT `fk_style_parent` FOREIGN KEY (`parent`) REFERENCES `style_parent` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `style_alias` (
  `alias` varchar(255) NOT NULL,
  `style_id` varchar(64) NOT NULL,
  PRIMARY KEY (`alias`),
  KEY `fk_style_alias_style` (`style_id`),
  CONSTRAINT `fk_style_alias_style` FOREIGN KEY (`style_id`) REFERENCES `style` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `parent_alias` (
  `alias` varchar(255) NOT NULL,
  `parent` varchar(64) NOT NULL,
  PRIMARY KEY (`alias`),
  KEY `fk_parent_alias_parent` (`parent`),
  CONSTRAINT `fk_parent_alias_parent` FOREIGN KEY (`parent`) REFERENCES `style_parent` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `class_alias` (
  `alias` varchar(255) NOT NULL,
  `class` varchar(64) NOT NULL,
  PRIMARY KEY (`alias`),
  KEY `fk_class_alias_class` (`class`),
  CONSTRAINT `fk_class_alias_class` FOREIGN KEY (`class`) REFERENCES `style_class` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `style_alias_approx` (
  `alias` varchar(255) NOT NULL,
  `style_id` varchar(64) NOT NULL,
  PRIMARY KEY (`alias`),
  KEY `fk_style_alias_approx_style` (`style_id`),
  CONSTRAINT `fk_style_alias_approx_style` FOREIGN KEY (`style_id`) REFERENCES `style` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `style_meta` (
  `id` tinyint NOT NULL DEFAULT '1',
  `version` varchar(32) NOT NULL,
  `last_updated` varchar(32) NOT NULL,
  `seeded_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `chk_style_meta_single` CHECK ((`id` = 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
