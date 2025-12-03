-- Thủ tục 1: Liệt kê các Sản phẩm theo Tên sản phẩm và Khoảng giá
IF OBJECT_ID('sp_HienThiSanPhamTheoTenVaGia') IS NOT NULL
    DROP PROCEDURE sp_HienThiSanPhamTheoTenVaGia;
GO

CREATE PROCEDURE sp_HienThiSanPhamTheoTenVaGia
    @TenSanPham NVARCHAR(200) = NULL,
    @GiaMin DECIMAL(18, 2) = NULL,
    @GiaMax DECIMAL(18, 2) = NULL
AS
BEGIN
    -- Câu truy vấn đơn giản 2 bảng trở lên có mệnh đề WHERE, ORDER BY
    SELECT
        PV.prod_id,
        PV.prod_name,
        PV.price,
        PV.stock_quantity,
        I.item_name,
        S.Address AS ShopAddress
    FROM
        PRODUCT_VARIANT PV
    INNER JOIN
        ITEM I ON PV.item_id = I.item_id
    INNER JOIN
        SHOP S ON I.shop_id = S.shop_id
    WHERE
        -- Lọc theo Tên sản phẩm (sử dụng LIKE để tìm kiếm tương đối)
        (@TenSanPham IS NULL OR PV.prod_name LIKE N'%' + @TenSanPham + '%')
        -- Lọc theo Khoảng giá
        AND (@GiaMin IS NULL OR PV.price >= @GiaMin)
        AND (@GiaMax IS NULL OR PV.price <= @GiaMax)
    ORDER BY
        PV.price DESC, PV.prod_name;
END
GO

-- Ví dụ gọi Thủ tục 1:
EXEC sp_HienThiSanPhamTheoTenVaGia @TenSanPham = N'Áo Thun', @GiaMin = 100000;
-- EXEC sp_HienThiSanPhamTheoTenVaGia @GiaMin = 30000000;
-- EXEC sp_HienThiSanPhamTheoTenVaGia;