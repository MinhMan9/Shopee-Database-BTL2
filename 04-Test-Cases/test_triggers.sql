USE SHOPEE_CLONE;
GO

PRINT N'========== TEST TRIGGER: SHIPMENT_BusinessRules ==========';

--------------------------------------------------
-- 1.1 VALID: order_id = 2 có status cuối cùng = 'Đã giao',
--            ORDER_GROUP.created_at = '2025-10-21'
--------------------------------------------------
INSERT INTO SHIPMENT (order_id, payment_date, amount, method, [status], provider_id)
VALUES (2, '2025-10-22', 15000, N'Nhanh', N'Đang giao', 1);
-- ✅ EXPECTED: HỢP LỆ

--------------------------------------------------
-- 1.2 INVALID: Shipment cho đơn CHƯA CÓ status nào
--------------------------------------------------
DECLARE @OrderNoStatus INT;

INSERT INTO [ORDER] (order_group_id, customer_id, shop_id, total_amount, ship_method, shipping_id)
VALUES (1, 1, 3, 100000, N'Nhanh', NULL);
SET @OrderNoStatus = SCOPE_IDENTITY();

INSERT INTO SHIPMENT (order_id, payment_date, amount, method, [status], provider_id)
VALUES (@OrderNoStatus, '2025-11-01', 15000, N'Nhanh', N'Đang giao', 1);
-- ❌ EXPECTED ERROR: SHIPMENT chỉ cho đơn có trạng thái 'Đang giao'/'Đã giao'

--------------------------------------------------
-- 1.3 INVALID: payment_date < ORDER_GROUP.created_at
--   order_id = 3 thuộc ORDER_GROUP 3, created_at = '2025-10-22'
--------------------------------------------------
INSERT INTO SHIPMENT (order_id, payment_date, amount, method, [status], provider_id)
VALUES (3, '2025-10-20', 15000, N'Nhanh', N'Đang giao', 1);
-- ❌ EXPECTED ERROR: Ngày giao < ngày đặt hàng


PRINT N'========== TEST TRIGGER: SHIPMENT_STATUS_OnePerShipment ==========';

--------------------------------------------------
-- 2.1 Tạo ORDER + ORDER_STATUS + SHIPMENT hợp lệ để test
--------------------------------------------------
DECLARE @NewOrderId INT, @NewShipId INT;

-- Tạo 1 order mới, gắn vào ORDER_GROUP 2 (created_at = '2025-10-21')
INSERT INTO [ORDER] (order_group_id, customer_id, shop_id, total_amount, ship_method, shipping_id)
VALUES (2, 2, 4, 200000, N'Tiết kiệm', NULL);
SET @NewOrderId = SCOPE_IDENTITY();

-- Tạo ORDER_STATUS 'Đang giao' cho order mới -> thỏa trigger SHIPMENT_BusinessRules
INSERT INTO ORDER_STATUS (order_id, status_timestamp, [status])
VALUES (@NewOrderId, '2025-11-20T08:00:00', N'Đang giao');

-- Tạo SHIPMENT mới, payment_date >= ORDER_GROUP.created_at
INSERT INTO SHIPMENT (order_id, payment_date, amount, method, [status], provider_id)
VALUES (@NewOrderId, '2025-11-21', 15000, N'Tiết kiệm', N'Đang giao', 1);
SET @NewShipId = SCOPE_IDENTITY();

-- 2.1 VALID: Thêm 1 Shipment_Status duy nhất → HỢP LỆ
INSERT INTO SHIPMENT_STATUS (shipment_id, status_name, update_time, current_location)
VALUES (@NewShipId, N'Lấy hàng thành công', GETDATE(), N'Kho test');
-- ✅ OK

--------------------------------------------------
-- 2.2 INVALID: Thêm status thứ 2 cho cùng shipment_id
--------------------------------------------------
INSERT INTO SHIPMENT_STATUS (shipment_id, status_name, update_time, current_location)
VALUES (@NewShipId, N'Thử thêm status lần 2', GETDATE(), N'Kho test 2');
-- ❌ EXPECTED ERROR: Mỗi shipment chỉ có 1 Shipment_Status

--------------------------------------------------
-- 2.3 INVALID: 2 status cho cùng shipment_id trong 1 batch
--------------------------------------------------
INSERT INTO SHIPMENT_STATUS (shipment_id, status_name, update_time, current_location)
VALUES (@NewShipId, N'Test batch 1', GETDATE(), N'Kho X'),
       (@NewShipId, N'Test batch 2', GETDATE(), N'Kho Y');
-- ❌ EXPECTED ERROR: batch insert 2 dòng cùng shipment_id


PRINT N'========== TEST TRIGGER: REVIEW_OnlyAfterDelivered ==========';

--------------------------------------------------
-- 3.1 VALID:
--  Customer 1 đã mua product_id 1 trong order_id 1
--  Order 1 có ORDER_STATUS 'Đã giao' → review hợp lệ
--------------------------------------------------
INSERT INTO REVIEW (product_id, customer_id, rating, comment, created_at, image_review)
VALUES (1, 1, 5, N'Review hợp lệ sau đơn đã giao', '2025-10-25', 'rv_ok_test.jpg');
-- ✅ OK

--------------------------------------------------
-- 3.2 INVALID:
--  Customer 1 cố review product_id 6 (trong dữ liệu gốc chỉ customer 5 mua)
--------------------------------------------------
INSERT INTO REVIEW (product_id, customer_id, rating, comment, created_at, image_review)
VALUES (6, 1, 5, N'Review sai, chưa từng mua', '2025-10-25', 'rv_fail_test.jpg');
-- ❌ EXPECTED ERROR: chưa có đơn 'Đã giao' với sản phẩm này


PRINT N'========== END TEST TRIGGERS ==========';

