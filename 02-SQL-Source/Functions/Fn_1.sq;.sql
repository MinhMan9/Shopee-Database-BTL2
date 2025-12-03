-- Hàm 2: Ki?m tra m?t s?n ph?m có c?n hàng hay không
IF OBJECT_ID('fn_KiemTraTrangThaiTonKho') IS NOT NULL
    DROP FUNCTION fn_KiemTraTrangThaiTonKho;
GO

CREATE FUNCTION fn_KiemTraTrangThaiTonKho
(
    @ProductID INT, -- Tham s? ð?u vào là ID c?a bi?n th? s?n ph?m
    @SoLuong INT = 1 -- S? lý?ng c?n mua ð? ki?m tra
)
RETURNS NVARCHAR(50) -- Tr? v? NVARCHAR(50)
AS
BEGIN
    DECLARE @TonKho INT;
    DECLARE @TrangThai NVARCHAR(50);

    -- Ch?a câu l?nh truy v?n d? li?u, l?y d? li?u t? truy v?n ð? ki?m tra tính toán
    SELECT
        @TonKho = stock_quantity
    FROM
        PRODUCT_VARIANT
    WHERE
        prod_id = @ProductID;

    -- Ki?m tra tham s? ð?u vào (ProductID có t?n t?i không)
    IF @TonKho IS NULL
    BEGIN
        SET @TrangThai = N'L?i: S?n ph?m không t?n t?i';
    END
    -- Tính toán
    ELSE IF @TonKho > 0 AND @TonKho >= @SoLuong
    BEGIN
        SET @TrangThai = N'C?n hàng (' + CONVERT(NVARCHAR, @TonKho) + N' s?n ph?m)';
    END
    ELSE IF @TonKho < @SoLuong
    BEGIN
        SET @TrangThai = N'H?t hàng/Không ð? s? lý?ng (' + CONVERT(NVARCHAR, @TonKho) + N' s?n ph?m)';
    END
    ELSE
    BEGIN
        SET @TrangThai = N'Tr?ng thái không xác ð?nh';
    END

    RETURN @TrangThai;
END
GO

-- Ví d? g?i Hàm 2:
-- S?n ph?m 1 (iPhone 15 Pro Max) - stock_quantity = 50
SELECT dbo.fn_KiemTraTrangThaiTonKho(1, 10) AS TrangThai_SP1_SL10;
-- S?n ph?m 5 (?p lýng) - stock_quantity = 200
SELECT dbo.fn_KiemTraTrangThaiTonKho(5, 500) AS TrangThai_SP5_SL500;
-- S?n ph?m không t?n t?i (Ví d?: 99)
SELECT dbo.fn_KiemTraTrangThaiTonKho(99, 1) AS TrangThai_SP99;