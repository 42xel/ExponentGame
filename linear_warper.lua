-- Some sugar around the linear library
-- meta-methods for arithmetic operations, function to print.
-- TODO? implement it directly into the linear library?

linear = require "linear"
oop = require "loop.simple"

--function to ease matrix definition
--TODO catch errors
Linear = oop.class(linear)
linear.Vector = oop.class({}, Linear)
linear.Matrix = oop.class({}, Linear)
function linear.Vector:__new(T)
  return linear.tolinear {type = "vector", length = #T, values = T}
--loop.simple kind of misused not returning tables but it's ok
end
function linear.Matrix:__new(T, order)
  order = order or "rowmajor"
  if order == "col" or order == "row" then
    order = order .. "major"
  end
  local rows, cols
  if order == "rowmajor" then
    rows, cols = #T, #(T[1])
  else
    rows, cols = #(T[1]), #T
  end
  return linear.tolinear {type = "matrix", rows = rows, cols = cols, order = order, values = T}
end
function Linear:__new(T, order) 
  if Linear.type(T) then
    return linear.create_copy(T)
  end
  if type (T[1]) == "table" then
    return linear.Matrix(T, order)
  else
    return linear.Vector(T)
  end
end

-- function to ease iterating over matrices rows and columns regardless of order
function linear.row(M, i)
-- returns the i-th row of a matrix, irrespective of its order
  local _, _, order = linear.size(M)
  return order == "row" and M[i] or linear.tvector(M, i)
end
function linear.col(M, i)
-- returns the i-th column of a matrix, irrespective of its order
  local _, _, order = linear.size(M)
  return order == "col" and M[i] or linear.tvector(M, i)
end

function linear.rows(M)
--creates an iterator over the rows of M
  local n, _, _ = linear.size(M)
  local i = 0
  return function ()
    i = i + 1
    if i <= n then return linear.row(M, i) end
  end
end
function linear.cols(M)
--creates an iterator over the columns of M
  local _, n, _ = linear.size(M)
  local i = 0
  return function ()
    i = i + 1
    if i <= n then return linear.col(M, i) end
  end
end

-- function to ease matrix printing
function linear.printable(A)
	local r = {}
	if linear.type(A) == "vector" then
		for i = 1, #A do
			table.insert(r, tostring(A[i]):sub(1, 7))
		end
		return table.concat(r, "\t")
	else if linear.type(A) == "matrix" then
		local rows, cols, order = linear.size(A)
		if order == "row" then
			for i = 1, rows do
				table.insert(r, linear.printable(A[i]))
			end
			return table.concat(r, "\n")
		else -- order == "col"
			for i = 1, rows do
				table.insert(r, linear.printable(linear.tvector(A,i) ))
			end
			return table.concat(r, "\n")
		end
	end end
end
function linear.print(A)
  print()
  print(linear.printable(A))
  print()
end

--serialization method to ease exporting of matrices and vectors
function linear.serializeVector(T)
  return "{" .. table.concat(linear.totable(T).values, " ,") .. "}"
end
function linear.serializeMatrix(M)
  local rows, cols, order = linear.size(M)
  local f, s
  if order == "row" then
    f = function (i) return M[i] end
    s = rows
  else
    f = function (i) return linear.tvector(M, i) end
    s = cols
  end
  local T = {}
  for i = 1, s do
    table.insert(T, linear.serializeVector(f(i)))
  end
  return "{" .. table.concat(T, " ,") .. "}"
end
function linear.serialize(M)
  if linear.type(M) == "vector" then
    return linear.serializeVector(M)
  elseif linear.type(M) == "matrix" then
    return linear.serializeMatrix(M)
  else
    error "not a linear object"
  end
end

function linear.create_copy(A)
  return linear.tolinear(linear.totable(A))
end

function linear.identity (n, order)
   local r = linear.matrix (n, n, order)
   for i = 1, n do
    r[i][i] = 1
   end
   return r
end


-- metathemods to use arithmetic operators with linear vector and matrix
local vector_metatable = getmetatable(linear.vector(1))
local matrix_metatable = getmetatable(linear.matrix(1, 1))

--vector_metatable.__index = linear
--matrix_metatable.__index = linear

function vector_metatable.__unm (x)
  local r = linear.create_copy(x)
  linear.scale(r, -1)
  return r
end
function vector_metatable.__add (x, y)
  local r = linear.create_copy(x)
  linear.axpy(y, r)
  return r
end
function vector_metatable.__sub (x, y)
  local r = linear.create_copy(x)
  linear.axpy(y, r, -1)
  return r
end

function vector_metatable.__mul (x, y)
-- cases: vector^t * matrix, vector * vector^t and scalar * vector 
  local r
  if linear.type(x) == "vector" then
    if linear.type(y) == "matrix" then
      local yrows, ycols, yorder = linear.size(y)
      local r = linear.matrix(#x, ycols)
      linear.gemv(x, y, r, 1, 0, "trans")
    else
      r = linear.matrix(#x, #y)
      linear.ger(x, y, r)
    end
  else 
    r = linear.create_copy(y)
    linear.scale(r, x)
  end
  return r
end

function vector_metatable.__mul (x, y)
-- cases: vector^t * matrix, vector * vector^t and scalar * vector 
  local r
  if linear.type(x) == "vector" then
    if linear.type(y) == "matrix" then
      local yrows, ycols, yorder = linear.size(y)
      local r = linear.matrix(#x, ycols)
      linear.gemv(x, y, r, 1, 0, "trans")
    else
      r = linear.matrix(#x, #y)
      linear.ger(x, y, r)
    end
  else 
    r = linear.create_copy(y)
    linear.scale(r, x)
  end
  return r
end

function matrix_metatable.__mul (x, y)
-- cases: matrix * matrix, matrix * vector and scalar * matrix 
--TODO: handle order mismatch
  local r
  if linear.type(x) == "matrix" then
    xrows, xcols, xorder = linear.size(x)
    if linear.type(y) == "matrix" then
      local yrows, ycols, yorder = linear.size(y)
      r = linear.matrix(xrows, ycols, xorder)
      linear.gemm(x, y, r)
    else
      r = linear.vector(xrows)
      linear.gemv(x, y, r)
    end
  else
    r = linear.create_copy(y)
    linear.scale(r, x)
  end
  return r
end

function matrix_metatable.__pow (A,n)
  -- Two cases: transpose and exponentiation
  if n == linear.transpose then return linear.transpose(A) end
    
  if n % 1 ~= 0 or n < 0 then
    error("Only positive integers power of matrices supported", 2)
  end
  local Arows, Acols, Aorder = linear.size(A)
  if Arows ~= Acols then
    error("square matrix required for power", 2)
  end
  local Atemp = Linear(A)
  local Atemp2 = linear.matrix(Arows, Acols, Aorder)
  local r1 = linear.identity(Arows, Aorder)
  local r2 = linear.matrix(Arows, Acols, Aorder)
  --iterative fast power, because linear lends itself to it 
  while n > 0 do
    if n%2 == 1 then
      linear.gemm(r1, Atemp, r2)
      r1, r2 = r2, r1
      n = math.floor(n/2)	-- n = n//2
      linear.gemm(Atemp, Atemp, Atemp2)
      Atemp, Atemp2 = Atemp2, Atemp
    end
  end
  return r
end

function linear.transpose(A, B, order)
--writes a transposed matrix of A in B and returns B. If B doesn't exist, it creates it, with order specified by order if any, defaulting to A's order
  local n, m, oA = linear.size(A)
  if B then
    _, _, order = linear.size(B)
  else
    order = order or oA
    B = linear.matrix(m, n, order)
  end
  
  if order == "row" then
    for i = 1, m do
      for j = 1, n do
        B[i][j]= linear.row(A, j)[i]
      end
    end
  elseif order == "col" then
    for i = 1, m do
      for j = 1, n do
        --print(B[i][j])
        B[j][i] = linear.row(A, j)[i]
      end
    end
  else
    print "ERROR"
  end
  return B
end
linear.t = linear.transpose

function linear.tmatrix(A, order)
  --returns a transposed referencing of A. Order defaults to the order of A.
  local m, n, o = linear.size(A)
  order = order or o
  local B = linear.matrix(n, m, order)
  if order == "row" then
    for i = 1, n do
      B[i] = linear.col(A, i)
    end
  else
    for i = 1, m do
      B[i] = linear.row(A, i)
    end
  end
end

--[[
    __concat - Concatenation. Invoked similar to addition, using the '..' operator. 
--]]
for _, v in pairs {"__unm", "__add", "__sub"} do
  matrix_metatable[v] = vector_metatable[v]
end


--receiver_vector_meta = {}
--receiver_matrix_meta = {}



return Linear