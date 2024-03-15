% define max time steps
#const max_time = 40.

% define nodes
node(N) :- N = 1..6.

% define edges
edges(1, 2; 2, 3; 3, 4; 4, 5; 2, 6; 3, 6).

% define factories (timestep, location, load)
factory(1, 1,10).

% define delivery points (time, location, required_packages)
delivery_point(1,4,2; 1,5,2).

% define charging points (location)
charging_point(2; 6).

% define trucks truck(id, time, location, load, capacity, charge_level, charge_capacity)
truck(1, 1, 1, 0, 1 , 2 , 10; 2, 1, 2, 0, 1, 2, 10).

% define initial spots for trucks
truck_at(truck1,0).
truck_at(truck2,1).

% generate all possible actions for all timesteps for each truck
1 { do(Time, Truck, wait; Time, Truck, move; Time, Truck, load; Time, Truck, unload; Time, Truck, charge;) } 1 :- 
Time = 1..max_time, Truck = 1..C, C = #count{Id: truck(Id, _, _, _, _, _, _)}.


% move function
% generate all possible moves for any timestep for any truck
1 { move(Time, Truck, OldNode, 1..6) } 1 :- do(Time, Truck, move), truck(Truck, Time, OldNode, _, _, _, _).

% check if truck can move to a new node
can_move(Time, Truck, NewNode) :- 
    do(Time, Truck, move),
    move(Time, Truck, OldNode, NewNode),
    truck(Truck, Time, OldNode, _, _, Charge, _),
    edges(OldNode, NewNode),
    Charge > 0.

% check if only one truck moves to given node
:- can_move(Time, Truck1, NewNode1),
    can_move(Time, Truck2, NewNode2),
    Truck1 != Truck2, 
    NewNode1 = NewNode2.

% update truck location
truck(Truck, Time + 1, NewNode, Load, Capacity, ChargeLevel - 1, ChargeCapacity) :-
    can_move(Time, Truck, NewNode), move(Time, Truck, _, NewNode),
    truck(Truck, Time, OldNode, Load, Capacity, ChargeLevel, ChargeCapacity).

% wait function
truck(Truck, Time + 1, OldNode, Load, Capacity, ChargeLevel, ChargeCapacity) :-
    do(Time, Truck, wait),
    truck(Truck, Time, OldNode, Load, Capacity, ChargeLevel, ChargeCapacity).

% load from factory function
truck(Truck, Time + 1, OldNode, Load + 1, Capacity, ChargeLevel, ChargeCapacity) :-
    do(Time, Truck, load),
    truck(Truck, Time, OldNode, Load, Capacity, ChargeLevel, ChargeCapacity),
    factory(Time, OldNode, _), Load < Capacity.
    
factory(Time + 1, OldNode, FactLoad - 1) :-
    do(Time, Truck, load),
    factory(Time, OldNode, FactLoad),
    truck(Truck, Time, OldNode, _, _, _, _).

% unload at delivery point function
truck(Truck, Time + 1, OldNode, Load - 1, Capacity, ChargeLevel, ChargeCapacity) :-
    do(Time, Truck, unload),
    truck(Truck, Time, OldNode, Load, Capacity, ChargeLevel, ChargeCapacity),
    delivery_point(Time, OldNode, Required), Load > 0, Required > 0.

delivery_point(Time + 1, OldNode, Required - 1) :- 
    do(Time, Truck, unload),
    delivery_point(Time, OldNode, Required),
    truck(Truck, Time, OldNode, _, _, _, _).

% charge function
truck(Truck, Time + 1, OldNode, Load, Capacity, ChargeLevel + 1, ChargeCapacity) :-
    do(Time, Truck, charge),
    truck(Truck, Time, OldNode, Load, Capacity, ChargeLevel, ChargeCapacity),
    charging_point(OldNode), ChargeLevel < ChargeCapacity.

% constraints
% trucks cannot pass each other on a piece of road—e.g., trucks at adjacent locations cannot swap places in a single time step
:- can_move(Time, Truck1, NewNode1),
    can_move(Time, Truck2, NewNode2),
    Truck1 != Truck2, 
    edges(NewNode1, NewNode2).
#show truck/7.
% :- delivery_point(Node, Required), Required > 0, not truck(_, Time, Node, Load, _, _, _), Time = 1..max_time.