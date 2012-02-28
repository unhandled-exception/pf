CREATE TABLE `roles` (
  `role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `name` VARCHAR(100) NULL ,
  `permissions` TEXT NULL ,
  `description` TEXT NULL ,
  `is_active` ENUM('0','1') NOT NULL DEFAULT 1 ,
  `sort_order` INT NOT NULL DEFAULT 0 ,
  PRIMARY KEY (`role_id`)
);

CREATE TABLE `roles_to_users` (
  `user_id` INT UNSIGNED NOT NULL ,
  `role_id` INT UNSIGNED NOT NULL ,
  PRIMARY KEY (`user_id`, `role_id`)
);
