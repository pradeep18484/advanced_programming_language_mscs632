import java.util.*;

/**
 * Employee shift scheduler (Java).
 * Run: javac Scheduler.java && java Scheduler
 */
public class Scheduler {
    static final String[] DAYS = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};
    static final String[] SHIFTS = {"Morning", "Afternoon", "Evening"};
    static final int MIN_PER_SHIFT = 2;
    static final int MAX_PER_SHIFT = 3;
    static final int MAX_DAYS = 5;

    static class Employee {
        final String name;
        final int[][] prefs = new int[DAYS.length][]; // prefs[day] = ranked shift indexes; empty = no preference
        int daysWorked = 0;

        Employee(String name) { this.name = name; }
    }

    // schedule[day][shift] = assigned employees
    static final List<List<List<Employee>>> schedule = new ArrayList<>();
    static final Random random = new Random();

    public static void main(String[] args) {
        List<Employee> employees = readEmployees(new Scanner(System.in));
        buildSchedule(employees);
        printSchedule(employees);
    }

    // ---------- 1. Input and storage ----------

    static List<Employee> readEmployees(Scanner in) {
        int count = 0;
        while (count < 1) {
            System.out.print("Number of employees: ");
            try {
                count = Integer.parseInt(in.nextLine().trim());
            } catch (NumberFormatException ex) {
                count = 0;
            }
            if (count < 1) System.out.println("Please enter a whole number greater than 0.");
        }

        List<Employee> employees = new ArrayList<>();
        System.out.println("For each day enter shifts in priority order using M, A, E (e.g. \"M E\"). Blank = no preference (you may still be assigned).");
        for (int i = 0; i < count; i++) {
            String name = "";
            while (name.isEmpty()) {
                System.out.print("\nEmployee " + (i + 1) + " name: ");
                name = in.nextLine().trim();
                if (name.isEmpty()) System.out.print("Name cannot be empty.");
            }
            Employee e = new Employee(name);
            for (int d = 0; d < DAYS.length; d++) {
                System.out.print("  " + DAYS[d] + ": ");
                e.prefs[d] = parsePrefs(in.nextLine());
            }
            employees.add(e);
        }
        return employees;
    }

    static int[] parsePrefs(String text) {
        List<Integer> ranked = new ArrayList<>();
        for (char c : text.toUpperCase().toCharArray()) {
            int shift = switch (c) {
                case 'M' -> 0;
                case 'A' -> 1;
                case 'E' -> 2;
                default -> -1;
            };
            if (shift >= 0 && !ranked.contains(shift)) ranked.add(shift);
        }
        return ranked.stream().mapToInt(Integer::intValue).toArray();
    }

    // ---------- 2 & 3. Scheduling logic and conflict resolution ----------

    record Request(Employee employee, int[] ranking) {}

    static void buildSchedule(List<Employee> employees) {
        List<Request> carryOver = new ArrayList<>();

        for (int d = 0; d < DAYS.length; d++) {
            List<List<Employee>> day = new ArrayList<>();
            for (int s = 0; s < SHIFTS.length; s++) day.add(new ArrayList<>());
            schedule.add(day);

            // Employees bumped from yesterday go first, then today's preferences.
            List<Request> queue = new ArrayList<>(carryOver);
            for (Employee e : employees) {
                if (e.prefs[d].length > 0) queue.add(new Request(e, e.prefs[d]));
            }
            carryOver = new ArrayList<>();

            for (Request r : queue) {
                Employee e = r.employee();
                if (e.daysWorked >= MAX_DAYS || isWorking(e, d)) continue;

                int shift = firstOpenShift(day, r.ranking());
                if (shift >= 0) {
                    assign(e, d, shift);
                    continue;
                }
                // Conflict: every preferred shift is full.
                shift = firstOpenShift(day, new int[]{0, 1, 2});
                if (shift >= 0) {
                    assign(e, d, shift);
                    System.out.printf("Conflict: %s's preference full on %s -> moved to %s%n", e.name, DAYS[d], SHIFTS[shift]);
                } else if (d + 1 < DAYS.length) {
                    carryOver.add(r);
                    System.out.printf("Conflict: %s's preference full on %s -> moved to %s%n", e.name, DAYS[d], DAYS[d + 1]);
                } else {
                    System.out.printf("Conflict: %s could not be placed on %s (no later day)%n", e.name, DAYS[d]);
                }
            }

            fillMinimum(employees, d);
        }
    }

    static int firstOpenShift(List<List<Employee>> day, int[] ranking) {
        for (int s : ranking) {
            if (day.get(s).size() < MAX_PER_SHIFT) return s;
        }
        return -1;
    }

    // Ensure at least MIN_PER_SHIFT employees per shift. Picks randomly among available
    // employees who have worked the fewest days, so no one runs out before the weekend.
    static void fillMinimum(List<Employee> employees, int d) {
        for (int s = 0; s < SHIFTS.length; s++) {
            List<Employee> shift = schedule.get(d).get(s);
            while (shift.size() < MIN_PER_SHIFT) {
                List<Employee> available = new ArrayList<>();
                for (Employee e : employees) {
                    if (e.daysWorked >= MAX_DAYS || isWorking(e, d)) continue;
                    if (!available.isEmpty() && e.daysWorked < available.get(0).daysWorked) available.clear();
                    if (available.isEmpty() || e.daysWorked == available.get(0).daysWorked) available.add(e);
                }
                if (available.isEmpty()) {
                    System.out.printf("Warning: %s %s is understaffed (no available employees)%n", DAYS[d], SHIFTS[s]);
                    break;
                }
                Employee pick = available.get(random.nextInt(available.size()));
                assign(pick, d, s);
                System.out.printf("Filled: %s randomly assigned to %s %s%n", pick.name, DAYS[d], SHIFTS[s]);
            }
        }
    }

    static boolean isWorking(Employee e, int d) {
        for (List<Employee> shift : schedule.get(d)) {
            if (shift.contains(e)) return true;
        }
        return false;
    }

    static void assign(Employee e, int d, int s) {
        schedule.get(d).get(s).add(e);
        e.daysWorked++;
    }

    // ---------- 4. Output ----------

    static void printSchedule(List<Employee> employees) {
        String row = "%-10s | %-24s | %-24s | %-24s%n";
        System.out.println("\n================ WEEKLY SCHEDULE (Java) ================");
        System.out.printf(row, "Day", SHIFTS[0], SHIFTS[1], SHIFTS[2]);
        System.out.println("-".repeat(92));
        for (int d = 0; d < DAYS.length; d++) {
            String[] cells = new String[SHIFTS.length];
            for (int s = 0; s < SHIFTS.length; s++) {
                StringJoiner names = new StringJoiner(", ");
                for (Employee e : schedule.get(d).get(s)) names.add(e.name);
                cells[s] = names.toString();
            }
            System.out.printf(row, DAYS[d], cells[0], cells[1], cells[2]);
        }
        System.out.println("\nDays worked:");
        for (Employee e : employees) System.out.printf("  %-8s %d%n", e.name, e.daysWorked);
    }
}
