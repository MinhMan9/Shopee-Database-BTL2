-- Stored Procedure: sp_ThongKeSanPhamChiTiet (Đã Sửa)
IF OBJECT_ID('sp_ThongKeSanPhamChiTiet') IS NOT NULL
    DROP PROCEDURE sp_ThongKeSanPhamChiTiet;
GO

CREATE PROCEDURE sp_ThongKeSanPhamChiTiet
    @ShopID INT = NULL,
    @CategoryName NVARCHAR(100) = NULL,
    @MinTotalSales INT = NULL,
    @MinAvgRating FLOAT = NULL
AS
BEGIN
    -- Câu truy vấn liệt kê sản phẩm, lấy dữ liệu trực tiếp từ PRODUCT_VARIANT
    SELECT
        C.category_name,
        U_Shop.username AS ShopName,
        PV.prod_id,
        PV.prod_name,
        PV.price AS CurrentPrice,
        PV.stock_quantity AS CurrentStock,
        
        -- LẤY DỮ LIỆU TRỰC TIẾP TỪ PRODUCT_VARIANT
        PV.total_sales AS TotalUnitsSold,        -- (Sử dụng cột Total_Sales trong PV thay cho SUM(OD.quantity))
        (PV.total_sales * PV.price) AS TotalRevenueGenerated, -- (Tính tổng doanh thu đơn giản)
        PV.rating_avg AS AvgRating
        
    FROM
        PRODUCT_VARIANT PV
    INNER JOIN
        ITEM I ON PV.item_id = I.item_id
    INNER JOIN
        CATEGORY C ON I.category_id = C.category_id
    INNER JOIN
        SHOP S ON I.shop_id = S.shop_id
    INNER JOIN
        [USER] U_Shop ON S.shop_id = U_Shop.user_id
    
    WHERE
        -- Lọc theo ShopID
        (@ShopID IS NULL OR S.shop_id = @ShopID)
        -- Lọc theo Tên Danh mục
        AND (@CategoryName IS NULL OR C.category_name LIKE N'%' + @CategoryName + '%')
        
        -- Lọc theo Total Sales (MinTotalSales)
        AND (@MinTotalSales IS NULL OR PV.total_sales >= @MinTotalSales)
        -- Lọc theo Rating Avg (MinAvgRating)
        AND (@MinAvgRating IS NULL OR PV.rating_avg >= @MinAvgRating)
        
    ORDER BY
        TotalRevenueGenerated DESC, TotalUnitsSold DESC, AvgRating DESC;
END
GO
-- Ví dụ gọi Thủ tục Phức tạp 1: Thống kê sản phẩm của Shop 'shop_apple' (ID 3) có tổng doanh số >= 1
EXEC sp_ThongKeSanPhamChiTiet @ShopID = 3, @MinTotalSales = 1;

-- Ví dụ gọi Thủ tục Phức tạp 2: Thống kê sản phẩm thuộc Danh mục 'Thời Trang' có Rating trung bình >= 4.5
EXEC sp_ThongKeSanPhamChiTiet @CategoryName = N'Thời Trang', @MinAvgRating = 4.5;