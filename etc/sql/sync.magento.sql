-- :adapter_id
-- :adapter_name
-- :attribute_set_id

SET @adapter_id = :adapter_id;
SET @adapter_name = :adapter_name;
SET @attribute_set_id = :attribute_set_id;

-- create temp table
DROP TABLE IF EXISTS `XmlImportEntities`;
CREATE TEMPORARY TABLE `XmlImportEntities` (
  `LocalId` INT NOT NULL,
  `SyncTag` VARCHAR(64) NOT NULL,
  `EntityId` INT,
  `Exists` INT NOT NULL,
  `Active` INT NOT NULL
);

INSERT INTO `XmlImportEntities`
SELECT
  xi.`ItemId` AS `LocalId`,
  COALESCE(p.`sku`, CONCAT(@adapter_name, '_', COALESCE(xi.`RemoteSKU`, xi.`RemoteId`))) AS `SyncTag`,
  vendor_product_id.`entity_id` AS `EntityId`,
  vendor_product_id.`entity_id` IS NOT NULL AS `Exists`,
  CASE WHEN product_status.`value` IS NULL OR product_status.`value`=1 THEN 1 ELSE 0 END AS `Active`
FROM
  `XmlImport` xi
  LEFT JOIN `mwcatalog_product_entity_varchar` vendor_product_id ON xi.`RemoteId`=vendor_product_id.`value` AND vendor_product_id.`attribute_id` = 176 AND vendor_product_id.`store_id` = 0
  LEFT JOIN `mwcatalog_product_entity` p ON vendor_product_id.`entity_id`=p.`entity_id` AND p.`attribute_set_id`=@attribute_set_id
  LEFT JOIN `mwcatalog_product_entity_int` product_status ON p.`entity_id`=product_status.`entity_id` AND vendor_product_id.`store_id` = 0
WHERE
  xi.`AdapterId` = @adapter_id;

-- disable existing entities first
UPDATE
  `mwcatalog_product_entity_int` ints
  INNER JOIN `mwcatalog_product_entity` p ON ints.`entity_id`=p.`entity_id` AND p.`attribute_set_id`=@attribute_set_id
SET
  ints.`value` = 6224
WHERE
  ints.`attribute_id` = 266 AND
  ints.`store_id` = 0;

-- update existing entities
UPDATE `mwcatalog_product_entity` p
INNER JOIN `XmlImportEntities` xie ON p.`entity_id`=xie.`EntityId` AND xie.`Active`=1
SET p.`updated_at`=NOW();

-- insert new entities
INSERT INTO `mwcatalog_product_entity`
SELECT
  NULL AS `entity_id`,
  4 AS `entity_type_id`,
  @attribute_set_id AS `attribute_set_id`,
  'simple' AS `type_id`,
  xie.`SyncTag` AS `sku`,
  0 AS `has_options`,
  0 AS `required_options`,
  NOW() AS `created_at`,
  NOW() AS `updated_at`
FROM 
  `XmlImportEntities` xie
WHERE
  xie.`Exists` = 0;

-- set entity_id of inserted entities
UPDATE
  `XmlImportEntities` xie
  LEFT JOIN `mwcatalog_product_entity` p ON xie.`SyncTag`=p.`sku`
SET
  xie.`EntityId`=p.`entity_id`
WHERE
  xie.`Exists` = 0;

-- update quantity
UPDATE
  `mwcataloginventory_stock_item` qty
  INNER JOIN `XmlImportEntities` xie ON qty.`product_id`=xie.`EntityId`
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
SET
  qty.`qty`=xi.Quantity,
  qty.`is_in_stock`=(xi.Quantity > 0)
WHERE
  xie.`Active` = 1;

-- insert quantity
INSERT INTO `mwcataloginventory_stock_item`
SELECT
  NULL AS `item_id`,
  xie.`EntityId` AS `product_id`,
  1 AS `stock_id`,
  xi.`Quantity` AS `qty`,
  0 AS `min_qty`,
  1 AS `use_config_min_qty`,
  0 AS `is_qty_decimal`,
  0 AS `backorders`,
  1 AS `use_config_backorders`,
  1 AS `min_sale_qty`,
  0 AS `use_config_min_sale_qty`,
  0 AS `max_sale_qty`,
  1 AS `use_config_max_sale_qty`,
  1 AS `is_in_stock`,
  NULL AS `low_stock_date`,
  NULL AS `notify_stock_qty`,
  1 AS `use_config_notify_stock_qty`,
  0 AS `manage_stock`,
  1 AS `use_config_manage_stock`,
  0 AS `stock_status_changed_automatically`,
  1 AS `use_config_qty_increments`,
  0 AS `qty_increments`,
  1 AS `use_config_enable_qty_increments`,
  0 AS `use_config_increments`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcataloginventory_stock_item` qty ON xie.`EntityId`=qty.`product_id`
WHERE
  qty.`product_id` IS NULL AND
  xie.`Active` = 1;

-- update ints
UPDATE
  `mwcatalog_product_entity_int` ints
  INNER JOIN `XmlImportEntities` xie ON ints.`entity_id`=xie.`EntityId`
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
SET
  ints.`value`=CASE ints.`attribute_id`
    WHEN 266 THEN IF(xi.`Status` = 1, 6223, 6222)
    WHEN 85 THEN CASE xi.`VAT`
      WHEN 18 THEN 2
      WHEN 8 THEN 6
      WHEN 10 THEN 7
      WHEN 1 THEN 8
    END
  END
WHERE
  ints.`attribute_id` IN (266) AND
  ints.`store_id` = 0 AND
  xie.`Active` = 1;

-- insert ints: remote id
INSERT INTO `mwcatalog_product_entity_int`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  176 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  xie.`SyncTag` AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_int` ints ON xie.`EntityId`=ints.`entity_id`
WHERE
  ints.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert ints: status
INSERT INTO `mwcatalog_product_entity_int`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  84 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  1 AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_int` ints ON xie.`EntityId`=ints.`entity_id`
WHERE
  ints.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert ints: tax class
INSERT INTO `mwcatalog_product_entity_int`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  85 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  CASE xi.`VAT`
    WHEN 18 THEN 2
    WHEN 8 THEN 6
    WHEN 10 THEN 7
    WHEN 1 THEN 8
  END AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_int` ints ON xie.`EntityId`=ints.`entity_id`
WHERE
  ints.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert ints: visibility
INSERT INTO `mwcatalog_product_entity_int`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  91 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  3808 AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_int` ints ON xie.`EntityId`=ints.`entity_id`
WHERE
  ints.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert ints: brand
INSERT INTO `mwcatalog_product_entity_int`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  159 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  XmlImportUpsertValue(159, xi.`Brand`) AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_int` ints ON xie.`EntityId`=ints.`entity_id`
WHERE
  ints.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert ints: category
INSERT INTO `mwcatalog_product_entity_int`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  195 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  XmlImportUpsertValue(195, xi.`RemoteCategoryName1`) AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_int` ints ON xie.`EntityId`=ints.`entity_id`
WHERE
  ints.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert ints: xml_updated
INSERT INTO `mwcatalog_product_entity_int`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  266 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  IF(xi.`Status` = 1, 6223, 6222) AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_int` ints ON xie.`EntityId`=ints.`entity_id`
WHERE
  ints.`value_id` IS NULL AND
  xie.`Active` = 1;

-- update decimals
UPDATE
  `mwcatalog_product_entity_decimal` decimals
  INNER JOIN `XmlImportEntities` xie ON decimals.`entity_id`=xie.`EntityId`
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
SET
  decimals.`value`=CASE decimals.attribute_id
    WHEN 64 THEN xi.`Price`
    WHEN 65 THEN xi.`DiscountedPrice`
  END
WHERE
  decimals.`attribute_id` IN (64, 65) AND decimals.`store_id` = 0 AND
  xie.`Active` = 1;

-- insert decimals: price
INSERT INTO `mwcatalog_product_entity_decimal`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  64 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  xi.`Price` AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_decimal` decimals ON xie.`EntityId`=decimals.`entity_id`
WHERE
  decimals.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert decimals: discounted price
INSERT INTO `mwcatalog_product_entity_decimal`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  65 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  xi.`DiscountedPrice` AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_decimal` decimals ON xie.`EntityId`=decimals.`entity_id`
WHERE
  decimals.`value_id` IS NULL AND
  xie.`Active` = 1;

-- delete decimals: discounted price
DELETE FROM `mwcatalog_product_entity_decimal`
WHERE `attribute_id` = 65 AND `value` = 0 AND `store_id` = 0;

-- update varchars
UPDATE
  `mwcatalog_product_entity_varchar` varchars
  INNER JOIN `XmlImportEntities` xie ON varchars.`entity_id`=xie.`EntityId`
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
SET
  varchars.`value`=CASE varchars.attribute_id
    WHEN 181 THEN xi.`RemoteBarcode`
  END
WHERE
  varchars.`attribute_id` IN (181) AND varchars.`store_id` = 0 AND
  xie.`Active` = 1;

-- insert varchars: name
INSERT INTO `mwcatalog_product_entity_varchar`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  60 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  xi.`Name` AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_varchar` varchars ON xie.`EntityId`=varchars.`entity_id`
WHERE
  varchars.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert varchars: description
INSERT INTO `mwcatalog_product_entity_varchar`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  61 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  xi.`LongDescription` AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_varchar` varchars ON xie.`EntityId`=varchars.`entity_id`
WHERE
  varchars.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert varchars: barcode
INSERT INTO `mwcatalog_product_entity_varchar`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  181 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  xi.`RemoteBarcode` AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_varchar` varchars ON xie.`EntityId`=varchars.`entity_id`
WHERE
  varchars.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert varchars: images
INSERT INTO `mwcatalog_product_entity_varchar`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  74 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  (SELECT xii.`Url` FROM `XmlImportImages` xii WHERE xii.`ItemId`=xie.`LocalId` ORDER BY xii.`ImageId` ASC LIMIT 0, 1) AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_varchar` varchars ON xie.`EntityId`=varchars.`entity_id`
WHERE
  varchars.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert varchars: small images
INSERT INTO `mwcatalog_product_entity_varchar`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  75 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  (SELECT xii.`Url` FROM `XmlImportImages` xii WHERE xii.`ItemId`=xie.`LocalId` ORDER BY xii.`ImageId` ASC LIMIT 0, 1) AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_varchar` varchars ON xie.`EntityId`=varchars.`entity_id`
WHERE
  varchars.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert varchars: thumbnails
INSERT INTO `mwcatalog_product_entity_varchar`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  76 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  (SELECT xii.`Url` FROM `XmlImportImages` xii WHERE xii.`ItemId`=xie.`LocalId` ORDER BY xii.`ImageId` ASC LIMIT 0, 1) AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_varchar` varchars ON xie.`EntityId`=varchars.`entity_id`
WHERE
  varchars.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert varchars: image labels
INSERT INTO `mwcatalog_product_entity_varchar`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  100 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  xi.`Name` AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_varchar` varchars ON xie.`EntityId`=varchars.`entity_id`
WHERE
  varchars.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert varchars: small image labels
INSERT INTO `mwcatalog_product_entity_varchar`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  101 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  xi.`Name` AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_varchar` varchars ON xie.`EntityId`=varchars.`entity_id`
WHERE
  varchars.`value_id` IS NULL AND
  xie.`Active` = 1;

-- insert varchars: thumbnail labels
INSERT INTO `mwcatalog_product_entity_varchar`
SELECT
  NULL AS `value_id`,
  4 AS `entity_type_id`,
  102 AS `attribute_id`,
  0 AS `store_id`,
  xie.`EntityId` AS `entity_id`,
  xi.`Name` AS `value`
FROM
  `XmlImportEntities` xie
  INNER JOIN `XmlImport` xi ON xie.`LocalId`=xi.`ItemId` AND xi.`AdapterId`=@adapter_id
  LEFT JOIN `mwcatalog_product_entity_varchar` varchars ON xie.`EntityId`=varchars.`entity_id`
WHERE
  varchars.`value_id` IS NULL AND
  xie.`Active` = 1;
