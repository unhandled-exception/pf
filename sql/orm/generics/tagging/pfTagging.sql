/* Структура табличек для MySQL */

CREATE TABLE `tags` (
  `tag_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` int(10) unsigned NOT NULL DEFAULT '0',
  `thread_id` int(10) unsigned NOT NULL DEFAULT '0',
  `title` varchar(125) NOT NULL,
  `slug` varchar(250) DEFAULT NULL,
  `description` text,
  `sort_order` int(11) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`tag_id`),
  KEY `tree` (`thread_id`,`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `tags_content` (
  `content_type_id` int(10) unsigned NOT NULL DEFAULT '0',
  `tag_id` int(10) unsigned NOT NULL,
  `content_id` int(10) unsigned NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`content_id`,`tag_id`,`content_type_id`),
  KEY `idx_tags` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `tags_counters` (
  `content_type_id` int(11) NOT NULL,
  `tag_id` int(10) unsigned NOT NULL,
  `count` int(10) unsigned NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`tag_id`,`content_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
