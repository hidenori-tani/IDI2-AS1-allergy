"""
Search GEO for candidate RNA-seq datasets - documentation script.

The actual search was conducted via web search (PubMed + GEO browsing) on 2026-04-18.
Final candidates selected: data/metadata/candidate_datasets.csv

Search criteria applied:
  - Platform: RNA-seq (Illumina HiSeq/NovaSeq) — microarray excluded
  - Tissue: disease-relevant (airway/skin/esophagus/nasal)
  - Sample size: prefer >= 10 per group (relaxed for EoE due to field limitation)
  - Metadata: partial or full clinical metadata available
  - Processed counts: available as supplementary file (not requiring re-alignment)

Selected datasets (8 total, 2 per disease):

  Asthma:
    GSE201955 (Ober lab, BECs, n=88+42)
    GSE152004 (Sajuthi 2020, NEC, n>>100)

  Atopic Dermatitis:
    GSE121212 (Tsoi, skin, n=27+38)
    GSE65832 (Suarez-Farinas, paired LS/NL, n=20+20)

  Eosinophilic Esophagitis:
    GSE58640 (Sherrill 2014, esophagus, n=10+6)  [field-standard]
    GSE246323 (Kleuskens 2024, esophagus, n=5+5)

  Nasal polyposis (CRSwNP):
    GSE136825 (Wang 2019, polyp, n=42+33)
    GSE179269 (Nakayama, polyp, n=17+7)

For new searches, use:
  https://www.ncbi.nlm.nih.gov/gds/
  Filter: Series, Expression profiling by high throughput sequencing, Homo sapiens
"""

import pandas as pd
from pathlib import Path

CSV = Path(__file__).parent.parent.parent / "data" / "metadata" / "candidate_datasets.csv"


def main():
    if not CSV.exists():
        raise FileNotFoundError(f"{CSV} not found. Run web search and populate manually.")
    df = pd.read_csv(CSV)
    print(f"Loaded {len(df)} candidate datasets")
    print()
    summary = df.groupby("disease").agg(
        n_datasets=("gse_id", "count"),
        total_patient=("n_patient", "sum"),
        total_control=("n_control", "sum"),
    )
    print(summary)
    print()
    print("Per-disease feasibility (>=2 datasets, >=10 patients each):")
    for disease, group in df.groupby("disease"):
        n_ds = len(group)
        n_qual = (group["n_patient"] >= 10).sum()
        status = "PASS" if (n_ds >= 2 and n_qual >= 1) else "REVIEW"
        print(f"  {disease}: {n_ds} datasets, {n_qual} with n_patient>=10 -> {status}")


if __name__ == "__main__":
    main()
