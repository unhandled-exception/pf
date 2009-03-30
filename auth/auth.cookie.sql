CREATE TABLE `users` (
  `login` varchar(100) NOT NULL default '',
  `password` varchar(41) default NULL,
  `is_active` enum('0','1') NOT NULL default '1',
  `dt_last_login` datetime default NULL,
  `dt_last_visit` datetime default NULL,
  `dt_last_logoff` datetime default NULL,
  PRIMARY KEY  (`login`)
) ENGINE=MyISAM;

CREATE TABLE `sessions` (
  `uid` varchar(64) NOT NULL default '',
  `sid` varchar(64) NOT NULL default '',
  `login` varchar(100) NOT NULL default '',
  `dt_create` datetime default NULL,
  `dt_access` datetime default NULL,
  `dt_close` datetime default NULL,
  `is_active` enum('0','1') NOT NULL default '1',
  `ip` int(10) unsigned default NULL,
  `is_persistent` enum('0','1') NOT NULL default '0',
  PRIMARY KEY  (`uid`,`sid`)
) ENGINE=MyISAM;