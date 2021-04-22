# SpiceMix

![overview](./SpiceMix_overview.png)

SpiceMix is an unsupervised tool for analyzing data of the spatial transcriptome. SpiceMix models the observed expression of genes within a cell as a mixture of latent factors. These factors are assumed to have some spatial affinity between neighboring cells. The factors and affinities are not known a priori, but are learned by SpiceMix directly from the data, by an alternating optimization method that seeks to maximize their posterior probability given the observed gene expression. In this way, SpiceMix learns a more expressive representation of the identity of cells from their spatial transcriptome data than other available methods. 

SpiceMix can be applied to any type of spatial transcriptomics data, including MERFISH, seqFISH, HDST, and Slide-seq.

## Requirement

- Python=3.7.3
- scipy=1.2.1
- gurobi=8.1.1
- pytorch=1.4.0
- numpy=1.16.2
- scikit-learn=0.21.1
- h5py=3.1.0

## Running SpiceMix

All code is contained within the SpiceMix folder. The script `main.py` runs the program -- see examples for usage.

### Step 1: Preparing input files

All files for one run of SpiceMix must be put into one directory. SpiceMix can be applied to multiple samples (or replicates, or fields-of-view (FOV)) simultaneously, learning shared parameters across samples (we use the term FOV for an independent sample). For each FOV with name `<FOV>` of `N` cells and `G` genes, the following two files stored as tab-delimited txt format are required for SpiceMix:

- `expression_<FOV>_<expr_suffix>.txt`, an N-by-G nonnegative-valued matrix of normalized single-cell expression profiles. In our paper, we applied the following steps of normalization to all data sets:
  - Filter out genes with low nonzero rates and/or cells that express only a few genes
  - Log transformation: Let <img src="https://render.githubusercontent.com/render/math?math=E_{ig}"> be the read counts of gene `g` in cell `i`, and the number of counts after log transformation is ![formula](https://render.githubusercontent.com/render/math?math=E'_{ig}=\log(1%2B10^4\cdot%20E_{ij}/\sum_{g'=1}^GE_{ig'}))
- `neighborhood_<FOV>_<neigh_suffix>.txt`, a neighbor graph represented as a list of cell pairs, i.e., an `|E|`-by-2 integer-valued matrix, where `|E|` is the number of edges in the graph. Cells are assigned with integer indices starting from 0 in the order that they appear in the expression profile file. We recommend the following two methods to generate the neighbor graph from cells' spatial coordinates:
  - K-nearest neighbor graph under Euclidean metric
  - Delaunay triangulation followed by discarding interactions between cells that are far away from each other

The following files for each FOV are required for downstream analysis and visualization:

- `genes_<expr_suffix>.txt`, a multi-line file containing gene IDs or symbols, one gene per line. The order of genes should match that in `expression_<FOV>_<expr_suffix>.txt`.
- `coordinates_<FOV>.txt`, an N-by-2 matrix of single cells' spatial coordinates in the 2D or 3D space. The current tutorial notebook works only with 2D coordinates.
- `celltypes_<FOV>.txt`, a multi-line file containing cell types from other analysis, one cell type per line. The order of cells should match that in `expression_<FOV>_<expr_suffix>.txt`.

When there are multiple isolated FOVs, the order of genes in `expression_<FOV>_<expr_suffix>.txt` for all FOVs must be identical.

The FOV name, denoted by `<FOV>` here, is required in order to distinguish between cells from different FOVs, especially when they don't share the same coordinate system. FOV names can be any string, such as '1', 'cortex', 'mouse brain Oct-10-2020'.
To compare different preprocessing approaches, the two suffices, `<expr_suffix>` and `<neigh_suffix>`, can be specified for each normalization and neighbor graph, respectively. For example, `neighborhood_3_KNN.txt` and `neighborhood_3_Delaunay.txt` may denote the neighbor graph generated by k-nearest neighbor and Delaunay triangulation, respectively.
The two suffices are optional, and the preceding underscore `_` should be absent when the corresponding suffix is not used (an empty string).

### Step 2: Organizing files

We recommend creating one directory for every data set. In the directory, denoted by `<dataset>`, a directory named `files` should be created and all aforementioned input files should be put in this directory.

For example, when we have one dataset, named `simulation 1`, consisting of 3 FOVs, we should arrange the files in the following manner
```
simulation 1
└── files
    ├── expression_1.txt
    ├── expression_2.txt
    ├── expression_3.txt
    ├── neighborhood_1.txt
    ├── neighborhood_2.txt
    ├── neighborhood_3.txt
    ├── celltypes_1.txt
    ├── celltypes_2.txt
    ├── celltypes_3.txt
    ├── genes_1.txt
    ├── genes_2.txt
    ├── genes_3.txt
    ├── coordinates_1.txt
    ├── coordinates_2.txt
    └── coordinates_3.txt
```

### Step 3: Inferring latent states, metagenes, and pairwise affinity matrix

SpiceMix requires a few arguments to specify the input files and hyperparameters. Below is the table of the description of all arguments:

#### Input related parameters
| params | type | description | example |
|-|-|-|-|
| --path2dataset      | str | path to the dataset | "simulation 1" or "../datasets/mouse primary visual cortex" |
| --neighbor_suffix   | str | suffix of the name of the file that contains interacting cell pairs | "", "KNN", or "Delaunay" |
| --expression_suffix | str | suffix of the name of the file that contains expressions | "", "allgenes", or "top100genes" |
| --repli_list        | list of strings (Python expression)  | A Python expression of a list of FOV names | "[0,1,2]", "[A,B]", or "range(3)" |
| --use_spatial       | list of booleans (Python expression) | A Python expression of a list of boolean variables controlling whether to use the neighbor graph for each FOV | "[True,True,True]", "[False]*5", or "[True,False,True]" |

#### Hyperparameters

| params | type | description | example |
|-|-|-|-|
| -K                  | int | number of metagenes; equivalently, dimension of latent space | 20 |
| --lambda_SigmaXInv  | float | regularization on Sigma_x^{-1} | 1e-4 |
| --max_iter          | int | maximum number of coordinate optimization iterations | 200 or 500 |
| --init_NMF_iter     | int | number of NMF iterations for initialization of SpiceMix, multiplied by 2; an odd number will include an extra round of optimization of latent states | 10 |
| --beta              | list of floats (Python expression) | A Python expression of a list of positive weights for FOVs, the weight will be normalized to be sum-to-one | "[1,1,1]", "[1,10]" |

#### Reproducibility related parameters
| params | type | description | example |
|-|-|-|-|
| --random_seed4kmeans | int | the initial random seed fed to k-means | 0 |

#### Output control
| params | type | description | example |
|-|-|-|-|
| --result_filename | str | the name of the hdf5 file that stores inferred parameters | 'SpiceMix', or 'NMF' |

To run SpiceMix, use the following command filled with proper value for each argument in the `script` directory, e.g.,
```
python main.py -K=20 --dataset="simulation 1" --repli_list="[1,3]" --use_spatial="[True]*2" --result_filename="SpiceMix_K20_FOV13"
python main.py -K=20 --dataset="simulation 1" --repli_list="[1,3]" --use_spatial="[False]*2" --result_filename="NMF_K20_FOV13"
```

### Locating results

The output of one SpiceMix run is saved in an HDF5 file in the `results` directory and its name is specified via the argument to `--result_filename`. In an HDF5 file, there are four groups and the content is organized in the following structure:

- `hyperparameters`: Hyperparameters specified for this run. For example,
  - `hyperparameters/K`: the number of metagenes;
  - `hyperparameters/lambda_SigmaXInv`: the value of the regularization coefficent on `Sigma_x^{-1}`;
  - `hyperparameters/repli_list`: the list of replicate names.
- `progress`: Criterion of convergence. Currently, only one indicator of convergence is implemented:
  - `progress/Q/{i}`: the Q-value after the `i`th iteration, which is the negative logarithm of the joint probability.
- `latent_states`: Latent states, currently including `X` only.
  - `latent_states/XT/{repli_name}/{i}`: an N-by-K matrix containing the latent states in replicate `<repli_name>` after iteration `i`.
- `parameters`: Model parameters:
  - `parameters/M/{i}`: a G-by-K matrix containing the metagenes after iteration `i`;
  - `parameters/Sigma_x_inv/{i}`: a K-by-K matrix containing the affinity matrix after iteration `i`;
  - `parameters/sigma_yx_invs/{repli_name}/{i}`: the value of the reciprocal estimated reconstruction error in replicate `<repli_name>` after iteration `i`.

## Cite

Cite our paper by

```
@article{chidester2020spicemix,
  title={SPICEMIX: Integrative single-cell spatial modeling for inferring cell identity},
  author={Chidester, Benjamin and Zhou, Tianming and Ma, Jian},
  journal={bioRxiv},
  year={2020},
  publisher={Cold Spring Harbor Laboratory}
}
```

![paper](./paper.png)
