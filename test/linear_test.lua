-- test of the linear library and of its warper

--usage: from ../ :
-- lua test/linear.test -i
------------
Linear = require "../linear_warper"
------------

local X, A, B, C, D, E
test = {} --(each test is a function/procedure, the set of which is stored in this global table)

----test of  Linear.__new and Linear.print on a vector
X = Linear{1,2,3}
function test.new()
  Linear.print(X)
end

----test of matrix creation and printing
  A = Linear{
    { 4 , 3,-2 },
    { 6 ,-1, 5 },
    { -3, 0, 7 }
  }
  B = Linear{
    { 4, 1 },
    { 2, 6 },
    {-1, 8 }
  }
function test.print()
  Linear.print(A)
  Linear.print(B)
end

----test of matrix multiplication and metamethod  
function test.mul()
  C = A * B
  Linear.print(C)
end

 A2 = Linear.matrix(3, 3, "col")
function test.trans_error()
  Linear.copy(A, A2, "trans")
  Linear.print(A2)
--errors because of mismatching orders
end


local v1, v2, w1, w2
v1 = Linear.tvector(B, 1)
--test col, row
function test.rows()
  Linear.print(v1)
  v2 = Linear.row(B, 1)
  Linear.print(v2)
  w1 = B[1]
  Linear.print(w1)
  w2 = Linear.col(B, 1)
  Linear.print(w2)
  
  for v in Linear.rows(B) do
    Linear.print(v)
  end
end

function test.referencing()
  Linear.print(B)
  v1[2] = 5
  Linear.print(B)
  --it is referencing: changing w[2] does change B as well
end

function test.iterators(M)
  M = M and Linear(M) or 
    Linear({
        { 4, 1 },
        { 2, 6 },
        {-1, 8 }
      },
      "colmajor")
  print("the matrix: ")
  Linear.print(M)
  print("iterating over its rows:")
  for v in Linear.rows(M) do
    Linear.print(v)
  end
  print("iterating over its columns:")
  for v in Linear.cols(M) do
    Linear.print(v)
  end
end


function test.transpose(M)
  
  M = M and Linear(M) or 
    Linear({
        { 4, 1 },
        { 2, 6 },
        {-1, 8 }
      },
      "rowmajor")
  print("the matrix: ")
  Linear.print(M)
  m, n, o = linear.size(M)
  
  print("Its transposition M^t: ")
  local t = linear.t
  local Mt = M^t
  Linear.print(Mt)
  
  print("Changing a coefficient: ")
  Mt[2][2] = -3
  Linear.print(Mt)
  
  print("setting it again through linear.transpose(M, Mt): ")
  linear.transpose(M, Mt)
  Linear.print(Mt)
  
  print("setting a matrix of different order to transpose.transpose(M, Mt): ")
  local Mt2 = linear.matrix(n, m, ({row = "col", col = "row"})[o])
  linear.transpose(M, Mt2)
  Linear.print(Mt2)
  
  --TODO test order parameter and tMatrix 
end
