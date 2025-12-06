-- SP_6.sql
-- Yêu cầu: 1 câu truy vấn có aggregate function, group by, having, where và order
-- Procedure báo cáo doanh thu theo danh mục

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('sp_ReportSalesByCategory') IS NOT NULL
    DROP PROCEDURE sp_ReportSalesByCategory;
GO

CREATE PROCEDURE sp_ReportSalesByCategory
    @ShopID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        C.category_name,
        COUNT(DISTINCT I.item_id) AS TotalProducts,
        SUM(PV.total_sales) AS TotalUnitsSold,
        SUM(PV.total_sales * PV.price) AS EstimatedRevenue
    FROM ITEM I
    INNER JOIN PRODUCT_VARIANT PV ON I.item_id = PV.item_id
    INNER JOIN CATEGORY C ON I.category_id = C.category_id
    WHERE I.shop_id = @ShopID
    GROUP BY C.category_name
    HAVING SUM(PV.total_sales) >= 0 -- HAVING clause
    ORDER BY EstimatedRevenue DESC; -- ORDER BY clause
END;
GO

-- Ví dụ gọi Procedure:
-- Báo cáo doanh thu theo danh mục cho Shop ID = 3
EXEC sp_ReportSalesByCategory @ShopID = 3;
-- Báo cáo doanh thu theo danh mục cho Shop ID = 4
EXEC sp_ReportSalesByCategory @ShopID = 4;

