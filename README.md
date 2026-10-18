# Employee Shift Scheduler — Java & Go

Schedules employees across 7 days × 3 shifts (Morning, Afternoon, Evening).

- One shift per employee per day, max 5 days per week
- At least 2 employees per shift: gaps are filled randomly from employees who are still available
- Max 3 per shift: if all of an employee's preferred shifts are full, they move to another shift that day, or to the next day if the whole day is full
- Bonus: each day's preferences are ranked (e.g. `M E` = Morning first, Evening second)

## Run

Enter the number of employees, then each name and their ranked shifts for every day (blank = no preference; the random fill may still assign that day). At least 9 employees are needed to staff every shift. `input.txt` has a ready-made set: `java Scheduler < ../input.txt` or `go run . < ../input.txt`.

```bash
cd java && javac Scheduler.java && java Scheduler
```

```bash
cd go && go run .
```
