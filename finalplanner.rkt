#lang dssl2

let eight_principles = ["Know your rights.",
    "Acknowledge your sources.",
    "Protect your work.",
    "Avoid suspicion.",
    "Do your own work.",
    "Never falsify a record or permit another person to do so.",
    "Never fabricate data, citations, or experimental results.",
    "Always tell the truth when discussing your work with your instructor."]


# Final project: Trip Planner

import cons
import 'project-lib/dictionaries.rkt'
import 'project-lib/graph.rkt'
import 'project-lib/stack-queue.rkt'
import 'project-lib/binheap.rkt'
import sbox_hash


### Basic Types ###

#  - Latitudes and longitudes are numbers:
let Lat?  = num?
let Lon?  = num?

#  - Point-of-interest categories and names are strings:
let Cat?  = str?
let Name? = str?

### Raw Item Types ###

#  - Raw positions are 2-element vectors with a latitude and a longitude
let RawPos? = TupC[Lat?, Lon?]

#  - Raw road segments are 4-element vectors with the latitude and
#    longitude of their first endpoint, then the latitude and longitude
#    of their second endpoint
let RawSeg? = TupC[Lat?, Lon?, Lat?, Lon?]

#  - Raw points-of-interest are 4-element vectors with a latitude, a
#    longitude, a point-of-interest category, and a name
let RawPOI? = TupC[Lat?, Lon?, Cat?, Name?]

### Contract Helpers ###

# ListC[T] is a list of `T`s (linear time):
let ListC = Cons.ListC
# List of unspecified element type (constant time):
let List? = Cons.list?

class Position:
    let _lat
    let _lon
    
    
    def __init__(self, Lat: Lat?, Lon: Lon?):
        self._lat = Lat
        self._lon = Lon
        
    def lat(self) -> Lat?:
        return self._lat
            
    def lon(self) -> Lon?:
        return self._lon
        
    def pos(self):
        return [self._lat, self._lon]
        

            
                
def dist(pos1, pos2) -> num?:
    let lat = (pos2.lat() - pos1.lat())**2
    let lon = (pos2.lon() - pos1.lon())**2
    return (lat + lon).sqrt()
    
 
class Road_segment:
    let start
    let end
    let distance
    
    def __init__(self, seg):
        if seg is not None:
            self.start = Position(seg[0], seg[1])
            self.end = Position(seg[2], seg[3])
            self.distance = dist(self.start, self.end)
        else:
            
            error('Invalid road segment')
        
    def start_pos(self):
        return self.start
        
    def end_pos(self):
        return self.end
        
    def road_len(self):
        return self.distance
    
    
class POI:
    let _pos
    let _cat    
    let _name
    
    def __init__(self, poi):
        self._pos = Position(poi[0], poi[1])
        self._cat = poi[2]
        self._name = poi[3]
        
    def position(self):
        return self._pos
        
    def cat(self):
        return self._cat
       
    def name(self):
        return self._name 
        
    def poi(self):
        return [self.position().lat(), self.position().lon(), self.cat(), self.name()]

def member(x, vec):
    for i in range(vec.len()):
        if vec[i] == x:
            return True
    return False
    
def other_pos(self):
    return [self.lat(), self.lon()]
    
def member2(x, lst):
    let current = lst
    while current is not None:
        if current.data == x:
            return True
        current = current.next
    return False
    
interface TRIP_PLANNER:

    # Returns the positions of all the points-of-interest that belong to
    # the given category.
    def locate_all(
            self,
            dst_cat:  Cat?           # point-of-interest category
        )   ->        ListC[RawPos?] # positions of the POIs

    # Returns the shortest route, if any, from the given source position
    # to the point-of-interest with the given name.
    def plan_route(
            self,
            src_lat:  Lat?,          # starting latitude
            src_lon:  Lon?,          # starting longitude
            dst_name: Name?          # name of goal
        )   ->        ListC[RawPos?] # path to goal

    # Finds no more than `n` points-of-interest of the given category
    # nearest to the source position.
    def find_nearby(
            self,
            src_lat:  Lat?,          # starting latitude
            src_lon:  Lon?,          # starting longitude
            dst_cat:  Cat?,          # point-of-interest category
            n:        nat?           # maximum number of results
        )   ->        ListC[RawPOI?] # list of nearby POIs


        
class TripPlanner (TRIP_PLANNER):
    let positions
    let roads
    let pois
    let Town #graph: positions are vertices and roads are edges
    let name_to_pos # dict: map names to pos
    let poi_to_pos # dict: map poi info to postion
    let pos_to_poi # dict: map pos to poi info
    
    def __init__(self, roadsx, poisx):
        
        
        #roads
        self.roads = vec(roadsx.len())
        let x = 0
        for r in roadsx:
            let s = Road_segment(r)
            self.roads[x] = s
            x = x + 1
        
        #positions
        let a = 0
        let b = (vec((2* self.roads.len())))
        for r in self.roads:
            if not member(r.start_pos(), b):
                b[a] = r.start_pos()
                a = a + 1
            if not member(r.end_pos(), b):
                b[a] = r.end_pos()
                a = a + 1
                
        self.positions = vec(a)
        for y in range(a):
            self.positions[y] = b[y]
                
             
            
        #pois
        self.pois = vec(poisx.len())
        for p in range (poisx.len()):
            self.pois[p] = POI(poisx[p])
            
        
        
        self.name_to_pos = HashTable(self.pois.len(), make_sbox_hash())
        for p in self.pois:
            self.name_to_pos.put(p.name(), p.position())
    
        self.Town = WUGraph(self.positions.len() + 1) #Town/Graph
        self.poi_to_pos = HashTable(self.positions.len(), make_sbox_hash())
        self.pos_to_poi = HashTable(self.positions.len(), make_sbox_hash())
        let curr = 0
        for r in self.roads:
            if r is not None:  # check for None idk if you need to though
                if self.pos_to_poi.mem?(r.start_pos()) == False:
                    self.pos_to_poi.put(r.start_pos(), curr)
                    self.poi_to_pos.put(curr, r.start_pos())
                    curr = curr + 1
                if self.pos_to_poi.mem?(r.end_pos()) == False:
                    self.pos_to_poi.put(r.end_pos(), curr)
                    self.poi_to_pos.put(curr, r.end_pos())
                    curr = curr + 1
                self.Town.set_edge(self.pos_to_poi.get(r.start_pos()), self.pos_to_poi.get(r.end_pos()), r.road_len())
                
        
     
                
    def locate_all(self, cat):
        let catpos = None
        for poi in self.pois:
            if poi != None:
                if poi.cat() == cat:
                    if catpos == None:
                        catpos = cons(poi.position().pos(), catpos)
                    else:    
                        if member(poi.position().pos(), Cons.to_vec(catpos)) == False:
                            catpos = cons(poi.position().pos(), catpos)
        return (catpos)
    
       
        
    def get_raw_position(self, vertex) -> RawPos?:
        if vertex is not None and member(vertex, self.pos_to_poi):
            return self.poi_to_pos.get(vertex).pos()
        return None
                
    def get_vertices(self):
        return self.positions
        
    def num_vertices(self) -> nat?:
        return self.Town.len()
            
    def locate_vertex(self, lat, lon):
        for vertex in self.positions:
            ##print("Checking vertex: {vertex}, lat: {lat}, lon: {lon}")
            if vertex is not None: 
                #print("Vertex details - lat: {vertex.lat()}, lon: {vertex.lon()}")
                if vertex.lat() == lat and vertex.lon() == lon:
                    #print("Located vertex: {vertex}")
                    return vertex
        #print("Could not locate vertex for lat: {lat}, lon: {lon}")
        return None
        
    
        
   
    def location(self, lat, lon):
        for vertex in self.positions:
            ##print("Checking vertex: {vertex}, lat: {lat}, lon: {lon}")
            if vertex is not None: 
                #print("Vertex details - lat: {vertex.lat()}, lon: {vertex.lon()}")
                if vertex.lat() == lat and vertex.lon() == lon:
                    #print("Located vertex: {vertex}")
                    return vertex
        #print("Could not locate vertex for lat: {lat}, lon: {lon}")
        return None   
        
        
    def dijkstra(self, graph, start_vertex):
        let distances = HashTable(self.positions.len(), make_sbox_hash())
        let previous_vertices = AssociationList()
        let priority_queue = BinHeap[nat?](self.positions.len(), lambda a, b: distances.get(a) < distances.get(b))
        for p in self.positions:
            if self.pos_to_poi.mem?(p):
                let pos_key = self.pos_to_poi.get(p)
                distances.put(pos_key, inf)

        distances.put(start_vertex, 0)
        if start_vertex is not None:
            priority_queue.insert(start_vertex)

       

    # If no path found
        return [distances, previous_vertices]
            
    def get_path(self, start_vertex, goal_vertex, distances, previous_vertices):
        let path = Cons.from_vec([])
        #println("first")
        let temp_vertex = goal_vertex
        #println("second")

        while previous_vertices.get(temp_vertex) is not None:
            #println("third")
            path = path.cons(self.get_raw_position(temp_vertex))
            #println("fourth")
            temp_vertex = previous_vertices.get(temp_vertex)
            #println("fifth")
        #println("sixth")
        return path
        

    def get_neighbors(self, vertex):
        let neighborss = self.Town.get_adjacent(vertex)
        return Cons.to_vec(neighborss)
        

        
       
            
    def plan_route(self, lat, lon, name):
        
        
        if not self.name_to_pos.mem?(name):
            return Cons.from_vec([])
            
            
        let start = Position(lat, lon)
        
        let start_vertex = self.pos_to_poi.get(start)
        let goal = self.pos_to_poi.get(self.name_to_pos.get(name))
        
        
        if start_vertex is None or goal is None:
            
            return Cons.from_vec([])
        
        let distances = HashTable(self.positions.len(), make_sbox_hash())
        for pos in self.positions:
            
            let pos_key = self.pos_to_poi.get(pos)
            
            distances.put(pos_key, inf)
        distances.put(start_vertex, 0)
        let previous_vertices = AssociationList()
        
        let priority_queue = BinHeap[nat?](self.positions.len() * 2, lambda a, b: distances.get(a) < distances.get(b))
        
        priority_queue.insert(start_vertex)

        while priority_queue.len() > 0:
            let current_vertex = priority_queue.find_min()
            priority_queue.remove_min() 
            
            let neighbors = self.Town.get_adjacent(current_vertex)
            for neighbor in Cons.to_vec(neighbors):
                if previous_vertices.mem?(current_vertex):
                    if neighbor == previous_vertices.get(current_vertex):
                        continue                
                for r in self.roads:
                    let curr = self.poi_to_pos.get(current_vertex)
                    let neigh = self.poi_to_pos.get(neighbor)                   
                let d = distances.get(current_vertex) + dist(self.poi_to_pos.get(current_vertex), self.poi_to_pos.get(neighbor))

                if d < distances.get(neighbor):
                     distances.put(neighbor, d)
                     previous_vertices.put(neighbor, current_vertex)
                     priority_queue.insert(neighbor)
       
                         
            
        if distances.get(goal) == inf:
           return Cons.from_vec([])
           
        let a = vec(self.positions.len())
        let current_vertex = goal
        let x = 0
        while current_vertex is not start_vertex:            
            a[x] = current_vertex
            x = x + 1
            current_vertex = previous_vertices.get(current_vertex)
        a[x] = start_vertex
        let b = vec(x + 1)
        for y in range(x + 1):
            b[y] = self.poi_to_pos.get(a[x - y])
            b[y] = other_pos(b[y]) 
        return Cons.from_vec(b)
        

 
    def coord_to_poi(self, position_lst):
        let lat = position_lst[0]
        let lon = position_lst[1]
        
        
   
           
    def find_nearby(self, lat, lon, cat, n):        
        
        let categories = Cons.from_vec([])
        let seen = Cons.from_vec([])
        let equidistant_pois = Cons.from_vec([])
        
        let startpos = Position(lat, lon) 

        let starter = self.pos_to_poi.get(startpos)
        
        if starter is None:
            return Cons.from_vec([])
        
        let distances = [inf for i in range(self.positions.len())]
        let preds = [None for i in range(self.positions.len())]

        #Djikstra's
         
        
        distances[starter] = 0 
        
        #println("distances[starter]: %p", distances[starter])
        
        let priority = BinHeap[nat?](self.positions.len()* 2, lambda a, b: distances[a] <= distances[b])
        let visited = [False for x in range (self.positions.len())]
        
        priority.insert(starter)
        
        #println("Initial distances: %p", distances)
        #println("Initial preds: %p", preds)
        let encounter_counter = 0
        
        while priority.len() > 0:
            let min_vertex = priority.find_min() 
            
            priority.remove_min()
            #println("min_vertex: %p", min_vertex)
            #println("distances: %p", distances)
            #println("preds: %p", preds)
            if not visited[min_vertex]:
                visited[min_vertex] = True
                let adj = self.Town.get_adjacent(min_vertex)  #cons list

                for adjacent in Cons.to_vec(adj):
                    let edge_weight = dist(self.poi_to_pos.get(min_vertex), self.poi_to_pos.get(adjacent))
                    #println("min_vertex: %p", min_vertex)
                    #println("distances[min_vertex]: %p", distances[min_vertex])
                    #println("adjacent: %p", adjacent)
                    #println("edge_weight: %p", edge_weight)
                    #println("distances[min_vertex] + edge_weight: %p", distances[min_vertex] + edge_weight)
                    #println("distances[adjacent]: %p", distances[adjacent])
                   # println("dist %p", dist(self.poi_to_pos.get(min_vertex), self.poi_to_pos.get(adjacent)))
                    if edge_weight < distances[adjacent] and edge_weight != inf:
                        
                        distances[adjacent] = edge_weight
                        #print("Updated distances: %p", distances)
                        #print("Updated preds: %p", preds)
                        preds[adjacent] = min_vertex
                        priority.insert(adjacent)
        
        #println("Final distances: %p", distances)
        #println("Final preds: %p", preds)
                                                                                                                  
        for poi in self.pois:
            if poi.cat() == cat:
                let poi_position = poi.position()
                if poi_position is not None:
                    let poi_key = poi_position.pos()
                    let poi_instance1 = POI([poi_position.lat(), poi_position.lon(), poi.cat(), poi.name()]) 
                        
                    let duplicate = False
                    let current = categories
                    while current is not None:
                        
                        if current.data.position().pos() == poi_key:
                            duplicate = True    
                            break   
                        current = current.next                       
                    if poi_key is not None and not duplicate:
                        let seen_current = seen
                        while seen_current is not None:
                            if seen_current.data == poi_key:
                                duplicate = True
                                break
                            seen_current = seen_current.next
                        if not duplicate and distances[self.pos_to_poi.get(poi_position)] != inf:
                            let poi_instance = POI([poi_position.lat(), poi_position.lon(), poi.cat(), poi.name()])
                            
                            seen = cons(poi_instance, seen)
                            categories = cons(poi_instance, categories)  
                             
                        
        #println("Final distances: %p", distances)
        #println("Final preds: %p", preds)
        #println("categories: %p", categories)                                  
                                       
                                        
        #println("End of loop. Categories: %p", categories)
        
        categories = Cons.sort(
    lambda poi1, poi2: (
        distances[self.pos_to_poi.get(poi1.position())] < distances[self.pos_to_poi.get(poi2.position())] or
        (distances[self.pos_to_poi.get(poi1.position())] == distances[self.pos_to_poi.get(poi2.position())] and
         preds[self.pos_to_poi.get(poi1.position())] <= preds[self.pos_to_poi.get(poi2.position())]) or
        (distances[self.pos_to_poi.get(poi1.position())] == distances[self.pos_to_poi.get(poi2.position())] and
         preds[self.pos_to_poi.get(poi1.position())] == preds[self.pos_to_poi.get(poi2.position())] and
         self.pos_to_poi.get(poi1.position()) < self.pos_to_poi.get(poi2.position())) or
         (distances[self.pos_to_poi.get(poi1.position())] == distances[self.pos_to_poi.get(poi2.position())] and
         self.pos_to_poi.get(poi1.position()) > self.pos_to_poi.get(poi2.position()))
    ),
    categories
)
        #categories = Cons.sort(lambda poi1, poi2: distances[self.pos_to_poi.get(poi1.position())] > distances[self.pos_to_poi.get(poi2.position())], categories)
        let final_return = Cons.from_vec([])
        let current = categories
        while current is not None and n > 0:
            let poi_instance = current.data
            let poi_position = poi_instance.position()
            let poi_key = poi_position.pos()
            let poi_index = self.pos_to_poi.get(poi_position)
            let poi_distance = distances[poi_index]
            if poi_key is not None and poi_distance != inf:
                let expected_data = [poi_position.lat(), poi_position.lon(), poi_instance.cat(), poi_instance.name()]
                final_return = cons(expected_data, final_return)
                n = n - 1
                #println("Added POI: %p, Distance: %p", expected_data, poi_distance)
            
            current = current.next  
        #println("Final result: %p", final_return)
        return final_return
        
        
        
        
                
#   ^ YOUR WORK GOES HERE


def my_first_example():
    return TripPlanner([[0,0, 0,1], [0,0, 1,0]],
                       [[0,0, "bar", "The Empty Bottle"],
                        [0,1, "food", "Pierogi"]])

test 'My first locate_all test':
    assert my_first_example().locate_all("food") == \
        cons([0,1], None)
        
test 'Locate all test for "bar" category':
    assert my_first_example().locate_all("bar") == \
        cons([0, 0], None)

test 'Locate all test for "restaurant" category':
    assert my_first_example().locate_all("restaurant") == \
        None

    

test 'My first plan_route test':
   assert my_first_example().plan_route(0, 0, "Pierogi") == \
       cons([0,0], cons([0,1], None))
       
test '2-step route':
   let tp = TripPlanner([[0, 0, 1.5, 0], [1.5, 0, 2.5, 0], [2.5, 0, 3, 0]], [[1.5, 0, 'bank', 'Union'], [2.5, 0, 'barber', 'Tony']])
   let result = tp.plan_route(0, 0, 'Tony')
   result = Cons.to_vec(result)
   assert result == [[0, 0], [1.5, 0], [2.5, 0]]
   
test '3-step route':
   let tp = TripPlanner(
     [[0, 0, 1.5, 0],
      [1.5, 0, 2.5, 0],
      [2.5, 0, 3, 0]],
     [[1.5, 0, 'bank', 'Union'],
      [3, 0, 'barber', 'Tony']])
   let result = tp.plan_route(0, 0, 'Tony')
   result = Cons.to_vec(result)
   assert result == [[0, 0], [1.5, 0], [2.5, 0], [3, 0]]
   
test 'from barber to bank':
   let tp = TripPlanner(
     [[0, 0, 1.5, 0],
      [1.5, 0, 2.5, 0],
      [2.5, 0, 3, 0]],
     [[1.5, 0, 'bank', 'Union'],
      [3, 0, 'barber', 'Tony']])
   let result = tp.plan_route(3, 0, 'Union')
   result = Cons.to_vec(result)
   assert result == [[3, 0], [2.5, 0], [1.5, 0]]
   
test '0-step route':
   let tp = TripPlanner(
     [[0, 0, 1, 0]],
     [[0, 0, 'bank', 'Union']])
   let result = tp.plan_route(0, 0, 'Union')
   result = Cons.to_vec(result)
   assert result == [[0, 0]]
   
test 'Destination isnt reachable':
   let tp = TripPlanner(
     [[0, 0, 1.5, 0],
      [1.5, 0, 2.5, 0],
      [2.5, 0, 3, 0],
      [4, 0, 5, 0]],
     [[1.5, 0, 'bank', 'Union'],
      [3, 0, 'barber', 'Tony'],
      [5, 0, 'barber', 'Judy']])
   let result = tp.plan_route(0, 0, 'Judy')
   result = Cons.to_vec(result)
   assert result == []

test 'BFS is not SSSP (route)':
   let tp = TripPlanner(
     [[0, 0, 0, 9],
      [0, 9, 9, 9],
      [0, 0, 1, 1],
      [1, 1, 2, 2],
      [2, 2, 3, 3],
      [3, 3, 4, 4],
      [4, 4, 5, 5],
      [5, 5, 6, 6],
      [6, 6, 7, 7],
      [7, 7, 8, 8],
      [8, 8, 9, 9]],
     [[7, 7, 'haberdasher', 'Archit'],
      [8, 8, 'haberdasher', 'Braden'],
      [9, 9, 'haberdasher', 'Cem']])
   let result = tp.plan_route(0, 0, 'Cem')
   result = Cons.to_vec(result)
   assert result == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [8, 8], [9, 9]]   
   
test 'MST is not SSSP (route)':
   let tp = TripPlanner(
     [[-1.1, -1.1, 0, 0],
      [0, 0, 3, 0],
      [3, 0, 3, 3],
      [3, 3, 3, 4],
      [0, 0, 3, 4]],
     [[0, 0, 'food', 'Sandwiches'],
      [3, 0, 'bank', 'Union'],
      [3, 3, 'barber', 'Judy'],
      [3, 4, 'barber', 'Tony']])
   let result = tp.plan_route(-1.1, -1.1, 'Tony')
   result = Cons.to_vec(result)
   assert result == [[-1.1, -1.1], [0, 0], [3, 4]]
   
test 'Destination is the 2nd of 3 POIs at that location':
   let tp = TripPlanner(
     [[0, 0, 1.5, 0],
      [1.5, 0, 2.5, 0],
      [2.5, 0, 3, 0],
      [4, 0, 5, 0],
      [3, 0, 4, 0]],
     [[1.5, 0, 'bank', 'Union'],
      [3, 0, 'barber', 'Tony'],
      [5, 0, 'bar', 'Pasta'],
      [5, 0, 'barber', 'Judy'],
      [5, 0, 'food', 'Jollibee']])
   let result = tp.plan_route(0, 0, 'Judy')
   result = Cons.to_vec(result)
   assert result == [[0, 0], [1.5, 0], [2.5, 0], [3, 0], [4, 0], [5, 0]]
   
test 'Two equivalent routes':
   let tp = TripPlanner(
     [[-2, 0, 0, 2],
      [0, 2, 2, 0],
      [2, 0, 0, -2],
      [0, -2, -2, 0]],
     [[2, 0, 'cooper', 'Dennis']])
   let result = tp.plan_route(-2, 0, 'Dennis')
   result = Cons.to_vec(result) 
   assert result == [[-2, 0], [0, 2], [2, 0]] \
     or result == [[-2, 0], [0, -2], [2, 0]]
    

     
test 'BinHeap needs capacity > |V|':
   let tp = TripPlanner(
     [[0, 0, 0, 1],
      [0, 1, 3, 0],
      [0, 1, 4, 0],
      [0, 1, 5, 0],
      [0, 1, 6, 0],
      [0, 0, 1, 1],
      [1, 1, 3, 0],
      [1, 1, 4, 0],
      [1, 1, 5, 0],
      [1, 1, 6, 0],
      [0, 0, 2, 1],
      [2, 1, 3, 0],
      [2, 1, 4, 0],
      [2, 1, 5, 0],
      [2, 1, 6, 0]],
     [[0, 0, 'blacksmith', "Revere's Silver Shop"],
      [6, 0, 'church', 'Old North Church']])
   let result = tp.plan_route(0, 0, 'Old North Church')
   result = Cons.to_vec(result)
   assert result == [[0, 0], [2, 1], [6, 0]]
#The stress test, 40 and in general
#Failed test: Two plan_route queries in a row, same TripPlanner???   

test 'My first find_nearby test':
    assert my_first_example().find_nearby(0, 0, "food", 1) == \
        cons([0,1, "food", "Pierogi"], None)
        
        
test "1 bank nearby":
    let tp = TripPlanner(
      [[0, 0, 1, 0]],
      [[1, 0, 'bank', 'Union']])
    let result = Cons.to_vec(tp.find_nearby(0, 0, 'bank', 1))
    #???result = _sort_for_grading_comparison(_Cons_to_vec(result))
    assert result == [[1, 0, 'bank', 'Union']]
    
test "1 barber nearby":
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony']])
    let result = Cons.to_vec(tp.find_nearby(0, 0, 'barber', 1))
    #result = _sort_for_grading_comparison(_Cons_to_vec(result))
    assert result == [[3, 0, 'barber', 'Tony']]
    
test "find bank from barber":
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony']])
    let result = Cons.to_vec(tp.find_nearby(3, 0, 'bank', 1))
    #result = _sort_for_grading_comparison(_Cons_to_vec(result))
    assert result == [[1.5, 0, 'bank', 'Union']]
    
test "2 relevant POIs; 1 reachable":
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [4, 0, 'food', 'Jollibee'],
       [5, 0, 'barber', 'Judy']])
    let result = Cons.to_vec(tp.find_nearby(0, 0, 'barber', 2))
    #result = _sort_for_grading_comparison(_Cons_to_vec(result))
    assert result == [[3, 0, 'barber', 'Tony']]
    
test "BFS is not SSSP (nearby)":
    #println("blach blach blach")
    let tp = TripPlanner(
      [[0, 0, 0, 9],
       [0, 9, 9, 9],
       [0, 0, 1, 1],
       [1, 1, 2, 2],
       [2, 2, 3, 3],
       [3, 3, 4, 4],
       [4, 4, 5, 5],
       [5, 5, 6, 6],
       [6, 6, 7, 7],
       [7, 7, 8, 8],
       [8, 8, 9, 9]],
      [[7, 7, 'haberdasher', 'Archit'],
       [8, 8, 'haberdasher', 'Braden'],
       [9, 9, 'haberdasher', 'Cem']])
    let result = Cons.to_vec(tp.find_nearby(0, 0, 'haberdasher', 2))
    #result = _sort_for_grading_comparison(_Cons_to_vec(result))
    assert result == [[7, 7, 'haberdasher', 'Archit'], [8, 8, 'haberdasher', 'Braden']]
    
test "MST is not SSSP (nearby)":
    #println("HIBERNATION")
    let tp = TripPlanner(
      [[-1.1, -1.1, 0, 0],
       [0, 0, 3, 0],
       [3, 0, 3, 3],
       [3, 3, 3, 4],
       [0, 0, 3, 4]],
      [[0, 0, 'food', 'Sandwiches'],
       [3, 0, 'bank', 'Union'],
       [3, 3, 'barber', 'Judy'],
       [3, 4, 'barber', 'Tony']])
    let result = Cons.to_vec(tp.find_nearby(-1.1, -1.1, 'barber', 1))
    #result = _sort_for_grading_comparison(_Cons_to_vec(result))
    assert result == [[3, 4, 'barber', 'Tony']]
    
test "2 relevant POIs; limit 3":
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0],
       [3, 0, 4, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [4, 0, 'food', 'Jollibee'],
       [5, 0, 'barber', 'Judy']])
    let result = Cons.to_vec(tp.find_nearby(0, 0, 'barber', 3))
    #result = _sort_for_grading_comparison(_Cons_to_vec(result))
    assert result == [[5, 0, 'barber', 'Judy'], [3, 0, 'barber', 'Tony']]
    

test "2 relevant equidistant POIs; limit 1":
    let tp = TripPlanner(
      [[-1, -1, 0, 0],
       [0, 0, 3.5, 0],
       [0, 0, 0, 3.5],
       [3.5, 0, 0, 3.5]],
      [[-1, -1, 'food', 'Jollibee'],
       [0, 0, 'bank', 'Union'],
       [3.5, 0, 'barber', 'Tony'],
       [0, 3.5, 'barber', 'Judy']])
    let result = Cons.to_vec(tp.find_nearby(-1, -1, 'barber', 1))
    #result = _sort_for_grading_comparison(_Cons_to_vec(result))
    assert result == [[3.5, 0, 'barber', 'Tony']] \
      or result == [[0, 3.5, 'barber', 'Judy']]
      
test '3 relevant POIs; farther 2 at same location; limit 2':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0],
       [3, 0, 4, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'barber', 'Judy'],
       [5, 0, 'barber', 'Lily']])
    let result = Cons.to_vec(tp.find_nearby(0, 0, 'barber', 2))
    #result = _sort_for_grading_comparison(_Cons_to_vec(result))
    assert result == [[5, 0, 'barber', 'Judy'], [3, 0, 'barber', 'Tony']] \
      or result == [[5, 0, 'barber', 'Lily'], [3, 0, 'barber', 'Tony']]
      
test "3 relevant POIs; farther 2 equidistant; limit 2":
    #println("9999999999999")
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0],
       [3, 0, 4, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [0, 0, 'barber', 'Lily'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'barber', 'Judy']])
    let result = Cons.to_vec(tp.find_nearby(2.5, 0, 'barber', 2))
    #result = _sort_for_grading_comparison(_Cons_to_vec(result))
    #println("result: %p", result)
    assert result == [[5, 0, 'barber', 'Judy'], [3, 0, 'barber', 'Tony']] \
      or result == [[0, 0, 'barber', 'Lily'], [3, 0, 'barber', 'Tony']]
      
test "POI is 2nd of 3 in that location":
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0],
       [3, 0, 4, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'food', 'Jollibee'],
       [5, 0, 'barber', 'Judy'],
       [5, 0, 'bar', 'Pasta']])
    let result = Cons.to_vec(tp.find_nearby(0, 0, 'barber', 2))
    #result = _sort_for_grading_comparison(_Cons_to_vec(result))
    assert result == [[5, 0, 'barber', 'Judy'], [3, 0, 'barber', 'Tony']]
    
#Failed test: Two find_nearby queries in a row, same TripPlanner instance??
#stress tests??
      

