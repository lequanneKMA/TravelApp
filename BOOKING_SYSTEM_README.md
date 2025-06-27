# Cập nhật hệ thống quản lý trạng thái đơn hàng và hóa đơn

## Tính năng mới được thêm:

### 1. Hệ thống trạng thái booking (đặt tour)
- **Trạng thái đơn hàng:**
  - `pending` (Đang chờ): Đơn mới được tạo, chờ thanh toán
  - `paid` (Đã thanh toán): Khách hàng đã thanh toán, tour được xác nhận
  - `completed` (Đã hoàn thành): Tour đã kết thúc

### 2. Hệ thống hóa đơn (Invoice)
- **Tự động tạo hóa đơn** khi booking chuyển sang trạng thái "Đã thanh toán"
- **Thông tin đầy đủ**: Số hóa đơn, ngày xuất, hạn thanh toán, chi tiết dịch vụ
- **Trạng thái hóa đơn**: Chưa thanh toán, Đã thanh toán
- **Tự động kiểm tra quá hạn** và cập nhật trạng thái

### 3. Giao diện quản lý cho Admin
- **Quản lý đặt tour**: Xem, tìm kiếm, filter theo trạng thái, cập nhật trạng thái
- **Quản lý hóa đơn**: Xem chi tiết, xác nhận thanh toán, thống kê doanh thu
- **Thống kê**: Số lượng booking theo trạng thái, doanh thu tổng, doanh thu theo tháng

### 4. Giao diện cho người dùng
- **Xem lịch sử booking** với trạng thái real-time
- **Xem hóa đơn cá nhân** với thông tin chi tiết
- **Chat với admin** về tour cụ thể hoặc tư vấn chung

## Cấu trúc dữ liệu mới:

### Collection `bookings`:
```
{
  "userId": "string",
  "tourId": "string", 
  "tourName": "string",
  "userName": "string",
  "userEmail": "string",
  "userPhone": "string",
  "dateStart": "string",
  "numPeople": "number",
  "totalPrice": "number",
  "status": "pending|paid|completed",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "paymentMethod": "string",
  "notes": "string",
  "adminNotes": "string",
  "cancelReason": "string"
}
```

### Collection `invoices`:
```
{
  "bookingId": "string",
  "userId": "string",
  "userName": "string",
  "userEmail": "string",
  "userPhone": "string",
  "userAddress": "string",
  "invoiceNumber": "string",
  "issueDate": "timestamp",
  "dueDate": "timestamp",
  "items": [
    {
      "description": "string",
      "quantity": "number",
      "unitPrice": "number", 
      "totalPrice": "number"
    }
  ],
  "subtotal": "number",
  "discount": "number",
  "tax": "number",
  "totalAmount": "number",
  "status": "unpaid|paid",
  "paymentMethod": "string",
  "paidDate": "timestamp",
  "notes": "string",
  "bankInfo": "string"
}
```

## Luồng hoạt động:

### 1. Đặt tour:
1. User đặt tour → Tạo booking với status = `pending`
2. Admin xem booking trong "Quản lý đặt tour"
3. Admin liên hệ khách hàng qua chat
4. Khi khách thanh toán → Admin cập nhật status = `paid` và tự động tạo hóa đơn
5. Sau khi tour kết thúc → status = `completed`

### 2. Quản lý hóa đơn:
1. Hóa đơn được tạo tự động khi booking = `paid`
2. Admin có thể xem chi tiết, xác nhận thanh toán
3. User có thể xem hóa đơn của mình trong profile

### 3. Migration dữ liệu:
- Dữ liệu cũ từ `booked_tours` được chuyển sang `bookings` với cấu trúc mới
- Tự động tính tổng tiền dựa trên giá tour và số người
- Cập nhật thông tin user từ collection `users`

## Cách sử dụng:

### Cho Admin:
1. Vào "Admin Home" → "Quản lý đặt tour"
2. Xem danh sách booking, filter theo trạng thái
3. Click vào booking để xem chi tiết
4. Cập nhật trạng thái khi cần thiết
5. Vào "Quản lý hóa đơn" để xem và quản lý hóa đơn

### Cho User:
1. Đặt tour như bình thường
2. Xem trạng thái booking trong "Các tour bạn đã đặt"
3. Chat với admin về tour cụ thể
4. Xem hóa đơn trong Profile → "Xem hóa đơn của tôi"

## Lưu ý kỹ thuật:
- Sử dụng Firestore transactions để đảm bảo tính nhất quán
- Stream real-time để cập nhật UI ngay lập tức
- Validation đầy đủ cho tất cả trạng thái chuyển đổi
- Error handling và user feedback
- Migration script để chuyển đổi dữ liệu cũ
