-- Adminer 5.5.1 MySQL 8.0.42-0ubuntu0.20.04.1 dump

SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

SET NAMES utf8mb4;

DROP TABLE IF EXISTS `patients`;
CREATE TABLE `patients` (
  `id` int NOT NULL AUTO_INCREMENT,
  `parentId` int NOT NULL COMMENT 'Owner Registration ID',
  `patient_code` varchar(50) NOT NULL,
  `profile_image` varchar(255) DEFAULT NULL,
  `full_name` varchar(255) NOT NULL,
  `age` int DEFAULT NULL,
  `gender` enum('Male','Female','Other') DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `address` text,
  `medical_conditions` json DEFAULT NULL,
  `emergency_contact_name` varchar(255) DEFAULT NULL,
  `emergency_contact_phone` varchar(20) DEFAULT NULL,
  `total_visits` int DEFAULT '0',
  `last_visit_date` date DEFAULT NULL,
  `created_by` int DEFAULT NULL,
  `status` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_parentId` (`parentId`),
  KEY `idx_phone` (`phone`),
  KEY `idx_patient_code` (`patient_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `payments`;
CREATE TABLE `payments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `parentId` int NOT NULL,
  `visit_id` int NOT NULL,
  `patient_id` int NOT NULL,
  `invoice_no` varchar(50) NOT NULL,
  `subtotal` decimal(10,2) DEFAULT '0.00',
  `discount` decimal(10,2) DEFAULT '0.00',
  `total_amount` decimal(10,2) NOT NULL,
  `paid_amount` decimal(10,2) DEFAULT '0.00',
  `pending_amount` decimal(10,2) DEFAULT '0.00',
  `payment_method` enum('Cash','UPI','Card','Bank Transfer') DEFAULT 'Cash',
  `payment_status` enum('Paid','Partial','Pending') DEFAULT 'Pending',
  `payment_date` datetime DEFAULT NULL,
  `remarks` text,
  `created_by` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_parentId` (`parentId`),
  KEY `idx_visit` (`visit_id`),
  KEY `idx_patient` (`patient_id`),
  KEY `idx_invoice` (`invoice_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `registration`;
CREATE TABLE `registration` (
  `id` int NOT NULL AUTO_INCREMENT,
  `userName` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `userEmail` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `userMobile` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `country` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reg_date` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `validity` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `purchase_date` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `purchase_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `flag` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT '0',
  `parentId` int DEFAULT NULL,
  `status` tinyint(1) DEFAULT '1',
  `access_key` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_parentId` (`parentId`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `visits`;
CREATE TABLE `visits` (
  `id` int NOT NULL AUTO_INCREMENT,
  `parentId` int NOT NULL,
  `patient_id` int NOT NULL,
  `doctor_id` int NOT NULL,
  `visit_no` int NOT NULL,
  `visit_date` datetime NOT NULL,
  `chief_complaint_text` text,
  `chief_complaint_images` json DEFAULT NULL,
  `clinical_findings_text` text,
  `clinical_findings_images` json DEFAULT NULL,
  `lab_text` text,
  `lab_images` json DEFAULT NULL,
  `advised_treatment_text` text,
  `advised_treatment_images` json DEFAULT NULL,
  `treatment_done_text` text,
  `treatment_done_images` json DEFAULT NULL,
  `medication_text` text,
  `medication_images` json DEFAULT NULL,
  `next_appointment_date` date DEFAULT NULL,
  `notes` text,
  `status` enum('Pending','Completed','Cancelled') DEFAULT 'Completed',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_parentId` (`parentId`),
  KEY `idx_patient` (`patient_id`),
  KEY `idx_doctor` (`doctor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `company`;
CREATE TABLE `company` (
  `id` int NOT NULL AUTO_INCREMENT,
  `userId` int NOT NULL,
  `companyName` varchar(255) NOT NULL,
  `companyAddress` text NOT NULL,
  `clinic_reg_no` varchar(150) DEFAULT NULL,
  `pollution_control_cert` varchar(150) DEFAULT NULL,
  `trade_license` varchar(150) DEFAULT NULL,
  `municipality_noc` varchar(150) DEFAULT NULL,
  `doctor_reg_cert` varchar(150) DEFAULT NULL,
  `terms` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_userId` (`userId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `appointments`;
CREATE TABLE `appointments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `visit_id` int DEFAULT NULL,
  `patient_id` int NOT NULL,
  `doctor_id` int NOT NULL,
  `appointment_date` datetime NOT NULL,
  `procedure_text` text,
  `status` varchar(50) DEFAULT 'Pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_patient` (`patient_id`),
  KEY `idx_doctor` (`doctor_id`),
  KEY `idx_visit` (`visit_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- -------------------------------------------------------------
-- MIGRATION ALTER SQL FOR EXISTING DATABASES:
-- Execute the following command on production database if upgrading:
-- -------------------------------------------------------------
--ALTER TABLE `company` DROP COLUMN `gst`;
--ALTER TABLE `company` CHANGE COLUMN `dlNo` `clinic_reg_no` varchar(150) DEFAULT NULL;
--ALTER TABLE `company` ADD COLUMN `pollution_control_cert` varchar(150) DEFAULT NULL AFTER `clinic_reg_no`;
--ALTER TABLE `company` ADD COLUMN `trade_license` varchar(150) DEFAULT NULL AFTER `pollution_control_cert`;
--ALTER TABLE `company` ADD COLUMN `municipality_noc` varchar(150) DEFAULT NULL AFTER `trade_license`;
--ALTER TABLE `company` ADD COLUMN `doctor_reg_cert` varchar(150) DEFAULT NULL AFTER `municipality_noc`;
-- -------------------------------------------------------------

