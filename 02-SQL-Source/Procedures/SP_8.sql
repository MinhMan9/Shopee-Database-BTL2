-- SP_9.sql
-- Yêu cầu: Tìm sản phẩm bán chạy nhất của Shop

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('sp_GetShopBestSeller') IS NOT NULL
    DROP PROCEDURE sp_GetShopBestSeller;
GO

CREATE PROCEDURE sp_GetShopBestSeller
    @ShopID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 
        PV.prod_name AS BestSellerName,
        PV.total_sales AS TotalSales
    FROM PRODUCT_VARIANT PV
    INNER JOIN ITEM I ON PV.item_id = I.item_id
    WHERE I.shop_id = @ShopID
    ORDER BY PV.total_sales DESC;
END;
GO

-- Ví dụ gọi Procedure:
-- Tìm sản phẩm bán chạy nhất của Shop ID = 3
EXEC sp_GetShopBestSeller @ShopID = 3;
