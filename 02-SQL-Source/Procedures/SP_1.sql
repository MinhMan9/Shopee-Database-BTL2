-- Thống kê Chi tiết Sản phẩm theo Danh mục và Shop
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
    -- Câu truy vấn liên kết 5+ bảng để tính toán các chỉ số tổng hợp
    SELECT
        C.category_name,
        U_Shop.username AS ShopName,
        PV.prod_id,
        PV.prod_name,
        PV.price AS CurrentPrice,
        PV.stock_quantity AS CurrentStock,
        -- Tính toán tổng doanh số bán được (từ ORDER_DETAIL)
        SUM(OD.quantity) AS TotalUnitsSold,
        SUM(OD.total_price) AS TotalRevenueGenerated,
        -- Tính toán đánh giá trung bình (từ REVIEW)
        AVG(R.rating * 1.0) AS AvgRating,
        COUNT(R.review_id) AS TotalReviews
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
    LEFT JOIN
        ORDER_DETAIL OD ON PV.prod_id = OD.product_id
    LEFT JOIN
        [ORDER] O ON OD.order_id = O.order_id
    LEFT JOIN
        REVIEW R ON PV.prod_id = R.product_id
    WHERE
        -- Lọc trong mệnh đề WHERE theo ShopID và Tên Danh mục
        (@ShopID IS NULL OR S.shop_id = @ShopID)
        AND (@CategoryName IS NULL OR C.category_name LIKE N'%' + @CategoryName + '%')
    GROUP BY
        C.category_name, U_Shop.username, PV.prod_id, PV.prod_name, PV.price, PV.stock_quantity
    HAVING
        -- Lọc trong mệnh đề HAVING theo Tổng Doanh số bán được và Đánh giá trung bình
        (@MinTotalSales IS NULL OR SUM(OD.quantity) >= @MinTotalSales)
        AND (@MinAvgRating IS NULL OR AVG(R.rating * 1.0) >= @MinAvgRating)
    ORDER BY
        TotalRevenueGenerated DESC, TotalUnitsSold DESC, AvgRating DESC;
END
GO

-- Ví dụ gọi Thủ tục Phức tạp 1: Thống kê sản phẩm của Shop 'shop_apple' (ID 3) có tổng doanh số >= 1
EXEC sp_ThongKeSanPhamChiTiet @ShopID = 3, @MinTotalSales = 1;

-- Ví dụ gọi Thủ tục Phức tạp 2: Thống kê sản phẩm thuộc Danh mục 'Thời Trang' có Rating trung bình >= 4.5
EXEC sp_ThongKeSanPhamChiTiet @CategoryName = N'Thời Trang', @MinAvgRating = 4.5;