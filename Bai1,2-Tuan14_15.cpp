#include<iostream>
using namespace std;

struct Nut{
    int dulieu;
    Nut*trai;
    Nut*phai;
};

Nut*taoNut(int giatri){
    Nut*nut=new Nut;
    nut->dulieu=giatri;
    nut->trai=NULL;
    nut->phai=NULL;
    return nut;
}

bool cayRong(Nut*goc){
    return goc==NULL;
}

void duyetTruoc(Nut*goc){
    if(goc==NULL)return;
    cout<<goc->dulieu<<" ";
    duyetTruoc(goc->trai);
    duyetTruoc(goc->phai);
}

void duyetGiua(Nut*goc){
    if(goc==NULL)return;
    duyetGiua(goc->trai);
    cout<<goc->dulieu<<" ";
    duyetGiua(goc->phai);
}

void duyetSau(Nut*goc){
    if(goc==NULL)return;
    duyetSau(goc->trai);
    duyetSau(goc->phai);
    cout<<goc->dulieu<<" ";
}

/*VUN DONG*/
void vunDong(Nut*goc){
    if(goc==NULL)return;

    Nut*lonnhat=goc;

    if(goc->trai!=NULL&&goc->trai->dulieu>lonnhat->dulieu)
        lonnhat=goc->trai;

    if(goc->phai!=NULL&&goc->phai->dulieu>lonnhat->dulieu)
        lonnhat=goc->phai;

    if(lonnhat!=goc){
        swap(goc->dulieu,lonnhat->dulieu);
        vunDong(lonnhat);
    }
}

void vunDongToanCay(Nut*goc){
    if(goc==NULL)return;
    vunDongToanCay(goc->trai);
    vunDongToanCay(goc->phai);
    vunDong(goc);
}

/*SO SANH 2 CAY*/
bool kiemTraGiongNhau(Nut*cay1,Nut*cay2){
    if(cay1==NULL&&cay2==NULL)return true;
    if(cay1==NULL||cay2==NULL)return false;
    if(cay1->dulieu!=cay2->dulieu)return false;
    return kiemTraGiongNhau(cay1->trai,cay2->trai)
        &&kiemTraGiongNhau(cay1->phai,cay2->phai);
}

int main(){
    Nut*goc=taoNut(4);
    goc->trai=taoNut(1);
    goc->phai=taoNut(3);
    goc->trai->trai=taoNut(2);
    goc->trai->phai=taoNut(16);
    goc->phai->trai=taoNut(9);
    goc->phai->phai=taoNut(10);
    goc->trai->trai->trai=taoNut(14);
    goc->trai->trai->phai=taoNut(8);
    goc->trai->phai->trai=taoNut(7);
    cout<<"Duyet truoc: ";
    duyetTruoc(goc);

    cout<<"\nDuyet giua: ";
    duyetGiua(goc);

    cout<<"\nDuyet sau: ";
    duyetSau(goc);

    vunDongToanCay(goc);
    cout<<"\nSau khi vun dong (duyet truoc): ";
    duyetTruoc(goc);

    Nut*cay1=taoNut(1);
    cay1->trai=taoNut(2);
    cay1->phai=taoNut(3);

    Nut*cay2=taoNut(1);
    cay2->trai=taoNut(2);
    cay2->phai=taoNut(3);

    if(kiemTraGiongNhau(cay1,cay2))
        cout<<"\nHai cay giong nhau";
    else
        cout<<"\nHai cay khong giong nhau";
    return 0;
}
