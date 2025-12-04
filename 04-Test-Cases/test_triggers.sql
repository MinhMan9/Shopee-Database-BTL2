USE SHOPEE_CLONE
GO

-- Tạo 1 order mới chưa có ORDER_STATUS
INSERT INTO [ORDER] (order_group_id, customer_id, shop_id, total_amount, ship_method, shipping_id)
VALUES (1, 1, 3, 100000, N'Nhanh', NULL);
GO

-- Thử tạo shipment cho order mới này (chưa có status)
INSERT INTO SHIPMENT (order_id, payment_date, amount, method, [status], provider_id)
VALUES (SCOPE_IDENTITY(), '2025-11-01', 15000, N'Nhanh', N'Đang giao', 1); -- => phải lỗi
GO

-- Lấy 1 order có order_group_id = 3 (created_at = '2025-10-22')
SELECT * FROM ORDER_GROUP WHERE order_group_id = 3;
GO

-- Cố tạo shipment với payment_date trước ngày tạo
INSERT INTO SHIPMENT (order_id, payment_date, amount, method, [status], provider_id)
VALUES (3, '2025-10-20', 15000, N'Nhanh', N'Đang giao', 1);  -- => phải lỗi
GO

-- Giả sử customer_id = 1 chưa từng mua product_id = 6
INSERT INTO REVIEW (product_id, customer_id, rating, comment, created_at, image_review)
VALUES (6, 1, 5, N'Test review sai quy định', GETDATE(), 'x.jpg');  -- => phải lỗi
GO
