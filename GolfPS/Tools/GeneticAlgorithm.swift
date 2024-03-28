////
////  GeneticAlgorithm.swift
////  GolfPS
////
////  Created by Greg DeJong on 3/26/24.
////  Copyright © 2024 DeJong Development. All rights reserved.
////
//
//import Foundation
//
//class GeneticAlgorithm {
//    
//    //start with a sizeable population with random routes
//    let populationSize = 1000
//    
//    //rate at which children will mutate their routes beyond parent sequence
//    private let mutationProbability = 0.025
//    
//    private var ballotBox:[Int] = [Int]()
//    
//    private let targets: [CGPoint]
//    var onNewGeneration: ((GolfShotRoute, GolfShotRoute, Int) -> ())?
//    
//    private var population: [GolfShotRoute] = []
//    
//    private(set) var bestPossibleRouteSoFar:GolfShotRoute!
//
//    init(withPoints points: [CGPoint]) {
//        self.targets = points
//        self.population.removeAll()
//        
//        //create ballot box
//        for i in 0..<populationSize {
//            for j in 0..<populationSize - i {
//                ballotBox.append(j)
//            }
//        }
//        
//        for _ in 0..<populationSize {
//            let randomPoints = points.shuffled()
//            self.population.append(GolfShotRoute(targets: randomPoints))
//        }
//    }
//    
//    func calculateStartingSolution() {
//        bestPossibleRouteSoFar = nil
//        
//        //create a starting point of routes
//        if (self.targets.count <= 8) {
//            calculateBrute()
//        }
//    }
//    
//    private func calculateBrute() {
//        let targetIndex = Array(0..<self.targets.count)
//        let allCombos:[[Int]] = permute(targetIndex)
//        
//        for routeIndicies in allCombos {
//            let route = GolfShotRoute(shotLocations: routeIndicies.map({self.shotLocations[$0]}))
//            let calculatedRouteDistance = route.distance
//            
//            if bestPossibleRouteSoFar == nil || calculatedRouteDistance < bestPossibleRouteSoFar!.distance {
//                bestPossibleRouteSoFar = route
//            }
//        }
//    }
//    
//    private func permute(_ array:[Int], minLen: Int? = nil) -> [[Int]] {
//        let minLength:Int = minLen ?? array.count
//        
//        func permute(fromList: [Int], toList: [Int], set: inout Set<[Int]>) {
//            if toList.count >= minLength {
//                set.insert(toList)
//            }
//            guard !fromList.isEmpty else {
//                return
//            }
//            for (index, item) in fromList.enumerated() {
//                var newFrom = fromList
//                newFrom.remove(at: index)
//                permute(fromList: newFrom, toList: toList + [item], set: &set)
//            }
//        }
//
//        var set = Set<[Int]>()
//        permute(fromList: array, toList:[], set: &set)
//        return Array(set)
//    }
//    
//    private var evolving = false
//    private var generation = 1
//    
//    public func startEvolution() {
//        generation = 1
//        evolving = true
//        DispatchQueue.global().async {
//            self.calculateStartingSolution()
//        }
//        
//        DispatchQueue.global().async {
//            
//            while self.evolving {
//                
//                //get the total travel distance of the entire population
//                let currentTotalDistance = self.population.reduce(0.0, { $0 + $1.distance })
//                
//                let sortByFitness: (GolfShotRoute, GolfShotRoute) -> Bool = {
//                    $0.fitness(withTotalDistance: currentTotalDistance) > $1.fitness(withTotalDistance: currentTotalDistance)
//                }
//                let currentGeneration = self.population.sorted(by: sortByFitness)
//                
//                var nextGeneration: [GolfShotRoute] = []
//                
//                //create new children from randomly selected parents in current population
//                for _ in 0..<self.populationSize {
//                    guard
//                        let parentOne = self.getParent(fromGeneration: currentGeneration, withTotalDistance: currentTotalDistance),
//                        let parentTwo = self.getParent(fromGeneration: currentGeneration, withTotalDistance: currentTotalDistance)
//                        else { continue }
//                    
//                    let child = self.produceOffspring(firstParent: parentOne, secondParent: parentTwo)
//                    let mutatedChild = self.attemptToMutate(child: child)
//                    
//                    nextGeneration.append(mutatedChild)
//                }
//                self.population = nextGeneration.sorted(by: sortByFitness)
//                
//                
//                if let bestRoute = self.population.first {
//                    let numBestRoutes = self.population.filter({$0.targets == bestRoute.targets}).count
//                    if (numBestRoutes == self.population.count) {
//                        print("population failed!")
//                    }
//                    
//                    if let bestRouteSoFar = self.bestPossibleRouteSoFar {
//                        if bestRoute.distance < bestRouteSoFar.distance {
//                            self.bestPossibleRouteSoFar = bestRoute
//                            print("found a new BEST solution: \(bestRoute.distance):\(bestRouteSoFar.distance)")
//                        }
//                    } else {
//                        self.bestPossibleRouteSoFar = bestRoute
//                    }
//                    
//                    self.onNewGeneration?(self.bestPossibleRouteSoFar, bestRoute, self.generation)
//                }
//                self.generation += 1
//            }
//        }
//    }
//    
//    public func stopEvolution() {
//        evolving = false
//        
//        bestPossibleRouteSoFar = nil
//    }
//    
//    ///The individuals with the highest fitness will have the best chances of being selected. Individuals with the lowest fitness still have chances of being selected, but those chances are slim
//    private func getParent(fromGeneration generation: [GolfShotRoute], withTotalShots totalShots: Int) -> GolfShotRoute? {
//        var result: GolfShotRoute?
//        
//        //routlette
//        //get the parent from the ballots
//        let ballotIndex = Int.random(in: 0..<self.ballotBox.count)
//
//        let parentIndex = self.ballotBox[ballotIndex]
//
//        //get the winning parent from the ballot box
//        result = generation[parentIndex]
//        
//        //elite
////        let fitness = CGFloat.random(in: 0..<1)
////
////        var currentFitness: CGFloat = 0.0
////        generation.forEach { (route) in
////            if currentFitness <= fitness {
////                currentFitness += route.fitness(withTotalDistance: totalDistance)
////                result = route
////            }
////        }
//        
//        return result
//    }
//    
//    /**
//     Split the parent targets randomly and combine their targets into a new route
//        - returns: A new route combining targets from both parents
//     */
//    private func produceOffspring(firstParent: GolfShotRoute, secondParent: GolfShotRoute) -> GolfShotRoute {
//        //create a split point
//        let slice: Int = Int.random(in: 0..<firstParent.targets.count)
//        
//        //store the first parent targets before the split point
//        var targets: [CGPoint] = Array(firstParent.targets[0..<slice])
//        
//        var idx = slice
//        while targets.count < secondParent.targets.count {
//            //get the new target at the split point and beyond
//            let target = secondParent.targets[idx]
//            
//            //make sure the new offspring does not contain the same target
//            if targets.contains(target) == false {
//                targets.append(target)
//            }
//            
//            //continue to search for new targets from the second parent
//            idx = (idx + 1) % secondParent.targets.count
//        }
//        
//        return GolfShotRoute(targets: targets)
//    }
//    
//    ///Mutate route by swapping a single route target at random.
//    private func attemptToMutate(child: GolfShotRoute) -> GolfShotRoute {
//        let mutagen = Double.random(in: 0..<1)
//        guard self.mutationProbability >= mutagen else {
//            return child
//        }
//        
//        return swapRandomly(child: child)
//    }
//    
//    private func swapRandomly(child: GolfShotRoute) -> GolfShotRoute {
//        let firstIdx = Int.random(in: 0..<child.targets.count)
//        let secondIdx = Int.random(in: 0..<child.targets.count)
//        
//        var targets = child.targets
//        targets.swapAt(firstIdx, secondIdx)
//        
//        return TraceRoute(targets: targets)
//    }
//}
