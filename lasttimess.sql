-- MySQL dump 10.13  Distrib 8.0.19, for Win64 (x86_64)
--
-- Host: open-rds.c7koouq2ob0m.us-east-1.rds.amazonaws.com    Database: testdb
-- ------------------------------------------------------
-- Server version	8.0.42

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Table structure for table `appointment_requests`
--

DROP TABLE IF EXISTS `appointment_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `appointment_requests` (
  `id` int NOT NULL AUTO_INCREMENT,
  `patient_id` int NOT NULL,
  `requested_date` date NOT NULL,
  `requested_time_slot` varchar(255) DEFAULT NULL,
  `treatment` varchar(255) NOT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'NEW',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_appt_req_patient` (`patient_id`),
  CONSTRAINT `fk_appt_req_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `appointment_requests`
--

LOCK TABLES `appointment_requests` WRITE;
/*!40000 ALTER TABLE `appointment_requests` DISABLE KEYS */;
INSERT INTO `appointment_requests` VALUES (1,1,'2025-10-31','10:00-11:00','อื่นๆ','test','CANCELLED','2025-10-30 19:56:14'),(2,1,'2025-10-31','16:00-17:00','อื่นๆ','eee','NEW','2025-10-30 20:01:40'),(3,1,'2025-10-31','13:00-14:00','Tooth Filling (Composite)','2','NEW','2025-10-30 20:09:12'),(4,1,'2025-11-08','10:00-11:00','Tooth Extraction','te','NEW','2025-10-30 20:17:50');
/*!40000 ALTER TABLE `appointment_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `appointments`
--

DROP TABLE IF EXISTS `appointments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `appointments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `patient_id` int NOT NULL,
  `dentist_id` int NOT NULL,
  `unit_id` int NOT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime NOT NULL,
  `status` varchar(255) NOT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `from_request_id` int DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `date` date DEFAULT NULL,
  `slot_text` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `from_request_id` (`from_request_id`),
  KEY `fk_appt_patient` (`patient_id`),
  KEY `fk_appt_dentist` (`dentist_id`),
  KEY `fk_appt_unit` (`unit_id`),
  CONSTRAINT `fk_appt_dentist` FOREIGN KEY (`dentist_id`) REFERENCES `dentists` (`id`),
  CONSTRAINT `fk_appt_from_req` FOREIGN KEY (`from_request_id`) REFERENCES `appointment_requests` (`id`),
  CONSTRAINT `fk_appt_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`id`),
  CONSTRAINT `fk_appt_unit` FOREIGN KEY (`unit_id`) REFERENCES `dental_units` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `appointments`
--

LOCK TABLES `appointments` WRITE;
/*!40000 ALTER TABLE `appointments` DISABLE KEYS */;
/*!40000 ALTER TABLE `appointments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dental_units`
--

DROP TABLE IF EXISTS `dental_units`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dental_units` (
  `id` int NOT NULL AUTO_INCREMENT,
  `unit_name` varchar(255) NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dental_units`
--

LOCK TABLES `dental_units` WRITE;
/*!40000 ALTER TABLE `dental_units` DISABLE KEYS */;
INSERT INTO `dental_units` VALUES (1,'Test 1','ACTIVE'),(6,'Test3','ACTIVE');
/*!40000 ALTER TABLE `dental_units` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dentist_schedules`
--

DROP TABLE IF EXISTS `dentist_schedules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dentist_schedules` (
  `id` int NOT NULL AUTO_INCREMENT,
  `dentist_id` int NOT NULL,
  `schedule_date` date NOT NULL,
  `time_slot` varchar(255) NOT NULL,
  `unit_id` int NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'AVAILABLE',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_ds_dentist` (`dentist_id`),
  KEY `fk_ds_unit` (`unit_id`),
  CONSTRAINT `fk_ds_dentist` FOREIGN KEY (`dentist_id`) REFERENCES `dentists` (`id`),
  CONSTRAINT `fk_ds_unit` FOREIGN KEY (`unit_id`) REFERENCES `dental_units` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dentist_schedules`
--

LOCK TABLES `dentist_schedules` WRITE;
/*!40000 ALTER TABLE `dentist_schedules` DISABLE KEYS */;
INSERT INTO `dentist_schedules` VALUES (1,1,'2025-10-30','10:00-11:00',1,'AVAILABLE','2025-10-30 20:29:45','2025-10-30 20:29:45'),(2,1,'2025-10-30','11:00-12:00',1,'AVAILABLE','2025-10-30 20:29:46','2025-10-30 20:29:46'),(3,1,'2025-10-30','12:00-13:00',1,'AVAILABLE','2025-10-30 20:29:46','2025-10-30 20:29:46'),(4,1,'2025-10-30','13:00-14:00',1,'AVAILABLE','2025-10-30 20:29:47','2025-10-30 20:29:47'),(5,1,'2025-10-30','14:00-15:00',1,'AVAILABLE','2025-10-30 20:29:47','2025-10-30 20:29:47'),(6,1,'2025-10-30','15:00-16:00',1,'AVAILABLE','2025-10-30 20:29:48','2025-10-30 20:29:48'),(7,1,'2025-10-30','16:00-17:00',1,'AVAILABLE','2025-10-30 20:29:48','2025-10-30 20:29:48'),(8,1,'2025-10-30','17:00-18:00',1,'AVAILABLE','2025-10-30 20:29:49','2025-10-30 20:29:49'),(9,1,'2025-10-30','18:00-19:00',1,'AVAILABLE','2025-10-30 20:29:49','2025-10-30 20:29:49'),(28,1,'2025-10-31','10:00-11:00',6,'AVAILABLE','2025-10-30 20:46:56','2025-10-30 20:46:56'),(30,1,'2025-10-31','11:00-12:00',6,'AVAILABLE','2025-10-30 20:46:57','2025-10-30 20:46:57'),(31,1,'2025-10-31','12:00-13:00',6,'AVAILABLE','2025-10-30 20:46:57','2025-10-30 20:46:57'),(32,1,'2025-10-31','13:00-14:00',6,'AVAILABLE','2025-10-30 20:46:58','2025-10-30 20:46:58'),(34,1,'2025-10-31','14:00-15:00',6,'AVAILABLE','2025-10-30 20:46:58','2025-10-30 20:46:58'),(36,1,'2025-10-31','15:00-16:00',6,'AVAILABLE','2025-10-30 20:46:59','2025-10-30 20:46:59'),(41,1,'2025-10-31','16:00-17:00',6,'AVAILABLE','2025-10-30 20:46:59','2025-10-30 20:46:59'),(42,1,'2025-10-31','17:00-18:00',6,'AVAILABLE','2025-10-30 20:47:00','2025-10-30 20:47:00'),(47,1,'2025-10-31','18:00-19:00',6,'AVAILABLE','2025-10-30 20:47:00','2025-10-30 20:47:00');
/*!40000 ALTER TABLE `dentist_schedules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dentists`
--

DROP TABLE IF EXISTS `dentists`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dentists` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `license_number` varchar(255) NOT NULL,
  `pre_name` varchar(255) NOT NULL,
  `first_name` varchar(255) NOT NULL,
  `last_name` varchar(255) NOT NULL,
  `speciality` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_dentists_user_id` (`user_id`),
  UNIQUE KEY `uk_dentists_license` (`license_number`),
  CONSTRAINT `fk_dentists_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dentists`
--

LOCK TABLES `dentists` WRITE;
/*!40000 ALTER TABLE `dentists` DISABLE KEYS */;
INSERT INTO `dentists` VALUES (1,7,'22222222222222222222222222222','ทพ.','2','2',NULL,'2','222@gmail.com','','2025-10-30 19:26:00');
/*!40000 ALTER TABLE `dentists` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `patients`
--

DROP TABLE IF EXISTS `patients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `patients` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `pre_name` varchar(255) DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `gender` varchar(255) DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `race` varchar(255) DEFAULT NULL,
  `nationality` varchar(255) DEFAULT NULL,
  `religion` varchar(255) DEFAULT NULL,
  `drug_allergy` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_patients_user` (`user_id`),
  CONSTRAINT `fk_patients_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `patients`
--

LOCK TABLES `patients` WRITE;
/*!40000 ALTER TABLE `patients` DISABLE KEYS */;
INSERT INTO `patients` VALUES (1,1,'นาย','som','choon','ชาย','2025-10-07','1111111111','221@gmail.com','1','1','1','1','ไม่มี','2025-10-30 18:45:21');
/*!40000 ALTER TABLE `patients` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `visit_id` int DEFAULT NULL,
  `amount` double NOT NULL,
  `payment_method` varchar(255) DEFAULT NULL,
  `payment_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `staff_id` int DEFAULT NULL,
  `status` varchar(100) DEFAULT 'pending',
  PRIMARY KEY (`id`),
  KEY `fk_payments_visit` (`visit_id`),
  KEY `fk_payments_staff` (`staff_id`),
  CONSTRAINT `fk_payments_staff` FOREIGN KEY (`staff_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_payments_visit` FOREIGN KEY (`visit_id`) REFERENCES `visits` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payments`
--

LOCK TABLES `payments` WRITE;
/*!40000 ALTER TABLE `payments` DISABLE KEYS */;
INSERT INTO `payments` VALUES (5,5,550,NULL,'2025-10-30 23:54:34',7,'paid'),(6,6,200,NULL,'2025-10-30 23:54:31',7,'paid'),(7,7,3500,NULL,'2025-10-31 00:26:38',7,'pending'),(8,8,220,NULL,'2025-10-31 00:29:05',7,'pending'),(9,9,8050,NULL,'2025-10-31 00:31:48',7,'pending'),(10,10,300,NULL,'2025-10-31 00:38:35',7,'pending'),(11,11,50,NULL,'2025-10-31 00:46:50',7,'pending'),(12,12,300,NULL,'2025-10-31 01:00:16',7,'pending');
/*!40000 ALTER TABLE `payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `procedure_codes`
--

DROP TABLE IF EXISTS `procedure_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `procedure_codes` (
  `code` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `default_price` double DEFAULT NULL,
  `category` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `procedure_codes`
--

LOCK TABLES `procedure_codes` WRITE;
/*!40000 ALTER TABLE `procedure_codes` DISABLE KEYS */;
INSERT INTO `procedure_codes` VALUES ('CROWN_PFM','Crown (PFM)',12000,'Prosthodontic'),('EXTRACT','Tooth Extraction',1500,'Surgical'),('FILL_COMPOSITE','Tooth Filling (Composite)',1200,'Restorative'),('IMPL_CONS','Implant Consultation',500,'Consultation'),('ORTH_ADJ','Ortho Adjustment',1000,'Orthodontic'),('RCT_SINGLE','Root Canal (Single)',6000,'Endodontic'),('SCALING','Scaling & Polishing',800,'Cleaning'),('WHITEN','Teeth Whitening',5000,'Cosmetic');
/*!40000 ALTER TABLE `procedure_codes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `citizen_id` varchar(255) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `role` varchar(255) NOT NULL DEFAULT 'patient',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'1111111111111','$2b$10$aLNumllRJ63AasdOUrS61Oj.al.V9p0S4vtYkRYBma1nMAv1Z9.yi','patient','2025-10-30 18:45:21'),(7,'2222222222222','$2b$10$gfvk.2v9xJ8jYpLW0GLRseRfnZfDRpVobJOeWwgP5KWhSC53T7Cmi','dentist','2025-10-30 19:26:00'),(17,'3333333333333','$2b$10$AuIdSiyTkkQKHlNMpkDg4uWwRoG0d82PiiUayouIuw6bi09VrQ5mO','staff','2025-10-30 20:22:27');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `visits`
--

DROP TABLE IF EXISTS `visits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `visits` (
  `id` int NOT NULL AUTO_INCREMENT,
  `patient_id` int NOT NULL,
  `appointment_id` int DEFAULT NULL,
  `visit_date` datetime NOT NULL,
  `procedure_list` json DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `xray_s3_urls` json DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `doctor_name` varchar(100) DEFAULT NULL,
  `xray_images_list` text,
  `clinical_notes` varchar(100) DEFAULT NULL,
  `vital_signs` json DEFAULT NULL,
  `status` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT 'unpaid',
  PRIMARY KEY (`id`),
  KEY `fk_visits_patient` (`patient_id`),
  KEY `fk_visits_appointment` (`appointment_id`),
  CONSTRAINT `fk_visits_appointment` FOREIGN KEY (`appointment_id`) REFERENCES `appointments` (`id`),
  CONSTRAINT `fk_visits_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `visits`
--

LOCK TABLES `visits` WRITE;
/*!40000 ALTER TABLE `visits` DISABLE KEYS */;
INSERT INTO `visits` VALUES (5,1,NULL,'2025-10-31 06:39:00','[{\"qty\": 1, \"code\": \"EXTRACT\", \"tooth_no\": \"\", \"price_each\": 550, \"description\": \"Tooth Extraction\"}]','1111',NULL,'2025-10-30 23:39:51','ทพ.2 2','[]',NULL,'{\"bp_dia\": \"1\", \"bp_sys\": \"1\", \"pulse_rate\": \"1\"}','unpaid'),(6,1,NULL,'2025-10-31 06:54:00','[{\"qty\": 1, \"code\": \"IMPL_CONS\", \"tooth_no\": \"\", \"price_each\": 200, \"description\": \"Implant Consultation\"}]','4',NULL,'2025-10-30 23:54:13','ทพ.2 2','[]',NULL,'{\"bp_dia\": \"2\", \"bp_sys\": \"1\", \"pulse_rate\": \"3\"}','unpaid'),(7,1,NULL,'2025-10-31 07:26:00','[{\"qty\": 1, \"code\": \"BLEACH\", \"tooth_no\": \"\", \"price_each\": 3500, \"description\": \"ฟอกสีฟัน\"}]','121',NULL,'2025-10-31 00:26:38','ทพ.2 2','[\"public/uploads/xrays/xrays-1761870398433-835555285.png\"]',NULL,'{\"bp_dia\": \"12\", \"bp_sys\": \"12\", \"pulse_rate\": \"12\"}','unpaid'),(8,1,NULL,'2025-10-31 07:28:00','[{\"qty\": 1, \"code\": \"ORTH_ADJ\", \"tooth_no\": \"\", \"price_each\": 220, \"description\": \"Ortho Adjustment\"}]','12321',NULL,'2025-10-31 00:29:04','ทพ.2 2','[null]',NULL,'{\"bp_dia\": \"2\", \"bp_sys\": \"222\", \"pulse_rate\": \"22\"}','unpaid'),(9,1,NULL,'2025-10-31 07:30:00','[{\"qty\": 1, \"code\": \"RCT_SINGLE\", \"tooth_no\": \"\", \"price_each\": 50, \"description\": \"Root Canal (Single)\"}, {\"qty\": 1, \"code\": \"CROWN\", \"tooth_no\": \"\", \"price_each\": 8000, \"description\": \"ครอบฟัน\"}]','5555',NULL,'2025-10-31 00:31:48','ทพ.2 2','[null]',NULL,'{\"bp_dia\": \"555\", \"bp_sys\": \"555\", \"pulse_rate\": \"55\"}','unpaid'),(10,1,NULL,'2025-10-31 07:38:00','[{\"qty\": 1, \"code\": \"XRAY-SM\", \"tooth_no\": \"\", \"price_each\": 300, \"description\": \"เอ็กซเรย์ฟิล์มเล็ก\"}]','213',NULL,'2025-10-31 00:38:34','ทพ.2 2','[]',NULL,'{\"bp_dia\": \"12\", \"bp_sys\": \"12\", \"pulse_rate\": \"212\"}','unpaid'),(11,1,NULL,'2025-10-31 07:46:00','[{\"qty\": 1, \"code\": \"ORTH_ADJ\", \"tooth_no\": \"\", \"price_each\": 50, \"description\": \"Ortho Adjustment\"}]','123',NULL,'2025-10-31 00:46:49','ทพ.2 2','[]',NULL,'{\"bp_dia\": \"123\", \"bp_sys\": \"341\", \"pulse_rate\": \"123\"}','unpaid'),(12,1,NULL,'2025-10-31 08:00:00','[{\"qty\": 1, \"code\": \"XRAY-SM\", \"tooth_no\": \"\", \"price_each\": 300, \"description\": \"เอ็กซเรย์ฟิล์มเล็ก\"}]','111',NULL,'2025-10-31 01:00:15','ทพ.2 2','[]',NULL,'{\"bp_dia\": \"111\", \"bp_sys\": \"111\", \"pulse_rate\": \"111\"}','unpaid');
/*!40000 ALTER TABLE `visits` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'testdb'
--
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-10-31  8:07:10
