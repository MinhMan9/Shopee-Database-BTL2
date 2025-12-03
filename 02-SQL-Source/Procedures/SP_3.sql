-- Thủ tục 2: Thống kê Doanh số Bán hàng theo Cửa hàng và Xếp hạng trung bình
IF OBJECT_ID('sp_ThongKeDoanhSoVaRatingShop') IS NOT NULL
    DROP PROCEDURE sp_ThongKeDoanhSoVaRatingShop;
GO

CREATE PROCEDURE sp_ThongKeDoanhSoVaRatingShop
    @NgayBatDau DATE = NULL,
    @NgayKetThuc DATE = NULL,
    @RatingShopMin FLOAT = NULL
AS
BEGIN
    -- 1 câu truy vấn có aggregate function, group by, having, where và order by có liên kết từ 2 bảng trở lên
    SELECT
        S.shop_id,
        U.username AS ShopName,
        S.Address,
        COUNT(DISTINCT O.order_id) AS TotalOrders,
        SUM(OD.total_price) AS TotalRevenue,
        AVG(S.Rating_avg) AS AvgShopRating
    FROM
        SHOP S
    INNER JOIN
        [USER] U ON S.shop_id = U.user_id
    INNER JOIN
        [ORDER] O ON S.shop_id = O.shop_id
    INNER JOIN
        ORDER_DETAIL OD ON O.order_id = OD.order_id
    INNER JOIN
        ORDER_GROUP OG ON O.order_group_id = OG.order_group_id
    WHERE
        -- Lọc theo khoảng thời gian tạo Order Group
        (@NgayBatDau IS NULL OR OG.created_at >= @NgayBatDau)
        AND (@NgayKetThuc IS NULL OR OG.created_at <= DATEADD(day, 1, @NgayKetThuc)) -- Lọc đến hết ngày kết thúc
    GROUP BY
        S.shop_id, U.username, S.Address
    HAVING
        -- Lọc theo Rating trung bình của Shop
        (@RatingShopMin IS NULL OR AVG(S.Rating_avg) >= @RatingShopMin)
    ORDER BY
        TotalRevenue DESC, AvgShopRating DESC;
END
GO

-- Ví dụ gọi Thủ tục 2:
EXEC sp_ThongKeDoanhSoVaRatingShop @NgayBatDau = '2025-10-01', @NgayKetThuc = '2025-10-31', @RatingShopMin = 45842;
-- EXEC sp_ThongKeDoanhSoVaRatingShop @RatingShopMin = 45873;
-- EXEC sp_ThongKeDoanhSoVaRatingShop;