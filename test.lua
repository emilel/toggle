str = 'hej. kuken. skiten'

i = 11
print('started at', string.sub(str, i))
while i > 0 and string.find(string.sub(str, i - 1, i - 1), '%w') do
    i = i - 1
end

print(string.sub(str, i + 1))
