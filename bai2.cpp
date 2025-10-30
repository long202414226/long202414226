#include <iostream>
using namespace std;

int step = 1;

void Partition(int A[], int dau, int cuoi) {
    if (dau >= cuoi) return;

    int c = A[dau];
    int i = dau + 1, j = cuoi;

    while (i <= j) {
        while (i <= j && A[i] <= c) i++;
        while (i <= j && A[j] > c) j--;
        if (i < j) swap(A[i], A[j]);
    }

    swap(A[dau], A[j]);

    // 🔹 In ra mảng sau mỗi lần chia
    cout << "Bước " << step++ << " (pivot = " << c << "): ";
    for (int k = 0; k <= cuoi; k++) cout << A[k] << " ";
    cout << endl;

    Partition(A, dau, j - 1);
    Partition(A, j + 1, cuoi);
}

int main() {
    int A[8] = {20, 90, 6, 33, 57, 235, 34, 1};

    cout << "Mảng ban đầu: ";
    for (int i = 0; i < 8; i++) cout << A[i] << " ";
    cout << "\n\n";

    Partition(A, 0, 7);

    cout << "\nMảng sau khi sắp xếp: ";
    for (int i = 0; i < 8; i++) cout << A[i] << " ";
    cout << endl;
}
