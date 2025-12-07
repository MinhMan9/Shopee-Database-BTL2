
-- SP_7.sql
-- Yêu cầu: Procedure lấy thống kê tổng quan cho Dashboard Shop
-- Sử dụng các Function đã tạo ở trên

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('sp_GetShopDashboardStats') IS NOT NULL
    DROP PROCEDURE sp_GetShopDashboardStats;
GO

CREATE PROCEDURE sp_GetShopDashboardStats
    @ShopID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        dbo.fn_CalculateShopRevenue(@ShopID) AS TotalRevenue,
        dbo.fn_CalculateShopRating(@ShopID) AS RealAvgRating,
        (SELECT COUNT(*) FROM [ORDER] WHERE shop_id = @ShopID) AS TotalOrders,
        (SELECT COUNT(*) FROM ITEM WHERE shop_id = @ShopID) AS TotalItems,
        (SELECT SUM(total_sales) FROM PRODUCT_VARIANT PV JOIN ITEM I ON PV.item_id = I.item_id WHERE I.shop_id = @ShopID) AS TotalProductsSold;
END;
GO

-- Ví dụ gọi Procedure:
-- Lấy thống kê Dashboard cho Shop ID = 3
EXEC sp_GetShopDashboardStats @ShopID = 3;
-- Lấy thống kê Dashboard cho Shop ID = 4
EXEC sp_GetShopDashboardStats @ShopID = 4;


