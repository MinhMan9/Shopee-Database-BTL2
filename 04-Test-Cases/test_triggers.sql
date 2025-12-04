USE SHOPEE_CLONE
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