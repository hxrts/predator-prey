# Predator-Prey Ising Model

This simulates the interaction between predators and prey with a classical Ising model on a 2D lattice, using a Monte Carlo algorithm that accepts states based on the Metropolis-Hastings rule.

The simulation models prey reproduction when empty space is available, predators hunting prey, and predators starving if no prey are nearby, using a Boltzmann probability to govern whether state transitions will occur.

As the system evolves over time it can capture emergent behavior such as predator-prey cycles, spatial clustering, and extinction events.

## The Ising Model in Systems Ecology

The classical Ising Model is used in statistical mechanics to describe interactions between binary spin states. In this project, we use the Ising model to model predator-prey dynamics by assigning discrete states to represent Prey (+1 or 🐸), Predator (-1 or 🦊), and Empty space (0 or ⬜).

Each site in the lattice interacts with its nearest-neighbors and follows the Metropolis-Hastings rule to determine if it's state should change.

## Simulation Details

#### Grid Representation

The system is modeled as a 10×10 grid. Each cell represents a local ecosystem state. 

#### Monte Carlo Steps

For 1000 simulation steps
1. Select a random site (i, j)
2. Determine valid state transitions according to the following rules:
   - Prey will reproduce if an empty neighbor exists, turning ⬜ → 🐸
   - Predators hunt prey, thereby growing their population and turning prey into predators, turning 🐸 → 🦊
   - Predators starve if no prey are nearby, turning 🦊 → ⬜
3. Compute energy change ΔH using the Ising-style Hamiltonian
   ```math
   H = - J \sum_{\langle i,j \rangle} s_i s_j - h \sum_i s_i
   ```
   where sᵢ is the state of site i, and nearest-neighbor interactions drive the system
4. Apply the Metropolis-Hastings rule: always accept state transitions that lower the system energy, only accept state transitions to higher-energy system configurations with probability:
   ```math
   P(\text{accept}) = e^{-\beta \Delta H}
   ```
5. Update the grid accordingly

#### Energy Calculation

Neighboring predator-prey interactions modify system energy. The probability of accepting state changes is governed by the Boltzmann factor $$e^{-\beta \Delta H}$$

#### Visualization

The lattice is shown before and after the simulation, represented by emojis: Prey = +1 = 🐸, Predator = -1 = 🦊, and Empty space = 0 = ⬜.

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