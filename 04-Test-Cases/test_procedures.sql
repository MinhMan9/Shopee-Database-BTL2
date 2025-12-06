USE SHOPEE_CLONE;
GO

PRINT N'========== TEST 2.1 – STORED PROCEDURES (CART_ITEM) ==========';

------------------------------------------------------------
-- 0. CHUẨN BỊ DỮ LIỆU TEST
------------------------------------------------------------
DECLARE @TestCartId     INT  = 1;   -- cart 1 trong data mẫu
DECLARE @TestProdId     INT  = 1;   -- iPhone 15 Pro Max 256GB
DECLARE @TestShopId     INT  = 3;
DECLARE @TestCartItemId INT;

-- Lấy cart_item tương ứng (nếu đã có sẵn)
SELECT TOP (1) @TestCartItemId = cart_item_id
FROM CART_ITEM
WHERE cart_id = @TestCartId
  AND prod_id = @TestProdId
  AND shop_id = @TestShopId;

-- Nếu chưa có thì tạo tạm cho chắc
IF (@TestCartItemId IS NULL)
BEGIN
    -- tạo cart mới cho user 1
    INSERT INTO CART (user_id, total_product, total_payment)
    VALUES (1, 0, 0);
    SET @TestCartId = SCOPE_IDENTITY();

    -- thêm 1 dòng CART_ITEM
    INSERT INTO CART_ITEM (prod_id, cart_id, shop_id, quantity, sub_total)
    VALUES (@TestProdId, @TestCartId, @TestShopId, 1, 0);
    SET @TestCartItemId = SCOPE_IDENTITY();
END;

DECLARE @msg nvarchar(200);

SET @msg = N'-- Dữ liệu ban đầu CART_ITEM cho cart_id = ' 
           + CAST(@TestCartId AS nvarchar(10));
PRINT @msg;

SELECT * 
FROM CART_ITEM 
WHERE cart_id = @TestCartId;

PRINT N'-- Thông tin PRODUCT_VARIANT dùng cho test';
SELECT prod_id, prod_name, price, stock_quantity
FROM PRODUCT_VARIANT
WHERE prod_id = @TestProdId;



/******************************************************************
 * 1. TEST sp_AddCartItem – Thêm sản phẩm vào giỏ hàng
 ******************************************************************/
PRINT N'========== 1. TEST sp_AddCartItem ==========';

------------------------------------------------------------
-- 1.1 VALID: thêm 2 cái iPhone 15 vào giỏ test
------------------------------------------------------------
PRINT N'--- 1.1 VALID: Thêm 2 cái iPhone 15 vào giỏ ---';

EXEC sp_AddCartItem
    @CartId   = @TestCartId,
    @ProdId   = @TestProdId,
    @ShopId   = @TestShopId,
    @Quantity = 2;

PRINT N'Kết quả sau 1.1:';
SELECT * 
FROM CART_ITEM
WHERE cart_id = @TestCartId
  AND prod_id = @TestProdId
  AND shop_id = @TestShopId;


------------------------------------------------------------
-- 1.2 INVALID: quantity <= 0
------------------------------------------------------------
PRINT N'--- 1.2 INVALID: quantity <= 0 ---';
BEGIN TRY
    EXEC sp_AddCartItem
        @CartId   = @TestCartId,
        @ProdId   = @TestProdId,
        @ShopId   = @TestShopId,
        @Quantity = 0;
    PRINT N'FAIL 1.2: Cho phép thêm sản phẩm với quantity <= 0.';
END TRY
BEGIN CATCH
    PRINT N'SUCCESS 1.2: Đã chặn quantity <= 0. Lỗi: ' + ERROR_MESSAGE();
END CATCH;


------------------------------------------------------------
-- 1.3 INVALID: Cart không tồn tại
------------------------------------------------------------
PRINT N'--- 1.3 INVALID: Cart không tồn tại ---';
BEGIN TRY
    EXEC sp_AddCartItem
        @CartId   = 999999,          -- cart_id chắc chắn không tồn tại
        @ProdId   = @TestProdId,
        @ShopId   = @TestShopId,
        @Quantity = 1;
    PRINT N'FAIL 1.3: Cho phép thêm vào cart không tồn tại.';
END TRY
BEGIN CATCH
    PRINT N'SUCCESS 1.3: Đã chặn Cart không tồn tại. Lỗi: ' + ERROR_MESSAGE();
END CATCH;


------------------------------------------------------------
-- 1.4 INVALID: Product không tồn tại
------------------------------------------------------------
PRINT N'--- 1.4 INVALID: Product không tồn tại ---';
BEGIN TRY
    EXEC sp_AddCartItem
        @CartId   = @TestCartId,
        @ProdId   = 999999,          -- prod_id không tồn tại
        @ShopId   = @TestShopId,
        @Quantity = 1;
    PRINT N'FAIL 1.4: Cho phép thêm product không tồn tại.';
END TRY
BEGIN CATCH
    PRINT N'SUCCESS 1.4: Đã chặn product không tồn tại. Lỗi: ' + ERROR_MESSAGE();
END CATCH;


------------------------------------------------------------
-- 1.5 INVALID: quantity vượt quá tồn kho
------------------------------------------------------------
PRINT N'--- 1.5 INVALID: quantity vượt quá tồn kho ---';

DECLARE @Stock INT;
SELECT @Stock = stock_quantity
FROM PRODUCT_VARIANT
WHERE prod_id = @TestProdId;

DECLARE @ExceedStock INT;
SET @ExceedStock = @Stock + 100;    -- cố ý > stock

BEGIN TRY
    EXEC sp_AddCartItem
        @CartId   = @TestCartId,
        @ProdId   = @TestProdId,
        @ShopId   = @TestShopId,
        @Quantity = @ExceedStock;
    PRINT N'FAIL 1.5: Cho phép thêm vượt quá tồn kho.';
END TRY
BEGIN CATCH
    PRINT N'SUCCESS 1.5: Đã chặn quantity vượt quá tồn kho. Lỗi: ' + ERROR_MESSAGE();
END CATCH;



/******************************************************************
 * 2. TEST sp_UpdateCartItem – Cập nhật số lượng trong giỏ
 ******************************************************************/
PRINT N'========== 2. TEST sp_UpdateCartItem ==========';

-- Cập nhật lại cart_item_id (phòng khi ở bước 1 thay đổi)
SELECT TOP (1) @TestCartItemId = cart_item_id
FROM CART_ITEM
WHERE cart_id = @TestCartId
  AND prod_id = @TestProdId
  AND shop_id = @TestShopId;

SET @msg = N'-- CART_ITEM dùng để test UPDATE, cart_item_id = '
           + CAST(@TestCartItemId AS nvarchar(10));
PRINT @msg;

SELECT * FROM CART_ITEM WHERE cart_item_id = @TestCartItemId;


------------------------------------------------------------
-- 2.1 VALID: cập nhật quantity = 5
------------------------------------------------------------
PRINT N'--- 2.1 VALID: Cập nhật quantity = 5 ---';

EXEC sp_UpdateCartItem
    @CartItemId  = @TestCartItemId,
    @NewQuantity = 5;

PRINT N'Kết quả sau 2.1:';
SELECT * FROM CART_ITEM WHERE cart_item_id = @TestCartItemId;


------------------------------------------------------------
-- 2.2 INVALID: quantity mới <= 0
------------------------------------------------------------
PRINT N'--- 2.2 INVALID: quantity mới <= 0 ---';
BEGIN TRY
    EXEC sp_UpdateCartItem
        @CartItemId  = @TestCartItemId,
        @NewQuantity = 0;
    PRINT N'FAIL 2.2: Cho phép cập nhật quantity mới <= 0.';
END TRY
BEGIN CATCH
    PRINT N'SUCCESS 2.2: Đã chặn quantity mới <= 0. Lỗi: ' + ERROR_MESSAGE();
END CATCH;


------------------------------------------------------------
-- 2.3 INVALID: cart_item_id không tồn tại
------------------------------------------------------------
PRINT N'--- 2.3 INVALID: cart_item_id không tồn tại ---';
BEGIN TRY
    EXEC sp_UpdateCartItem
        @CartItemId  = -1,          -- id không tồn tại
        @NewQuantity = 3;
    PRINT N'FAIL 2.3: Cho phép cập nhật cart_item_id không tồn tại.';
END TRY
BEGIN CATCH
    PRINT N'SUCCESS 2.3: Đã chặn cart_item_id không tồn tại. Lỗi: ' + ERROR_MESSAGE();
END CATCH;


------------------------------------------------------------
-- 2.4 INVALID: quantity mới vượt quá stock
------------------------------------------------------------
PRINT N'--- 2.4 INVALID: quantity mới vượt quá stock ---';

DECLARE @Stock2 INT;
SELECT @Stock2 = stock_quantity
FROM PRODUCT_VARIANT
WHERE prod_id = @TestProdId;

DECLARE @TooMuchQty INT;
SET @TooMuchQty = @Stock2 + 100;    -- cố ý > stock

BEGIN TRY
    EXEC sp_UpdateCartItem
        @CartItemId  = @TestCartItemId,
        @NewQuantity = @TooMuchQty;
    PRINT N'FAIL 2.4: Cho phép cập nhật quantity vượt quá stock.';
END TRY
BEGIN CATCH
    PRINT N'SUCCESS 2.4: Đã chặn quantity vượt quá stock. Lỗi: ' + ERROR_MESSAGE();
END CATCH;



/******************************************************************
 * 3. TEST sp_DeleteCartItem – Xoá sản phẩm khỏi giỏ
 ******************************************************************/
PRINT N'========== 3. TEST sp_DeleteCartItem ==========';

------------------------------------------------------------
-- 3.1 VALID: xoá cart_item test
------------------------------------------------------------
PRINT N'--- 3.1 VALID: Xoá cart_item test ---';

EXEC sp_DeleteCartItem
    @CartItemId = @TestCartItemId;

PRINT N'Kết quả sau 3.1 (mong đợi: 0 dòng):';
SELECT * FROM CART_ITEM WHERE cart_item_id = @TestCartItemId;


------------------------------------------------------------
-- 3.2 INVALID: xoá lại cart_item vừa xoá
------------------------------------------------------------
PRINT N'--- 3.2 INVALID: Xoá lại cart_item đã xoá ---';
BEGIN TRY
    EXEC sp_DeleteCartItem
        @CartItemId = @TestCartItemId;
    PRINT N'FAIL 3.2: Cho phép xoá cart_item không tồn tại.';
END TRY
BEGIN CATCH
    PRINT N'SUCCESS 3.2: Đã chặn xoá cart_item không tồn tại. Lỗi: ' + ERROR_MESSAGE();
END CATCH;


PRINT N'--- KẾT THÚC TEST CASES PHẦN 2.1 (CART_ITEM) ---';
GO
