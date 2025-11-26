Aqui está um arquivo `README.md` para acompanhar o script `main.py`:

---

# Heatmap Generator for Research Questions

This Python script generates a heatmap visualization showing the relationship between academic articles and research questions based on text files.

## Overview

The script processes multiple text files (prefixed with 'rq') where each file represents a research question and contains a list of article references. It creates a heatmap where:
- **Rows** represent individual articles
- **Columns** represent research questions (RQ1, RQ2, etc.)
- **Cells** indicate presence (1) or absence (0) of an article for a particular research question

## Prerequisites

Before running the script, ensure you have the following Python packages installed:

```bash
pip install pandas seaborn matplotlib
```

## Input Files

1. Create text files with the naming pattern `rq*.txt` (e.g., `rq1.txt`, `rq2.txt`, `rq3.txt`)
2. Each file should contain one article reference per line
3. Article references can be any unique identifier (DOIs, titles, citation keys, etc.)
4. Empty lines are automatically ignored

### Example file structure:
```
rq1.txt:
Article_A
Article_B
Article_C

rq2.txt:
Article_B
Article_D
Article_E
```

## Usage

1. Place all your `rq*.txt` files in the same directory as `main.py`
2. Run the script:

```bash
python main.py
```

3. The heatmap will be displayed in a matplotlib window

## Output

- A heatmap visualization showing article distribution across research questions
- Articles are sorted by frequency (most cited articles at the bottom)
- Research questions are sorted numerically (RQ1, RQ2, RQ3, etc.)
- White cells indicate absence, blue cells indicate presence of an article

## Customization

You can modify the following parameters in the script:
- `altura_por_linha`: Height per row in the heatmap
- `largura_por_coluna`: Width per column in the heatmap
- Color scheme in `sns.color_palette(["#ffffff", "#1f77b4"])`
- Font sizes for axis labels

## Notes

- The script automatically handles duplicate references within the same research question
- The heatmap dimensions adjust dynamically based on the number of articles and research questions
- For large datasets, consider adjusting the font sizes to maintain readability

---