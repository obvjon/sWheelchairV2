CREATE TABLE IF NOT EXISTS `wheelchair_sentences` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL,
    `release_time` INT UNSIGNED NOT NULL COMMENT 'UNIX timestamp of when the sentence ends',
    `active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = active sentence, 0 = cleared or expired',

    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    INDEX `idx_identifier_active` (`identifier`, `active`),
    INDEX `idx_release_time` (`release_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
