-- Fn_7.sql
-- Description: Đếm số lượng sản phẩm sắp hết hàng (Stock <= ngưỡng)

-- Kiểm tra và xóa function nếu đã tồn tại
IF OBJECT_ID('fn_CountLowStockProducts') IS NOT NULL
    DROP FUNCTION fn_CountLowStockProducts;
GO

CREATE FUNCTION fn_CountLowStockProducts (@shop_id INT, @threshold INT)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;
    
    SELECT @Count = COUNT(PV.prod_id)
    FROM PRODUCT_VARIANT PV
    INNER JOIN ITEM I ON PV.item_id = I.item_id
    WHERE I.shop_id = @shop_id AND PV.stock_quantity <= @threshold;

    RETURN @Count;
END;
GO

-- Ví dụ gọi Hàm:
-- Đếm số sản phẩm có tồn kho <= 10 của Shop ID = 3
SELECT dbo.fn_CountLowStockProducts(3, 10) AS LowStockCount_Shop3;
-- Đếm số sản phẩm có tồn kho <= 50 của Shop ID = 4
SELECT dbo.fn_CountLowStockProducts(4, 50) AS LowStockCount_Shop4;
