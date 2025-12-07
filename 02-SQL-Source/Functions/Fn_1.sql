-- Hàm 1: Tính tổng giá trị giỏ hàng của một khách hàng
IF OBJECT_ID('fn_TinhTongTienGioHang') IS NOT NULL
    DROP FUNCTION fn_TinhTongTienGioHang;
GO

CREATE FUNCTION fn_TinhTongTienGioHang
(
    @UserID INT -- Tham số đầu vào là ID của người dùng (khách hàng)
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @TongTien DECIMAL(18, 2);

    -- Lấy tổng giá trị giỏ hàng (dựa trên sub_total của CART_ITEM)
    SELECT
        @TongTien = SUM(CI.sub_total)
    FROM
        CART C
    INNER JOIN
        CART_ITEM CI ON C.cart_id = CI.cart_id
    WHERE
        C.user_id = @UserID;

    -- Kiểm tra tính toán
    IF @TongTien IS NULL
        SET @TongTien = 0; -- Trả về 0 nếu không tìm thấy giỏ hàng hoặc giỏ hàng trống

    RETURN @TongTien;
END
GO

-- Ví dụ gọi Hàm 1:
-- Khách hàng có user_id = 1
SELECT dbo.fn_TinhTongTienGioHang(1) AS TongTienGioHang_KH1;
-- Khách hàng có user_id = 5
SELECT dbo.fn_TinhTongTienGioHang(5) AS TongTienGioHang_KH5;
-- Khách hàng không tồn tại (Ví dụ: 99)
SELECT dbo.fn_TinhTongTienGioHang(99) AS TongTienGioHang_KH99;