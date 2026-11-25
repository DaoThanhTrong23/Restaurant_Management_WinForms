using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics.Eventing.Reader;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using BLL;

namespace QUANLY_NHAHANG
{
    public partial class UC_GopBan : UserControl
    {
        public UC_GopBan()
        {
            InitializeComponent();
            this.Load += UC_GopBan_Load;
            btn_Them.Click += Btn_Them_Click;
            btn_gopban.Click += Btn_gopban_Click;
            btn_huyGopBan.Click += Btn_huyGopBan_Click;
            btn_thuhoi.Click += Btn_thuhoi_Click;
        }

        private void Btn_thuhoi_Click(object sender, EventArgs e)
        {
            if (dgv_hoadon_doiban.SelectedRows.Count == 0)
            {
                MessageBox.Show("Vui lòng chọn bàn thu hồi thao tác", "Thông báo");
                return;
            }

            for (int i = dgv_hoadon_doiban1.SelectedRows.Count - 1; i >= 0; i--)
            {
                DataGridViewRow rowToRemove = dgv_hoadon_doiban1.SelectedRows[i];

                if (!rowToRemove.IsNewRow)
                {
                    dgv_hoadon_doiban1.Rows.Remove(rowToRemove);
                }
            }
        }

        private void Btn_huyGopBan_Click(object sender, EventArgs e)
        {
            foreach(DataGridViewRow r in dgv_hoadon_doiban1.Rows)
            {
                dgv_hoadon_doiban1.Rows.Remove(r);

            }

            Reload();

        }

        private void Btn_gopban_Click(object sender, EventArgs e)
        {
            if (dgv_hoadon_doiban1.Rows.Count != 2)
            {
                MessageBox.Show("Vui lòng chọn chính xác 2 bàn để gộp.", "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }


            DataGridViewRow row1 = dgv_hoadon_doiban1.Rows[0];
            DataGridViewRow row2 = dgv_hoadon_doiban1.Rows[1];

            if (row1.IsNewRow || row2.IsNewRow)
            {
                MessageBox.Show("Dữ liệu bàn không hợp lệ.", "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }


            int maBanDich = 0;
            int maHoaDonDich = 0;

            int maBanNguon = 0;
            int maHoaDonNguon = 0;

            try
            {
                maBanDich = int.Parse(row1.Cells["MaBan1"].Value.ToString());
                maHoaDonDich = int.Parse(row1.Cells["MaHoaDon1"].Value.ToString());
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi lấy dữ liệu MaBan/MaHoaDon từ Bàn 1. Vui lòng kiểm tra lại tên cột. Chi tiết: " + ex.Message, "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            

            try
            {
                maBanNguon = int.Parse(row2.Cells["MaBan1"].Value.ToString());
                maHoaDonNguon = int.Parse(row2.Cells["MaHoaDon1"].Value.ToString());
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi lấy dữ liệu MaBan/MaHoaDon từ Bàn 2. Vui lòng kiểm tra lại tên cột. Chi tiết: " + ex.Message, "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }


            if (maBanNguon <= 0 || maHoaDonNguon <= 0 ||maBanDich <= 0 || maHoaDonDich <= 0)
            {
                MessageBox.Show("Không tìm thấy đủ thông tin Mã Bàn hoặc Mã Hóa đơn để thực hiện gộp.", "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }




            BanAnBLL ba_bll = new BanAnBLL();
            if (ba_bll.GopBanAn(maBanNguon, maBanDich, maHoaDonNguon, maHoaDonDich))
            {
                MessageBox.Show("Đã gộp bàn thành công!", "Thành công", MessageBoxButtons.OK, MessageBoxIcon.Information);
                Reload(); 
            }   
            else
            {
                MessageBox.Show("Không thể gộp bàn");
                return;
            }    
        }

        private void Btn_Them_Click(object sender, EventArgs e)
        {
         
            if (dgv_hoadon_doiban.SelectedRows.Count == 0)
                return;

            DataGridViewRow sourceRow = dgv_hoadon_doiban.SelectedRows[0];

            string maBan = sourceRow.Cells["MaBan"].Value.ToString();

            foreach (DataGridViewRow row in dgv_hoadon_doiban1.Rows)
            {
                if (row.IsNewRow) continue;

                if (row.Cells["MaBan1"].Value != null && row.Cells["MaBan1"].Value.ToString() == maBan)
                {
                    MessageBox.Show("Bàn này đã được thêm rồi!","Cảnh báo",MessageBoxButtons.OK,MessageBoxIcon.Warning);
                    return;
                }
            }

            int index = dgv_hoadon_doiban1.Rows.Add();
            for (int i = 0; i < sourceRow.Cells.Count; i++)
            {
                dgv_hoadon_doiban1.Rows[index].Cells[i].Value = sourceRow.Cells[i].Value;
            }

        }


        private void UC_GopBan_Load(object sender, EventArgs e)
        {
            LoadDSKhachHangDaDat();
            InitTableGopBan();

        }

        private void LoadDSKhachHangDaDat()
        {
            BanAnBLL banan = new BanAnBLL();
     
            dgv_hoadon_doiban.DataSource = banan.GopBan_TongTien0();
        }

        private void InitTableGopBan()
        {
            DataTable source = dgv_hoadon_doiban.DataSource as DataTable;
            if (source == null) return;

            DataTable dtTarget = source.Clone(); 
            dgv_hoadon_doiban1.DataSource = dtTarget;
        }
        public void Reload()
        {
            LoadDSKhachHangDaDat();
            DataTable dtTarget = dgv_hoadon_doiban1.DataSource as DataTable;
            if (dtTarget != null)
            {
                dtTarget.Clear();
            }
            else
            {
                dgv_hoadon_doiban1.Rows.Clear();
            }
        }
    }
}
