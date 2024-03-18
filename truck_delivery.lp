% define max time steps
#const max_time = 40.

% define nodes
node(N) :- N = 1..6.

% define edges
edges(1, 2; 2, 3; 3, 4; 4, 5; 2, 6; 3, 6; 2, 1; 3, 2; 4, 3; 5, 4; 6, 2; 6, 3).
% define factories (timestep, location, load)
factory(1, 1, 3).

% define delivery points (time, location, required_packages)
delivery_point(1,4,2; 1,5,2).

% define charging points (location)
charging_point(2; 6).

% define trucks: truck(id, time, location, load, capacity, charge_level, charge_capacity)
truck(1, 1, 1, 0, 1, 2, 10; 2, 1, 2, 0, 1, 2, 10).

% define initial spots for trucks
truck_at(1,1).
truck_at(2,2).

% first, count total amount of trucks and delivery points for later
num_trucks(N) :- N = #count{Id: truck_at(Id,_)}.
num_delivery_points(N) :- N = #count{Id: delivery_point(_,Id,_)}.

% generate all possible actions for all timesteps for each truck
1 { do(Time, Truck, move(1..6);Time, Truck, charge;Time, Truck, wait; Time, Truck, load; Time, Truck, unload)} 1 :- 
Time = 1..max_time, Truck = 1..C, C = #count{Id: truck(Id, _, _, _, _, _, _)}.

% below we define the actions that can be taken with their constraints

% MOVE
% move truck location at next timestep.
truck(Truck, Time + 1, N, Load, Capacity, Charge - 1, MaxCharge) :-
    do(Time, Truck, move(N)),
    truck(Truck, Time, _, Load, Capacity, Charge, MaxCharge).

% moving constraint
% constraint: truck cannot move to location if another truck also moves to the same location at the same time
:- do(Time1, Truck1, move(N1)),
    do(Time1, Truck2, move(N2)),
    Time1 == Time2,
    Truck1 != Truck2,
    N1 == N2.

% constraint: truck cannot move to location if another truck wants to move ro your location at the same time
:- do(Time1, Truck1, move(N1)),
    do(Time2, Truck2, move(N2)),
    truck(Truck1, Time1, N2, _, _, _, _),
    truck(Truck2, Time2, N1, _, _, _, _),
    Time1 == Time2,
    Truck1 != Truck2.

% constraint: truck cannot move to location if edges are not defined.
:- do(Time, Truck, move(New)),
    truck(Truck, Time, Old, _, _, _, _),
    not edges(Old, New).

% constraint: truck cannot move to location if another truck is already there this timestep. 
:- do(Time, Truck1, move(Node)),
    truck(Truck2, Time, Node, _, _, _, _),
    truck(Truck2, Time + 1, Node, _, _, _, _),
    Truck1 != Truck2.

% constraint: cant move to your own node
:- do(Time, Truck, move(Node)),
    truck(Truck, Time, Node, _, _, _, _).

% CHARGE
% charge truck at charging point
truck(Truck, Time + 1, N, Load, Capacity, Charge + 1, MaxCharge) :-
    do(Time, Truck, charge),
    truck(Truck, Time, N, Load, Capacity, Charge, MaxCharge).

% charging constraints
% can only charge if at charging_point
:- do(Time, Truck, charge),
    truck(Truck, Time, N, _, _, _, _),
    not charging_point(N).

% wait truck location at next timestep.
truck(Truck, Time + 1, N, Load, Capacity, Charge, MaxCharge) :-
    do(Time, Truck, wait),
    truck(Truck, Time, N, Load, Capacity, Charge, MaxCharge).

% LOAD
% load truck at factory
truck(Truck, Time + 1, N, Load + 1, Capacity, Charge, MaxCharge) :-
    do(Time, Truck, load),
    truck(Truck, Time, N, Load, Capacity, Charge, MaxCharge).

%  reduce factory load by one if load is performed
factory(Time + 1, N, FacLoad - 1) :-
    do(Time, _, load),
    factory(Time, N, FacLoad).

action(Time) :- do(Time, _, _).

% if load is not performed, dont change load
factory(Time + 1, N, FacLoad) :-
    action(Time),
    not do(Time, _, load),
    factory(Time, N, FacLoad).

% load constraints
% truck must be at factory
:- do(Time, Truck, load),
    truck(Truck, Time, N, _, _, _, _),
    not factory(_, N, _).

% truck must not have reached max load
:- do(Time, Truck, load),
    truck(Truck, Time, N, Load, Maxload, _, _),
    Load == Maxload.

% factory cannot go below 0 load
:- factory(_, _, Load), Load < 0.

% UNLOAD
% unload truck at delivery point
truck(Truck, Time + 1, N, Load - 1, Capacity, Charge, MaxCharge) :-
     do(Time, Truck, unload),
     truck(Truck, Time, N, Load, Capacity, Charge, MaxCharge).

% decrease required deliveries by 1
delivery_point(Time + 1, N, Required - 1) :-
    do(Time, Truck, unload),
    delivery_point(Time, N, Required).

% if unload is not performed, dont change load
delivery_point(Time + 1, N, Required) :-
    action(Time),
    not do(Time, _, load),
    delivery_point(Time, N, Required).

% unload constraints
% truck must be at a delivery point
:- do(Time, Truck, unload),
     truck(Truck, Time, N, _, _, _, _),
     not delivery_point(_, N, _).

% truck must have atleast 1 load
:- do(Time, Truck, unload),
     truck(Truck, Time, N, Load, _, _, _),
     Load < 1.

% GOALS
% define goal: if all trucks are at charging station, then the goal is reached

% first, define a helper predicate to check if a truck is not at a charging point
trucks_done(Time, false) :-
    truck(_, Time, N, _, _, _, _),
    not charging_point(N).

% then, define a predicate to check if there is a truck that still has load
trucks_done(Time, false) :-
    truck(_, Time, _, Load, _, _, _),
    Load > 0.

% if no truck is not at a charging point and no truck has load, then the first goal is reached
trucks_done(Time, true) :-
    truck(_, Time, _, _, _, _, _),
    not trucks_done(Time, false).

% define goal: if all delivery points do not have any required packages, then the goal is reached

% first, define a helper predicate to check if there is a delivery point that still has required packages
deliveries_done(Time, false) :-
    delivery_point(Time, _, Required),
    Required > 0.

% if no delivery point has required packages, then the second goal is reached
deliveries_done(Time, true) :-
    truck(_, Time, _, _, _, _, _),
    not deliveries_done(Time, false).

% if both goals are reached, then the final goal is reached
goal_reached(Time, true) :-
    deliveries_done(Time, true),
    trucks_done(Time, true).

% define a predicate to check if the goal is not reached
goal_reached(Time, false) :-
    truck(_, Time, _, _, _, _, _),
    not goal_reached(Time, true).

% goal must be reached for model to be considered
:- not goal_reached(_, true).

% MAXIMIZE WAIT STEPS
% the following lines serve as a way to maximize the amount of trucks that perform wait action,
% by counting the amount of trucks that perform wait action for each timestep and maximizing the amount of times all trucks perform wait action.

% for each timestep, count the amount of trucks that perform wait action
wait_count(Time, N) :- action(Time),
                        N = #count{wait, Truck: do(Time, Truck, wait)}.

% maximize the amount of trucks that perform wait action
% first, check if all trucks perform wait action for each timestep
all_trucks_await(Time) :- action(Time),
                        num_trucks(NumTrucks),
                        wait_count(Time, Count),
                        Count = NumTrucks.

% then, maximize the amount of times all trucks perform wait action
#maximize {Time: all_trucks_await(Time)}.


#show do/3.
#show truck_at/2.