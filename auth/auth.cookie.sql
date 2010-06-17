CREATE TABLE  `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `login` varchar(100) NOT NULL DEFAULT '',
  `password` varchar(100) DEFAULT NULL,
  `is_active` enum('0','1') NOT NULL DEFAULT '1',
  `is_admin` enum('0','1') NOT NULL DEFAULT '0',
  `dt_last_login` datetime DEFAULT NULL,
  `dt_last_visit` datetime DEFAULT NULL,
  `dt_last_logoff` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `login_unique` (`login`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8

CREATE TABLE  `sessions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(64) NOT NULL DEFAULT '',
  `sid` varchar(64) NOT NULL DEFAULT '',
  `login` varchar(100) NOT NULL DEFAULT '',
  `dt_create` datetime DEFAULT NULL,
  `dt_access` datetime DEFAULT NULL,
  `dt_close` datetime DEFAULT NULL,
  `is_active` enum('0','1') NOT NULL DEFAULT '1',
  `ip` int(10) unsigned DEFAULT NULL,
  `is_persistent` enum('0','1') NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uid_sid_unique` (`uid`,`sid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8

