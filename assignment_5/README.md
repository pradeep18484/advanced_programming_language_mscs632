# Ride Sharing System — Smalltalk & C++

A class-based ride sharing system showing encapsulation, inheritance, and polymorphism.

- `Ride` base class with `fare()` and `rideDetails()`
- `StandardRide` ($2.50 + $1.50/mi), `PremiumRide` ($5.00 + $3.00/mi), and `SharedRide` (Standard with 30% off, inherits from `StandardRide`)
- `Driver` with a private `assignedRides` list, `addRide()`, and `getDriverInfo()` (includes total earnings)
- `Rider` with a private `requestedRides` list, `requestRide()`, and `viewRides()`
- Validation: distance must be positive and driver rating must be between 0 and 5

## Run

Run these commands from the `assignment_5` folder.

**C++** (C++17 compiler)
```bash
cd cpp
clang++ -std=c++17 ride_sharing.cpp -o ride_sharing
./ride_sharing
```
`g++` works the same way.

**Smalltalk** ([GNU Smalltalk](https://www.gnu.org/software/smalltalk/); on macOS: `brew install gnu-smalltalk`)
```bash
cd smalltalk
gst ride_sharing.st
```
