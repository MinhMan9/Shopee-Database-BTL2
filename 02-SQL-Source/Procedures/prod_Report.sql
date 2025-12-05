
-- =============================================
-- [NEW] CÁC PROCEDURE BÁO CÁO CHO SHOP (Added on 2025-12-05)
-- =============================================

-- 1. Procedure lấy thống kê tổng quan cho Dashboard Shop
-- Sử dụng các Function đã tạo ở trên
CREATE OR ALTER PROCEDURE sp_GetShopDashboardStats
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

-- 2. Procedure lấy danh sách đơn hàng của Shop (Kèm thông tin khách hàng)
CREATE OR ALTER PROCEDURE sp_GetShopOrderList
    @ShopID INT,
    @Limit INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Limit)
        O.order_id,
        O.created_at, -- Lưu ý: Cần đảm bảo bảng ORDER hoặc ORDER_GROUP có created_at. Theo schema là ORDER_GROUP.
        -- Fix: Lấy created_at từ ORDER_GROUP
        OG.created_at AS OrderDate,
        C.customer_id,
        U.username AS CustomerName,
        O.total_amount,
        OS.status AS OrderStatus
    FROM [ORDER] O
    INNER JOIN ORDER_GROUP OG ON O.order_group_id = OG.order_group_id
    INNER JOIN CUSTOMER C ON O.customer_id = C.customer_id
    INNER JOIN [USER] U ON C.customer_id = U.user_id
    LEFT JOIN ORDER_STATUS OS ON O.order_id = OS.order_id
    WHERE O.shop_id = @ShopID
    ORDER BY OG.created_at DESC;
END;
GO
GO
-- =============================================
-- [NEW] PROCEDURE: Báo cáo hiệu quả kinh doanh từng sản phẩm của Shop
-- =============================================
CREATE PROCEDURE sp_GetShopProductPerformance
    @ShopID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        PV.prod_id,
        PV.prod_name,
        PV.price,
        PV.stock_quantity,
        PV.total_sales,
        PV.rating_avg,
        PV.status
    FROM PRODUCT_VARIANT PV
    INNER JOIN ITEM I ON PV.item_id = I.item_id
    WHERE I.shop_id = @ShopID
    ORDER BY PV.total_sales DESC;
END;
GO

GO
-- =============================================
-- [NEW] PROCEDURE: Báo cáo doanh số theo danh mục (Aggregate, Group By, Having) - Yêu cầu 2.3
-- =============================================
CREATE PROCEDURE sp_ReportSalesByCategory
    @ShopID INT,
    @MinSales INT -- Điều kiện Having
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        C.category_name,
        COUNT(PV.prod_id) AS TotalProducts,
        SUM(PV.total_sales) AS TotalUnitsSold,
        SUM(PV.total_sales * PV.price) AS EstimatedRevenue
    FROM CATEGORY C
    INNER JOIN ITEM I ON C.category_id = I.category_id
    INNER JOIN PRODUCT_VARIANT PV ON I.item_id = PV.item_id
    WHERE I.shop_id = @ShopID
    GROUP BY C.category_name
    HAVING SUM(PV.total_sales) >= @MinSales
    ORDER BY TotalUnitsSold DESC;
END;
GO
