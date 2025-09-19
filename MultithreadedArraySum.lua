-- Багатопотокове обчислення суми масиву за допомогою корутин в Lua

-- Клас для обчислення суми масиву
ArraySumCalculator = {}
ArraySumCalculator.__index = ArraySumCalculator

function ArraySumCalculator:new(array, num_coroutines)
    local obj = {
        array = array,
        num_coroutines = num_coroutines,
        partial_sums = {},
        coroutines = {}
    }
    setmetatable(obj, self)
    return obj
end

-- Функція для обчислення частинної суми (виконується в корутині)
function ArraySumCalculator:calculate_partial_sum(coroutine_id, start_index, end_index)
    local partial_sum = 0
    
    -- Обчислення суми з періодичним поверненням управління
    for i = start_index, end_index - 1 do
        partial_sum = partial_sum + self.array[i]
        
        -- Періодично повертаємо управління для імітації багатозадачності
        if i % 1000 == 0 then
            coroutine.yield(partial_sum)
        end
    end
    
    -- Зберігаємо результат
    self.partial_sums[coroutine_id] = partial_sum
    print(string.format("Корутина %d: обчислено суму діапазону [%d:%d] = %d", 
                       coroutine_id, start_index, end_index, partial_sum))
    
    return partial_sum
end

-- Головний метод для обчислення загальної суми
function ArraySumCalculator:calculate_total_sum()
    local array_length = #self.array
    local chunk_size = math.floor(array_length / self.num_coroutines)
    
    print(string.format("Розділяємо масив з %d елементів на %d частин", 
                       array_length, self.num_coroutines))
    print(string.format("Розмір кожної частини: ~%d елементів", chunk_size))
    
    -- Створення корутин
    for i = 1, self.num_coroutines do
        local start_index = (i - 1) * chunk_size + 1
        local end_index
        
        if i == self.num_coroutines then
            end_index = array_length + 1  -- Останя корутина обробляє залишок
        else
            end_index = i * chunk_size + 1
        end
        
        -- Створюємо корутину для обчислення частинної суми
        local co = coroutine.create(function()
            return self:calculate_partial_sum(i, start_index, end_index)
        end)
        
        table.insert(self.coroutines, co)
    end
    
    -- Виконання всіх корутин до завершення
    local active_coroutines = #self.coroutines
    while active_coroutines > 0 do
        for i, co in ipairs(self.coroutines) do
            if coroutine.status(co) ~= "dead" then
                local success, result = coroutine.resume(co)
                if not success then
                    print("Помилка в корутині " .. i .. ": " .. result)
                elseif coroutine.status(co) == "dead" then
                    active_coroutines = active_coroutines - 1
                end
            end
        end
    end
    
    -- Підсумовування результатів
    local total_sum = 0
    for _, partial_sum in pairs(self.partial_sums) do
        total_sum = total_sum + partial_sum
    end
    
    return total_sum
end

-- Функція для створення масиву випадкових чисел
function generate_random_array(size)
    local array = {}
    math.randomseed(os.time())
    
    for i = 1, size do
        array[i] = math.random(1, 100)
    end
    
    return array
end

-- Функція для однопотокового обчислення суми
function calculate_sum_single_threaded(array)
    local sum = 0
    for _, value in ipairs(array) do
        sum = sum + value
    end
    return sum
end

-- Функція для вимірювання часу виконання
function measure_time(func, ...)
    local start_time = os.clock()
    local result = func(...)
    local end_time = os.clock()
    return result, end_time - start_time
end

-- Головна функція
function main()
    -- Створення масиву з 500000+ елементів
    local array_size = 500000
    print(string.format("Генерація масиву з %d випадкових чисел...", array_size))
    
    local array = generate_random_array(array_size)
    local num_coroutines = 8  -- Кількість корутин
    
    -- Обчислення з використанням корутин
    print(string.format("\n=== Багатопотокове обчислення (%d корутин) ===", num_coroutines))
    
    local calculator = ArraySumCalculator:new(array, num_coroutines)
    local multithreaded_sum, multithreaded_time = measure_time(
        function() return calculator:calculate_total_sum() end
    )
    
    -- Обчислення без корутин для порівняння
    print(string.format("\n=== Однопотокове обчислення (для порівняння) ==="))
    local single_threaded_sum, single_threaded_time = measure_time(
        calculate_sum_single_threaded, array
    )
    
    -- Виведення результатів
    print(string.format("\n=== РЕЗУЛЬТАТИ ==="))
    print(string.format("Розмір масиву: %d елементів", #array))
    print(string.format("Кількість корутин: %d", num_coroutines))
    print(string.format("Багатопотокова сума: %d", multithreaded_sum))
    print(string.format("Однопотокова сума: %d", single_threaded_sum))
    print(string.format("Результати збігаються: %s", 
                       multithreaded_sum == single_threaded_sum and "true" or "false"))
    print(string.format("Час багатопотокового обчислення: %.4f сек", multithreaded_time))
    print(string.format("Час однопотокового обчислення: %.4f сек", single_threaded_time))
    
    if single_threaded_time > 0 then
        local speedup = single_threaded_time / multithreaded_time
        print(string.format("Співвідношення швидкості: %.2fx", speedup))
    end
end

-- Запуск програми
main()
