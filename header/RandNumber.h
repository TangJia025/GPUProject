#ifndef RANDNUMBER_H_
#define RANDNUMBER_H_

#include <stdlib.h>
#include <time.h>
#include <math.h>

class RandNumber
{
public:
	static void init()
	{
		srand((unsigned)time(NULL));
	}

	static int rand_int()
	{
		return rand();
	}

	static double rand_gaussian()
	{
		static double V1, V2, S;
		static int phase = 0;
		double X;

		if (phase == 0)
		{
			do{
				double U1 = (double)rand() / RAND_MAX;
				double U2 = (double)rand() / RAND_MAX;

				V1 = 2*U1 - 1;
				V2 = 2*U2 - 1;
				S = V1*V1 + V2*V2;
			}while (S >= 1 || S == 0);
			X = V1 * sqrt(-2 * log(S) / S);
		}
		else
		{
			X = V2 * sqrt(-2 * log(S) / S);
		}
		phase = 1-phase;

		return X;
	}

	static double rand_float()
	{
		return (double)rand()/RAND_MAX*2 - 1;
	} 

	static double rand_pos_float()
	{
		return (double)rand() / RAND_MAX;
	}
};

#endif

