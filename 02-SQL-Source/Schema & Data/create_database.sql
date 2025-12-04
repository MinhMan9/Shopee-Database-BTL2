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

SET IDENTITY_INSERT [USER] ON;
INSERT INTO [USER] (user_id, username, password, email, phone_number, gender, day_of_birth, avatar, day_create) VALUES 
(1, 'nguyenvanA', 'pass123', 'a@gmail.com', '901234567', N'Nam', '2000-01-01', 'ava1.jpg', '2024-01-01'),
(2, 'tranthiB', 'pass456', 'b@gmail.com', '902345678', N'Nữ', '2002-05-05', 'ava2.jpg', '2024-02-01'),
(3, 'shop_apple', 'shop123', 'shop1@mail.com', '908888888', N'Khác', '1990-01-01', 'logo1.jpg', '2023-01-01'),
(4, 'shop_thoitrang', 'shop456', 'shop2@mail.com', '909999999', N'Khác', '1995-10-10', 'logo2.jpg', '2023-05-01'),
(5, 'lequangC', 'pass789', 'c@gmail.com', '903456789', N'Nam', '1998-09-15', 'ava3.jpg', '2023-11-10'),
(6, 'beauty_shop', 'shop789', 'shop3@mail.com', '907777777', N'Khác', '1993-07-20', 'logo3.jpg', '2022-09-01'),
(7, 'shop_giadung', 'shop321', 'shop4@mail.com', '908888888', N'Khác', '1992-12-01', 'logo4.jpg', '2023-12-01');
SET IDENTITY_INSERT [USER] OFF;
GO

CREATE TABLE [CUSTOMER] (
  [customer_id] int PRIMARY KEY,
  [tier_id] int,
  [total_spending] decimal(18,2)
)

INSERT INTO CUSTOMER (customer_id, tier_id, total_spending) VALUES 
(1, 1, 250000),
(2, 3, 6000000),
(3, 1, 800000),
(4, 3, 12000000),
(5, 4, 25000000);
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

INSERT INTO SHOP (shop_id, tax_code, Address, Shop_description, Total_sales, Rating_response, Avg_time_response, Rating_avg) VALUES 
(3, 'MST001', N'Q1, TP.HCM', N'Chuyên iPhone', 1000, 4.9, N'30 phút', 45873),
(4, 'MST002', N'Q3, Hà Nội', N'Quần áo genZ', 500, 4.5, N'1 giờ', 45812),
(5, 'MST003', N'Q10, TP.HCM', N'Phụ kiện điện thoại', 300, 4.7, N'45 phút', 45842),
(6, 'MST004', N'Hoàn Kiếm, Hà Nội', N'Mỹ phẩm chính hãng', 800, 4.8, N'40 phút', 45873),
(7, 'MST005', N'Thủ Đức, TP.HCM', N'Đồ gia dụng tiện ích', 600, 4.6, N'35 phút', 45812);
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

-- --- Bảng MEMBERSHIP_TIER ---
SET IDENTITY_INSERT MEMBERSHIP_TIER ON;
INSERT INTO MEMBERSHIP_TIER (tier_id, tier_name, tier_lvl, min_spending, max_spending, description, min_order, max_order, discount_percent, shopee_coin) VALUES 
(1, N'Thành Viên', 1, 0, 2999000, N'6 voucher miễn phí vận chuyển hàng tháng và Ưu đãi Ngày hội Thành Viên.', 0, 2, 0, 0),
(2, N'Bạc', 2, 3000000, 4999000, N'Ưu đãi độc quyền từ thương hiệu và đối tác và Sản phẩm giá độc quyền từ thương hiệu và người bán và Các voucher hot từ shop.', 3, 74, 0.05, 100),
(3, N'Vàng', 3, 5000000, 9999000, N'Voucher thăng hạng và Voucher sinh nhật.', 75, NULL, 0.075, 300),
(4, N'Kim Cương', 4, 20000000, NULL, N'Các ưu đãi trước đó cùng với voucher duy trì thứ hạng Kim Cương.', 75, NULL, 0.1, 500);
SET IDENTITY_INSERT MEMBERSHIP_TIER OFF;
GO

CREATE TABLE [CATEGORY] (
  [category_id] int PRIMARY KEY IDENTITY(1, 1),
  [category_name] nvarchar(100),
  [category_level] int,
  [category_image] varchar(255),
  [parent_id] int,
  [shop_id] int
)

-- --- Bảng CATEGORY ---
SET IDENTITY_INSERT CATEGORY ON;
INSERT INTO CATEGORY (category_id, category_name, category_level, category_image, parent_id, shop_id) VALUES 
(1, N'Điện Tử', 1, 'img_elec.png', NULL, NULL),
(2, N'Thời Trang', 1, 'img_fash.png', NULL, NULL),
(3, N'Phụ Kiện Điện Tử', 2, 'img_accessory.png', 1, 5),
(4, N'Mỹ Phẩm', 2, 'img_cosmetic.png', 2, 6),
(5, N'Đồ Gia Dụng', 2, 'img_home.png', 2, 7);
SET IDENTITY_INSERT CATEGORY OFF;
GO

CREATE TABLE [ITEM] (
  [item_id] int PRIMARY KEY IDENTITY(1, 1),
  [category_id] int,
  [item_name] nvarchar(200),
  [total_item] int,
  [shop_id] int
)

-- --- Bảng ITEM ---
SET IDENTITY_INSERT ITEM ON;
INSERT INTO ITEM (item_id, category_id, item_name, total_item, shop_id) VALUES 
(1, 1, N'iPhone 15 Pro Max', 2, 3),
(2, 2, N'Áo Thun Cotton', 2, 4),
(3, 1, N'iPhone 16 ', 2, 3),
(4, 3, N'Ốp lưng iPhone trong suốt', 5, 5),
(5, 5, N'Bộ dụng cụ nhà bếp 5 món', 3, 7);
SET IDENTITY_INSERT ITEM OFF;
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

-- --- Bảng PRODUCT_VARIANT ---
SET IDENTITY_INSERT PRODUCT_VARIANT ON;
INSERT INTO PRODUCT_VARIANT (prod_id, item_id, prod_name, prod_description, price, stock_quantity, product_specification, illustration_images, status, total_sales, rating_avg) VALUES 
(1, 1, N'iPhone 15 Pro Max 256GB', N'Hàng chính hãng', 30000000, 50, N'256GB, Titan', 'ip15.jpg', N'Đang bán', 10, 4.9),
(2, 2, N'Áo Thun Đen Size L', N'Vải mát 100%', 150000, 100, N'Size L, Đen', 'ao_den.jpg', N'Đang bán', 50, 4.5),
(3, 2, N'Áo Thun Trắng Size M', N'Cotton thoáng mát', 140000, 80, N'Size M, Trắng', 'ao_trang.jpg', N'Đang bán', 30, 4.6),
(4, 3, N'iPhone 16 256GB', N'Hàng chính hãng, bảo hành 12 tháng', 35000000, 40, N'256GB, Titan', 'ip16.jpg', N'Đang bán', 5, 4.9),
(5, 4, N'Ốp lưng iPhone trong suốt', N'Chống sốc, không ố vàng', 200000, 200, N'Trong suốt', 'op_trongsuot.jpg', N'Đang bán', 70, 4.7),
(6, 5, N'Bộ dụng cụ nhà bếp 5 món', N'Thép không gỉ, dùng được cho máy rửa chén', 400000, 60, N'Inox 304', 'bep5mon.jpg', N'Đang bán', 20, 4.4);
SET IDENTITY_INSERT PRODUCT_VARIANT OFF;
GO

CREATE TABLE [PRODUCT_IMAGE] (
  [prod_image_id] int IDENTITY(1, 1),
  [prod_id] int,
  [image_url] varchar(255),
  [is_primary] bit,
  PRIMARY KEY ([prod_image_id], [prod_id])
)

-- --- Bảng PRODUCT_IMAGE ---
SET IDENTITY_INSERT PRODUCT_IMAGE ON;
INSERT INTO PRODUCT_IMAGE (prod_image_id, prod_id, image_url, is_primary) VALUES 
(1, 1, 'ip15_mat_truoc.jpg', 1),
(2, 1, 'ip15_mat_sau.jpg', 0),
(3, 2, 'ao_den_mat_truoc.jpg', 1),
(4, 3, 'ao_trang_mat_truoc.jpg', 1),
(5, 4, 'ip16_mat_truoc.jpg', 1),
(6, 4, 'ip16_mat_sau.jpg', 0),
(7, 5, 'op_trongsuot_1.jpg', 1),
(8, 6, 'bep5mon_1.jpg', 1);
SET IDENTITY_INSERT PRODUCT_IMAGE OFF;
GO

CREATE TABLE [PRODUCT_ATTRIBUTE] (
  [attr_id] int IDENTITY(1, 1),
  [prod_id] int,
  [attribute_size] nvarchar(50),
  [is_primary] bit,
  PRIMARY KEY ([attr_id], [prod_id])
)

-- --- Bảng PRODUCT_ATTRIBUTE ---
SET IDENTITY_INSERT PRODUCT_ATTRIBUTE ON;
INSERT INTO PRODUCT_ATTRIBUTE (attr_id, prod_id, attribute_size, is_primary) VALUES 
(1, 1, N'256GB', 1),
(2, 2, N'L', 1),
(3, 3, N'M', 1),
(4, 4, N'256GB', 1),
(5, 5, N'Free size', 1),
(6, 6, N'One size', 1);
SET IDENTITY_INSERT PRODUCT_ATTRIBUTE OFF;
GO

CREATE TABLE [PRODUCT_SPECIFICATION] (
  [size] nvarchar(50),
  [color] nvarchar(50),
  [prod_id] int,
  PRIMARY KEY ([size], [color], [prod_id])
)

-- --- Bảng PRODUCT_SPECIFICATION ---
-- Bảng này không có ID tự tăng trong thiết kế
INSERT INTO PRODUCT_SPECIFICATION (size, color, prod_id) VALUES 
(N'6.7 inch', N'Titan Tự nhiên', 1),
(N'L', N'Đen', 2),
(N'M', N'Trắng', 3),
(N'6.7 inch', N'Titan Đen', 4),
(N'Free', N'Trong suốt', 5),
(N'Standard', N'Bạc', 6);
GO

CREATE TABLE [ILLUSTRATIVE_IMAGE] (
  [illustrative_image_id] int IDENTITY(1, 1),
  [prod_id] int,
  PRIMARY KEY ([illustrative_image_id], [prod_id])
)

-- --- Bảng ILLUSTRATIVE_IMAGE ---
SET IDENTITY_INSERT ILLUSTRATIVE_IMAGE ON;
INSERT INTO ILLUSTRATIVE_IMAGE (illustrative_image_id, prod_id) VALUES 
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6);
SET IDENTITY_INSERT ILLUSTRATIVE_IMAGE OFF;
GO

CREATE TABLE [CART] (
  [cart_id] int PRIMARY KEY IDENTITY(1, 1),
  [user_id] int,
  [total_product] int,
  [total_payment] decimal(18,2)
)

-- --- Bảng CART ---
SET IDENTITY_INSERT CART ON;
INSERT INTO CART (cart_id, user_id, total_product, total_payment) VALUES 
(1, 1, 1, 30000000),
(2, 2, 2, 600000),
(3, 3, 2, 30150000),
(4, 4, 3, 450000),
(5, 5, 1, 150000);
SET IDENTITY_INSERT CART OFF;
GO

CREATE TABLE [CART_ITEM] (
  [cart_item_id] int PRIMARY KEY IDENTITY(1, 1),
  [prod_id] int,
  [cart_id] int,
  [shop_id] int,
  [quantity] int,
  [sub_total] decimal(18,2)
)

-- --- Bảng CART_ITEM ---
SET IDENTITY_INSERT CART_ITEM ON;
INSERT INTO CART_ITEM (cart_item_id, prod_id, cart_id, shop_id, quantity, sub_total) VALUES 
(1, 1, 1, 3, 1, 30000000),
(2, 2, 2, 4, 2, 600000),
(3, 1, 3, 3, 1, 30000000),
(4, 2, 3, 4, 1, 150000),
(5, 2, 4, 4, 3, 450000),
(6, 2, 5, 4, 1, 150000);
SET IDENTITY_INSERT CART_ITEM OFF;
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

-- --- Bảng ORDER_GROUP ---
SET IDENTITY_INSERT ORDER_GROUP ON;
INSERT INTO ORDER_GROUP (order_group_id, customer_id, voucher_id, total_amount, payment_id, created_at, coin_shopee, total_delivery, total_discount, total_payment, ship_address) VALUES 
(1, 1, 1, 30000000, NULL, '2025-10-20 00:00:00', 0, 15000, 10000, 30005000, N'123 Đường A'),
(2, 2, 2, 150000, NULL, '2025-10-21 00:00:00', 200, 15000, 15000, 150000, N'456 Đường B'),
(3, 3, 1, 30150000, NULL, '2025-10-22 00:00:00', 100, 15000, 5000, 30160000, N'789 Đường C'),
(4, 4, 2, 450000, NULL, '2025-10-23 00:00:00', 50, 20000, 15000, 455000, N'12 Nguyễn Trãi'),
(5, 5, NULL, 400000, NULL, '2025-10-24 00:00:00', 0, 15000, 0, 415000, N'34 Lê Lợi');
SET IDENTITY_INSERT ORDER_GROUP OFF;
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

-- --- Bảng ORDER ---
SET IDENTITY_INSERT [ORDER] ON;
INSERT INTO [ORDER] (order_id, order_group_id, customer_id, shop_id, total_amount, ship_method, shipping_id) VALUES 
(1, 1, 1, 3, 30000000, N'Nhanh', NULL),
(2, 2, 2, 4, 150000, N'Tiết kiệm', NULL),
(3, 3, 3, 3, 30000000, N'Nhanh', NULL),
(4, 3, 3, 4, 150000, N'Tiết kiệm', NULL),
(5, 4, 4, 4, 450000, N'Tiết kiệm', NULL),
(6, 5, 5, 7, 400000, N'Nhanh', NULL);
SET IDENTITY_INSERT [ORDER] OFF;
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

-- --- Bảng ORDER_DETAIL ---
SET IDENTITY_INSERT ORDER_DETAIL ON;
INSERT INTO ORDER_DETAIL (order_detail_id, order_id, product_id, product_specification, quantity, price, total_price, note) VALUES 
(1, 1, 1, N'Titan 256GB', 1, 30000000, 30000000, N'Giao giờ HC'),
(2, 2, 2, N'Size L', 1, 150000, 150000, N'Không che tên'),
(3, 3, 1, N'Titan 256GB', 1, 30000000, 30000000, N'Giao nhanh trong ngày'),
(4, 4, 2, N'Size L', 1, 150000, 150000, N'Đóng gói kỹ'),
(5, 5, 2, N'Size L', 3, 150000, 450000, N'3 cái size L'),
(6, 6, 6, N'Inox 304', 1, 400000, 400000, N'Giao giờ HC');
SET IDENTITY_INSERT ORDER_DETAIL OFF;
GO

CREATE TABLE [ORDER_STATUS] (
  [order_status_id] int IDENTITY(1, 1),
  [order_id] int,
  [status_timestamp] datetime,
  [status] nvarchar(50),
  PRIMARY KEY ([order_status_id], [order_id])
)

-- --- Bảng ORDER_STATUS ---
SET IDENTITY_INSERT ORDER_STATUS ON;
INSERT INTO ORDER_STATUS (order_status_id, order_id, status_timestamp, status) VALUES 
(1, 1, '2025-10-20 08:00:00', N'Đang xử lý'),
(2, 2, '2025-10-21 09:00:00', N'Đã giao'),
(3, 1, '2025-10-20 14:00:00', N'Đã giao'),
(4, 3, '2025-10-22 08:30:00', N'Đang xử lý'),
(5, 4, '2025-10-22 18:00:00', N'Đã giao'),
(6, 5, '2025-10-23 10:00:00', N'Đang xử lý'),
(7, 6, '2025-10-24 16:00:00', N'Đã giao'),
(8, 3, '2025-10-22 12:00:00', N'Đã giao'),
(9, 5, '2025-10-23 18:00:00', N'Đã giao');
SET IDENTITY_INSERT ORDER_STATUS OFF;
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

-- --- Bảng VOUCHER ---
SET IDENTITY_INSERT VOUCHER ON;
INSERT INTO VOUCHER (voucher_id, description, discount_type, condition, valid_from, valid_to, quantity_available) VALUES 
(1, N'Giảm 10k đơn 0đ', 'amount', N'min_0', '2025-01-01', '2025-12-31', 1000),
(2, N'Freeship Extra', 'shipping', N'min_50k', '2025-01-01', '2025-06-30', 5000),
(3, N'Giảm 5% đơn từ 500k', 'percent', N'min_500k', '2025-02-01', '2025-12-31', 2000),
(4, N'Giảm 50k đơn từ 1M', 'amount', N'min_1M', '2025-03-01', '2025-12-31', 1500),
(5, N'Voucher thành viên mới', 'amount', N'new_member', '2025-01-01', '2025-03-31', 3000);
SET IDENTITY_INSERT VOUCHER OFF;
GO

CREATE TABLE [CUSTOMER_VOUCHER] (
  [customer_id] int,
  [voucher_id] int,
  PRIMARY KEY ([customer_id], [voucher_id])
)

-- --- Bảng CUSTOMER_VOUCHER ---
INSERT INTO CUSTOMER_VOUCHER (customer_id, voucher_id) VALUES 
(1, 1),
(2, 2),
(3, 1),
(3, 2),
(4, 1),
(5, 2);
GO

CREATE TABLE [PAYMENT] (
  [payment_id] int PRIMARY KEY IDENTITY(1, 1),
  [order_id] int,
  [payment_date] datetime,
  [amount] decimal(18,2),
  [method] nvarchar(50),
  [status] nvarchar(50)
)

-- --- Bảng PAYMENT ---
SET IDENTITY_INSERT PAYMENT ON;
INSERT INTO PAYMENT (payment_id, order_id, payment_date, amount, method, status) VALUES 
(1, 1, '2025-10-20', 30005000, N'COD', N'Pending'),
(2, 2, '2025/10/21', 150000, N'ShopeePay', N'Completed'),
(3, 3, '2025/10/22', 30160000, N'ShopeePay', N'Completed'),
(4, 4, '2025/10/22', 150000, N'COD', N'Completed'),
(5, 5, '2025/10/23', 455000, N'COD', N'Pending'),
(6, 6, '2025/10/24', 415000, N'ShopeePay', N'Completed');
SET IDENTITY_INSERT PAYMENT OFF;
GO

CREATE TABLE [SHIPMENT_PROVIDER] (
  [provider_id] int PRIMARY KEY IDENTITY(1, 1),
  [provider_name] nvarchar(100),
  [weight_limit] float,
  [coverage_area] nvarchar(255),
  [size_limit] nvarchar(50),
  [delivery_method] nvarchar(100)
)

-- --- Bảng SHIPMENT_PROVIDER ---
SET IDENTITY_INSERT SHIPMENT_PROVIDER ON;
INSERT INTO SHIPMENT_PROVIDER (provider_id, provider_name, weight_limit, coverage_area, size_limit, delivery_method) VALUES 
(1, N'SPX Express', 20.0, N'Toàn quốc', N'50x50x50', N'Đường bộ'),
(2, N'Giao Hàng Nhanh', 30.0, N'Toàn quốc', N'100x100x100', N'Đường bộ/Bay'),
(3, N'Viettel Post', 25.0, N'Toàn quốc', N'80x80x80', N'Đường bộ/Bay'),
(4, N'J&T Express', 20.0, N'Toàn quốc', N'60x60x60', N'Đường bộ'),
(5, N'SPX Express', 15.0, N'Nội thành', N'40x40x40', N'Đường bộ');
SET IDENTITY_INSERT SHIPMENT_PROVIDER OFF;
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
CREATE TABLE [SHIPMENT] (
    [shipment_id] INT IDENTITY(1,1) PRIMARY KEY, 
    [order_id] INT NOT NULL,
    [tracking_no] VARCHAR(50),             
    [fee] DECIMAL(18, 2),                        
    [estimated_delivery] DATETIME,
    [provider_id] INT NOT NULL
);
GO

-- --- Bảng SHIPMENT ---
SET IDENTITY_INSERT SHIPMENT ON;
INSERT INTO SHIPMENT (shipment_id, order_id, tracking_no, fee, estimated_delivery_day, provider_id) VALUES 
(1, 1, 'SPX00129388', 15000, '2025-10-21', 1),
(2, 2, 'GHN88273111', 32000, '2025-10-22', 2),
(3, 3, 'VNP99281122', 22000, '2025-10-23', 3),
(4, 4, 'GHN88273999', 45000, '2025-10-22', 2),
(5, 5, 'JNT11223344', 18000, '2025-10-25', 4);
SET IDENTITY_INSERT SHIPMENT OFF;
GO

CREATE TABLE [SHIPMENT_STATUS] (
  [status_id] int IDENTITY(1, 1),
  [shipment_id] int,
  [status_name] nvarchar(100),
  [update_time] datetime,
  [current_location] nvarchar(255),
  PRIMARY KEY ([status_id], [shipment_id])
)

-- --- Bảng SHIPMENT_STATUS ---
SET IDENTITY_INSERT SHIPMENT_STATUS ON;
INSERT INTO SHIPMENT_STATUS (status_id, shipment_id, status_name, update_time, current_location) VALUES 
(1, 1, N'Lấy hàng thành công', '2025-10-20 10:00:00', N'Kho Q1'),
(2, 2, N'Giao hàng thành công', '2025-10-22 14:00:00', N'Nhà khách'),
(3, 1, N'Đang giao', '2025-10-20 15:00:00', N'Đang giao Q3'),
(4, 3, N'Lấy hàng thành công', '2025-10-22 09:00:00', N'Kho Q3'),
(5, 4, N'Đang giao', '2025-10-22 19:00:00', N'Đang giao Q1'),
(6, 5, N'Chờ lấy hàng', '2025-10-23 08:00:00', N'Kho Thủ Đức'),
(7, 3, N'Giao hàng thành công', '2025-10-23 16:00:00', N'Nhà khách');
SET IDENTITY_INSERT SHIPMENT_STATUS OFF;
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

-- --- Bảng REVIEW ---
SET IDENTITY_INSERT REVIEW ON;
INSERT INTO REVIEW (review_id, product_id, customer_id, rating, comment, created_at, image_review) VALUES 
(1, 1, 1, 5, N'Điện thoại xịn', '2025-10-23', 'rv1.jpg'),
(2, 2, 2, 4, N'Vải hơi mỏng', '2025-10-24', 'rv2.jpg'),
(3, 2, 3, 5, N'Áo đẹp, form rộng', '2025-10-25', 'rv3.jpg'),
(4, 1, 4, 4, N'iPhone dùng ổn, pin tốt', '2025-10-26', 'rv4.jpg'),
(5, 6, 5, 5, N'Bộ dụng cụ bếp chắc chắn', '2025-10-27', 'rv5.jpg');
SET IDENTITY_INSERT REVIEW OFF;
GO

-- > Cập nhật lại Payment_ID vào ORDER_GROUP
UPDATE ORDER_GROUP SET payment_id = 1 WHERE order_group_id = 1;
UPDATE ORDER_GROUP SET payment_id = 2 WHERE order_group_id = 2;
UPDATE ORDER_GROUP SET payment_id = 3 WHERE order_group_id = 3;
UPDATE ORDER_GROUP SET payment_id = 4 WHERE order_group_id = 4;
UPDATE ORDER_GROUP SET payment_id = 5 WHERE order_group_id = 5;
UPDATE ORDER_GROUP SET payment_id = 6 WHERE order_group_id = 6;

-- > Cập nhật lại Shipping_ID vào ORDER
UPDATE [ORDER] SET shipping_id = 1 WHERE order_id = 1;
UPDATE [ORDER] SET shipping_id = 2 WHERE order_id = 2;
UPDATE [ORDER] SET shipping_id = 3 WHERE order_id = 3;
UPDATE [ORDER] SET shipping_id = 4 WHERE order_id = 4;
UPDATE [ORDER] SET shipping_id = 5 WHERE order_id = 5;

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

PRINT N'--- ĐÃ TẠO DATABASE THÀNH CÔNG ---';