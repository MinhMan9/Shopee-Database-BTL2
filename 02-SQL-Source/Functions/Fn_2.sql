-- Hàm 2: Kiểm tra một sản phẩm có còn hàng hay không
IF OBJECT_ID('fn_KiemTraTrangThaiTonKho') IS NOT NULL
    DROP FUNCTION fn_KiemTraTrangThaiTonKho;
GO

CREATE FUNCTION fn_KiemTraTrangThaiTonKho
(
    @ProductID INT, -- Tham số đầu vào là ID của biến thể sản phẩm
    @SoLuong INT = 1 -- Số lượng cần mua để kiểm tra
)
RETURNS NVARCHAR(50) -- Trả về NVARCHAR(50)
AS
BEGIN
    DECLARE @TonKho INT;
    DECLARE @TrangThai NVARCHAR(50);

    -- Chứa câu lệnh truy vấn dữ liệu, lấy dữ liệu từ truy vấn để kiểm tra tính toán
    SELECT
        @TonKho = stock_quantity
    FROM
        PRODUCT_VARIANT
    WHERE
        prod_id = @ProductID;

    -- Kiểm tra tham số đầu vào (ProductID có tồn tại không)
    IF @TonKho IS NULL
    BEGIN
        SET @TrangThai = N'Lỗi: Sản phẩm không tồn tại';
    END
    -- Tính toán
    ELSE IF @TonKho > 0 AND @TonKho >= @SoLuong
    BEGIN
        SET @TrangThai = N'Còn hàng (' + CONVERT(NVARCHAR, @TonKho) + N' sản phẩm)';
    END
    ELSE IF @TonKho < @SoLuong
    BEGIN
        SET @TrangThai = N'Hết hàng/Không đủ số lượng (' + CONVERT(NVARCHAR, @TonKho) + N' sản phẩm)';
    END
    ELSE
    BEGIN
        SET @TrangThai = N'Trạng thái không xác định';
    END

    RETURN @TrangThai;
END
GO

-- Ví dụ gọi Hàm 2:
-- Sản phẩm 1 (iPhone 15 Pro Max) - stock_quantity = 50
SELECT dbo.fn_KiemTraTrangThaiTonKho(1, 10) AS TrangThai_SP1_SL10;
-- Sản phẩm 5 (Ốp lưng) - stock_quantity = 200
SELECT dbo.fn_KiemTraTrangThaiTonKho(5, 500) AS TrangThai_SP5_SL500;
-- Sản phẩm không tồn tại (Ví dụ: 99)
SELECT dbo.fn_KiemTraTrangThaiTonKho(99, 1) AS TrangThai_SP99;