
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

