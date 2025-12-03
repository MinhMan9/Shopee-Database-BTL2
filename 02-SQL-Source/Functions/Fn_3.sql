-- Hàm Phức tạp: Kiểm tra Tiềm năng Thăng hạng Thành viên
IF OBJECT_ID('fn_KiemTraThangHangThanhVien') IS NOT NULL
    DROP FUNCTION fn_KiemTraThangHangThanhVien;
GO

CREATE FUNCTION fn_KiemTraThangHangThanhVien
(
    @CustomerID INT
)
RETURNS @ThongTinThangHang TABLE
(
    CustomerID INT,
    Username NVARCHAR(50),
    CurrentTierName NVARCHAR(50),
    TotalSpending DECIMAL(18, 2),
    NextTierName NVARCHAR(50) NULL,
    SpendingNeeded DECIMAL(18, 2) NULL
)
AS
BEGIN
    -- Khai báo biến để lưu thông tin hiện tại của khách hàng
    DECLARE @CurrentTierID INT;
    DECLARE @TotalSpending DECIMAL(18, 2);
    DECLARE @CurrentTierLVL INT;

    -- 1. Lấy thông tin khách hàng và cấp bậc hiện tại
    SELECT
        @CurrentTierID = C.tier_id,
        @TotalSpending = C.total_spending
    FROM
        CUSTOMER C
    WHERE
        C.customer_id = @CustomerID;

    IF @CurrentTierID IS NULL -- Kiểm tra khách hàng có tồn tại không
    BEGIN
        INSERT INTO @ThongTinThangHang (CustomerID, Username, CurrentTierName, TotalSpending)
        SELECT @CustomerID, N'Không tìm thấy', N'N/A', 0;
        RETURN;
    END

    -- 2. Lấy cấp độ hiện tại
    SELECT @CurrentTierLVL = tier_lvl FROM MEMBERSHIP_TIER WHERE tier_id = @CurrentTierID;

    -- 3. Tìm cấp bậc cao hơn tiếp theo
    INSERT INTO @ThongTinThangHang
    SELECT TOP 1
        @CustomerID AS CustomerID,
        U.username AS Username,
        MT_Current.tier_name AS CurrentTierName,
        @TotalSpending AS TotalSpending,
        MT_Next.tier_name AS NextTierName,
        MT_Next.min_spending - @TotalSpending AS SpendingNeeded
    FROM
        [USER] U
    INNER JOIN
        CUSTOMER C ON U.user_id = C.customer_id
    INNER JOIN
        MEMBERSHIP_TIER MT_Current ON C.tier_id = MT_Current.tier_id
    LEFT JOIN
        MEMBERSHIP_TIER MT_Next ON MT_Next.tier_lvl = @CurrentTierLVL + 1
    WHERE
        U.user_id = @CustomerID AND @CurrentTierLVL < (SELECT MAX(tier_lvl) FROM MEMBERSHIP_TIER) -- Đảm bảo không phải cấp Kim Cương
    ORDER BY
        MT_Next.tier_lvl;

    -- Trường hợp đã đạt cấp cao nhất (Kim Cương)
    IF NOT EXISTS (SELECT 1 FROM @ThongTinThangHang WHERE NextTierName IS NOT NULL)
    BEGIN
        -- Cập nhật trường hợp cấp cao nhất
        UPDATE T
        SET T.NextTierName = N'Đã đạt cấp cao nhất',
            T.SpendingNeeded = 0
        FROM @ThongTinThangHang T
        INNER JOIN CUSTOMER C ON T.CustomerID = C.customer_id
        INNER JOIN MEMBERSHIP_TIER MT ON C.tier_id = MT.tier_id
        WHERE MT.tier_lvl = (SELECT MAX(tier_lvl) FROM MEMBERSHIP_TIER);
    END
    
    -- Trường hợp khách hàng chỉ có cấp ban đầu mà chưa có thông tin chi tiêu
    IF NOT EXISTS (SELECT 1 FROM @ThongTinThangHang)
    BEGIN
        INSERT INTO @ThongTinThangHang
        SELECT
            U.user_id,
            U.username,
            MT.tier_name,
            C.total_spending,
            N'Bạc' AS NextTierName,
            MT_Next.min_spending - C.total_spending AS SpendingNeeded
        FROM [USER] U
        INNER JOIN CUSTOMER C ON U.user_id = C.customer_id
        INNER JOIN MEMBERSHIP_TIER MT ON C.tier_id = MT.tier_id
        INNER JOIN MEMBERSHIP_TIER MT_Next ON MT_Next.tier_lvl = 2 -- Cấp tiếp theo
        WHERE U.user_id = @CustomerID;
    END

    RETURN;
END
GO

SELECT * FROM dbo.fn_KiemTraThangHangThanhVien(1);