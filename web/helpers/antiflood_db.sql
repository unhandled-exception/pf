CREATE  TABLE IF NOT EXISTS `antiflood` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `salt` BIGINT UNSIGNED NOT NULL ,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ,
  `processed_at` TIMESTAMP NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `idx_created_at` (`created_at` ASC) )
ENGINE = InnoDB;