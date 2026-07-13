#!/usr/bin/env python3

import sys
from pathlib import Path

# This file is `celltypist.py`, which would shadow the `celltypist` pip package on
# `import celltypist` (the script's own dir is sys.path[0]). Replace that entry with
# the vendored `src/` dir: drops the shadow AND puts `common` (src/common) on the path.
sys.path[0] = str(Path(__file__).resolve().parent / "src")

import argparse

import scanpy as sc
import pandas as pd

from common import cli

import celltypist
from celltypist import models


def log(msg: str) -> None:
    print(f"[celltypist.py] {msg}", file=sys.stderr, flush=True)


def parse_args():
    # src/common/cli injects the shared contract (base args + the ANNO stage I/O);
    # --model is this module's own method parameter
    p = argparse.ArgumentParser(description="ANNO module (CellTypist)")
    cli.add_base_args(p)            # --output_dir, --name
    cli.add_stage_args(p, "ANNO")   # --normalized_selected_h5, --rawdata_h5ad
    p.add_argument("--model", required=True,
                   help="CellTypist model, e.g. Immune_All_Low or Immune_All_High")
    return p.parse_args()


def main() -> None:
    args = parse_args()

    print(f"Output directory: {args.output_dir}")
    print(f"Module name: {args.name}")
    print(f"rawdata_h5ad: {args.rawdata_h5ad}")
    print(f"model: {args.model}")

    # CellTypist ships models as `<name>.pkl`; accept the bare name on the CLI too.
    model_file = args.model if args.model.endswith(".pkl") else f"{args.model}.pkl"

    # Read raw counts, all genes. Trust .X (counts); ignore the mislabeled logcounts layer.
    adata = sc.read_h5ad(args.rawdata_h5ad)
    log(f"loaded AnnData: {adata.n_obs} cells x {adata.n_vars} genes")

    # CellTypist expects log1p CP10k in .X -> normalize in-module from the raw counts.
    sc.pp.normalize_total(adata, target_sum=1e4)
    sc.pp.log1p(adata)
    log(f"normalized to log1p CP10k; running celltypist model {model_file}")

    # Fetch the model if it isn't cached yet (no-op when already present).
    models.download_models(model=model_file, force_update=False)

    predictions = celltypist.annotate(adata, model=model_file, majority_voting=False)
    pred = predictions.predicted_labels  # DataFrame indexed by cell_id, col 'predicted_labe

    out_df = pd.DataFrame({
        "cell_id": pred.index.astype(str),
        "predicted_labels": pred["predicted_labels"].astype(str).values,
    })

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    out_path = output_dir / f"{args.name}_annotations.tsv"
    out_df.to_csv(out_path, sep="\t", index=False)
    log(f"wrote {out_path}")


if __name__ == "__main__":
    main()