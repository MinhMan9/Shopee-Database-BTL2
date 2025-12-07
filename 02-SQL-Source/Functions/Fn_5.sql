-- Fn_5.sql
-- Description: Tính tổng doanh thu của Shop

-- Kiểm tra và xóa function nếu đã tồn tại
IF OBJECT_ID('fn_CalculateShopRevenue') IS NOT NULL
    DROP FUNCTION fn_CalculateShopRevenue;
GO

CREATE FUNCTION fn_CalculateShopRevenue (@shop_id INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TotalRevenue DECIMAL(18,2);
    
    SELECT @TotalRevenue = SUM(O.total_amount)
    FROM [ORDER] O
    WHERE O.shop_id = @shop_id;

    RETURN ISNULL(@TotalRevenue, 0);
END;
GO

-- Ví dụ gọi Hàm:
-- Tính doanh thu cho Shop có ID = 3
SELECT dbo.fn_CalculateShopRevenue(3) AS ShopRevenue_ID3;
-- Tính doanh thu cho Shop có ID = 4
SELECT dbo.fn_CalculateShopRevenue(4) AS ShopRevenue_ID4;
