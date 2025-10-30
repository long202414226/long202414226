#include<iostream>
using namespace std;
void MergeArrays(int A[],int dau,int giua,int cuoi){
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
void Split_Merg(int A[],int dau,int cuoi){
if(dau>=cuoi)return;
int giua=(dau+cuoi)/2;
Split_Merg(A,dau,giua);
Split_Merg(A,giua+1,cuoi);
MergeArrays(A,dau,giua,cuoi);
}
void MergeSort(int A[],int N){
if(N<2)return;
Split_Merg(A,0,N-1);
}
int main(){
int A[8]={20,90,6,33,57,235,34,1};
MergeSort(A,8);
for(int k=0;k<8;k++)cout<<A[k]<<" ";
}
