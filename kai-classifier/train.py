"""Baseline condition-tag classifier for ChatConnect's Insights feature.

Trains on datasets/4.zip:Classification_dataset.csv (cleaned Reddit posts
labeled Anxiety / bipolar / BPD / depression). This tags journal/chat entries
with a likely condition theme — it is NOT a crisis/self-harm risk detector.
"""

import zipfile
from pathlib import Path

import joblib
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.model_selection import train_test_split

ROOT = Path(__file__).resolve().parent.parent
DATASET_ZIP = ROOT / "datasets" / "4.zip"
MODEL_DIR = Path(__file__).resolve().parent / "model"

with zipfile.ZipFile(DATASET_ZIP) as z:
    with z.open("Classification_dataset.csv") as f:
        df = pd.read_csv(f)

df = df.dropna(subset=["cleaned_text", "subreddit"])

X_train, X_test, y_train, y_test = train_test_split(
    df["cleaned_text"],
    df["subreddit"],
    test_size=0.2,
    stratify=df["subreddit"],
    random_state=42,
)

vectorizer = TfidfVectorizer(max_features=5000, ngram_range=(1, 2), min_df=2)
X_train_vec = vectorizer.fit_transform(X_train)
X_test_vec = vectorizer.transform(X_test)

model = LogisticRegression(max_iter=1000, class_weight="balanced")
model.fit(X_train_vec, y_train)

y_pred = model.predict(X_test_vec)

print(classification_report(y_test, y_pred))
print("Confusion matrix (rows=actual, cols=predicted):")
print(pd.DataFrame(
    confusion_matrix(y_test, y_pred, labels=model.classes_),
    index=model.classes_,
    columns=model.classes_,
))

MODEL_DIR.mkdir(exist_ok=True)
joblib.dump(vectorizer, MODEL_DIR / "vectorizer.joblib")
joblib.dump(model, MODEL_DIR / "condition_classifier.joblib")
print(f"\nSaved vectorizer + model to {MODEL_DIR}")
