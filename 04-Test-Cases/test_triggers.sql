USE SHOPEE_CLONE
GO

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
GO

-- ============================TEST CHO 2.2.1========================================
PRINT N'=== NHẬP LIỆU TEST TRIGGER 10 ===';
-- 1. Tạo Voucher test loại 'min_50k' (Đơn tối thiểu 50.000)
SET IDENTITY_INSERT VOUCHER ON;
INSERT INTO VOUCHER (voucher_id, description, discount_type, condition, valid_from, valid_to, quantity_available)
VALUES (101, N'Test 50k', 'amount', 'min_50k', '2024-01-01', '2030-12-31', 100);
SET IDENTITY_INSERT VOUCHER OFF; -- Nếu bảng có identity thì cần set dòng này, nếu không thì bỏ qua

-- 2. Tạo Voucher test loại 'min_1M' (Đơn tối thiểu 1.000.000)
INSERT INTO VOUCHER (description, discount_type, condition, valid_from, valid_to, quantity_available)
VALUES (N'Test 1M', 'amount', 'min_1M', '2024-01-01', '2030-12-31', 100);

-- 3. Tạo Voucher đã hết hạn (Expired)
INSERT INTO VOUCHER (description, discount_type, condition, valid_from, valid_to, quantity_available)
VALUES (N'Test Hết hạn', 'amount', 'min_0', '2020-01-01', '2023-12-31', 100);

-- 4. Tạo Voucher hết số lượng (Quantity = 0)
INSERT INTO VOUCHER (description, discount_type, condition, valid_from, valid_to, quantity_available)
VALUES (N'Test Hết hàng', 'amount', 'min_0', '2024-01-01', '2030-12-31', 0);
GO

PRINT N'=== TEST 1: KIỂM TRA CONDITION min_50k ===';
DECLARE @Voucher50k INT = (SELECT TOP 1 voucher_id FROM VOUCHER WHERE condition = 'min_50k' AND valid_to > GETDATE());

-- Case 1.1: Đơn hàng 40.000 (Thấp hơn 50k) -> Mong đợi: LỖI (FAIL)
BEGIN TRY
    INSERT INTO ORDER_GROUP (customer_id, voucher_id, total_amount, created_at)
    VALUES (1, @Voucher50k, 40000, GETDATE());
    PRINT N'FAIL: Lỗi logic! Đơn 40k vẫn dùng được voucher min_50k.';
END TRY
BEGIN CATCH
    PRINT N'SUCCESS: Đã chặn thành công đơn 40k. Lỗi: ' + ERROR_MESSAGE();
END CATCH;

-- Case 1.2: Đơn hàng 60.000 (Cao hơn 50k) -> Mong đợi: THÀNH CÔNG
BEGIN TRY
    INSERT INTO ORDER_GROUP (customer_id, voucher_id, total_amount, created_at)
    VALUES (1, @Voucher50k, 60000, GETDATE());
    PRINT N'SUCCESS: Áp dụng voucher min_50k cho đơn 60k thành công.';
END TRY
BEGIN CATCH
    PRINT N'FAIL: Lỗi không mong muốn: ' + ERROR_MESSAGE();
END CATCH;

PRINT N'=== TEST 2: KIỂM TRA CONDITION min_1M ===';
DECLARE @Voucher1M INT = (SELECT TOP 1 voucher_id FROM VOUCHER WHERE condition = 'min_1M' AND valid_to > GETDATE());

-- Case 2.1: Đơn hàng 900.000 -> Mong đợi: LỖI
BEGIN TRY
    INSERT INTO ORDER_GROUP (customer_id, voucher_id, total_amount, created_at)
    VALUES (1, @Voucher1M, 900000, GETDATE());
    PRINT N'FAIL: Lỗi logic! Đơn 900k vẫn dùng được voucher min_1M.';
END TRY
BEGIN CATCH
    PRINT N'SUCCESS: Đã chặn thành công đơn 900k. Lỗi: ' + ERROR_MESSAGE();
END CATCH;

-- Case 2.2: Đơn hàng 1.500.000 -> Mong đợi: THÀNH CÔNG
BEGIN TRY
    INSERT INTO ORDER_GROUP (customer_id, voucher_id, total_amount, created_at)
    VALUES (1, @Voucher1M, 1500000, GETDATE());
    PRINT N'SUCCESS: Áp dụng voucher min_1M cho đơn 1.5tr thành công.';
END TRY
BEGIN CATCH
    PRINT N'FAIL: Lỗi không mong muốn: ' + ERROR_MESSAGE();
END CATCH;

PRINT N'=== TEST 3: KIỂM TRA HẠN SỬ DỤNG ===';
-- Lấy 1 voucher đã hết hạn
DECLARE @VoucherExpired INT = (SELECT TOP 1 voucher_id FROM VOUCHER WHERE valid_to < GETDATE());

BEGIN TRY
    -- Insert đơn hợp lệ về tiền (1 tỷ) nhưng voucher hết hạn
    INSERT INTO ORDER_GROUP (customer_id, voucher_id, total_amount, created_at)
    VALUES (1, @VoucherExpired, 1000000000, GETDATE());
    PRINT N'FAIL: Trigger hỏng! Cho phép dùng voucher hết hạn.';
END TRY
BEGIN CATCH
    PRINT N'SUCCESS: Chặn voucher hết hạn thành công. Lỗi: ' + ERROR_MESSAGE();
END CATCH;

PRINT N'=== TEST 4: KIỂM TRA SỐ LƯỢNG ===';
-- Lấy 1 voucher có quantity = 0
DECLARE @VoucherEmpty INT = (SELECT TOP 1 voucher_id FROM VOUCHER WHERE quantity_available = 0);

BEGIN TRY
    INSERT INTO ORDER_GROUP (customer_id, voucher_id, total_amount, created_at)
    VALUES (1, @VoucherEmpty, 1000000000, GETDATE());
    PRINT N'FAIL: Trigger hỏng! Cho phép dùng voucher đã hết số lượng.';
END TRY
BEGIN CATCH
    PRINT N'SUCCESS: Chặn voucher hết số lượng thành công. Lỗi: ' + ERROR_MESSAGE();
END CATCH;
-- ============================KẾT THÚC TEST CHO 2.2.1========================================