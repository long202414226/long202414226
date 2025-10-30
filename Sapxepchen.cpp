#include<iostream>
using namespace std;
void Chenmang(int A[],int dau,int giua,int cuoi){
int i=dau,j=giua+1;
while(i<j&&j<=cuoi){
if(A[i]<=A[j])i++;
else{
int x=A[j];
for(int k=j-1;k>=i;k--){
A[k+1]=A[k];
            }
A[i]=x;
i++;j++;
        }
    }
}
void Trunggian(int A[],int dau,int cuoi){
if(dau>=cuoi)return;
int giua=(dau+cuoi)/2;
Trunggian(A,dau,giua);
Trunggian(A,giua+1,cuoi);
Chenmang(A,dau,giua,cuoi);
}
void sapxepchen(int A[],int N){
if(N<2)return;
Trunggian(A,0,N-1);
}
int main(){
int A[8]={20,90,6,33,57,235,34,1};
sapxepchen(A,8);
for(int k=0;k<8;k++)cout<<A[k]<<" ";
}
