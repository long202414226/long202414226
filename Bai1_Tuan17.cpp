#include <iostream>
#include <string>
using namespace std;

struct Nut {
    int ma;                
    string tieuDe;         
    int soTrang;          

    Nut* conDau;           
    Nut* anhEmKe;           

    Nut(int m, string td, int st = 0) {
        ma = m;
        tieuDe = td;
        soTrang = st;
        conDau = nullptr;
        anhEmKe = nullptr;
    }
};
int demSoChuong(Nut* sach) {
    int dem = 0;
    Nut* p = sach->conDau;
    while (p != nullptr) {
        dem++;
        p = p->anhEmKe;
    }
    return dem;
}
Nut* timChuongDaiNhat(Nut* sach) {
    Nut* p = sach->conDau;
    Nut* chuongMax = nullptr;
    int maxTrang = -1;

    while (p != nullptr) {
        if (p->soTrang > maxTrang) {
            maxTrang = p->soTrang;
            chuongMax = p;
        }
        p = p->anhEmKe;
    }
    return chuongMax;
}
int capNhatSoTrang(Nut* nut) {
    if (nut == nullptr) return 0;

    int tong = 0;
    Nut* con = nut->conDau;

    while (con != nullptr) {
        tong += capNhatSoTrang(con);
        con = con->anhEmKe;
    }

    if (nut->conDau != nullptr)
        nut->soTrang = tong;

    return nut->soTrang;
}
bool xoaNut(Nut* cha, int maCanXoa) {
    if (cha == nullptr) return false;

    Nut* hienTai = cha->conDau;
    Nut* truoc = nullptr;

    while (hienTai != nullptr) {
        if (hienTai->ma == maCanXoa) {
            if (truoc == nullptr)
                cha->conDau = hienTai->anhEmKe;
            else
                truoc->anhEmKe = hienTai->anhEmKe;

            delete hienTai;
            return true;
        }

        if (xoaNut(hienTai, maCanXoa))
            return true;

        truoc = hienTai;
        hienTai = hienTai->anhEmKe;
    }
    return false;
}
void xoaVaCapNhat(Nut* sach, int maCanXoa) {
    xoaNut(sach, maCanXoa);
    capNhatSoTrang(sach);
}
Nut* timChuong(Nut* sach, int maChuong) {
    Nut* p = sach->conDau;
    while (p != nullptr) {
        if (p->ma == maChuong)
            return p;
        p = p->anhEmKe;
    }
    return nullptr;
}
void inCay(Nut* nut, int muc = 0) {
    if (nut == nullptr) return;
    cout << nut->tieuDe << " (" << nut->soTrang << " trang)\n";
    inCay(nut->conDau);
    inCay(nut->anhEmKe);
}
int main() {
    Nut* sach = new Nut(0, "Cau truc du lieu");

    Nut* chuong1 = new Nut(1, "Chuong 1");
    Nut* chuong2 = new Nut(2, "Chuong 2");

    Nut* muc11 = new Nut(11, "Muc 1.1", 10);
    Nut* muc12 = new Nut(12, "Muc 1.2", 15);
    Nut* muc13 = new Nut(13, "Muc 1.3", 10);
    Nut* muc21 = new Nut(21, "Muc 2.1", 20);

    sach->conDau = chuong1;
    chuong1->anhEmKe = chuong2;
    chuong1->conDau = muc11;
    muc11->anhEmKe = muc12;
    muc12->anhEmKe = muc13;
    chuong2->conDau = muc21;

    capNhatSoTrang(sach);
    cout << "So chuong: " << demSoChuong(sach) << endl;

    Nut* chuongMax = timChuongDaiNhat(sach);
    cout << "Chuong dai nhat: " << chuongMax->tieuDe << endl;

    cout << "\nNoi dung Chuong 1:\n";
    inCay(timChuong(sach, 1));

    cout << "\nXoa muc 1.2\n";
    xoaVaCapNhat(sach, 12);
    inCay(sach);

    return 0;
}
