#include <iostream>
#include <string>
using namespace std;
struct Nut {
    int chiSo;          
    string tenMuc;     
    Nut* trai;          
    Nut* phai;          

    Nut(int cs, string tm) {
        chiSo = cs;
        tenMuc = tm;
        trai = nullptr;
        phai = nullptr;
    }
};

bool laBanCopy(Nut* sach1, Nut* sach2) {
    if (sach1 == nullptr && sach2 == nullptr)
        return true;
    if (sach1 == nullptr || sach2 == nullptr)
        return false;
    if (sach1->chiSo != sach2->chiSo ||
        sach1->tenMuc != sach2->tenMuc)
        return false;
    return laBanCopy(sach1->trai, sach2->trai) &&
           laBanCopy(sach1->phai, sach2->phai);
}

Nut* taoCaySach1() {
    Nut* goc = new Nut(1, "Chuong 1");

    goc->trai = new Nut(2, "Muc 1.1");
    goc->phai = new Nut(3, "Muc 1.2");

    goc->trai->trai = new Nut(4, "Muc 1.1.1");
    goc->trai->phai = new Nut(5, "Muc 1.1.2");

    return goc;
}

Nut* taoCaySach2() {
    Nut* goc = new Nut(1, "Chuong 1");

    goc->trai = new Nut(2, "Muc 1.1");
    goc->phai = new Nut(3, "Muc 1.2");

    goc->trai->trai = new Nut(4, "Muc 1.1.1");
    goc->trai->phai = new Nut(5, "Muc 1.1.2");

    return goc;
}
int main() {
    Nut* cuonSach1 = taoCaySach1();
    Nut* cuonSach2 = taoCaySach2();

    if (laBanCopy(cuonSach1, cuonSach2))
        cout << "Hai cuon sach la ban copy cua nhau";
    else
        cout << "Hai cuon sach KHONG phai la ban copy cua nhau";

    return 0;
}
