----------.NET QUẢN LÝ NHÀ HÀNG
CREATE DATABASE QL_NHAHANG
GO
USE QL_NHAHANG
GO

CREATE TABLE KhachHang (
    MaKhachHang INT PRIMARY KEY IDENTITY(1,1),
    HoTen NVARCHAR(100),
    SoDienThoai NVARCHAR(20),
	SoLuongKhach INT,
)
GO


CREATE TABLE BanAn (
    MaBan INT PRIMARY KEY IDENTITY(1,1),
    SoBan INT,
    SoChoNgoi INT,
	Tang INT,(1, 2, 3....)
    TrangThai NVARCHAR(50) -- Trống, Đã đặt, Đang sử dụng
)GO

CREATE TABLE DatBan (
    MaDatBan INT PRIMARY KEY IDENTITY(1,1),
    MaKhachHang INT FOREIGN KEY REFERENCES KhachHang(MaKhachHang),
    MaBan INT FOREIGN KEY REFERENCES BanAn(MaBan),
    ThoiGianDat DATETIME,
    GhiChu NVARCHAR(255)
)
GO

CREATE TABLE NhanVien (
    MaNhanVien INT PRIMARY KEY IDENTITY(1,1),
    HoTen NVARCHAR(100),
	GioiTinh NVARCHAR(100),
    ChucVu NVARCHAR(50), -- Phục vụ, Quản lý, Đầu bếp
    SoDienThoai NVARCHAR(20),
    NgayVaoLam DATE
)
GO

CREATE TABLE TaiKhoan (
    TenDangNhap NVARCHAR(50) PRIMARY KEY,
    MatKhau NVARCHAR(255),
    MaNhanVien INT FOREIGN KEY REFERENCES NhanVien(MaNhanVien)
)GO


CREATE TABLE MonAn (
    MaMon INT PRIMARY KEY IDENTITY(1,1),
    TenMon NVARCHAR(100),
    MoTa NVARCHAR(255),
    DonGia DECIMAL(10,2),
	HinhAnh NVARCHAR(255),
    LoaiMon NVARCHAR(50),
	SoLuong int-- Khai vị, Món chính, Tráng miệng
)
GO

CREATE TABLE HoaDon (
    MaHoaDon INT PRIMARY KEY IDENTITY(1,1),
    MaBan INT FOREIGN KEY REFERENCES BanAn(MaBan),
    MaNhanVien INT FOREIGN KEY REFERENCES NhanVien(MaNhanVien),
    ThoiGianLap DATETIME DEFAULT GETDATE(),
    TongTien DECIMAL(10,2),
	MaKhachHang INT FOREIGN KEY REFERENCES KhachHang(MaKhachHang),
	GiamGia INT,
    ThanhToan DECIMAL(10,2) DEFAULT 0

)
GO

CREATE TABLE ChiTietHoaDon (
    MaChiTiet INT PRIMARY KEY IDENTITY(1,1),
    MaHoaDon INT FOREIGN KEY REFERENCES HoaDon(MaHoaDon),
    MaMon INT FOREIGN KEY REFERENCES MonAn(MaMon),
    SoLuong INT,
    ThanhTien DECIMAL,
)
GO


CREATE TABLE KhuyenMai (
    MaKM INT PRIMARY KEY IDENTITY(1,1),
    TenKM NVARCHAR(100),
    MoTa NVARCHAR(255),
    PhanTramGiam INT CHECK (PhanTramGiam BETWEEN 0 AND 100),
    NgayBatDau DATE,
    NgayKetThuc DATE
)
GO

--thêm vào hi tiết hóa đơn nếu đã tồn tại thì tăng sl
CREATE PROCEDURE sp_ThemMonVaoHoaDon
    @MaHoaDon INT,
    @MaMon INT
AS
BEGIN
    SET NOCOUNT OFF;

    DECLARE @DonGia DECIMAL(18, 2);
    DECLARE @SoLuongTon INT;

    SELECT @DonGia = DonGia, @SoLuongTon = SoLuong FROM MonAn WHERE MaMon = @MaMon;

    IF @SoLuongTon <= 0
    BEGIN
        RAISERROR(N'Món ăn đã hết hàng.', 16, 1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1 FROM ChiTietHoaDon WHERE MaHoaDon = @MaHoaDon AND MaMon = @MaMon
    )
    BEGIN
        UPDATE ChiTietHoaDon
        SET SoLuong = SoLuong + 1,
            ThanhTien = (SoLuong + 1) * @DonGia
        WHERE MaHoaDon = @MaHoaDon AND MaMon = @MaMon;
    END
    ELSE
    BEGIN
        INSERT INTO ChiTietHoaDon (MaHoaDon, MaMon, SoLuong, ThanhTien)
        VALUES (@MaHoaDon, @MaMon, 1, @DonGia);
    END

    UPDATE MonAn
    SET SoLuong = SoLuong - 1
    WHERE MaMon = @MaMon;

	--lấy mã bàn để update trạng thái
	DECLARE @MABAN int
	SELECT @MABAN = hd.MaBan
	FROM HoaDon hd
	WHERE hd.MaHoaDon = @MaHoaDon

	UPDATE BanAn
	SET TrangThai = N'Đang dùng'
	WHERE MaBan = @MABAN;

END
GO

----giảm số luongj ở chi teieetshoas đơn
CREATE PROCEDURE sp_GiamSoLuongChiTiet
    @MaChiTiet INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaMon INT, @DonGia DECIMAL(18,2), @SoLuong INT;

    SELECT @MaMon = MaMon, @SoLuong = SoLuong FROM ChiTietHoaDon WHERE MaChiTiet = @MaChiTiet;
    SELECT @DonGia = DonGia FROM MonAn WHERE MaMon = @MaMon;

    -- Nếu số lượng > 1 giảm số lượng và cập nhật tiền
    IF @SoLuong > 1
    BEGIN
        UPDATE ChiTietHoaDon
        SET SoLuong = SoLuong - 1,
            ThanhTien = (@SoLuong - 1) * @DonGia
        WHERE MaChiTiet = @MaChiTiet;

        -- Tăng lại tồn kho
        UPDATE MonAn
        SET SoLuong = SoLuong + 1
        WHERE MaMon = @MaMon;
    END
    ELSE
    BEGIN
        -- Nếu số lượng = 1 xóa dòng chi tiết
        DELETE FROM ChiTietHoaDon WHERE MaChiTiet = @MaChiTiet;

        -- Tăng lại tồn kho
        UPDATE MonAn
        SET SoLuong = SoLuong + 1
        WHERE MaMon = @MaMon;
    END
END
GO

-- nút tăng trong chi tiết hoa đơn
CREATE PROCEDURE sp_TangSoLuongChiTiet
    @MaChiTiet INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaMon INT, @DonGia DECIMAL(18,2), @SoLuong INT, @TonKho INT;

    SELECT @MaMon = MaMon, @SoLuong = SoLuong FROM ChiTietHoaDon WHERE MaChiTiet = @MaChiTiet;

    SELECT @DonGia = DonGia, @TonKho = SoLuong FROM MonAn WHERE MaMon = @MaMon;

    IF @TonKho <= 0
    BEGIN
        RAISERROR(N'Món ăn đã hết hàng, không thể tăng số lượng.', 16, 1);
        RETURN;
    END

    UPDATE ChiTietHoaDon
    SET SoLuong = SoLuong + 1,
        ThanhTien = (@SoLuong + 1) * @DonGia
    WHERE MaChiTiet = @MaChiTiet;

    UPDATE MonAn
    SET SoLuong = SoLuong - 1
    WHERE MaMon = @MaMon;
END
GO

CREATE PROCEDURE sp_TinhTongTienHoaDon
    @MaHoaDon INT,
    @TongTien DECIMAL(18,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TongTien = SUM(ThanhTien)
    FROM ChiTietHoaDon
    WHERE MaHoaDon = @MaHoaDon;

    IF @TongTien IS NULL
        SET @TongTien = 0;
END
GO




select * from NhanVien
select * from TaiKhoan
select * from HoaDon
select * from BanAn
select * from ChiTietHoaDon
select * from MonAn
select * from KhachHang
select * from KhuyenMai
select * from DatBan


