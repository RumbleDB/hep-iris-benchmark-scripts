# Plots

This folder contains the exact PDFs used in the final paper, the measurements
used in the plots, and the scripts that generate them.

## Prerequisites

* Python 3 with `pip` and the dependencies:
  ```bash
  pip install -r requirements.txt
  ```

## Updating measurements

If you rerun some experiments, put them into the corresponding `system.json` as
instructed by the README of that system.

## Reproducing plots

The subfigures of each figure of the paper are produced by one `.sh` script. To
invoke all these script, simply run:

```bash
./plots.sh
```

That file also documents the mapping of the individual scripts to paper figures.
