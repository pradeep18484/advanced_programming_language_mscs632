// Employee shift scheduler (Go).
// Run: go run main.go
package main

import (
	"bufio"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"strings"
)

const (
	minPerShift = 2
	maxPerShift = 3
	maxDays     = 5
)

var (
	days   = []string{"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
	shifts = []string{"Morning", "Afternoon", "Evening"}
)

type Employee struct {
	Name       string
	Prefs      [7][]int // Prefs[day] = ranked shift indexes; empty = no preference
	DaysWorked int
}

type Request struct {
	Emp     *Employee
	Ranking []int
}

// schedule[day][shift] = assigned employees
var schedule [7][3][]*Employee

func main() {
	employees := readEmployees(bufio.NewScanner(os.Stdin))
	buildSchedule(employees)
	printSchedule(employees)
}

// ---------- 1. Input and storage ----------

func readEmployees(in *bufio.Scanner) []*Employee {
	readLine := func() string {
		if !in.Scan() {
			fmt.Println("\nInput ended unexpectedly.")
			os.Exit(1)
		}
		return strings.TrimSpace(in.Text())
	}

	count := 0
	for count < 1 {
		fmt.Print("Number of employees: ")
		count, _ = strconv.Atoi(readLine())
		if count < 1 {
			fmt.Println("Please enter a whole number greater than 0.")
		}
	}

	fmt.Println(`For each day enter shifts in priority order using M, A, E (e.g. "M E"). Blank = no preference (you may still be assigned).`)
	employees := make([]*Employee, 0, count)
	for i := 0; i < count; i++ {
		e := &Employee{}
		for e.Name == "" {
			fmt.Printf("\nEmployee %d name: ", i+1)
			e.Name = readLine()
			if e.Name == "" {
				fmt.Print("Name cannot be empty.")
			}
		}
		for d, day := range days {
			fmt.Printf("  %s: ", day)
			e.Prefs[d] = parsePrefs(readLine())
		}
		employees = append(employees, e)
	}
	return employees
}

func parsePrefs(text string) []int {
	var ranked []int
	seen := map[int]bool{}
	for _, c := range strings.ToUpper(text) {
		shift := -1
		switch c {
		case 'M':
			shift = 0
		case 'A':
			shift = 1
		case 'E':
			shift = 2
		}
		if shift >= 0 && !seen[shift] {
			seen[shift] = true
			ranked = append(ranked, shift)
		}
	}
	return ranked
}

// ---------- 2 & 3. Scheduling logic and conflict resolution ----------

func buildSchedule(employees []*Employee) {
	var carryOver []Request

	for d := range days {
		// Employees bumped from yesterday go first, then today's preferences.
		queue := carryOver
		carryOver = nil
		for _, e := range employees {
			if len(e.Prefs[d]) > 0 {
				queue = append(queue, Request{e, e.Prefs[d]})
			}
		}

		for _, r := range queue {
			e := r.Emp
			if e.DaysWorked >= maxDays || isWorking(e, d) {
				continue
			}
			if s := firstOpenShift(d, r.Ranking); s >= 0 {
				assign(e, d, s)
				continue
			}
			// Conflict: every preferred shift is full.
			if s := firstOpenShift(d, []int{0, 1, 2}); s >= 0 {
				assign(e, d, s)
				fmt.Printf("Conflict: %s's preference full on %s -> moved to %s\n", e.Name, days[d], shifts[s])
			} else if d+1 < len(days) {
				carryOver = append(carryOver, r)
				fmt.Printf("Conflict: %s's preference full on %s -> moved to %s\n", e.Name, days[d], days[d+1])
			} else {
				fmt.Printf("Conflict: %s could not be placed on %s (no later day)\n", e.Name, days[d])
			}
		}

		fillMinimum(employees, d)
	}
}

func firstOpenShift(d int, ranking []int) int {
	for _, s := range ranking {
		if len(schedule[d][s]) < maxPerShift {
			return s
		}
	}
	return -1
}

// fillMinimum ensures at least minPerShift employees per shift. It picks randomly among available
// employees who have worked the fewest days, so no one runs out before the weekend.
func fillMinimum(employees []*Employee, d int) {
	for s := range shifts {
		for len(schedule[d][s]) < minPerShift {
			var available []*Employee
			for _, e := range employees {
				if e.DaysWorked >= maxDays || isWorking(e, d) {
					continue
				}
				if len(available) > 0 && e.DaysWorked < available[0].DaysWorked {
					available = nil
				}
				if len(available) == 0 || e.DaysWorked == available[0].DaysWorked {
					available = append(available, e)
				}
			}
			if len(available) == 0 {
				fmt.Printf("Warning: %s %s is understaffed (no available employees)\n", days[d], shifts[s])
				break
			}
			pick := available[rand.Intn(len(available))]
			assign(pick, d, s)
			fmt.Printf("Filled: %s randomly assigned to %s %s\n", pick.Name, days[d], shifts[s])
		}
	}
}

func isWorking(e *Employee, d int) bool {
	for _, shift := range schedule[d] {
		for _, x := range shift {
			if x == e {
				return true
			}
		}
	}
	return false
}

func assign(e *Employee, d, s int) {
	schedule[d][s] = append(schedule[d][s], e)
	e.DaysWorked++
}

// ---------- 4. Output ----------

func printSchedule(employees []*Employee) {
	row := "%-10s | %-24s | %-24s | %-24s\n"
	fmt.Println("\n================ WEEKLY SCHEDULE (Go) ================")
	fmt.Printf(row, "Day", shifts[0], shifts[1], shifts[2])
	fmt.Println(strings.Repeat("-", 92))
	for d, day := range days {
		var cells [3]string
		for s := range shifts {
			names := make([]string, 0, len(schedule[d][s]))
			for _, e := range schedule[d][s] {
				names = append(names, e.Name)
			}
			cells[s] = strings.Join(names, ", ")
		}
		fmt.Printf(row, day, cells[0], cells[1], cells[2])
	}
	fmt.Println("\nDays worked:")
	for _, e := range employees {
		fmt.Printf("  %-8s %d\n", e.Name, e.DaysWorked)
	}
}
