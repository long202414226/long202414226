#include <iostream>
using namespace std;
void swap(int *a,int *b){
    int t=*a;
    *a=*b;
    *b=t;
}
void selectionSort(int A[], int n){
    int i,j,min;
    for(i=0;i<n-1;i++){
        min= i;
        for (j =i + 1; j < n; j++){
            if (A[j] < A[min]){
                min = j;
        swap(&A[min], &A[i]);

            }
        }
    }
}
int main(){
   int A[9]={2,4,6,34,567,235,34,21};
   selectionSort(A,8);
   for(int i=0;i<8;i++){
    cout<<A[i]<<" ";
   }
}
