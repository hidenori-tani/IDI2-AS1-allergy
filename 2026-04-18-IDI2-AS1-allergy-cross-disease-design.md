# IDI2-AS1-IL5軸のIL5依存性アレルギー疾患横断解析（ドライ解析論文）デザイン

- **作成日**: 2026-04-18
- **著者**: 谷英典（Hidenori Tani, シングルオーサー）
- **想定投稿先**: Frontiers in Immunology（IF ~5.7）
- **位置づけ**: Endo, Kurisu, Tani (BBRC 2025) の臨床的in silico extension

---

## Section 1: リサーチクエスチョンとナラティブ

### 中心仮説

A549細胞でIDI2-AS1低下→IL5上昇という制御軸が、IL5依存性ヒトアレルギー疾患（喘息・アトピー性皮膚炎・好酸球性食道炎・鼻ポリープ）の患者組織でも普遍的に観察される。

### 論文のストーリーアーク

1. 前報（BBRC 2025）で示したIDI2-AS1↓→IL5↑をin vitroでのfindingとして提示
2. 公開RNA-seqで4疾患の患者組織を解析し、IDI2-AS1↓・IL5↑を疾患横断で確認
3. 好酸球浸潤（CIBERSORTx）と相関させ、「IDI2-AS1↓→IL5↑→好酸球↑」を量的に裏付け
4. 特異性check：他の自家lncRNA（4本）・他のサイトカイン（4本）との比較で、IDI2-AS1とIL5の特異的関係を強調
5. Discussion：lncRNA標的治療（メポリズマブ後継としてのRNA医薬）への展望

### タイトル案（仮）

> "Long noncoding RNA IDI2-AS1 is consistently downregulated in IL5-driven allergic diseases: a cross-disease transcriptomic analysis"

---

## Section 2: データソース

### 主データ（4疾患のbulk RNA-seq）

| 疾患 | 組織 | データベース | 規模目安 |
|------|------|------------|---------|
| 喘息 | 気道上皮（bronchial brushing） | GEO（SARP / U-BIOPRED系列）+ ArrayExpress | 患者100+、対照50+ |
| アトピー性皮膚炎 | 皮膚（lesional / non-lesional / healthy） | GEO | 患者30+、対照20+ |
| 好酸球性食道炎 | 食道生検 | GEO | 患者20+、対照15+ |
| 鼻ポリープ（CRSwNP） | 鼻粘膜 | GEO | 患者20+、対照15+ |

### データセット選定の必須条件

- **具体的なGSE番号は実装フェーズで必ず検証**（記憶ベースで番号を固定すると捏造リスクがあるため）
- ①RNA-seqであること（マイクロアレイはlncRNA検出力が弱いので除外）
- ②患者・対照両方を含むこと
- ③サンプルサイズ各群10以上
- ④メタデータ（年齢・性別・重症度）が公開されていること
- ⑤各疾患で**2つ以上の独立データセット**を確保し、再現性を疾患内でも担保

### 補助データ

- **GTEx**: 健常組織（肺・皮膚・食道粘膜・上気道）におけるIDI2-AS1のbaseline発現確認
- **Tabula Sapiens / Human Cell Atlas**（任意）: 組織内のどの細胞でIDI2-AS1が発現するかをsingle-cellレベルで確認（Discussion用）
- **POSTAR3 / RBPDB**（メカニズム考察用）: IDI2-AS1に結合するRBP候補をDiscussionで言及

### 除外する選択肢と理由

- **TCGA**: アレルギー疾患が主題なので除外。Discussionで一言触れる程度
- **マイクロアレイデータ**: IDI2-AS1のような中程度発現lncRNAは旧型アレイでは検出限界以下のリスクあり

### データアクセス・再現性

- 全データは公開済みなので倫理審査不要・追加コスト0
- 解析コードはGitHubで公開（Frontiersは推奨、reviewerからも好まれる）
- 中間データはZenodoでDOI付与（任意だが格上げ要素）

---

## Section 3: 解析パイプライン

### Step 1: データ取得・前処理

- GEOからRNA-seq raw counts（またはFASTQ→再カウント）取得
- 各データセットでquality filter（low count遺伝子除外、サンプルoutlier除外）
- バッチ補正：データセット間統合時は **ComBat-seq**（rawカウント保持型）

### Step 2: 発現解析（疾患ごと独立 → 横断統合）

- 各疾患データセット内：DESeq2で患者vs対照のDEG解析
- IDI2-AS1とIL5のlog2FCとp値を抽出
- 疾患横断：4疾患のlog2FCをforest plotで提示（メタ解析的可視化）
- 必要に応じてrandom-effects meta-analysis（metafor）

### Step 3: 相関解析

- 各データセット内でIDI2-AS1とIL5のサンプルレベル相関（Spearman）
- 全データセット統合での相関も提示
- 期待される結果：負相関（IDI2-AS1↓ ↔ IL5↑）

### Step 4: 好酸球デコンボリューション

- **CIBERSORTx**でLM22 signatureを使い好酸球分画推定
- IDI2-AS1発現 vs 好酸球分画の相関
- IL5発現 vs 好酸球分画の相関（陽性対照として）
- 媒介解析（mediation analysis）も検討：IDI2-AS1 → IL5 → 好酸球の経路を量的に評価

### Step 5: 特異性check

- **lncRNAパネル**: MIR22HG, GABPB1-AS1, OIP5-AS1, LITATS1の各疾患での発現変動 → IDI2-AS1だけが一貫して下がるか
- **サイトカインパネル**: IL4, IL13（Th2）、IL6, TNF（炎症）、IFNG（Th1対照）→ IL5だけがIDI2-AS1と特異的に逆相関するか（IL5本体含めて計6本）
- ヒートマップで一望できる図にまとめる

### Step 6: メカニズム考察用in silico解析（Discussion用、軽め）

- POSTAR3でIDI2-AS1のRBP結合候補をリスト化
- JASPARでIL5プロモーター/エンハンサーの転写因子結合部位
- これらは「mechanism speculation」としてDiscussionに配置（過度に主張しない）

### 使用ツール（全てfree / open source）

- R: DESeq2, ComBat-seq, metafor, immunedeconv
- Python: pandas, scanpy（必要なら）
- Web: CIBERSORTx, GTEx portal, POSTAR3, JASPAR
- 環境：Conda + renvでバージョン固定

### 統計的厳密性の担保

- 多重検定補正：BH法
- 効果量は常にlog2FC + 95% CIで提示
- p値ハッキング回避：解析前にプロトコル固定（OSF登録は任意）

---

## Section 4: Figures & 原稿構成

### Figure構成（6-7枚 + Supplement）

| Fig | 内容 | データ | 図形式 |
|-----|------|------|------|
| **Fig 1** | Graphical abstract / 仮説モデル | コンセプト図 | Schema |
| **Fig 2** | 4疾患でのIDI2-AS1とIL5の発現変動 | DESeq2結果 | Box plot × 4疾患 + Forest plot |
| **Fig 3** | IDI2-AS1とIL5のサンプルレベル相関 | サンプル発現値 | Scatter plot × 4疾患 + 統合 |
| **Fig 4** | 好酸球浸潤との関係 | CIBERSORTx結果 | Scatter plot + Mediation diagram |
| **Fig 5** | lncRNAパネル特異性check | 5本のlncRNA × 4疾患 | Heatmap |
| **Fig 6** | サイトカインパネル特異性check | 6本のサイトカイン × 4疾患 | Heatmap |
| **Fig 7** | メカニズム考察図（RBP / TF予測） | POSTAR3 + JASPAR | Schema + 候補リスト |

### Supplementary

- Sup Table 1: 使用データセット一覧（GSE番号・サンプル数・年齢性別）
- Sup Table 2: 全DEG結果
- Sup Fig 1: GTExでの組織別baseline発現
- Sup Fig 2: バッチ補正前後のPCA
- Sup Fig 3: 各データセット個別の詳細結果

### 原稿構成（Frontiersフォーマット準拠）

| セクション | 目安語数 | 主な内容 |
|----------|--------|--------|
| Abstract | 350語 | 構造化、Background/Methods/Results/Conclusion |
| Introduction | 700-900語 | lncRNA→IDI2-AS1→前報→本研究の位置づけ |
| Materials and Methods | 1500-2000語 | データソース・解析パイプライン詳細 |
| Results | 2000-2500語 | Fig 2-7に沿って |
| Discussion | 1500-2000語 | 臨床的意義・制限・今後の展望 |
| Conclusion | 200語 | 簡潔に |
| References | 50-70本 | |
| **合計** | **6500-8000語** | Frontiers original researchの標準範囲 |

### カバーレターのキーポイント案

- 「BBRC 2025の自然な臨床的延長」
- 「IL5標的biologics（メポリズマブ等）の時代におけるlncRNA上流制御因子の重要性」
- 「dry-only with single author だが、reproducibilityはGitHub公開で担保」

---

## Section 5: リスク・対策・タイムライン

### 主要リスクと対策

| リスク | 確率 | 影響 | 対策 |
|--------|----|------|------|
| **R1: IDI2-AS1が公開RNA-seqで十分検出されない** | 中 | 致命的 | 実装フェーズ最初に「実現可能性チェック」。3-4データセットでIDI2-AS1のカウントを確認してからGo/No-go判断 |
| **R2: 期待した負相関が出ない** | 中 | 大 | ネガティブ結果として論文化する選択肢もある（"in vitro mechanism does not translate"）。ただしFrontiers acceptは厳しくなるのでBBRCに方向転換 |
| **R3: 4疾患のうち1-2疾患で適切なデータセットが見つからない** | 中 | 中 | 最低3疾患で成立すれば論文化可能 |
| **R4: reviewerからwet validation要求** | 高 | 中 | カバーレターで「dry-only design」を明示。GitHub公開コードと再現性を強調。それでもmajor revisionで要求されたら、A549でのRT-qPCR追試をlimited validationとして提示 |
| **R5: シングルオーサーへのreviewer違和感** | 中 | 中 | Acknowledgmentsで前報の共同研究者（Endo, Kurisu）に明記。「Following our previous work (Endo et al., 2025), the present in silico extension was conducted by HT」と説明 |
| **R6: 研究時間の確保**（教育・授業多忙） | 高 | 中 | 段階的マイルストーン制で進める |

### 実現可能性チェック（Go/No-go gate）

実装の最初に必ず実施：

1. GEOで4疾患それぞれRNA-seqデータセット2個以上見つかるか
2. その中でIDI2-AS1のcountが検出可能（5サンプル以上で>10 reads）か
3. 1疾患でもいいのでパイロット解析でIDI2-AS1↓のtrendが見えるか

→ 全てYesなら本格着手。Noなら設計再考。

### タイムライン目安

| Month | マイルストーン |
|-------|--------------|
| M1 | データセット選定 + Go/No-go判定（パイロット解析含む） |
| M2-3 | 全データセットの取得・前処理・DEG解析 |
| M4 | 好酸球デコンボリューション + 相関解析 |
| M5 | 特異性check（lncRNA/サイトカインパネル） |
| M6 | Figure整形 + Methods執筆 |
| M7 | Results + Discussion執筆 |
| M8 | Introduction + Abstract + Cover letter |
| M9 | 内部review（先生自身 + AI review）+ submission |

→ **submit目標：2027年1月頃**（2026年5月開始想定）

### 「やめどき」の基準

- M1のGo/No-go gateで赤信号 → 撤退
- M3でDEG結果が期待と全く逆 → 方向転換（ネガティブ結果論文 or 別lncRNAへピボット）
- それ以外は最後まで走る

---

## 著者・利益相反

- **筆頭・責任著者**: Hidenori Tani（横浜薬科大学 健康薬学講座 准教授）
- **利益相反**: なし
- **資金**: 該当なし（既存ラボリソース内で実施）
- **倫理**: 公開データのみ使用のため不要

## データ・コード公開

- 解析コード: GitHub（投稿時公開）
- 中間データ・最終結果: Zenodo（任意）
- 使用データ: 全て公開GEO/ArrayExpress（GSE番号はSup Table 1に記載）
