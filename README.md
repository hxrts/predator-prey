# Predator-Prey Ising Model

This program uses an Ising model to simulate the interaction between predators and prey on a 2D lattice using a Monte Carlo algorithm with the Metropolis-Hastings acceptance rule.

The simulation models prey reproduction when empty space is available, predators hunting prey, predators starving if no prey is nearby, and the Boltzmann probability that governs whether transitions occur.

The system evolves over time capturing emergent behavior such as predator-prey cycles, spatial clustering, and extinction events.

## The Ising Model in Systems Ecology

The classical Ising Model is used in statistical mechanics to describe interactions between binary spin states. In this project, we use the Ising model to model predator-prey dynamics by assigning discrete states to represent, +1 (🐑, Prey), -1 (👹, Predator), and 0 (🌳, Empty space).

Each site in the lattice interacts with its nearest-neighbors and follows the Metropolis-Hastings rule to determine if it's state should change.

## Simulation Details

#### Grid Representation

The system is modeled as a 10×10 grid. Each cell represents an ecosystem state. 

#### Monte Carlo Steps

For 1000 simulation steps
1. Select a random site (i, j)
2. Determine valid state transitions according to the following rules:
   - Prey reproduce if an empty neighbor exists
   - Predators hunt prey, thereby growing their population and turning prey into predators
   - Predators starve if no prey are nearby
3. Compute energy change ΔH using the Ising-style Hamiltonian
   ```math
   H = - J \sum_{\langle i,j \rangle} s_i s_j - h \sum_i s_i
   ```
   where sᵢ is the state of site i, and nearest-neighbor interactions drive the system
4. Apply the Metropolis-Hastings rule: Always accept lower-energy transitions and only accept higher-energy transitions with probability:
   ```math
   P(\text{accept}) = e^{-\beta \Delta H}
   ```
1. Update the grid accordingly

#### Energy Calculation

Neighboring predator-prey interactions modify system energy. The probability of accepting state changes is governed by the Boltzmann factor $$e^{-\beta \Delta H}$$

#### Visualization

The lattice is printed before and after the simulation using emojis: +1 (🐑, Prey), -1 (👹, Predator), and 0 (🌳, Empty space).

## Development

Enter the development environment with
```bash
nix develop
```

The following development commands are also made available:

- `watch-project` - Build the project, start the development server, and watch for changes
- `build-project` - Build and bundle the application without serving
- `serve-project` - Build and serve the application without watching for changes
- `spago build` - Build the project (PureScript compilation only)
- `spago test` - Run tests
- `spago repl` - Start a PureScript REPL session 