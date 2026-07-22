from pathlib import Path
import pandas as pd

RAW_DIR = Path("data/raw")
DOCS_DIR = Path("docs")
DOCS_DIR.mkdir(exist_ok=True)

csv_files = sorted(RAW_DIR.glob("*.csv"))

if not csv_files:
    raise FileNotFoundError("No CSV files found in data/raw folder.")

profile_lines = []
profile_lines.append("# Olist E-Commerce Dataset Profile\n")
profile_lines.append("This file was generated automatically from the raw CSV files.\n\n")

for csv_file in csv_files:
    print(f"Reading: {csv_file.name}")

    df_sample = pd.read_csv(csv_file, nrows=5000, encoding="utf-8")
    total_rows = sum(1 for _ in open(csv_file, encoding="utf-8")) - 1

    profile_lines.append(f"## {csv_file.name}\n")
    profile_lines.append(f"- Rows: {total_rows}\n")
    profile_lines.append(f"- Columns: {len(df_sample.columns)}\n\n")

    profile_lines.append("| Column | Pandas inferred dtype | Missing in sample | Example value |\n")
    profile_lines.append("|---|---|---:|---|\n")

    for col in df_sample.columns:
        dtype = str(df_sample[col].dtype)
        missing = int(df_sample[col].isna().sum())
        example = df_sample[col].dropna().iloc[0] if not df_sample[col].dropna().empty else ""
        example = str(example).replace("|", " ")
        profile_lines.append(f"| {col} | {dtype} | {missing} | {example} |\n")

    profile_lines.append("\n")

output_path = DOCS_DIR / "dataset_profile.md"
output_path.write_text("".join(profile_lines), encoding="utf-8")

print(f"\nProfile generated successfully: {output_path}")
