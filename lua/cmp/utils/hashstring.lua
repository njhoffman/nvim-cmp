local function str_split(str, size)
  local result = {}
  for i = 1, #str, size do
    table.insert(result, str:sub(i, i + size - 1))
  end
  return result
end

local function dec2bin(num)
  local result = ''
  repeat
    local halved = num / 2
    local int, frac = math.modf(halved)
    num = int
    result = math.ceil(frac) .. result
  until num == 0
  return result
end

local function padRight(str, length, char)
  while #str % length ~= 0 do
    str = str .. char
  end
  return str
end

local base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'

local  base32_encode = function(str)
  -- Create binary string zeropadded to eight bits
  local binary = str:gsub('.', function(char)
    return string.format('%08u', dec2bin(char:byte()))
  end)

  -- Split to five bit chunks and make sure last chunk has five bits
  binary = str_split(binary, 5)
  local last = table.remove(binary)
  table.insert(binary, padRight(last, 5, '0'))

  -- Convert each five bits to Base32 character
  local encoded = {}
  for i = 1, #binary do
    local num = tonumber(binary[i], 2)
    table.insert(encoded, base32Alphabet:sub(num + 1, num + 1))
  end
  return padRight(table.concat(encoded), 8, '=')
end

local base32_decode = function(str)
  local binary = str:gsub('.', function(char)
    if char == '=' then
      return ''
    end
    local pos = string.find(base32Alphabet, char)
    pos = pos - 1
    return string.format('%05u', dec2bin(pos))
  end)

  local bytes = str_split(binary, 8)

  local decoded = {}
  for _, byte in pairs(bytes) do
    table.insert(decoded, string.char(tonumber(byte, 2)))
  end
  return table.concat(decoded)
end

-- local enc = 'The quick brown fox jumped over the whatever' --需要被加密的值
-- print(base32_encode(enc))
-- print(base32_decode('KRUGKIDROVUWG2ZAMJZG653OEBTG66BANJ2W24DFMQQG65TFOIQHI2DFEB3WQYLUMV3GK4Q='))
--
return { base32_decode = base32_decode, base32_encode = base32_encode }
