from flask import Flask, render_template, request, redirect, url_for, flash, session
import pyodbc
from decimal import Decimal

app = Flask(__name__)
# KHÓA BÍ MẬT LÀ BẮT BUỘC để Session hoạt động ổn định
app.secret_key = 'KEY_BI_MAT_CUA_BAN_ABCXYZ' 

# --- CẤU HÌNH KẾT NỐI CSDL CỦA BẠN ---
DRIVER = '{ODBC Driver 17 for SQL Server}'
SERVER = 'QUANGHUY'
DATABASE = 'SHOPEE_CLONE' 

CONNECTION_STRING = (
    f"DRIVER={DRIVER};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    f"Trusted_Connection=yes;"
    f"TrustServerCertificate=yes;"
)

# --- CÁC HÀM XỬ LÝ CSDL CHUNG ---

def execute_select(sql, params=None):
    conn = None
    try:
        conn = pyodbc.connect(CONNECTION_STRING)
        cursor = conn.cursor()
        cursor.execute(sql, params if params else ())
        columns = [column[0] for column in cursor.description]
        data = [dict(zip(columns, row)) for row in cursor.fetchall()]
        return data, columns
    except Exception as e:
        print(f"LỖI SELECT CSDL: {e}")
        flash(f"LỖI KẾT NỐI/TRUY VẤN: {e}", 'error')
        return [], []
    finally:
        if conn:
            conn.close()

def execute_non_query(sql, params=None):
    conn = None
    try:
        conn = pyodbc.connect(CONNECTION_STRING)
        cursor = conn.cursor()
        cursor.execute(sql, params if params else ())
        conn.commit()
        return True
    except Exception as e:
        flash(f"LỖI THAO TÁC CSDL: {e}", 'error')
        print(f"LỖI NON-QUERY CSDL: {e}")
        return False
    finally:
        if conn:
            conn.close()

# --- BỘ LỌC JINJA2 ---
def format_currency(value):
    try:
        return "{:,.0f} VNĐ".format(value).replace(",", "#").replace(".", ",").replace("#", ".")
    except:
        return str(value)

app.jinja_env.filters['format_currency'] = format_currency


# --- ROUTES XÁC THỰC VÀ PHÂN QUYỀN ---

@app.route('/')
def index():
    if 'user_id' not in session: return redirect(url_for('login'))
    if session.get('is_shop'): return redirect(url_for('seller_dashboard'))
    elif session.get('is_customer'): return redirect(url_for('customer_dashboard'))
    return redirect(url_for('logout'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if 'user_id' in session: return redirect(url_for('index'))
        
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password') 

        sql_user = "SELECT user_id, username FROM [USER] WHERE email = ? AND password = ?"
        user_data, _ = execute_select(sql_user, (email, password))
        
        if user_data:
            user_id = user_data[0]['user_id']
            session['user_id'] = user_id
            session['username'] = user_data[0]['username']
            
            sql_shop = "SELECT shop_id FROM SHOP WHERE shop_id = ?"
            sql_customer = "SELECT customer_id FROM CUSTOMER WHERE customer_id = ?"
            session['is_shop'] = len(execute_select(sql_shop, (user_id,))[0]) > 0 
            session['is_customer'] = len(execute_select(sql_customer, (user_id,))[0]) > 0 
            
            if session['is_shop']:
                flash(f'Đăng nhập thành công! Vai trò kép (SHOP & CUSTOMER).', 'success')
                return redirect(url_for('seller_dashboard'))
            elif session['is_customer']:
                flash(f'Đăng nhập thành công! Vai trò CUSTOMER.', 'success')
                return redirect(url_for('customer_dashboard'))
            else:
                flash('Tài khoản không có vai trò (Shop/Customer).', 'error')
                return redirect(url_for('login'))
        else:
            flash('Email hoặc mật khẩu không đúng. Vui lòng thử lại.', 'error')
            return redirect(url_for('login')) 
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    flash('Bạn đã đăng xuất.', 'success')
    return redirect(url_for('login'))


# --- 1. ROUTES CHO KHÁCH HÀNG (TÍCH HỢP FUNCTIONS & SP) ---

@app.route('/customer/dashboard', methods=['GET'])
def customer_dashboard():
    if 'user_id' not in session or not session.get('is_customer'):
        flash('Bạn cần đăng nhập với tài khoản Customer.', 'error')
        return redirect(url_for('login'))

    user_id = session['user_id']
    search_results = [] # Khởi tạo biến
    
    # --- TÍCH HỢP 3 FUNCTIONS ---
    sql_func_cart_total = "SELECT dbo.fn_TinhTongTienGioHang(?)"
    cart_total_result, _ = execute_select(sql_func_cart_total, (user_id,))
    cart_total = cart_total_result[0][list(cart_total_result[0].keys())[0]] if cart_total_result else 0
    
    sql_func_tier_check = "SELECT * FROM dbo.fn_KiemTraThangHangThanhVien(?)"
    tier_check_result, _ = execute_select(sql_func_tier_check, (user_id,))
    tier_info = tier_check_result[0] if tier_check_result else {}
    
    sql_func_stock = "SELECT dbo.fn_KiemTraTrangThaiTonKho(?, ?)"
    stock_check_result, _ = execute_select(sql_func_stock, (1, 5)) 
    stock_status_sp1 = stock_check_result[0][list(stock_check_result[0].keys())[0]] if stock_check_result else 'Lỗi kiểm tra'
    
    # --- TRUY VẤN DỮ LIỆU CƠ BẢN ---
    sql_info = """
    SELECT U.username, U.email, U.phone_number, U.gender, U.day_of_birth, C.total_spending, T.tier_name
    FROM [USER] U LEFT JOIN CUSTOMER C ON U.user_id = C.customer_id
    LEFT JOIN MEMBERSHIP_TIER T ON C.tier_id = T.tier_id WHERE U.user_id = ?
    """
    user_info, _ = execute_select(sql_info, (user_id,))
    
    sql_orders = """
    SELECT TOP 5 OG.order_group_id, OG.total_payment, OG.created_at, OG.ship_address,
    (SELECT TOP 1 OS.[status] FROM ORDER_STATUS OS JOIN [ORDER] O ON OS.order_id = O.order_id WHERE O.order_group_id = OG.order_group_id ORDER BY status_timestamp DESC) AS latest_status
    FROM ORDER_GROUP OG WHERE OG.customer_id = ? ORDER BY OG.created_at DESC
    """
    order_history, _ = execute_select(sql_orders, (user_id,))
    
    sql_cart = """
    SELECT PV.prod_name, CI.quantity, CI.sub_total, U_Shop.username AS ShopName
    FROM CART C JOIN CART_ITEM CI ON C.cart_id = CI.cart_id JOIN PRODUCT_VARIANT PV ON CI.prod_id = PV.prod_id
    JOIN [USER] U_Shop ON CI.shop_id = U_Shop.user_id WHERE C.user_id = ?
    """
    cart_items, _ = execute_select(sql_cart, (user_id,))

    # --- TRUY VẤN VOUCHER VÀ ÁP DỤNG FUNCTION KIỂM TRA ---
    sql_vouchers = """
    SELECT 
        V.voucher_id, V.description, V.discount_type, V.condition, V.valid_to, V.quantity_available
    FROM CUSTOMER_VOUCHER CV JOIN VOUCHER V ON CV.voucher_id = V.voucher_id
    WHERE CV.customer_id = ? ORDER BY V.valid_to DESC
    """
    current_vouchers, _ = execute_select(sql_vouchers, (user_id,))
    
    vouchers_with_status = []
    for voucher in current_vouchers:
        sql_check = "SELECT dbo.fn_KiemTraVoucherHopLe(?, ?, ?)"
        check_result, _ = execute_select(sql_check, (voucher['voucher_id'], cart_total, user_id))
        
        if check_result:
            status = check_result[0][list(check_result[0].keys())[0]]
        else:
            status = 'Lỗi kết nối kiểm tra';
        
        voucher['is_valid_for_cart'] = (status == 'Hợp lệ')
        voucher['validation_reason'] = status
        vouchers_with_status.append(voucher)

    # --- TÍCH HỢP SP: sp_ThongKeSanPhamChiTiet (CHO TAB SẢN PHẨM) VÀ SẮP XẾP ---
    ten_dm = request.args.get('ten_dm')
    min_rating = request.args.get('min_rating')
    min_sales = request.args.get('min_sales')
    sort_by = request.args.get('sort_by')
    order = request.args.get('order', 'desc') 

    p_min_rating = None
    try:
        if min_rating: p_min_rating = float(min_rating)
    except (ValueError, TypeError): pass

    p_min_sales = None
    try:
        if min_sales: p_min_sales = int(min_sales)
    except (ValueError, TypeError): pass
        
    params = (None, ten_dm, p_min_sales, p_min_rating)
    sql_sp_search = "EXEC sp_ThongKeSanPhamChiTiet @ShopID = ?, @CategoryName = ?, @MinTotalSales = ?, @MinAvgRating = ?"
    search_results, _ = execute_select(sql_sp_search, params)

    # Áp dụng SẮP XẾP trong Python
    if search_results and sort_by:
        reverse_order = (order == 'desc')
        
        if sort_by == 'AvgRating':
            sort_key = lambda x: float(x.get('AvgRating') or 0.0) 
        elif sort_by == 'TotalUnitsSold':
            sort_key = lambda x: int(x.get('TotalUnitsSold') or 0)
        elif sort_by == 'CurrentPrice':
            sort_key = lambda x: float(x.get('CurrentPrice') or 0.0)
        else:
            sort_key = lambda x: x.get('TotalRevenueGenerated')
            
        try:
            search_results.sort(key=sort_key, reverse=reverse_order)
        except Exception as e:
            print(f"Lỗi sắp xếp: {e}")
            flash(f"Lỗi sắp xếp dữ liệu: {e}", 'error')

    return render_template('customer_dashboard.html', 
                           user_data=user_info[0] if user_info else {},
                           order_history=order_history,
                           cart_items=cart_items,
                           is_shop_user=session.get('is_shop', False),
                           cart_total=cart_total,
                           tier_info=tier_info,
                           stock_status_sp1=stock_status_sp1,
                           vouchers_with_status=vouchers_with_status,
                           search_results=search_results,
                           current_sort_by=sort_by,
                           current_order=order)


# --- 2. ROUTES CHO NGƯỜI BÁN (TÍCH HỢP STORED PROCEDURES) ---

@app.route('/seller/dashboard')
def seller_dashboard():
    if 'user_id' not in session or not session.get('is_shop'):
        flash('Bạn cần đăng nhập với tài khoản Shop.', 'error')
        return redirect(url_for('login'))
        
    SHOP_ID = session['user_id']
    
    # Lấy tham số Tìm kiếm/Lọc
    keyword = request.args.get('keyword', '').lower()
    status_filter = request.args.get('status_filter')
    
    # Tích hợp SP: sp_HienThiSanPhamTheoTenVaGia
    sql_sp_list = "EXEC sp_HienThiSanPhamTheoTenVaGia @TenSanPham = NULL, @GiaMin = NULL, @GiaMax = NULL"
    all_products_sp, columns = execute_select(sql_sp_list)
    
    item_names_of_shop = [item['item_name'] for item in execute_select("SELECT item_name FROM ITEM WHERE shop_id = ?", (SHOP_ID,))[0]]
    
    # Áp dụng Lọc trong Python (Filter Logic)
    products = []
    for p in all_products_sp:
        # Lọc theo Shop hiện tại
        if p.get('item_name') in item_names_of_shop:
            
            # Lọc theo Tên Sản phẩm / Item Name (Keyword)
            name_match = True
            if keyword:
                prod_name = str(p.get('prod_name', '')).lower()
                item_name = str(p.get('item_name', '')).lower()
                if keyword not in prod_name and keyword not in item_name:
                    name_match = False
            
            # Lọc theo Trạng thái (Dropdown)
            status_match = True
            if status_filter:
                current_status = str(p.get('status', ''))
                if status_filter == 'Còn hàng':
                    if p.get('stock_quantity', 0) <= 0:
                        status_match = False
                elif status_filter != 'Còn hàng' and status_filter != current_status:
                    status_match = False

            if name_match and status_match:
                products.append(p)

    return render_template('seller_dashboard.html', 
                           products=products, 
                           columns=columns, 
                           shop_id=SHOP_ID,
                           is_customer_user=session.get('is_customer', False),
                           current_keyword=keyword,
                           current_status=status_filter) 

@app.route('/seller/reports', methods=['GET'])
def seller_reports():
    if 'user_id' not in session or not session.get('is_shop'):
        flash('Bạn cần đăng nhập với tài khoản Shop để truy cập báo cáo.', 'error')
        return redirect(url_for('login'))
        
    SHOP_ID = session['user_id']
    
    sql_sp_revenue = "EXEC sp_ThongKeDoanhSoVaRatingShop @NgayBatDau = NULL, @NgayKetThuc = NULL, @RatingShopMin = NULL"
    all_revenue, revenue_cols = execute_select(sql_sp_revenue)
    revenue_data = [r for r in all_revenue if r['shop_id'] == SHOP_ID]
    
    sql_sp_stats = "EXEC sp_ThongKeSanPhamChiTiet @ShopID = ?, @CategoryName = NULL, @MinTotalSales = 1, @MinAvgRating = NULL"
    product_stats, stats_cols = execute_select(sql_sp_stats, (SHOP_ID,))
    
    return render_template('seller_reports.html',
                           revenue_data=revenue_data,
                           product_stats=product_stats,
                           shop_id=SHOP_ID,
                           is_customer_user=session.get('is_customer', False))

# --- Route Chi tiết Sản phẩm ---
@app.route('/product/<int:prod_id>')
def product_detail(prod_id):
    if 'user_id' not in session: 
        flash('Vui lòng đăng nhập để xem chi tiết sản phẩm.', 'error')
        return redirect(url_for('login'))

    # 1. Truy vấn thông tin chi tiết cơ bản
    sql_detail = """
    SELECT PV.*, PV.rating_avg, PV.total_sales, I.item_name, C.category_name, U_Shop.username AS ShopName, U_Shop.phone_number AS ShopPhone
    FROM PRODUCT_VARIANT PV INNER JOIN ITEM I ON PV.item_id = I.item_id
    INNER JOIN CATEGORY C ON I.category_id = C.category_id
    INNER JOIN [USER] U_Shop ON I.shop_id = U_Shop.user_id
    WHERE PV.prod_id = ?
    """
    detail_data, _ = execute_select(sql_detail, (prod_id,))
    
    if not detail_data:
        flash(f'Sản phẩm ID {prod_id} không tồn tại.', 'error')
        return redirect(url_for('customer_dashboard')) 

    product = detail_data[0]
    
    # 2. TRUY VẤN THÔNG TIN BỔ SUNG:
    sql_spec = "SELECT size, color FROM PRODUCT_SPECIFICATION WHERE prod_id = ?"
    specs_data, _ = execute_select(sql_spec, (prod_id,))
    
    sql_attr = "SELECT attribute_size, is_primary FROM PRODUCT_ATTRIBUTE WHERE prod_id = ?"
    attrs_data, _ = execute_select(sql_attr, (prod_id,))

    sql_review_stats = """
    SELECT 
        COUNT(review_id) AS total_reviews, 
        AVG(rating * 1.0) AS calculated_rating_avg 
    FROM REVIEW 
    WHERE product_id = ?
    """
    review_stats, _ = execute_select(sql_review_stats, (prod_id,))
    
    total_reviews = review_stats[0]['total_reviews'] if review_stats and review_stats[0]['total_reviews'] is not None else 0
    calculated_rating_avg = review_stats[0]['calculated_rating_avg'] if review_stats and review_stats[0]['calculated_rating_avg'] is not None else 0.0

    sql_reviews = """
    SELECT TOP 5 
        R.rating, R.comment, R.created_at, U_Cust.username AS CustomerName
    FROM REVIEW R INNER JOIN CUSTOMER C ON R.customer_id = C.customer_id
    INNER JOIN [USER] U_Cust ON C.customer_id = U_Cust.user_id
    WHERE R.product_id = ?
    ORDER BY R.created_at DESC
    """
    reviews, _ = execute_select(sql_reviews, (prod_id,))

    return render_template('product_detail.html',
                           product=product,
                           reviews=reviews,
                           specs=specs_data,
                           attributes=attrs_data,
                           total_reviews=total_reviews,
                           calculated_rating_avg=calculated_rating_avg)

# --- Các hàm CRUD (add_product, delete_product) cần được chèn vào đây ---
@app.route('/seller/add_product', methods=['GET', 'POST'])
def add_product():
    # Thêm logic CRUD của bạn vào đây
    return "Trang thêm sản phẩm (CRUD logic cần được sao chép vào đây)"

@app.route('/seller/delete_product/<int:prod_id>', methods=['POST'])
def delete_product(prod_id):
    # Thêm logic CRUD của bạn vào đây
    return "Xóa sản phẩm (CRUD logic cần được sao chép vào đây)"


if __name__ == '__main__':
    app.run(debug=True)