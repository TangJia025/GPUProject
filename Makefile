a.out: main.o QueryKernel.o 
	nvcc -arch=sm_35 $^ -lcudadevrt -o $@

main.o: main.cu 
	nvcc -arch=sm_35 -dc $<

clean: 
	rm -rf *.o


