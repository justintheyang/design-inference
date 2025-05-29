# design-inference
Psych 254a project on inferring design intent from physical arrangements. 


To set up the `design-inference` environment, at the root of the directory:
```
conda env create -f environment.yml # creates "design-inference"
conda activate design-inference
```

To set up the `gym-cooking` submodule, I had to take a hacky approach to get things to run on apple silicon. Specifically, from the project root:
```
cd gym-cooking
conda env create -f environment.yml    # creates “design-overcooked”
conda activate design-overcooked
```

`design-overcooked` is a separate conda environment from `design-inference` and should be used only when needed (e.g., getting model outputs, making graphics, etc)