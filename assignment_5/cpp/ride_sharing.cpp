// Ride Sharing System (C++)
// Build: clang++ -std=c++17 ride_sharing.cpp -o ride_sharing && ./ride_sharing
#include <iomanip>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

using namespace std;

// ---------- Base class ----------
// A single trip. All attributes are private and read through getters;
// fare() and rideDetails() are virtual so each ride type can redefine them.
class Ride {
public:
    Ride(int id, string pickup, string dropoff, double distance)
        : rideID(id), pickupLocation(std::move(pickup)), dropoffLocation(std::move(dropoff)), distance(distance) {
        if (distance <= 0) throw invalid_argument("Distance must be positive");
    }
    virtual ~Ride() = default;

    // Base fare: $1.00 per mile. Subclasses override with their own pricing.
    virtual double fare() const { return distance * 1.00; }
    virtual string rideType() const { return "Basic"; }

    virtual void rideDetails() const {
        cout << "  Ride #" << rideID << " [" << rideType() << "] "
             << pickupLocation << " -> " << dropoffLocation << ", "
             << fixed << setprecision(1) << distance << " mi, fare $"
             << setprecision(2) << fare() << "\n";
    }

    // Getters (read-only access; a ride's details never change after creation)
    int getID() const { return rideID; }
    const string& getPickupLocation() const { return pickupLocation; }
    const string& getDropoffLocation() const { return dropoffLocation; }
    double getDistance() const { return distance; }

private:
    int rideID;
    string pickupLocation;
    string dropoffLocation;
    double distance;
};

// ---------- Subclasses ----------
// Standard ride: $2.50 base fee + $1.50 per mile.
class StandardRide : public Ride {
public:
    using Ride::Ride;
    double fare() const override { return 2.50 + getDistance() * 1.50; }
    string rideType() const override { return "Standard"; }
};

// Premium ride: $5.00 base fee + $3.00 per mile, plus extra details about perks.
class PremiumRide : public Ride {
public:
    using Ride::Ride;
    double fare() const override { return 5.00 + getDistance() * 3.00; }
    string rideType() const override { return "Premium"; }
    void rideDetails() const override {
        Ride::rideDetails();
        cout << "      Includes: luxury vehicle, complimentary water\n";
    }
};

// Shared ride: standard pricing with a 30% discount for carpooling.
class SharedRide : public StandardRide {
public:
    using StandardRide::StandardRide;
    double fare() const override { return StandardRide::fare() * 0.70; }
    string rideType() const override { return "Shared"; }
};

// ---------- Driver ----------
// A driver and the rides assigned to them. assignedRides is private and can
// only be changed through addRide().
class Driver {
public:
    Driver(int id, string name, double rating) : driverID(id), name(std::move(name)) { setRating(rating); }

    int getID() const { return driverID; }
    const string& getName() const { return name; }
    double getRating() const { return rating; }
    size_t getRideCount() const { return assignedRides.size(); }

    // Setter with validation: a rating must stay between 0 and 5.
    void setRating(double r) {
        if (r < 0.0 || r > 5.0) throw invalid_argument("Rating must be between 0 and 5");
        rating = r;
    }

    void addRide(const shared_ptr<Ride>& ride) { assignedRides.push_back(ride); }

    double totalEarnings() const {
        double total = 0;
        for (const auto& ride : assignedRides) total += ride->fare();
        return total;
    }

    void getDriverInfo() const {
        cout << "Driver #" << driverID << ": " << name << " (rating " << fixed << setprecision(1) << rating
             << "), " << assignedRides.size() << " rides, earnings $" << setprecision(2) << totalEarnings() << "\n";
        for (const auto& ride : assignedRides) ride->rideDetails();
    }

private:
    int driverID;
    string name;
    double rating = 0;
    vector<shared_ptr<Ride>> assignedRides; // private: only changed through addRide()
};

// ---------- Rider ----------
// A rider and the rides they have requested.
class Rider {
public:
    Rider(int id, string name) : riderID(id), name(std::move(name)) {}

    int getID() const { return riderID; }
    const string& getName() const { return name; }
    size_t getRideCount() const { return requestedRides.size(); }

    void requestRide(const shared_ptr<Ride>& ride) { requestedRides.push_back(ride); }

    void viewRides() const {
        cout << "Rider #" << riderID << ": " << name << ", " << requestedRides.size() << " rides requested\n";
        for (const auto& ride : requestedRides) ride->rideDetails();
    }

private:
    int riderID;
    string name;
    vector<shared_ptr<Ride>> requestedRides; // private: only changed through requestRide()
};

// ---------- System demo ----------
int main() {
    vector<shared_ptr<Ride>> rides = {
        make_shared<StandardRide>(101, "Downtown", "Airport", 12.0),
        make_shared<PremiumRide>(102, "Hotel Plaza", "Convention Center", 5.5),
        make_shared<SharedRide>(103, "University", "Mall", 8.0),
        make_shared<PremiumRide>(104, "Airport", "Uptown", 15.2),
        make_shared<StandardRide>(105, "Mall", "Stadium", 3.4),
    };

    cout << "=== All rides (polymorphic fare() and rideDetails()) ===\n";
    double total = 0;
    for (const auto& ride : rides) {
        ride->rideDetails();
        total += ride->fare();
    }
    cout << "Total fares: $" << fixed << setprecision(2) << total << "\n\n";

    Driver alice(1, "Alice Johnson", 4.9);
    Driver bob(2, "Bob Smith", 4.6);
    alice.addRide(rides[0]);
    alice.addRide(rides[1]);
    alice.addRide(rides[3]);
    bob.addRide(rides[2]);
    bob.addRide(rides[4]);

    cout << "=== Drivers ===\n";
    alice.getDriverInfo();
    bob.getDriverInfo();

    Rider carol(201, "Carol White");
    Rider dan(202, "Dan Brown");
    carol.requestRide(rides[0]);
    carol.requestRide(rides[2]);
    dan.requestRide(rides[1]);
    dan.requestRide(rides[3]);
    dan.requestRide(rides[4]);

    cout << "\n=== Riders ===\n";
    carol.viewRides();
    dan.viewRides();

    cout << "\n=== Encapsulation: getters and setters ===\n";
    cout << alice.getName() << " has " << alice.getRideCount() << " rides and a "
         << setprecision(1) << alice.getRating() << " rating\n";
    cout << carol.getName() << " requested " << carol.getRideCount() << " rides\n";
    bob.setRating(4.8);
    cout << bob.getName() << "'s rating updated to " << bob.getRating() << "\n";
    try {
        bob.setRating(7.5);
    } catch (const invalid_argument& e) {
        cout << "Rejected invalid rating for Bob: " << e.what() << "\n";
    }
    return 0;
}
