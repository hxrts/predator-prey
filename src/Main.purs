module Main where

import Prelude

import Data.Array (elem, length, replicate, (!!), modifyAt, foldl)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Number (exp, floor)
import Data.String (joinWith)
import Effect (Effect)
import Effect.Console (log)
import Effect.Random (randomInt, random)
import Web.DOM.NonElementParentNode (getElementById)
import Web.HTML (window)
import Web.HTML.HTMLDocument (toNonElementParentNode)
import Web.HTML.Window (document)
import Data.Foldable (sum)
import Data.Traversable (sequence)
import Data.Int (toNumber)
import Web.DOM.Internal.Types (Element)

foreign import setInnerHTML :: Element -> String -> Effect Unit

-- Define possible states in the lattice
type State = Int
preyState :: State
preyState = 1        -- Represents a prey animal  🐑
predatorState :: State
predatorState = -1   -- Represents a predator 👹
emptyState :: State
emptyState = 0       -- Represents an empty space 🌳

-- Lattice parameters
latticeSize :: Int
latticeSize = 10  -- Grid size (10x10)

temperature :: Number
temperature = 2.5  -- Controls randomness in state transitions (higher T = more randomness)

beta :: Number
beta = 1.0 / temperature  -- Inverse temperature (affects probability of energy changes)

-- | Generates a random lattice of size latticeSize x latticeSize
randomLattice :: Effect (Array (Array State))
randomLattice = sequence $ replicate latticeSize (sequence $ replicate latticeSize randomState)
  where
    -- Randomly assign each cell as prey (1), predator (-1), or empty (0)
    randomState :: Effect State
    randomState = do
      r <- randomInt 0 2
      pure $ case r of
        0 -> emptyState
        1 -> preyState
        _ -> predatorState

-- | Get the state of a cell at (i, j), applying periodic boundary conditions
getState :: Array (Array State) -> Int -> Int -> State
getState lattice i j =
  let n = length lattice
  in (lattice !! (i `mod` n)) >>= (_ !! (j `mod` n)) # fromMaybe emptyState  -- Wraps around edges

-- | Compute energy difference ΔH if a state at (i, j) changes
energyDifference :: Array (Array State) -> Int -> Int -> State -> Number
energyDifference lattice i j s =
  let neighbors = [ getState lattice (i+1) j   -- Right neighbor
                  , getState lattice (i-1) j   -- Left neighbor
                  , getState lattice i (j+1)   -- Down neighbor
                  , getState lattice i (j-1)   -- Up neighbor
                  ]
      -- Interaction energy: sum of spin-product interactions
      interactionEnergy = toNumber $ sum $ map (_ * s) neighbors
  in 2.0 * interactionEnergy  -- ΔH depends on neighboring influence

-- | Uses Metropolis-Hastings rule to determine if a transition is accepted
acceptFlip :: Number -> Effect Boolean
acceptFlip deltaE = do
  r <- random  -- Generate a random number between 0 and 1
  pure $ r < exp (-beta * deltaE)  -- Accept transition with probability e^(-βΔH)

-- | Attempts to update the state of a random cell (i, j) based on ecosystem rules
monteCarloStep :: Array (Array State) -> Effect (Array (Array State))
monteCarloStep lattice = do
  -- Pick a random site (i, j) in the lattice
  i <- randomInt 0 (latticeSize - 1)
  j <- randomInt 0 (latticeSize - 1)
  
  -- Retrieve the current state at (i, j)
  let currentState = getState lattice i j
  
  -- Determine possible state transitions
  newState <- case currentState of
    s | s == preyState -> if hasPredatorNeighbor i j then pure predatorState else pure preyState   -- Prey eaten by predator
    s | s == predatorState -> if hasPreyNeighbor i j then pure emptyState else pure predatorState  -- Predator starves without prey
    _ -> if hasPreyNeighbor i j then pure preyState else pure emptyState         -- New prey appears if adjacent prey exist
  
  -- Compute energy change ΔH if transition occurs
  let deltaE = energyDifference lattice i j newState

  -- Decide whether to accept the change
  accept <- acceptFlip deltaE
  pure $ if accept then updateLattice i j newState lattice else lattice  -- Apply or reject the transition
  where
    -- Checks if a given (i, j) site has a prey neighbor
    hasPreyNeighbor i j = hasNeighbor i j preyState
    -- Checks if a given (i, j) site has a predator neighbor
    hasPredatorNeighbor i j = hasNeighbor i j predatorState

    -- Helper function to check if a specific type of neighbor exists
    hasNeighbor :: Int -> Int -> State -> Boolean
    hasNeighbor i j s = 
      let neighbors = [ getState lattice (i+1) j
                      , getState lattice (i-1) j
                      , getState lattice i (j+1)
                      , getState lattice i (j-1)
                      ]
      in s `elem` neighbors

-- | Updates a specific cell (i, j) in the lattice with a new state
updateLattice :: Int -> Int -> State -> Array (Array State) -> Array (Array State)
updateLattice i j newState lattice =
  fromMaybe lattice $ modifyAt i (\row -> fromMaybe row (modifyAt j (const newState) row)) lattice

-- | Runs the Monte Carlo simulation for N steps
monteCarloSimulation :: Int -> Array (Array State) -> Effect (Array (Array State))
monteCarloSimulation 0 lattice = pure lattice
monteCarloSimulation steps lattice = do
  newLattice <- monteCarloStep lattice
  monteCarloSimulation (steps - 1) newLattice

-- | Converts the lattice into a readable string format
latticeToString :: Array (Array State) -> String
latticeToString lattice =
  joinWith "\n" $ map (joinWith "" <<< map stateToChar) lattice
  where
    -- Maps numerical states to emojis for better visualization
    stateToChar :: State -> String
    stateToChar s = case s of
      s' | s' == preyState -> "🐑"       -- Prey
      s' | s' == predatorState -> "👹"   -- Predator
      _ -> "🌳"                          -- Empty space

-- | Calculate statistics for the current lattice state
type SimulationStats = 
  { preyCount :: Int
  , predatorCount :: Int
  , emptyCount :: Int
  , totalCells :: Int
  , preyPercentage :: Number
  , predatorPercentage :: Number
  , emptyPercentage :: Number
  }

calculateStats :: Array (Array State) -> SimulationStats
calculateStats lattice = 
  let counts = foldl (\acc row -> foldl (addCount) acc row) { prey: 0, pred: 0, empty: 0 } lattice
      total = latticeSize * latticeSize
      toPercent count = (toNumber count / toNumber total) * 100.0
  in 
    { preyCount: counts.prey
    , predatorCount: counts.pred
    , emptyCount: counts.empty
    , totalCells: total
    , preyPercentage: toPercent counts.prey
    , predatorPercentage: toPercent counts.pred
    , emptyPercentage: toPercent counts.empty
    }
  where
    addCount acc state = case state of
      s | s == preyState -> acc { prey = acc.prey + 1 }
      s | s == predatorState -> acc { pred = acc.pred + 1 }
      _ -> acc { empty = acc.empty + 1 }

-- | Create an HTML table with simulation statistics
statsToHtml :: SimulationStats -> String
statsToHtml stats = 
  "<table style=\"margin: 20px 0; border-collapse: collapse; font-family: monospace;\">" <>
    "<tr>" <>
      "<th style=\"padding: 8px; border: 1px solid #ddd; text-align: left;\">Metric</th>" <>
      "<th style=\"padding: 8px; border: 1px solid #ddd; text-align: right;\">Count</th>" <>
      "<th style=\"padding: 8px; border: 1px solid #ddd; text-align: right;\">Percentage</th>" <>
    "</tr>" <>
    "<tr>" <>
      "<td style=\"padding: 8px; border: 1px solid #ddd;\">Prey 🐑</td>" <>
      "<td style=\"padding: 8px; border: 1px solid #ddd; text-align: right;\">" <> show stats.preyCount <> "</td>" <>
      "<td style=\"padding: 8px; border: 1px solid #ddd; text-align: right;\">" <> show (floor (stats.preyPercentage * 10.0) / 10.0) <> "%</td>" <>
    "</tr>" <>
    "<tr>" <>
      "<td style=\"padding: 8px; border: 1px solid #ddd;\">Predators 👹</td>" <>
      "<td style=\"padding: 8px; border: 1px solid #ddd; text-align: right;\">" <> show stats.predatorCount <> "</td>" <>
      "<td style=\"padding: 8px; border: 1px solid #ddd; text-align: right;\">" <> show (floor (stats.predatorPercentage * 10.0) / 10.0) <> "%</td>" <>
    "</tr>" <>
    "<tr>" <>
      "<td style=\"padding: 8px; border: 1px solid #ddd;\">Empty 🌳</td>" <>
      "<td style=\"padding: 8px; border: 1px solid #ddd; text-align: right;\">" <> show stats.emptyCount <> "</td>" <>
      "<td style=\"padding: 8px; border: 1px solid #ddd; text-align: right;\">" <> show (floor (stats.emptyPercentage * 10.0) / 10.0) <> "%</td>" <>
    "</tr>" <>
    "<tr>" <>
      "<td style=\"padding: 8px; border: 1px solid #ddd;\"><strong>Total</strong></td>" <>
      "<td style=\"padding: 8px; border: 1px solid #ddd; text-align: right;\"><strong>" <> show stats.totalCells <> "</strong></td>" <>
      "<td style=\"padding: 8px; border: 1px solid #ddd; text-align: right;\"><strong>100.0%</strong></td>" <>
    "</tr>" <>
  "</table>"

-- | Updates the DOM with the current lattice state and statistics
updateDisplay :: Element -> String -> Effect Unit
updateDisplay element content = setInnerHTML element content

-- | Main function: Runs the simulation and renders results to DOM
main :: Effect Unit
main = do
  -- Get the window and document
  w <- window
  doc <- document w
  
  -- Try to get the app element
  appElement <- getElementById "app" (toNonElementParentNode doc)
  case appElement of
    Just element -> do
      log "Generating initial lattice..."
      lattice <- randomLattice
      let initialState = latticeToString lattice
          initialStats = calculateStats lattice
      
      log "Running Monte Carlo simulation..."
      finalLattice <- monteCarloSimulation 1000 lattice
      let finalStats = calculateStats finalLattice
          finalState = 
            "<div style='font-family: monospace;'>" <>
            "<h3>Initial State</h3>" <>
            "<pre style='line-height: 1.5;'>" <> initialState <> "</pre>" <>
            "<h4>Initial Statistics</h4>" <>
            statsToHtml initialStats <>
            "<h3>Final State</h3>" <>
            "<pre style='line-height: 1.5;'>" <> latticeToString finalLattice <> "</pre>" <>
            "<h4>Final Statistics</h4>" <>
            statsToHtml finalStats <>
            "</div>"
      
      updateDisplay element finalState
      
    Nothing -> 
      log "Could not find app element" 