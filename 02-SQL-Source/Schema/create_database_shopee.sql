CREATE DATABASE SHOPEE_CLONE
GO

USE SHOPEE_CLONE
GO

CREATE TABLE [USER] (
  [user_id] int PRIMARY KEY IDENTITY(1, 1),
  [username] varchar(50),
  [password] varchar(255),
  [email] varchar(100),
  [phone_number] varchar(15),
  [gender] nvarchar(10),
  [day_of_birth] date,
  [avatar] varchar(255),
  [day_create] datetime DEFAULT (getdate())
)
GO

CREATE TABLE [CUSTOMER] (
  [customer_id] int PRIMARY KEY,
  [tier_id] int,
  [total_spending] decimal(18,2)
)
GO

CREATE TABLE [SHOP] (
  [shop_id] int PRIMARY KEY,
  [tax_code] varchar(50),
  [Address] nvarchar(255),
  [Shop_description] ntext,
  [Total_sales] int,
  [Rating_response] float,
  [Avg_time_response] varchar(50),
  [Rating_avg] float
)
GO

CREATE TABLE [MEMBERSHIP_TIER] (
  [tier_id] int PRIMARY KEY IDENTITY(1, 1),
  [tier_name] nvarchar(50),
  [tier_lvl] int,
  [min_spending] decimal(18,2),
  [max_spending] decimal(18,2),
  [description] nvarchar(255),
  [min_order] int,
  [max_order] int,
  [discount_percent] float,
  [shopee_coin] int
)
GO

CREATE TABLE [CATEGORY] (
  [category_id] int PRIMARY KEY IDENTITY(1, 1),
  [category_name] nvarchar(100),
  [category_level] int,
  [category_image] varchar(255),
  [parent_id] int,
  [shop_id] int
)
GO

CREATE TABLE [ITEM] (
  [item_id] int PRIMARY KEY IDENTITY(1, 1),
  [category_id] int,
  [item_name] nvarchar(200),
  [total_item] int,
  [shop_id] int
)
GO

CREATE TABLE [PRODUCT_VARIANT] (
  [prod_id] int PRIMARY KEY IDENTITY(1, 1),
  [item_id] int,
  [prod_name] nvarchar(200),
  [prod_description] ntext,
  [price] decimal(18,2),
  [stock_quantity] int,
  [product_specification] nvarchar(255),
  [illustration_images] varchar(255),
  [status] nvarchar(50),
  [total_sales] int,
  [rating_avg] float
)
GO

CREATE TABLE [PRODUCT_IMAGE] (
  [prod_image_id] int IDENTITY(1, 1),
  [prod_id] int,
  [image_url] varchar(255),
  [is_primary] bit,
  PRIMARY KEY ([prod_image_id], [prod_id])
)
GO

CREATE TABLE [PRODUCT_ATTRIBUTE] (
  [attr_id] int IDENTITY(1, 1),
  [prod_id] int,
  [attribute_size] nvarchar(50),
  [is_primary] bit,
  PRIMARY KEY ([attr_id], [prod_id])
)
GO

CREATE TABLE [PRODUCT_SPECIFICATION] (
  [size] nvarchar(50),
  [color] nvarchar(50),
  [prod_id] int,
  PRIMARY KEY ([size], [color], [prod_id])
)
GO

CREATE TABLE [ILLUSTRATIVE_IMAGE] (
  [illustrative_image_id] int IDENTITY(1, 1),
  [prod_id] int,
  PRIMARY KEY ([illustrative_image_id], [prod_id])
)
GO

CREATE TABLE [CART] (
  [cart_id] int PRIMARY KEY IDENTITY(1, 1),
  [user_id] int,
  [total_product] int,
  [total_payment] decimal(18,2)
)
GO

CREATE TABLE [CART_ITEM] (
  [cart_item_id] int PRIMARY KEY IDENTITY(1, 1),
  [prod_id] int,
  [cart_id] int,
  [shop_id] int,
  [quantity] int,
  [sub_total] decimal(18,2)
)
GO

CREATE TABLE [ORDER_GROUP] (
  [order_group_id] int PRIMARY KEY IDENTITY(1, 1),
  [customer_id] int,
  [voucher_id] int,
  [total_amount] decimal(18,2),
  [payment_id] int,
  [created_at] datetime,
  [coin_shopee] int,
  [total_delivery] decimal(18,2),
  [total_discount] decimal(18,2),
  [total_payment] decimal(18,2),
  [ship_address] nvarchar(255)
)
GO

CREATE TABLE [ORDER] (
  [order_id] int PRIMARY KEY IDENTITY(1, 1),
  [order_group_id] int,
  [customer_id] int,
  [shop_id] int,
  [total_amount] decimal(18,2),
  [ship_method] nvarchar(50),
  [shipping_id] int
)
GO

CREATE TABLE [ORDER_DETAIL] (
  [order_detail_id] int PRIMARY KEY IDENTITY(1, 1),
  [order_id] int,
  [product_id] int,
  [product_specification] nvarchar(255),
  [quantity] int,
  [price] decimal(18,2),
  [total_price] decimal(18,2),
  [note] nvarchar(255)
)
GO

CREATE TABLE [ORDER_STATUS] (
  [order_status_id] int IDENTITY(1, 1),
  [order_id] int,
  [status_timestamp] datetime,
  [status] nvarchar(50),
  PRIMARY KEY ([order_status_id], [order_id])
)
GO

CREATE TABLE [VOUCHER] (
  [voucher_id] int PRIMARY KEY IDENTITY(1, 1),
  [description] nvarchar(255),
  [discount_type] nvarchar(50),
  [condition] nvarchar(255),
  [valid_from] datetime,
  [valid_to] datetime,
  [quantity_available] int
)
GO

CREATE TABLE [CUSTOMER_VOUCHER] (
  [customer_id] int,
  [voucher_id] int,
  PRIMARY KEY ([customer_id], [voucher_id])
)
GO

CREATE TABLE [PAYMENT] (
  [payment_id] int PRIMARY KEY IDENTITY(1, 1),
  [order_id] int,
  [payment_date] datetime,
  [amount] decimal(18,2),
  [method] nvarchar(50),
  [status] nvarchar(50)
)
GO

CREATE TABLE [SHIPMENT_PROVIDER] (
  [provider_id] int PRIMARY KEY IDENTITY(1, 1),
  [provider_name] nvarchar(100),
  [weight_limit] float,
  [coverage_area] nvarchar(255),
  [size_limit] nvarchar(50),
  [delivery_method] nvarchar(100)
)
GO

CREATE TABLE [SHIPMENT] (
  [shipment_id] int PRIMARY KEY IDENTITY(1, 1),
  [order_id] int,
  [payment_date] datetime,
  [amount] decimal(18,2),
  [method] nvarchar(50),
  [status] nvarchar(50),
  [provider_id] int
)
GO

CREATE TABLE [SHIPMENT_STATUS] (
  [status_id] int IDENTITY(1, 1),
  [shipment_id] int,
  [status_name] nvarchar(100),
  [update_time] datetime,
  [current_location] nvarchar(255),
  PRIMARY KEY ([status_id], [shipment_id])
)
GO

CREATE TABLE [REVIEW] (
  [review_id] int PRIMARY KEY IDENTITY(1, 1),
  [product_id] int,
  [customer_id] int,
  [rating] int,
  [comment] ntext,
  [created_at] datetime,
  [image_review] varchar(255)
)
GO

ALTER TABLE [CUSTOMER] ADD FOREIGN KEY ([customer_id]) REFERENCES [USER] ([user_id])
GO

ALTER TABLE [CUSTOMER] ADD FOREIGN KEY ([tier_id]) REFERENCES [MEMBERSHIP_TIER] ([tier_id])
GO

ALTER TABLE [SHOP] ADD FOREIGN KEY ([shop_id]) REFERENCES [USER] ([user_id])
GO

ALTER TABLE [CATEGORY] ADD FOREIGN KEY ([parent_id]) REFERENCES [CATEGORY] ([category_id])
GO

ALTER TABLE [CATEGORY] ADD FOREIGN KEY ([shop_id]) REFERENCES [SHOP] ([shop_id])
GO

ALTER TABLE [ITEM] ADD FOREIGN KEY ([category_id]) REFERENCES [CATEGORY] ([category_id])
GO

ALTER TABLE [ITEM] ADD FOREIGN KEY ([shop_id]) REFERENCES [SHOP] ([shop_id])
GO

ALTER TABLE [PRODUCT_VARIANT] ADD FOREIGN KEY ([item_id]) REFERENCES [ITEM] ([item_id])
GO

ALTER TABLE [PRODUCT_IMAGE] ADD FOREIGN KEY ([prod_id]) REFERENCES [PRODUCT_VARIANT] ([prod_id])
GO

ALTER TABLE [PRODUCT_ATTRIBUTE] ADD FOREIGN KEY ([prod_id]) REFERENCES [PRODUCT_VARIANT] ([prod_id])
GO

ALTER TABLE [PRODUCT_SPECIFICATION] ADD FOREIGN KEY ([prod_id]) REFERENCES [PRODUCT_VARIANT] ([prod_id])
GO

ALTER TABLE [ILLUSTRATIVE_IMAGE] ADD FOREIGN KEY ([prod_id]) REFERENCES [PRODUCT_VARIANT] ([prod_id])
GO

ALTER TABLE [CART] ADD FOREIGN KEY ([user_id]) REFERENCES [CUSTOMER] ([customer_id])
GO

ALTER TABLE [CART_ITEM] ADD FOREIGN KEY ([prod_id]) REFERENCES [PRODUCT_VARIANT] ([prod_id])
GO

ALTER TABLE [CART_ITEM] ADD FOREIGN KEY ([cart_id]) REFERENCES [CART] ([cart_id])
GO

ALTER TABLE [CART_ITEM] ADD FOREIGN KEY ([shop_id]) REFERENCES [SHOP] ([shop_id])
GO

ALTER TABLE [ORDER_GROUP] ADD FOREIGN KEY ([customer_id]) REFERENCES [CUSTOMER] ([customer_id])
GO

ALTER TABLE [ORDER_GROUP] ADD FOREIGN KEY ([voucher_id]) REFERENCES [VOUCHER] ([voucher_id])
GO

ALTER TABLE [ORDER_GROUP] ADD FOREIGN KEY ([payment_id]) REFERENCES [PAYMENT] ([payment_id])
GO

ALTER TABLE [ORDER] ADD FOREIGN KEY ([order_group_id]) REFERENCES [ORDER_GROUP] ([order_group_id])
GO

ALTER TABLE [ORDER] ADD FOREIGN KEY ([customer_id]) REFERENCES [CUSTOMER] ([customer_id])
GO

ALTER TABLE [ORDER] ADD FOREIGN KEY ([shop_id]) REFERENCES [SHOP] ([shop_id])
GO

ALTER TABLE [ORDER] ADD FOREIGN KEY ([shipping_id]) REFERENCES [SHIPMENT] ([shipment_id])
GO

ALTER TABLE [ORDER_DETAIL] ADD FOREIGN KEY ([order_id]) REFERENCES [ORDER] ([order_id])
GO

ALTER TABLE [ORDER_DETAIL] ADD FOREIGN KEY ([product_id]) REFERENCES [PRODUCT_VARIANT] ([prod_id])
GO

ALTER TABLE [ORDER_STATUS] ADD FOREIGN KEY ([order_id]) REFERENCES [ORDER] ([order_id])
GO

ALTER TABLE [CUSTOMER_VOUCHER] ADD FOREIGN KEY ([customer_id]) REFERENCES [CUSTOMER] ([customer_id])
GO

ALTER TABLE [CUSTOMER_VOUCHER] ADD FOREIGN KEY ([voucher_id]) REFERENCES [VOUCHER] ([voucher_id])
GO

ALTER TABLE [PAYMENT] ADD FOREIGN KEY ([order_id]) REFERENCES [ORDER] ([order_id])
GO

ALTER TABLE [SHIPMENT] ADD FOREIGN KEY ([order_id]) REFERENCES [ORDER] ([order_id])
GO

ALTER TABLE [SHIPMENT] ADD FOREIGN KEY ([provider_id]) REFERENCES [SHIPMENT_PROVIDER] ([provider_id])
GO

ALTER TABLE [SHIPMENT_STATUS] ADD FOREIGN KEY ([shipment_id]) REFERENCES [SHIPMENT] ([shipment_id])
GO

ALTER TABLE [REVIEW] ADD FOREIGN KEY ([product_id]) REFERENCES [PRODUCT_VARIANT] ([prod_id])
GO

ALTER TABLE [REVIEW] ADD FOREIGN KEY ([customer_id]) REFERENCES [CUSTOMER] ([customer_id])
GO
