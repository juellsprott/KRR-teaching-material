 #const h=4.
 #const w=6.
 item(1, 1, 3; 2, 2, 2; 3, 2, 3; 4, 3, 3).
 % all possible positions
 1 { positions(I, 0..h, 0..h, 0..w, 0..w)} 1 :- I = 1..N, N = #count{Idx: item(Idx, _, _)}.
 % filter 1: only possible positions within grid
 :- positions(I, X1, X2, Y1, Y2), item(I, X, Y), X2 - X1 != X.
 :- positions(I, X1, X2, Y1, Y2), item(I, X, Y), Y2 - Y1 != Y.
 % filter 2: no overlap between bounding boxes
 :- positions(I1, X1_min, X1_max, Y1_min, Y1_max), 
    positions(I2, X2_min, X2_max, Y2_min, Y2_max), 
    X1_max > X2_min,
    X2_max > X1_min,
    Y1_max > Y2_min,
    Y2_max > Y1_min,
    I1 != I2.

 #show positions/5.