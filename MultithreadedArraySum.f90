program multithreaded_array_sum
    use omp_lib
    implicit none
    
    ! Параметри програми
    integer, parameter :: ARRAY_SIZE = 500000
    integer, parameter :: NUM_THREADS = 8
    integer, parameter :: dp = selected_real_kind(15, 307)
    
    ! Змінні
    integer, dimension(ARRAY_SIZE) :: array
    integer(kind=8) :: total_sum_parallel, total_sum_serial
    integer(kind=8), dimension(NUM_THREADS) :: partial_sums
    real(dp) :: start_time, end_time, parallel_time, serial_time
    real(dp) :: speedup
    integer :: i, thread_id, chunk_size, start_idx, end_idx
    integer :: actual_threads
    
    ! Ініціалізація OpenMP
    call omp_set_num_threads(NUM_THREADS)
    
    ! Генерація випадкового масиву
    write(*,*) 'Генерація масиву з ', ARRAY_SIZE, ' випадкових чисел...'
    call generate_random_array(array, ARRAY_SIZE)
    
    ! Ініціалізація часткових сум
    partial_sums = 0
    
    ! Багатопотокове обчислення
    write(*,*) ''
    write(*,*) '=== Багатопотокове обчислення (', NUM_THREADS, ' потоків) ==='
    
    start_time = omp_get_wtime()
    
    !$omp parallel private(thread_id, start_idx, end_idx, i) shared(array, partial_sums)
    thread_id = omp_get_thread_num() + 1  ! FORTRAN використовує індексацію з 1
    actual_threads = omp_get_num_threads()
    
    ! Обчислення діапазону для кожного потоку
    chunk_size = ARRAY_SIZE / actual_threads
    start_idx = (thread_id - 1) * chunk_size + 1
    
    if (thread_id == actual_threads) then
        end_idx = ARRAY_SIZE  ! Останній потік обробляє залишок
    else
        end_idx = thread_id * chunk_size
    end if
    
    ! Обчислення частинної суми
    do i = start_idx, end_idx
        partial_sums(thread_id) = partial_sums(thread_id) + array(i)
    end do
    
    !$omp critical
    write(*,'(A,I0,A,I0,A,I0,A,I0)') 'Потік ', thread_id, &
         ': обчислено суму діапазону [', start_idx, ':', end_idx, &
         '] = ', partial_sums(thread_id)
    !$omp end critical
    
    !$omp end parallel
    
    end_time = omp_get_wtime()
    parallel_time = end_time - start_time
    
    ! Об'єднання часткових сум
    total_sum_parallel = 0
    do i = 1, NUM_THREADS
        total_sum_parallel = total_sum_parallel + partial_sums(i)
    end do
    
    ! Однопотокове обчислення для порівняння
    write(*,*) ''
    write(*,*) '=== Однопотокове обчислення (для порівняння) ==='
    
    start_time = omp_get_wtime()
    total_sum_serial = calculate_sum_serial(array, ARRAY_SIZE)
    end_time = omp_get_wtime()
    serial_time = end_time - start_time
    
    ! Виведення результатів
    write(*,*) ''
    write(*,*) '=== РЕЗУЛЬТАТИ ==='
    write(*,'(A,I0,A)') 'Розмір масиву: ', ARRAY_SIZE, ' елементів'
    write(*,'(A,I0)') 'Кількість потоків: ', NUM_THREADS
    write(*,'(A,I0)') 'Багатопотокова сума: ', total_sum_parallel
    write(*,'(A,I0)') 'Однопотокова сума: ', total_sum_serial
    
    if (total_sum_parallel == total_sum_serial) then
        write(*,*) 'Результати збігаються: TRUE'
    else
        write(*,*) 'Результати збігаються: FALSE'
    end if
    
    write(*,'(A,F8.4,A)') 'Час багатопотокового обчислення: ', parallel_time, ' сек'
    write(*,'(A,F8.4,A)') 'Час однопотокового обчислення: ', serial_time, ' сек'
    
    if (parallel_time > 0.0) then
        speedup = serial_time / parallel_time
        write(*,'(A,F6.2,A)') 'Прискорення: ', speedup, 'x'
    end if

contains

    ! Підпрограма для генерації випадкового масиву
    subroutine generate_random_array(arr, size)
        implicit none
        integer, intent(in) :: size
        integer, dimension(size), intent(out) :: arr
        integer :: i
        real :: rand_num
        
        ! Ініціалізація генератора випадкових чисел
        call random_seed()
        
        do i = 1, size
            call random_number(rand_num)
            arr(i) = int(rand_num * 100) + 1  ! Числа від 1 до 100
        end do
    end subroutine generate_random_array
    
    ! Функція для послідовного обчислення суми
    function calculate_sum_serial(arr, size) result(sum_result)
        implicit none
        integer, intent(in) :: size
        integer, dimension(size), intent(in) :: arr
        integer(kind=8) :: sum_result
        integer :: i
        
        sum_result = 0
        do i = 1, size
            sum_result = sum_result + arr(i)
        end do
    end function calculate_sum_serial

end program multithreaded_array_sum
