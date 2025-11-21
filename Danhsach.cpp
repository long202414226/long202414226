#include <iostream>
#include <string>
using namespace std;
struct SinhVien {
    string hoten;
    string mssv;
    int namsinh;
    float gpa;
};
struct Node {
    SinhVien data;
    Node* next;
};
struct List {
    Node* first;
};
void Indanhsach(List* a){
    Node* b= a->first;
    if (a->first == 0){
        cout<<"List rong";
    }
    else{
        while (b != 0)
    {
        cout<<b->data.mssv<<"  "<<b->data.hoten<<"  "<<b->data.namsinh<<"  "<<b->data.gpa<<"\n";
        b=b->next;
    }
    }
}
int Chieudai(List* a){
    Node* b=a->first;
    int i=0;
      while (b != 0)
    {
        i++;
        b=b->next;
    }
    return i;
}
int Dem(List* a){
    Node* b=a->first;
    int i=0;
    while (b != 0)
    {
        if(b->data.gpa>3.2) i++;
        b=b->next;
    }
    return i;
}
void Sapxep(List* a){
    for (Node* i=a->first; i!=nullptr; i=i->next) {
        for (Node* j=i->next; j!=nullptr; j=j->next) {
            if (i->data.gpa > j->data.gpa) {
                SinhVien tmp=i->data;
                i->data=j->data;
                j->data=tmp;
            }
        }
    }

}
void Chen(List* a,SinhVien b){
    Sapxep(a);
    Node* c = new Node;
    c->data=b;
    c->next=nullptr;
    if (a->first == nullptr || b.gpa <= a->first->data.gpa){
             c->next = a->first;
             a->first = c;
             return;
    }
    for(Node* i=a->first;i != nullptr;i=i->next){
        if (i->next == nullptr){
            i->next=c;
            return;
        }
         if (b.gpa>=i->data.gpa && b.gpa<=i->next->data.gpa){
            c->next= i->next;
            i->next=c;
            return;
        }    
    }
}
int main(){
    SinhVien sv1 = {"Nguyen Van A", "SV001", 2003, 3.5};
    SinhVien sv2 = {"Tran Thi B",  "SV002", 2004, 2.9};
    SinhVien sv3 = {"Le Van C",    "SV003", 2002, 3.8};
    SinhVien sv4 = {"Pham Thi D",  "SV004", 2003, 2.1};
    SinhVien svMoi = {"Sinh Vien Moi", "SV999", 2005, 2.4};
    SinhVien b[]={sv1,sv2,sv3,sv4};
    List l;
    l.first = nullptr;
    Node* tail = nullptr;
    for (int i = 0; i < 4; i++){
        Node* node = new Node;
        node->data = b[i];
        node->next = nullptr;
        if (l.first == nullptr){
            l.first = node;
            tail = node;
        } else {
            tail->next = node;
            tail = node;
        }
    }
    Indanhsach(&l);
    cout<<"Chieu dai bang: "<<Chieudai(&l)<<"\n";
    cout<<Dem(&l);
    Sapxep(&l);
    Chen(&l,svMoi);
    Indanhsach(&l);
}