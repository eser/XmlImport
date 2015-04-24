/*
Navicat MariaDB Data Transfer

Source Server         : local-maria
Source Server Version : 50542
Source Host           : localhost:3306
Source Database       : localhost

Target Server Type    : MariaDB
Target Server Version : 50542
File Encoding         : 65001

Date: 2015-04-22 01:32:36
*/

-- ----------------------------
-- Table structure for XmlImport
-- ----------------------------
DROP TABLE IF EXISTS `XmlImport`;
CREATE TABLE `XmlImport` (
  `ItemId`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
  `AdapterId`  int(10) UNSIGNED NOT NULL ,
  `Checksum`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `Status`  int(10) UNSIGNED NOT NULL ,
  `LastUpdate`  datetime NOT NULL ,
  `RemoteId`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `RemoteUrl`  varchar(2048) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `RemoteSKU`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `RemoteBarcode`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `Brand`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `Model`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `RemoteCategoryId1`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `RemoteCategoryName1`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `RemoteCategoryId2`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `RemoteCategoryName2`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `RemoteCategoryId3`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `RemoteCategoryName3`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `RemoteCategoryId4`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `RemoteCategoryName4`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `Name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `ShortDescription`  text CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `LongDescription`  text CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `Price`  decimal(10,4) NOT NULL ,
  `DiscountedPrice`  decimal(10,4) NOT NULL ,
  `VAT`  int(10) UNSIGNED NOT NULL ,
  `Currency`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `Quantity`  int(10) UNSIGNED NOT NULL ,
  `Minimum`  int(10) UNSIGNED NOT NULL ,
  `Images`  text CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `Options`  text CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `Attributes`  text CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `Type`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `AttributeSet`  int(10) UNSIGNED NOT NULL ,
  `VendorCode`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  `VendorProfile`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  PRIMARY KEY (`ItemId`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci;


-- ----------------------------
-- Table structure for XmlImportImages
-- ----------------------------
DROP TABLE IF EXISTS `XmlImportImages`;
CREATE TABLE `XmlImportImages` (
  `ImageId`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
  `ItemId`  int(10) UNSIGNED NOT NULL ,
  `Url`  varchar(2048) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
  PRIMARY KEY (`ImageId`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci;

DROP FUNCTION XmlImportUpsertValue;
CREATE FUNCTION XmlImportUpsertValue(attribute_id INT, name VARCHAR(255)) RETURNS INT
  DETERMINISTIC
BEGIN
  DECLARE ReturnId INT;

  SELECT
    aov.`option_id` INTO ReturnId
  FROM
    `mweav_attribute` a
    INNER JOIN `mweav_attribute_option` ao ON a.`attribute_id` = ao.`attribute_id`
    INNER JOIN `mweav_attribute_option_value` aov ON ao.`option_id` = aov.`option_id`
  WHERE
    a.`attribute_id` = attribute_id AND aov.`value` LIKE name AND aov.`store_id` = 0
  LIMIT 1;

  IF ReturnId IS NULL THEN
    INSERT INTO `mweav_attribute_option` VALUES (NULL, attribute_id, 0);
    SELECT LAST_INSERT_ID() INTO ReturnId;
    INSERT INTO `mweav_attribute_option_value` VALUES (NULL, ReturnId, 0, name);
  END IF;

  RETURN (ReturnId);
END;
