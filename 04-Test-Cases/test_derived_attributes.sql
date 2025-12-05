USE SHOPEE_CLONE;
GO

PRINT N'========== TEST DERIVED ATTRIBUTE TRIGGERS ==========';

-------------------------------------------------------------
-- TEST 1: CUSTOMER.total_spending (trg_CUSTOMER_UpdateTotalSpending)
-- total_spending = SUM(ORDER_GROUP.total_payment)
-------------------------------------------------------------
USE SHOPEE_CLONE;
DECLARE @CustId INT = 1;
DECLARE @NewOrderGroupId INT;

PRINT N'--- TEST 1: CUSTOMER.total_spending ---';
PRINT N'--- BEFORE (CUSTOMER.total_spending vs SUM(ORDER_GROUP.total_payment)) ---';

SELECT 'Before' AS [Step],
       c.customer_id,
       c.total_spending AS current_total,
       ISNULL(SUM(og.total_payment),0) AS expected_from_orders
FROM CUSTOMER c
LEFT JOIN ORDER_GROUP og ON og.customer_id = c.customer_id
WHERE c.customer_id = @CustId
GROUP BY c.customer_id, c.total_spending;

PRINT N'--- INSERT 1 ORDER_GROUP MỚI CHO CUSTOMER 1 ---';

INSERT INTO ORDER_GROUP (customer_id, voucher_id, total_amount, payment_id,
                         created_at, coin_shopee, total_delivery, total_discount,
                         total_payment, ship_address)
VALUES (@CustId, NULL, 500000, NULL,
        GETDATE(), 0, 15000, 0, 515000, N'Địa chỉ test trigger total_spending');
SET @NewOrderGroupId = SCOPE_IDENTITY();

PRINT N'--- AFTER INSERT ORDER_GROUP ---';

SELECT 'After INSERT' AS [Step],
       c.customer_id,
       c.total_spending AS current_total,
       ISNULL(SUM(og.total_payment),0) AS expected_from_orders
FROM CUSTOMER c
LEFT JOIN ORDER_GROUP og ON og.customer_id = c.customer_id
WHERE c.customer_id = @CustId
GROUP BY c.customer_id, c.total_spending;

PRINT N'--- UPDATE total_payment CỦA ORDER_GROUP VỪA THÊM ---';

UPDATE ORDER_GROUP
SET total_payment = 615000
WHERE order_group_id = @NewOrderGroupId;

SELECT 'After UPDATE total_payment' AS [Step],
       c.customer_id,
       c.total_spending AS current_total,
       ISNULL(SUM(og.total_payment),0) AS expected_from_orders
FROM CUSTOMER c
LEFT JOIN ORDER_GROUP og ON og.customer_id = c.customer_id
WHERE c.customer_id = @CustId
GROUP BY c.customer_id, c.total_spending;

PRINT N'--- DELETE ORDER_GROUP TEST ---';

DELETE FROM ORDER_GROUP
WHERE order_group_id = @NewOrderGroupId;

SELECT 'After DELETE order_group' AS [Step],
       c.customer_id,
       c.total_spending AS current_total,
       ISNULL(SUM(og.total_payment),0) AS expected_from_orders
FROM CUSTOMER c
LEFT JOIN ORDER_GROUP og ON og.customer_id = c.customer_id
WHERE c.customer_id = @CustId
GROUP BY c.customer_id, c.total_spending;
GO

-------------------------------------------------------------
-- TEST 2:
--   - ORDER_DETAIL.total_price        (trg_ORDER_DETAIL_SetTotalPrice)
--   - ORDER.total_amount              (trg_ORDER_DETAIL_UpdateAggregates)
--   - PRODUCT_VARIANT.total_sales
--   - SHOP.Total_sales
-------------------------------------------------------------
USE SHOPEE_CLONE;
DECLARE @TestCustomerId INT = 1;
DECLARE @TestProductId INT = 1;  -- iPhone 15 Pro Max 256GB
DECLARE @TestShopId INT;
DECLARE @TestOrderGroupId INT;
DECLARE @TestOrderId INT;
DECLARE @TestOrderDetailId INT;

PRINT N'--- TEST 2: ORDER_DETAIL + ORDER + PRODUCT_VARIANT.total_sales + SHOP.Total_sales ---';

-- Lấy shop_id của sản phẩm test
SELECT @TestShopId = it.shop_id
FROM PRODUCT_VARIANT pv
JOIN ITEM it ON it.item_id = pv.item_id
WHERE pv.prod_id = @TestProductId;

PRINT N'--- TẠO ORDER_GROUP + ORDER TEST ---';

INSERT INTO ORDER_GROUP (customer_id, voucher_id, total_amount, payment_id,
                         created_at, coin_shopee, total_delivery, total_discount,
                         total_payment, ship_address)
VALUES (@TestCustomerId, NULL, 0, NULL,
        GETDATE(), 0, 0, 0, 0, N'Địa chỉ test aggregates');
SET @TestOrderGroupId = SCOPE_IDENTITY();

INSERT INTO [ORDER] (order_group_id, customer_id, shop_id, total_amount, ship_method, shipping_id)
VALUES (@TestOrderGroupId, @TestCustomerId, @TestShopId, 0, N'Nhanh', NULL);
SET @TestOrderId = SCOPE_IDENTITY();

PRINT N'--- BEFORE (CHƯA CÓ ORDER_DETAIL) ---';

SELECT 'Before' AS [Step],
       o.order_id,
       o.total_amount,
       ISNULL(SUM(od.quantity * od.price),0) AS detail_sum
FROM [ORDER] o
LEFT JOIN ORDER_DETAIL od ON od.order_id = o.order_id
WHERE o.order_id = @TestOrderId
GROUP BY o.order_id, o.total_amount;

SELECT 'Before' AS [Step],
       pv.prod_id,
       pv.prod_name,
       pv.total_sales
FROM PRODUCT_VARIANT pv
WHERE pv.prod_id = @TestProductId;

SELECT 'Before' AS [Step],
       s.shop_id,
       s.Address,
       s.Total_sales
FROM SHOP s
WHERE s.shop_id = @TestShopId;

PRINT N'--- INSERT 1 ORDER_DETAIL (quantity = 2, price = 123456) ---';

INSERT INTO ORDER_DETAIL (order_id, product_id, product_specification,
                          quantity, price, total_price, note)
VALUES (@TestOrderId, @TestProductId, N'Test spec', 2, 123456, NULL, N'Test derived triggers');
SET @TestOrderDetailId = SCOPE_IDENTITY();

PRINT N'--- AFTER INSERT ORDER_DETAIL ---';

-- Kiểm tra total_price được trigger tính = quantity * price
SELECT 'After INSERT' AS [Step],
       od.order_detail_id,
       od.order_id,
       od.product_id,
       od.quantity,
       od.price,
       od.total_price   -- phải = 2 * 123456
FROM ORDER_DETAIL od
WHERE od.order_detail_id = @TestOrderDetailId;

-- ORDER.total_amount
SELECT 'After INSERT' AS [Step],
       o.order_id,
       o.total_amount,
       ISNULL(SUM(od.quantity * od.price),0) AS detail_sum
FROM [ORDER] o
LEFT JOIN ORDER_DETAIL od ON od.order_id = o.order_id
WHERE o.order_id = @TestOrderId
GROUP BY o.order_id, o.total_amount;

-- PRODUCT_VARIANT.total_sales
SELECT 'After INSERT' AS [Step],
       pv.prod_id,
       pv.prod_name,
       pv.total_sales
FROM PRODUCT_VARIANT pv
WHERE pv.prod_id = @TestProductId;

-- SHOP.Total_sales
SELECT 'After INSERT' AS [Step],
       s.shop_id,
       s.Address,
       s.Total_sales
FROM SHOP s
WHERE s.shop_id = @TestShopId;

PRINT N'--- UPDATE ORDER_DETAIL: quantity = 3 ---';

UPDATE ORDER_DETAIL
SET quantity = 3
WHERE order_detail_id = @TestOrderDetailId;

SELECT 'After UPDATE quantity=3' AS [Step],
       od.order_detail_id,
       od.order_id,
       od.product_id,
       od.quantity,
       od.price,
       od.total_price
FROM ORDER_DETAIL od
WHERE od.order_detail_id = @TestOrderDetailId;

SELECT 'After UPDATE' AS [Step],
       o.order_id,
       o.total_amount,
       ISNULL(SUM(od.quantity * od.price),0) AS detail_sum
FROM [ORDER] o
LEFT JOIN ORDER_DETAIL od ON od.order_id = o.order_id
WHERE o.order_id = @TestOrderId
GROUP BY o.order_id, o.total_amount;

SELECT 'After UPDATE' AS [Step],
       pv.prod_id,
       pv.prod_name,
       pv.total_sales
FROM PRODUCT_VARIANT pv
WHERE pv.prod_id = @TestProductId;

SELECT 'After UPDATE' AS [Step],
       s.shop_id,
       s.Address,
       s.Total_sales
FROM SHOP s
WHERE s.shop_id = @TestShopId;

PRINT N'--- DELETE ORDER_DETAIL TEST (DỌN DATA) ---';

DELETE FROM ORDER_DETAIL
WHERE order_detail_id = @TestOrderDetailId;

DELETE FROM [ORDER]
WHERE order_id = @TestOrderId;

DELETE FROM ORDER_GROUP
WHERE order_group_id = @TestOrderGroupId;

SELECT 'After DELETE test data' AS [Step],
       pv.prod_id,
       pv.prod_name,
       pv.total_sales
FROM PRODUCT_VARIANT pv
WHERE pv.prod_id = @TestProductId;

SELECT 'After DELETE test data' AS [Step],
       s.shop_id,
       s.Address,
       s.Total_sales
FROM SHOP s
WHERE s.shop_id = @TestShopId;
GO

-------------------------------------------------------------
-- TEST 3: CART.total_product + CART.total_payment
--         (trg_CART_ITEM_UpdateCartTotals)
-------------------------------------------------------------
USE SHOPEE_CLONE;
DECLARE @TestCartId INT = 1;
DECLARE @NewCartItemId INT;

PRINT N'--- TEST 3: CART.total_product & total_payment ---';

PRINT N'--- BEFORE CART TOTALS ---';
SELECT 'Before' AS [Step],
       c.cart_id,
       c.total_product,
       c.total_payment,
       ISNULL(SUM(ci.quantity),0) AS expected_qty,
       ISNULL(SUM(ci.sub_total),0) AS expected_sub_total
FROM CART c
LEFT JOIN CART_ITEM ci ON ci.cart_id = c.cart_id
WHERE c.cart_id = @TestCartId
GROUP BY c.cart_id, c.total_product, c.total_payment;

PRINT N'--- INSERT CART_ITEM MỚI ---';

INSERT INTO CART_ITEM (prod_id, cart_id, shop_id, quantity, sub_total)
VALUES (1, @TestCartId, 3, 2, 999999);   -- prod_id=1 (ip), shop_id=3
SET @NewCartItemId = SCOPE_IDENTITY();

SELECT 'After INSERT' AS [Step],
       c.cart_id,
       c.total_product,
       c.total_payment,
       ISNULL(SUM(ci.quantity),0) AS expected_qty,
       ISNULL(SUM(ci.sub_total),0) AS expected_sub_total
FROM CART c
LEFT JOIN CART_ITEM ci ON ci.cart_id = c.cart_id
WHERE c.cart_id = @TestCartId
GROUP BY c.cart_id, c.total_product, c.total_payment;

PRINT N'--- UPDATE CART_ITEM: quantity = 3, sub_total = 1234567 ---';

UPDATE CART_ITEM
SET quantity = 3,
    sub_total = 1234567
WHERE cart_item_id = @NewCartItemId;

SELECT 'After UPDATE' AS [Step],
       c.cart_id,
       c.total_product,
       c.total_payment,
       ISNULL(SUM(ci.quantity),0) AS expected_qty,
       ISNULL(SUM(ci.sub_total),0) AS expected_sub_total
FROM CART c
LEFT JOIN CART_ITEM ci ON ci.cart_id = c.cart_id
WHERE c.cart_id = @TestCartId
GROUP BY c.cart_id, c.total_product, c.total_payment;

PRINT N'--- DELETE CART_ITEM TEST ---';

DELETE FROM CART_ITEM
WHERE cart_item_id = @NewCartItemId;

SELECT 'After DELETE test item' AS [Step],
       c.cart_id,
       c.total_product,
       c.total_payment,
       ISNULL(SUM(ci.quantity),0) AS expected_qty,
       ISNULL(SUM(ci.sub_total),0) AS expected_sub_total
FROM CART c
LEFT JOIN CART_ITEM ci ON ci.cart_id = c.cart_id
WHERE c.cart_id = @TestCartId
GROUP BY c.cart_id, c.total_product, c.total_payment;
GO

-------------------------------------------------------------
-- TEST 4: PRODUCT_VARIANT.rating_avg (trg_REVIEW_UpdateRatingAvg)
-------------------------------------------------------------
USE SHOPEE_CLONE;
DECLARE @ReviewTestProdId INT = 1;
DECLARE @ReviewTestCustomerId INT = 1;
DECLARE @NewReviewId INT;

PRINT N'--- TEST 4: PRODUCT_VARIANT.rating_avg ---';

PRINT N'--- BEFORE rating_avg ---';
SELECT 'Before' AS [Step],
       pv.prod_id,
       pv.prod_name,
       pv.rating_avg AS current_rating,
       (SELECT AVG(CAST(r.rating AS FLOAT))
        FROM REVIEW r
        WHERE r.product_id = pv.prod_id) AS expected_rating
FROM PRODUCT_VARIANT pv
WHERE pv.prod_id = @ReviewTestProdId;

PRINT N'--- INSERT REVIEW TEST (rating = 1) ---';

INSERT INTO REVIEW (product_id, customer_id, rating, comment, created_at, image_review)
VALUES (@ReviewTestProdId, @ReviewTestCustomerId, 1,
        N'Review test thấp điểm', GETDATE(), 'rv_test_low.jpg');
SET @NewReviewId = SCOPE_IDENTITY();

SELECT 'After INSERT' AS [Step],
       pv.prod_id,
       pv.prod_name,
       pv.rating_avg AS current_rating,
       (SELECT AVG(CAST(r.rating AS FLOAT))
        FROM REVIEW r
        WHERE r.product_id = pv.prod_id) AS expected_rating
FROM PRODUCT_VARIANT pv
WHERE pv.prod_id = @ReviewTestProdId;

PRINT N'--- UPDATE REVIEW TEST (rating = 5) ---';

UPDATE REVIEW
SET rating = 5,
    comment = N'Review test chỉnh lại 5 sao'
WHERE review_id = @NewReviewId;

SELECT 'After UPDATE rating=5' AS [Step],
       pv.prod_id,
       pv.prod_name,
       pv.rating_avg AS current_rating,
       (SELECT AVG(CAST(r.rating AS FLOAT))
        FROM REVIEW r
        WHERE r.product_id = pv.prod_id) AS expected_rating
FROM PRODUCT_VARIANT pv
WHERE pv.prod_id = @ReviewTestProdId;

PRINT N'--- DELETE REVIEW TEST ---';

DELETE FROM REVIEW
WHERE review_id = @NewReviewId;

SELECT 'After DELETE test review' AS [Step],
       pv.prod_id,
       pv.prod_name,
       pv.rating_avg AS current_rating,
       (SELECT AVG(CAST(r.rating AS FLOAT))
        FROM REVIEW r
        WHERE r.product_id = pv.prod_id) AS expected_rating
FROM PRODUCT_VARIANT pv
WHERE pv.prod_id = @ReviewTestProdId;
GO

PRINT N'========== END TEST DERIVED ATTRIBUTE TRIGGERS ==========';

