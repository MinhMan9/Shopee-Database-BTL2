-- Hàm 4: Kiểm tra tính hợp lệ và điều kiện áp dụng của Voucher
IF OBJECT_ID('fn_KiemTraVoucherHopLe') IS NOT NULL
    DROP FUNCTION fn_KiemTraVoucherHopLe;
GO

CREATE FUNCTION fn_KiemTraVoucherHopLe
(
    @VoucherID INT,
    @TotalAmount DECIMAL(18, 2), -- Tổng giá trị sản phẩm trước khi giảm
    @CustomerID INT = NULL -- Khách hàng sử dụng (nếu cần kiểm tra voucher cá nhân)
)
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @IsValid NVARCHAR(100) = N'Hợp lệ';
    DECLARE @ValidTo DATETIME;
    DECLARE @QuantityAvailable INT;
    DECLARE @Condition NVARCHAR(255);

    SELECT 
        @ValidTo = valid_to, 
        @QuantityAvailable = quantity_available, 
        @Condition = [condition]
    FROM VOUCHER
    WHERE voucher_id = @VoucherID;

    -- 1. Kiểm tra Voucher có tồn tại không
    IF @ValidTo IS NULL 
        SET @IsValid = N'Lỗi: Voucher không tồn tại.';
    
    -- 2. Kiểm tra Hạn sử dụng
    ELSE IF @ValidTo < GETDATE()
        SET @IsValid = N'Voucher đã hết hạn sử dụng.';

    -- 3. Kiểm tra Số lượng còn lại
    ELSE IF @QuantityAvailable <= 0
        SET @IsValid = N'Voucher đã hết số lượng.';

    -- 4. Kiểm tra Điều kiện áp dụng (Rất đơn giản)
    ELSE IF @Condition = 'min_50k' AND @TotalAmount < 50000
        SET @IsValid = N'Tổng giá trị đơn hàng chưa đạt mức tối thiểu.';
        
    -- 5. Kiểm tra Voucher đã được lưu bởi KH chưa (Ví dụ cho voucher cá nhân)
    ELSE IF @CustomerID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM CUSTOMER_VOUCHER WHERE customer_id = @CustomerID AND voucher_id = @VoucherID)
        SET @IsValid = N'Voucher không thuộc quyền sở hữu của bạn.';

    RETURN @IsValid;
END
GO