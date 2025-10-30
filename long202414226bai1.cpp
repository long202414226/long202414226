#include<iostream>
using namespace std ;
void Partition(int A[], int dau, int cuoi){
if (dau>=cuoi) return;
int c=A[dau];
int i=dau+1,j=cuoi;
while (i<=j){
while (A[i]<=c && i<=j) i++;
while (A[j]>c && i<=j) j--;
if (i<j) swap(A[i],A[j]);
}
swap(A[dau],A[j]);
Partition(A, dau,j-1);
Partition(A, j+1,cuoi);
}
void QuickSort(int A[], int N){
	Partition(A,0,N-1);
}
int main(){
   int A[9]={2,4,6,34,567,235,34,21};
   QuickSort(A,8);
   for(int i=0;i<8;i++){
    cout<<A[i]<<" ";
   }
}