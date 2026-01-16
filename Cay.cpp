#include <iostream>
using namespace std;
struct CayTuanTu {
    int dulieu[100];
    int soluong;
};
void khoiTaoCay(CayTuanTu &cay) {
    cay.soluong = 0;
}
bool cayRong(CayTuanTu cay) {
    return cay.soluong == 0;
}
void themNut(CayTuanTu &cay,int giatri) {
    if (cay.soluong >= 100) return;
    cay.dulieu[++cay.soluong] = giatri;
}
void duyetTruoc(CayTuanTu cay,int vitri) {
    if (vitri > cay.soluong) return;
    cout << cay.dulieu[vitri] << " ";
    duyetTruoc(cay,2*vitri);
    duyetTruoc(cay,2*vitri + 1);
}
void duyetGiua(CayTuanTu cay,int vitri) {
    if (vitri > cay.soluong) return;
    duyetGiua(cay,2*vitri);
    cout << cay.dulieu[vitri] << " ";
    duyetGiua(cay,2*vitri + 1);
}
void duyetSau(CayTuanTu cay,int vitri) {
    if (vitri > cay.soluong) return;
    duyetSau(cay,2*vitri);
    duyetSau(cay,2*vitri + 1);
    cout << cay.dulieu[vitri] << " ";
}
struct Nut {
    int dulieu;
    Nut* trai;
    Nut* phai;
};
Nut* taoNut(int giatri) {
    Nut* nut = new Nut;
    nut->dulieu = giatri;
    nut->trai = NULL;
    nut->phai = NULL;
    return nut;
}
bool cayRong(Nut* goc) {
    return goc == NULL;
}
void themConTrai(Nut* nutcha, int giatri) {
    nutcha->trai = taoNut(giatri);
}
void themConPhai(Nut* nutcha, int giatri) {
    nutcha->phai = taoNut(giatri);
}
void duyetTruoc(Nut* goc) {
    if (goc == NULL) return;
    cout << goc->dulieu << " ";
    duyetTruoc(goc->trai);
    duyetTruoc(goc->phai);
}
void duyetGiua(Nut* goc) {
    if (goc == NULL) return;
    duyetGiua(goc->trai);
    cout << goc->dulieu << " ";
    duyetGiua(goc->phai);
}
void duyetSau(Nut* goc) {
    if (goc == NULL) return;
    duyetSau(goc->trai);
    duyetSau(goc->phai);
    cout << goc->dulieu <<" ";
}
int main() {
    cout << "Cay tuan tu";
    CayTuanTu caytuantu;
    khoiTaoCay(caytuantu);
    for (int i = 1; i <= 7; i++){
        themNut(caytuantu, i);
    }
    cout << "Duyet truoc: ";
    duyetTruoc(caytuantu, 1);
    cout << "\nDuyet giua: ";
    duyetGiua(caytuantu, 1);
    cout << "\nDuyet sau: ";
    duyetSau(caytuantu, 1);
    cout << "\nCay moc noi";
    Nut* goc = taoNut(1);
    themConTrai(goc, 2);
    themConPhai(goc, 3);
    themConTrai(goc->trai, 4);
    themConPhai(goc->trai, 5);
    themConTrai(goc->phai, 6);
    themConPhai(goc->phai, 7);
    cout << "\nDuyet truoc: ";
    duyetTruoc(goc);
    cout << "\nDuyet giua: ";
    duyetGiua(goc);
    cout << "\nDuyet sau: ";
    duyetSau(goc);
}
