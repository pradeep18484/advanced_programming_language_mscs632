"Ride Sharing System (GNU Smalltalk)
 Run: gst ride_sharing.st"

"---------- Base class ----------"
Object subclass: Ride [
    | rideID pickupLocation dropoffLocation distance |
    <comment: 'A single trip. Instance variables are private; other objects read them through accessor methods.'>

    Ride class >> id: anId pickup: aPickup dropoff: aDropoff distance: miles [
        miles <= 0 ifTrue: [^Error new signal: 'Distance must be positive'].
        ^self new setID: anId pickup: aPickup dropoff: aDropoff distance: miles
    ]

    "Formats a number with a fixed number of decimal places."
    Ride class >> format: aNumber places: places [
        | scale scaled |
        scale := 10 raisedTo: places.
        scaled := (aNumber * scale) rounded.
        ^(scaled // scale) printString, '.', ((scaled \\ scale) printPaddedWith: $0 to: places)
    ]

    setID: anId pickup: aPickup dropoff: aDropoff distance: miles [
        <category: 'private'>
        rideID := anId.
        pickupLocation := aPickup.
        dropoffLocation := aDropoff.
        distance := miles
    ]

    "Accessors (read-only: a ride's details never change after creation)"
    rideID [ ^rideID ]
    pickupLocation [ ^pickupLocation ]
    dropoffLocation [ ^dropoffLocation ]
    distance [ ^distance ]

    "Base fare: $1.00 per mile. Subclasses override with their own pricing."
    fare [ ^distance * 1.0 ]

    rideType [ ^'Basic' ]

    rideDetails [
        Transcript showCr: '  Ride #', rideID printString, ' [', self rideType, '] ',
            pickupLocation, ' -> ', dropoffLocation, ', ',
            (Ride format: distance places: 1), ' mi, fare $', (Ride format: self fare places: 2)
    ]
]

"---------- Subclasses ----------"
Ride subclass: StandardRide [
    <comment: 'Standard ride: $2.50 base fee + $1.50 per mile.'>
    fare [ ^2.50 + (self distance * 1.50) ]
    rideType [ ^'Standard' ]
]

Ride subclass: PremiumRide [
    <comment: 'Premium ride: $5.00 base fee + $3.00 per mile, plus extra details about perks.'>
    fare [ ^5.00 + (self distance * 3.00) ]
    rideType [ ^'Premium' ]
    rideDetails [
        super rideDetails.
        Transcript showCr: '      Includes: luxury vehicle, complimentary water'
    ]
]

StandardRide subclass: SharedRide [
    <comment: 'Shared ride: standard pricing with a 30% carpool discount.'>
    fare [ ^super fare * 0.70 ]
    rideType [ ^'Shared' ]
]

"---------- Driver ----------"
Object subclass: Driver [
    | driverID name rating assignedRides |
    <comment: 'A driver and the rides assigned to them. assignedRides can only be changed through addRide:.'>

    Driver class >> id: anId name: aName rating: aRating [
        ^self new setID: anId name: aName rating: aRating
    ]

    setID: anId name: aName rating: aRating [
        <category: 'private'>
        driverID := anId.
        name := aName.
        assignedRides := OrderedCollection new.
        self rating: aRating
    ]

    driverID [ ^driverID ]
    name [ ^name ]
    rating [ ^rating ]
    rideCount [ ^assignedRides size ]

    "Setter with validation: a rating must stay between 0 and 5."
    rating: aRating [
        (aRating < 0 or: [aRating > 5]) ifTrue: [^Error new signal: 'Rating must be between 0 and 5'].
        rating := aRating
    ]

    "assignedRides is private: it can only be changed through addRide:"
    addRide: aRide [ assignedRides add: aRide ]

    totalEarnings [ ^assignedRides inject: 0 into: [:sum :ride | sum + ride fare] ]

    getDriverInfo [
        Transcript showCr: 'Driver #', driverID printString, ': ', name,
            ' (rating ', (Ride format: rating places: 1), '), ',
            assignedRides size printString, ' rides, earnings $', (Ride format: self totalEarnings places: 2).
        assignedRides do: [:ride | ride rideDetails]
    ]
]

"---------- Rider ----------"
Object subclass: Rider [
    | riderID name requestedRides |
    <comment: 'A rider and the rides they have requested.'>

    Rider class >> id: anId name: aName [ ^self new setID: anId name: aName ]

    setID: anId name: aName [
        <category: 'private'>
        riderID := anId.
        name := aName.
        requestedRides := OrderedCollection new
    ]

    riderID [ ^riderID ]
    name [ ^name ]
    rideCount [ ^requestedRides size ]

    "requestedRides is private: it can only be changed through requestRide:"
    requestRide: aRide [ requestedRides add: aRide ]

    viewRides [
        Transcript showCr: 'Rider #', riderID printString, ': ', name, ', ',
            requestedRides size printString, ' rides requested'.
        requestedRides do: [:ride | ride rideDetails]
    ]
]

"---------- System demo ----------"
Eval [
    | rides total alice bob carol dan |
    rides := OrderedCollection new.
    rides
        add: (StandardRide id: 101 pickup: 'Downtown' dropoff: 'Airport' distance: 12.0);
        add: (PremiumRide id: 102 pickup: 'Hotel Plaza' dropoff: 'Convention Center' distance: 5.5);
        add: (SharedRide id: 103 pickup: 'University' dropoff: 'Mall' distance: 8.0);
        add: (PremiumRide id: 104 pickup: 'Airport' dropoff: 'Uptown' distance: 15.2);
        add: (StandardRide id: 105 pickup: 'Mall' dropoff: 'Stadium' distance: 3.4).

    Transcript showCr: '=== All rides (polymorphic fare and rideDetails) ==='.
    total := 0.
    rides do: [:ride |
        ride rideDetails.
        total := total + ride fare].
    Transcript showCr: 'Total fares: $', (Ride format: total places: 2); cr.

    alice := Driver id: 1 name: 'Alice Johnson' rating: 4.9.
    bob := Driver id: 2 name: 'Bob Smith' rating: 4.6.
    alice addRide: (rides at: 1); addRide: (rides at: 2); addRide: (rides at: 4).
    bob addRide: (rides at: 3); addRide: (rides at: 5).

    Transcript showCr: '=== Drivers ==='.
    alice getDriverInfo.
    bob getDriverInfo.

    carol := Rider id: 201 name: 'Carol White'.
    dan := Rider id: 202 name: 'Dan Brown'.
    carol requestRide: (rides at: 1); requestRide: (rides at: 3).
    dan requestRide: (rides at: 2); requestRide: (rides at: 4); requestRide: (rides at: 5).

    Transcript cr; showCr: '=== Riders ==='.
    carol viewRides.
    dan viewRides.

    Transcript cr; showCr: '=== Encapsulation: getters and setters ==='.
    Transcript showCr: alice name, ' has ', alice rideCount printString, ' rides and a ',
        (Ride format: alice rating places: 1), ' rating'.
    Transcript showCr: carol name, ' requested ', carol rideCount printString, ' rides'.
    bob rating: 4.8.
    Transcript showCr: bob name, '''s rating updated to ', (Ride format: bob rating places: 1).
    [bob rating: 7.5]
        on: Error
        do: [:e | Transcript showCr: 'Rejected invalid rating for Bob: ', e messageText]
]
