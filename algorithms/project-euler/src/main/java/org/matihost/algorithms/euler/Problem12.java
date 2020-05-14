package org.matihost.algorithms.euler;

import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

/**


 The sequence of triangle numbers is generated by adding the natural numbers. So the 7th triangle number would be 1 + 2 + 3 + 4 + 5 + 6 + 7 = 28. The first ten terms would be:

 1, 3, 6, 10, 15, 21, 28, 36, 45, 55, ...

 Let us list the factors of the first seven triangle numbers:

 1: 1
 3: 1,3
 6: 1,2,3,6
 10: 1,2,5,10
 15: 1,3,5,15
 21: 1,3,7,21
 28: 1,2,4,7,14,28

 We can see that 28 is the first triangle number to have over five divisors.

 What is the value of the first triangle number to have over five hundred divisors?

 */
public class Problem12 {


  public static int divisors(int n) {
    if (n < 2) {
      return 1;
    }
    if (n < 3) {
      return 2;
    }
    int divisors = 0;
    while (n % 2 == 0) {
      n /= 2;
      divisors++;
    }
    long currentLargestPrimeFactor = 2;
    List<Long> primes = new LinkedList<>(Arrays.asList(2L));
    long i = 3;
    while (n > 1) {
      if (Problem3.isPrime(i, primes)) {
        primes.add(i);
        currentLargestPrimeFactor = i;
        int increments = divisors + 1;
        while (n % i == 0) {
          n /= i;
          divisors = divisors + increments;
        }
        long primeFactorBoundary = (long) Math.sqrt(n);
        if (currentLargestPrimeFactor > primeFactorBoundary) {
          // remaining is prime
          i = n;
        } else {
          i = i + 2;
        }
      } else {
        i = i + 2;
      }
    }

    return divisors + 1;
  }

  public static int triangleNumber(int n) {
    return n * (n + 1) / 2;
  }


  public static int triangleNumberWithDivisorsMoreThan(int divisorsLimit) {
    int currentDivisors = 0;
    int i = 1;
    int triangle = 1;
    while (currentDivisors <= divisorsLimit) {
      triangle = triangleNumber(i++);
      currentDivisors = divisors(triangle);
    }
    return triangle;

  }



  public static void main(String[] args) {
    int[] samples = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 21, 28, 27000};
    for (int sample : samples) {
      System.out.println(sample + "->" + divisors(sample));
    }

    System.out.println(triangleNumberWithDivisorsMoreThan(500));
  }

}
