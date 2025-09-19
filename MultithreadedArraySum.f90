program sum_compare
  implicit none
  integer, parameter :: n = 500000
  integer, parameter :: num_parts = 8
  integer(kind=8), allocatable :: a(:)
  integer(kind=8), allocatable :: partial(:)
  integer(kind=8) :: total_seq, total_par
  integer :: i, part, chunk, start_idx, end_idx
  integer :: t1, t2, rate
  real(8) :: time_seq, time_par

  allocate(a(n))
  allocate(partial(num_parts))

  ! Заповнення масиву
  a = 1

  call system_clock(t1, rate)
  ! ---- Послідовний підрахунок ----
  total_seq = sum(a)
  call system_clock(t2)
  time_seq = real(t2 - t1) / rate

  call system_clock(t1)
  ! ---- Паралельний підрахунок через do concurrent ----
  chunk = n / num_parts
  partial = 0
  do concurrent (part = 1:num_parts)
     start_idx = (part-1)*chunk + 1
     if (part < num_parts) then
        end_idx = part*chunk
     else
        end_idx = n
     end if
     partial(part) = sum(a(start_idx:end_idx))
  end do
  total_par = sum(partial)
  call system_clock(t2)
  time_par = real(t2 - t1) / rate

  ! ---- Результати ----
  print *, "Array size:", n
  print *, "Expected sum:", n
  print *
  print *, "Sequential sum:", total_seq
  print '(A,F8.5)', "Time sequential (s): ", time_seq
  print *
  print *, "Parallel sum (", num_parts, " parts):", total_par
  print '(A,F8.5)', "Time parallel (s):   ", time_par

  deallocate(a, partial)
end program sum_compare

