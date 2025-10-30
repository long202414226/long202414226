#include<iostream>
using namespace std ;
void sapxepnhanh(int A[], int dau, int cuoi){
int b=cuoi;
if (dau>=cuoi) return;
int c=A[dau];
int i=dau+1,j=cuoi;
while (i<=j){
while (A[i]<=c && i<=j) i++;
while (A[j]>c && i<=j) j--;
if (i<j) swap(A[i],A[j]);
}
for(int k=0;k<=7;k++) {
        cout<<A[k]<<" ";
    }
    cout<<"\n";
swap(A[dau],A[j]);
sapxepnhanh(A, dau,j-1);
sapxepnhanh(A, j+1,cuoi);
}
int main(){
   int A[9]={20,90,6,33,57,235,34,1};
   sapxepnhanh(A,0,7);
}