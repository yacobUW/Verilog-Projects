#include <iostream>
using namespace std;

// Function to find the normalization exponent for a given 8-bit value
int normalize(int variable) {
    int ex = 0;
    for (int i = 7; i >= 0; i--) {
        if ((variable >> i) & 1) {
            ex = 7 - i;
            break;
        }
    }
    return ex;
}

// Function to perform two's complement of an 8-bit value
int twosComplement(int frac) {
    int invert = ~frac;
    int match = 0;
    bool start = true;
    bool copy = false;

    for (int i = 7; i >= 0; i--) {
        if (start && !((invert >> i) & 1)) {
            start = false;
            copy = true;
            match |= ((invert >> i) & 1) << i;
        } else if (copy) {
            match |= ((invert >> i) & 1) << i;
        }
    }

    return match + 1;
}

// Function to perform multiplication
int multiplier(int multiplier, int N_b) {
    int multiplier_trun = multiplier << (8 - N_b);
    int repeated = multiplier_trun * multiplier_trun;
    return repeated >> 8;
}

// Function to perform accumulation
int accumulator(int a, int starting, bool stopping) {
    static int reg1 = 0;
    static int reg2 = starting;
    static bool carry = false;
    static bool overflow = false;

    int sum1 = a + reg1;
    bool cout = (sum1 >> 8) & 1;

    if (!stopping) {
        reg1 = a;
        reg2 = sum1;
        carry = cout;
        overflow = (sum1 >> 7) & 1;
    }

    return reg2;
}

// Function to determine the value of s using a lookup table
int LUT(int t, int n) {
    if (n == 4) {
        switch (t) {
            case 1: return 3;
            case 2: return 3;
            default: return 0;
        }
    }

    if (n == 8) {
        switch (t) {
            case 1: return 4;
            case 2: return 6;
            case 3: return 6;
            case 4: return 6;
            case 5: return 7;
            case 6: return 7;
            case 7: return 7;
            default: return 0;
        }
    }

    return 0;
}

// Main function to simulate the Verilog module
int main() {
    int a = 100; // input [7:0] a
    int accuracy_cycles = 3; // input [4:0] accuracy_cycles
    int b = 25; // input [7:0] b

    int eb = normalize(b);
    int ea = normalize(a);

    int normalize_b = twosComplement(b);
    int reciprocal;

    int Qout;
    int QoutC;

    bool stop = false;

    int s = LUT(accuracy_cycles, 8);
    int trun_reciprocal;
    int Qout_shifted;
    int whole_number = 1;

    if (stop) {
        reciprocal = normalize_b * a;
        trun_reciprocal = reciprocal >> 9;
        Qout = (trun_reciprocal << (ea - eb + 1)) & 0xFF;
        Qout_shifted = Qout >> s;
        QoutC = Qout + Qout_shifted;
    }

    int sum = (whole_number << 8) | QoutC;

    cout << "Result: " << sum << endl;

    return 0;
}
